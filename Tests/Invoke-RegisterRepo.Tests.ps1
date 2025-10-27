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
    Mock Register-PSResourceRepository {}
}

Describe 'Invoke-RegisterRepo' {
    Context 'Valid GitHub Packages URL' {
        It 'Should register repository with valid URL' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            { Invoke-RegisterRepo -RepositoryName 'TestRepo' -RegistryUri 'https://nuget.pkg.github.com/testorg/index.json' -Credential $cred } | Should -Not -Throw
            
            # Assert
            Should -Invoke Register-PSResourceRepository -Times 1 -Exactly
        }
        
        It 'Should register repository with Trusted flag' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            { Invoke-RegisterRepo -RepositoryName 'TestRepo' -RegistryUri 'https://nuget.pkg.github.com/testorg/index.json' -Credential $cred -Trusted } | Should -Not -Throw
            
            # Assert
            Should -Invoke Register-PSResourceRepository -Times 1 -Exactly -ParameterFilter { $Trusted -eq $true }
        }
        
        It 'Should log success message' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-RegisterRepo -RepositoryName 'TestRepo' -RegistryUri 'https://nuget.pkg.github.com/testorg/index.json' -Credential $cred
            
            # Assert
            Should -Invoke Write-LogInfo -Times 2 -Exactly
        }
        
        It 'Should mask credentials in debug log' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-RegisterRepo -RepositoryName 'TestRepo' -RegistryUri 'https://nuget.pkg.github.com/testorg/index.json' -Credential $cred
            
            # Assert
            Should -Invoke Write-LogDebug -ParameterFilter { $Message -match '\*\*\*' }
        }
    }
    
    Context 'Invalid GitHub Packages URL' {
        It 'Should throw error for invalid hostname' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act & Assert
            { Invoke-RegisterRepo -RepositoryName 'TestRepo' -RegistryUri 'https://invalid.example.com/index.json' -Credential $cred } | Should -Throw -ExpectedMessage '*Invalid GitHub Packages URL*'
        }
        
        It 'Should not call Register-PSResourceRepository for invalid URL' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            try {
                Invoke-RegisterRepo -RepositoryName 'TestRepo' -RegistryUri 'https://invalid.example.com/index.json' -Credential $cred
            }
            catch {
                # Expected to throw
            }
            
            # Assert
            Should -Invoke Register-PSResourceRepository -Times 0 -Exactly
        }
        
        It 'Should log error message for invalid URL' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            try {
                Invoke-RegisterRepo -RepositoryName 'TestRepo' -RegistryUri 'https://invalid.example.com/index.json' -Credential $cred
            }
            catch {
                # Expected to throw
            }
            
            # Assert
            Should -Invoke Write-LogError -Times 1 -Exactly
        }
    }
    
    Context 'Error handling' {
        It 'Should propagate errors from Register-PSResourceRepository' {
            # Arrange
            Mock Register-PSResourceRepository { throw "Registration failed" }
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act & Assert
            { Invoke-RegisterRepo -RepositoryName 'TestRepo' -RegistryUri 'https://nuget.pkg.github.com/testorg/index.json' -Credential $cred } | Should -Throw
        }
    }
}
