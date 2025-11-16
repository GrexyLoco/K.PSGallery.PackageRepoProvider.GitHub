BeforeAll {
    # Source the SafeLogging and function directly instead of importing module
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath "Private" | Join-Path -ChildPath "SafeLogging.ps1")
    . (Join-Path $modulePath "Public" | Join-Path -ChildPath "Invoke-Install.ps1")
    
    # Mock the SafeLogging functions
    Mock Write-SafeInfoLog {}
    Mock Write-SafeDebugLog {}
    Mock Write-SafeErrorLog {}
    Mock Write-SafeWarningLog {}
    
    # Mock PSResourceGet cmdlets
    Mock Install-PSResource {}
    Mock Import-Module {}
}

Describe 'Invoke-Install' {
    Context 'API signature validation' {
        It 'Should have expected parameters' {
            $command = Get-Command Invoke-Install
            $parameters = $command.Parameters.Keys
            
            $parameters | Should -Contain 'RepositoryName'
            $parameters | Should -Contain 'ModuleName'
            $parameters | Should -Contain 'Version'
            $parameters | Should -Contain 'Credential'
            $parameters | Should -Contain 'Scope'
            $parameters | Should -Contain 'ImportAfterInstall'
            
            $command.Parameters['RepositoryName'].ParameterType.Name | Should -Be 'String'
            $command.Parameters['ModuleName'].ParameterType.Name | Should -Be 'String'
            $command.Parameters['Version'].ParameterType.Name | Should -Be 'String'
            $command.Parameters['Credential'].ParameterType.Name | Should -Be 'PSCredential'
            $command.Parameters['Scope'].ParameterType.Name | Should -Be 'String'
            $command.Parameters['ImportAfterInstall'].ParameterType.Name | Should -Be 'SwitchParameter'
        }
    }
    
    Context 'Version parsing' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestRepo'
            $script:moduleName = 'TestModule'
        }
        
        It 'Should parse version "v1" to "1.*"' {
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Version 'v1' -Credential $script:testCred
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Version -eq '1.*' }
        }
        
        It 'Should parse version "1" to "1.*"' {
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Version '1' -Credential $script:testCred
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Version -eq '1.*' }
        }
        
        It 'Should parse version "1.2" to "1.2.*"' {
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Version '1.2' -Credential $script:testCred
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Version -eq '1.2.*' }
        }
        
        It 'Should keep version "1.2.3" as is' {
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Version '1.2.3' -Credential $script:testCred
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Version -eq '1.2.3' }
        }
        
        It 'Should install latest version when no version specified' {
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Credential $script:testCred
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { -not $PSBoundParameters.ContainsKey('Version') }
        }
    }
    
    Context 'Scope parameter' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestRepo'
            $script:moduleName = 'TestModule'
        }
        
        It 'Should use CurrentUser scope by default' {
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Credential $script:testCred
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Scope -eq 'CurrentUser' }
        }
        
        It 'Should use AllUsers scope when specified' {
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Scope 'AllUsers' -Credential $script:testCred
            Should -Invoke Install-PSResource -Times 1 -Exactly -ParameterFilter { $Scope -eq 'AllUsers' }
        }
    }
    
    Context 'Import after install' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestRepo'
            $script:moduleName = 'TestModule'
        }
        
        It 'Should import module when ImportAfterInstall is specified' {
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Credential $script:testCred -ImportAfterInstall
            Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter { $Name -eq $script:moduleName -and $Force -eq $true }
        }
        
        It 'Should not import module when ImportAfterInstall is not specified' {
            Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Credential $script:testCred
            Should -Invoke Import-Module -Times 0 -Exactly -Scope It
        }
    }
    
    Context 'Error handling' {
        BeforeEach {
            Mock Install-PSResource { throw "Installation failed" }
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestRepo'
            $script:moduleName = 'TestModule'
        }
        
        It 'Should propagate errors from Install-PSResource' {
            { Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Credential $script:testCred } | Should -Throw
        }
        
        It 'Should log error message on failure' {
            try {
                Invoke-Install -RepositoryName $script:repoName -ModuleName $script:moduleName -Credential $script:testCred
            }
            catch {
                # Expected to throw
            }
            
            Should -Invoke Write-SafeErrorLog -Times 1 -Exactly -Scope It
        }
    }
}
