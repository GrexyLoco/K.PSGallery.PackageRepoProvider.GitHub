BeforeAll {
    # Import the module
    $modulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$modulePath/K.PSGallery.PackageRepoProvider.GitHub.psd1" -Force
    
    # Mock the logging functions
    Mock Write-LogInfo {}
    Mock Write-LogDebug {}
    Mock Write-LogError {}
    Mock Write-LogWarning {}
    
    # Mock PSResourceGet cmdlets
    Mock Publish-PSResource {}
    
    # Create a temporary test module directory
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
    
    # Mock Import-PowerShellDataFile
    Mock Import-PowerShellDataFile {
        return @{
            RootModule = 'TestModule.psm1'
            ModuleVersion = '1.0.0'
        }
    }
}

Describe 'Invoke-Publish' {
    Context 'Valid module with manifest' {
        It 'Should publish module successfully' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            { Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $script:testModuleDir.FullName -Credential $cred } | Should -Not -Throw
            
            # Assert
            Should -Invoke Publish-PSResource -Times 1 -Exactly
        }
        
        It 'Should log success message' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $script:testModuleDir.FullName -Credential $cred
            
            # Assert
            Should -Invoke Write-LogInfo -Times 2 -Exactly
        }
        
        It 'Should mask credentials in debug log' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $script:testModuleDir.FullName -Credential $cred
            
            # Assert
            Should -Invoke Write-LogDebug -ParameterFilter { $Message -match '\*\*\*' }
        }
        
        It 'Should warn on module name mismatch' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $script:testModuleDir.FullName -ModuleName 'DifferentName' -Credential $cred
            
            # Assert
            Should -Invoke Write-LogWarning -Times 1 -Exactly
        }
    }
    
    Context 'Missing module manifest' {
        It 'Should throw error when manifest is missing' {
            # Arrange
            $emptyDir = New-Item -Path (Join-Path $TestDrive 'EmptyModule') -ItemType Directory -Force
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act & Assert
            { Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $emptyDir.FullName -Credential $cred } | Should -Throw
        }
        
        It 'Should not call Publish-PSResource when manifest is missing' {
            # Arrange
            $emptyDir = New-Item -Path (Join-Path $TestDrive 'EmptyModule2') -ItemType Directory -Force
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            try {
                Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $emptyDir.FullName -Credential $cred
            }
            catch {
                # Expected to throw
            }
            
            # Assert - Reset invoke count for this specific test
            Should -Invoke Publish-PSResource -Times 0 -Exactly -Scope It
        }
        
        It 'Should log error message when manifest is missing' {
            # Arrange
            $emptyDir = New-Item -Path (Join-Path $TestDrive 'EmptyModule3') -ItemType Directory -Force
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            try {
                Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $emptyDir.FullName -Credential $cred
            }
            catch {
                # Expected to throw
            }
            
            # Assert
            Should -Invoke Write-LogError -Times 1 -Exactly -Scope It
        }
    }
    
    Context 'Error handling' {
        It 'Should propagate errors from Publish-PSResource' {
            # Arrange
            Mock Publish-PSResource { throw "Publish failed" }
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act & Assert
            { Invoke-Publish -RepositoryName 'TestRepo' -ModulePath $script:testModuleDir.FullName -Credential $cred } | Should -Throw
        }
    }
}
