BeforeAll {
    # Source the SafeLogging and function directly instead of importing module
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath "Private" | Join-Path -ChildPath "SafeLogging.ps1")
    . (Join-Path $modulePath "Public" | Join-Path -ChildPath "Invoke-RegisterRepo.ps1")
    
    # Mock the SafeLogging functions
    Mock Write-SafeInfoLog {}
    Mock Write-SafeDebugLog {}
    Mock Write-SafeErrorLog {}
    Mock Write-SafeWarningLog {}
    
    # Mock PSResourceGet cmdlets
    Mock Register-PSResourceRepository {}
}

Describe 'Invoke-RegisterRepo' {
    Context 'API signature validation' {
        It 'Should have expected parameters' {
            $command = Get-Command Invoke-RegisterRepo
            $parameters = $command.Parameters.Keys
            
            $parameters | Should -Contain 'RepositoryName'
            $parameters | Should -Contain 'RegistryUri'
            $parameters | Should -Contain 'Credential'
            $parameters | Should -Contain 'Trusted'
            
            $command.Parameters['RepositoryName'].ParameterType.Name | Should -Be 'String'
            $command.Parameters['RegistryUri'].ParameterType.Name | Should -Be 'Uri'
            $command.Parameters['Credential'].ParameterType.Name | Should -Be 'PSCredential'
            $command.Parameters['Trusted'].ParameterType.Name | Should -Be 'SwitchParameter'
        }
    }
    
    Context 'Valid GitHub Packages URL' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:validUri = 'https://nuget.pkg.github.com/testorg/index.json'
            $script:repoName = 'TestRepo'
        }
        
        It 'Should register repository with valid URL' {
            { Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:validUri -Credential $script:testCred } | Should -Not -Throw
            Should -Invoke Register-PSResourceRepository -Times 1 -Exactly
        }
        
        It 'Should register repository with Trusted flag' {
            { Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:validUri -Credential $script:testCred -Trusted } | Should -Not -Throw
            Should -Invoke Register-PSResourceRepository -Times 1 -Exactly -ParameterFilter { $Trusted -eq $true }
        }
        
        It 'Should log success message' {
            Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:validUri -Credential $script:testCred
            Should -Invoke Write-SafeInfoLog -Times 2 -Exactly
        }
        
        It 'Should mask credentials in debug log' {
            Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:validUri -Credential $script:testCred
            Should -Invoke Write-SafeDebugLog -ParameterFilter { $Additional.Secret -eq '***' }
        }
    }
    
    Context 'Invalid GitHub Packages URL' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:invalidUri = 'https://invalid.example.com/index.json'
            $script:repoName = 'TestRepo'
        }
        
        It 'Should throw error for invalid hostname' {
            { Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:invalidUri -Credential $script:testCred } | Should -Throw -ExpectedMessage '*Invalid GitHub Packages URL*'
        }
        
        It 'Should not call Register-PSResourceRepository for invalid URL' {
            try {
                Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:invalidUri -Credential $script:testCred
            }
            catch {
                # Expected to throw
            }
            
            Should -Invoke Register-PSResourceRepository -Times 0 -Exactly
        }
        
        It 'Should log error message for invalid URL' {
            try {
                Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:invalidUri -Credential $script:testCred
            }
            catch {
                # Expected to throw
            }
            
            Should -Invoke Write-SafeErrorLog -Times 1 -Exactly
        }
    }
    
    Context 'Error handling' {
        BeforeEach {
            Mock Register-PSResourceRepository { throw "Registration failed" }
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:validUri = 'https://nuget.pkg.github.com/testorg/index.json'
            $script:repoName = 'TestRepo'
        }
        
        It 'Should propagate errors from Register-PSResourceRepository' {
            { Invoke-RegisterRepo -RepositoryName $script:repoName -RegistryUri $script:validUri -Credential $script:testCred } | Should -Throw
        }
    }
}
