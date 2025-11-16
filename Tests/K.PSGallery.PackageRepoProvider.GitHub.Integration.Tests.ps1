BeforeAll {
    # Source SafeLogging first (provides Write-Safe* functions)
    $modulePath = Split-Path -Parent $PSScriptRoot
    . "$modulePath/Private/SafeLogging.ps1"
    
    # Source the PUBLIC functions (moved from Private to Public)
    . "$modulePath/Public/Invoke-RegisterRepo.ps1"
    . "$modulePath/Public/Invoke-Publish.ps1"
    . "$modulePath/Public/Invoke-Install.ps1"
    . "$modulePath/Public/Invoke-Import.ps1"
    . "$modulePath/Public/Invoke-RemoveRepo.ps1"
    
    # Mock the SafeLogging functions (they're already sourced from SafeLogging.ps1)
    Mock Write-SafeInfoLog {}
    Mock Write-SafeDebugLog {}
    Mock Write-SafeErrorLog {}
    Mock Write-SafeWarningLog {}
    
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
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestGitHubRepo'
            $script:repoUri = 'https://nuget.pkg.github.com/testorg/index.json'
            $script:moduleName = 'TestModule'
        }
        
        It 'Should complete full workflow without errors' {
            # Act & Assert - Register Repository
            { Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:repoUri -Credential $script:testCred -Trusted } | Should -Not -Throw
            Should -Invoke Register-PSResourceRepository -Times 1 -Exactly
            
            # Act & Assert - Publish Module
            { Invoke-Publish -RepositoryName $script:repoName -ModulePath $script:testModuleDir.FullName -Credential $script:testCred } | Should -Not -Throw
            Should -Invoke Publish-PSResource -Times 1 -Exactly
            
            # Act & Assert - Install Module
            { Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Version 'v1' -Credential $script:testCred -ImportAfterInstall } | Should -Not -Throw
            Should -Invoke Install-PSResource -Times 1 -Exactly
            Should -Invoke Import-Module -Times 1 -Exactly
            
            # Act & Assert - Import Module (standalone)
            { Invoke-Import -ModuleName $script:moduleName -Force } | Should -Not -Throw
            Should -Invoke Import-Module -Times 2 -Exactly
            
            # Act & Assert - Remove Repository
            { Invoke-RemoveRepo -RepositoryName $script:repoName } | Should -Not -Throw
            Should -Invoke Unregister-PSResourceRepository -Times 1 -Exactly
        }
    }
    
    Context 'Repository lifecycle' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestRepo'
            $script:repoUri = 'https://nuget.pkg.github.com/testorg/index.json'
        }
        
        It 'Should register and remove repository successfully' {
            # Act - Register
            Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:repoUri -Credential $script:testCred
            
            # Assert
            Should -Invoke Register-PSResourceRepository -Times 1 -Exactly -Scope It
            
            # Act - Remove
            Invoke-RemoveRepo -RepositoryName $script:repoName
            
            # Assert
            Should -Invoke Unregister-PSResourceRepository -Times 1 -Exactly -Scope It
        }
    }
    
    Context 'Module publishing and installation' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestRepo'
            $script:moduleName = 'TestModule'
        }
        
        It 'Should publish and install module with version parsing' {
            # Act - Publish
            Invoke-Publish -RepositoryName $script:repoName -ModulePath $script:testModuleDir.FullName -Credential $script:testCred
            
            # Assert
            Should -Invoke Publish-PSResource -Times 1 -Exactly -Scope It
            
            # Act - Install with different version formats
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Version 'v1' -Credential $script:testCred
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Version '1.2' -Credential $script:testCred
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Version '1.2.3' -Credential $script:testCred
            
            # Assert
            Should -Invoke Install-PSResource -Times 3 -Exactly -Scope It
        }
    }
    
    Context 'Error scenarios' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
        }
        
        It 'Should handle invalid repository URL gracefully' {
            { Invoke-RegisterRepo -RepositoryName 'BadRepo' -RegistryUri 'https://invalid.com/index.json' -Credential $script:testCred } | Should -Throw -ExpectedMessage '*Invalid GitHub Packages URL*'
        }
        
        It 'Should handle missing manifest gracefully' {
            $emptyDir = New-Item -Path (Join-Path $TestDrive 'EmptyModule') -ItemType Directory -Force
            { Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $emptyDir.FullName -Credential $script:testCred } | Should -Throw
        }
    }
}
