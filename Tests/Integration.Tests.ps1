BeforeAll {
    # Import the module
    $modulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$modulePath/K.PSGallery.PackageRepoProvider.GitHub.psd1" -Force
    
    # Mock the logging functions
    Mock Write-LogInfo {}
    Mock Write-LogDebug {}
    Mock Write-LogError {}
    Mock Write-LogWarning {}
    
    # Mock all external cmdlets
    Mock Register-PSResourceRepository {}
    Mock Publish-PSResource {}
    Mock Install-PSResource {}
    Mock Import-Module {}
    Mock Unregister-PSResourceRepository {}
    Mock Import-PowerShellDataFile {
        return @{
            RootModule = 'TestModule.psm1'
            ModuleVersion = '1.0.0'
        }
    }
    
    # Create test module directory
    $script:testModuleDir = New-Item -Path (Join-Path $TestDrive 'TestModule') -ItemType Directory -Force
    $script:testManifest = New-Item -Path (Join-Path $script:testModuleDir 'TestModule.psd1') -ItemType File -Force
    
    # Create a manifest content
    $manifestContent = @"
@{
    RootModule = 'TestModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'Test Author'
}
"@
    Set-Content -Path $script:testManifest -Value $manifestContent
}

Describe 'Integration Tests - End-to-End Workflow' {
    Context 'Complete workflow: Register -> Publish -> Install -> Import -> Remove' {
        It 'Should complete full workflow without errors' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $repoName = 'TestGitHubRepo'
            $repoUri = 'https://nuget.pkg.github.com/testorg/index.json'
            $moduleName = 'TestModule'
            
            # Act & Assert - Register Repository
            { Invoke-RegisterRepo -RepositoryName $repoName -RegistryUri $repoUri -Credential $cred -Trusted } | Should -Not -Throw
            Should -Invoke Register-PSResourceRepository -Times 1 -Exactly
            
            # Act & Assert - Publish Module
            { Invoke-Publish -RepositoryName $repoName -ModulePath $script:testModuleDir.FullName -Credential $cred } | Should -Not -Throw
            Should -Invoke Publish-PSResource -Times 1 -Exactly
            
            # Act & Assert - Install Module
            { Invoke-Install -RepositoryName $repoName -ModuleName $moduleName -Version 'v1' -Credential $cred -ImportAfterInstall } | Should -Not -Throw
            Should -Invoke Install-PSResource -Times 1 -Exactly
            Should -Invoke Import-Module -Times 1 -Exactly
            
            # Act & Assert - Import Module (standalone)
            { Invoke-Import -ModuleName $moduleName -Force } | Should -Not -Throw
            Should -Invoke Import-Module -Times 2 -Exactly
            
            # Act & Assert - Remove Repository
            { Invoke-RemoveRepo -RepositoryName $repoName } | Should -Not -Throw
            Should -Invoke Unregister-PSResourceRepository -Times 1 -Exactly
        }
    }
    
    Context 'Repository lifecycle' {
        It 'Should register and remove repository successfully' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $repoName = 'TestRepo'
            $repoUri = 'https://nuget.pkg.github.com/testorg/index.json'
            
            # Act - Register
            Invoke-RegisterRepo -RepositoryName $repoName -RegistryUri $repoUri -Credential $cred
            
            # Assert
            Should -Invoke Register-PSResourceRepository -Times 1 -Exactly -Scope It
            
            # Act - Remove
            Invoke-RemoveRepo -RepositoryName $repoName
            
            # Assert
            Should -Invoke Unregister-PSResourceRepository -Times 1 -Exactly -Scope It
        }
    }
    
    Context 'Module publishing and installation' {
        It 'Should publish and install module with version parsing' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $repoName = 'TestRepo'
            $moduleName = 'TestModule'
            
            # Act - Publish
            Invoke-Publish -RepositoryName $repoName -ModulePath $script:testModuleDir.FullName -Credential $cred
            
            # Assert
            Should -Invoke Publish-PSResource -Times 1 -Exactly -Scope It
            
            # Act - Install with different version formats
            Invoke-Install -RepositoryName $repoName -ModuleName $moduleName -Version 'v1' -Credential $cred
            Invoke-Install -RepositoryName $repoName -ModuleName $moduleName -Version '1.2' -Credential $cred
            Invoke-Install -RepositoryName $repoName -ModuleName $moduleName -Version '1.2.3' -Credential $cred
            
            # Assert
            Should -Invoke Install-PSResource -Times 3 -Exactly -Scope It
        }
    }
    
    Context 'Error scenarios' {
        It 'Should handle invalid repository URL gracefully' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act & Assert
            { Invoke-RegisterRepo -RepositoryName 'BadRepo' -RegistryUri 'https://invalid.com/index.json' -Credential $cred } | Should -Throw -ExpectedMessage '*Invalid GitHub Packages URL*'
        }
        
        It 'Should handle missing manifest gracefully' {
            # Arrange
            $emptyDir = New-Item -Path (Join-Path $TestDrive 'EmptyModule') -ItemType Directory -Force
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act & Assert
            { Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $emptyDir.FullName -Credential $cred } | Should -Throw
        }
    }
}
