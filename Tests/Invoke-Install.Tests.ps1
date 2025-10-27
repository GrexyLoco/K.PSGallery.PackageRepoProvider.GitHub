BeforeAll {
    # Create stub logging functions before sourcing
    function Write-LogInfo { param($Message) }
    function Write-LogDebug { param($Message) }
    function Write-LogError { param($Message) }
    function Write-LogWarning { param($Message) }
    
    # Source the function directly instead of importing module
    $modulePath = Split-Path -Parent $PSScriptRoot
    . "$modulePath/Private/Invoke-Install.ps1"
    
    # Mock the logging functions
    Mock Write-LogInfo {}
    Mock Write-LogDebug {}
    Mock Write-LogError {}
    Mock Write-LogWarning {}
    
    # Mock PSResourceGet cmdlets
    Mock Install-PSResource {}
    Mock Import-Module {}
}

Describe 'Invoke-Install' {
    Context 'Version parsing' {
        It 'Should parse version "v1" to "1.*"' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Version 'v1' -Credential $cred
            
            # Assert
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Version -eq '1.*' }
        }
        
        It 'Should parse version "1" to "1.*"' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Version '1' -Credential $cred
            
            # Assert
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Version -eq '1.*' }
        }
        
        It 'Should parse version "1.2" to "1.2.*"' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Version '1.2' -Credential $cred
            
            # Assert
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Version -eq '1.2.*' }
        }
        
        It 'Should keep version "1.2.3" as is' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Version '1.2.3' -Credential $cred
            
            # Assert
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Version -eq '1.2.3' }
        }
        
        It 'Should install latest version when no version specified' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Credential $cred
            
            # Assert
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { -not $PSBoundParameters.ContainsKey('Version') }
        }
    }
    
    Context 'Scope parameter' {
        It 'Should use CurrentUser scope by default' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Credential $cred
            
            # Assert
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Scope -eq 'CurrentUser' }
        }
        
        It 'Should use AllUsers scope when specified' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Scope 'AllUsers' -Credential $cred
            
            # Assert
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Scope -eq 'AllUsers' }
        }
    }
    
    Context 'Import after install' {
        It 'Should import module when ImportAfterInstall is specified' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Credential $cred -ImportAfterInstall
            
            # Assert
            Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter { $Name -eq 'TestModule' -and $Force -eq $true }
        }
        
        It 'Should not import module when ImportAfterInstall is not specified' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Credential $cred
            
            # Assert
            Should -Invoke Import-Module -Times 0 -Exactly -Scope It
        }
    }
    
    Context 'Logging' {
        It 'Should log installation start and success' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Credential $cred
            
            # Assert
            Should -Invoke Write-LogInfo -Times 2 -Exactly -Scope It
        }
        
        It 'Should log debug information with version' {
            # Arrange
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Version '1.2.3' -Credential $cred
            
            # Assert
            Should -Invoke Write-LogDebug -Times 1 -Exactly -Scope It
        }
    }
    
    Context 'Error handling' {
        It 'Should propagate errors from Install-PSResource' {
            # Arrange
            Mock Install-PSResource { throw "Installation failed" }
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act & Assert
            { Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Credential $cred } | Should -Throw
        }
        
        It 'Should log error message on failure' {
            # Arrange
            Mock Install-PSResource { throw "Installation failed" }
            $cred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            
            # Act
            try {
                Invoke-Install -RepositoryName 'TestRepo' -ModuleName 'TestModule' -Credential $cred
            }
            catch {
                # Expected to throw
            }
            
            # Assert
            Should -Invoke Write-LogError -Times 1 -Exactly -Scope It
        }
    }
}
