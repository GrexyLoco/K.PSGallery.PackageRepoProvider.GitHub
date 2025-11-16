BeforeAll {
    # Create stub logging functions before sourcing
    function Write-LogInfo { param($Message) }
    function Write-LogDebug { param($Message) }
    function Write-LogError { param($Message) }
    function Write-LogWarning { param($Message) }
    
    # Source the SafeLogging and function directly instead of importing module
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath "Private" | Join-Path -ChildPath "SafeLogging.ps1")
    . (Join-Path $modulePath "Public" | Join-Path -ChildPath "Invoke-Publish.ps1")
    
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
    Context 'API signature validation' {
        It 'Should have expected parameters' {
            $command = Get-Command Invoke-Publish
            $parameters = $command.Parameters.Keys
            
            $parameters | Should -Contain 'RepositoryName'
            $parameters | Should -Contain 'ModulePath'
            $parameters | Should -Contain 'ModuleName'
            $parameters | Should -Contain 'Credential'
            
            $command.Parameters['RepositoryName'].ParameterType.Name | Should -Be 'String'
            $command.Parameters['ModulePath'].ParameterType.Name | Should -Be 'String'
            $command.Parameters['ModuleName'].ParameterType.Name | Should -Be 'String'
            $command.Parameters['Credential'].ParameterType.Name | Should -Be 'PSCredential'
        }
    }
    
    Context 'Valid module with manifest' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestRepo'
        }
        
        It 'Should publish module successfully' {
            { Invoke-Publish -RepositoryName $script:repoName -ModulePath $script:testModuleDir.FullName -Credential $script:testCred } | Should -Not -Throw
            Should -Invoke Publish-PSResource -Times 1 -Exactly
        }
        
        It 'Should log success message' {
            Invoke-Publish -RepositoryName $script:repoName -ModulePath $script:testModuleDir.FullName -Credential $script:testCred
            Should -Invoke Write-LogInfo -Times 2 -Exactly
        }
        
        It 'Should mask credentials in debug log' {
            Invoke-Publish -RepositoryName $script:repoName -ModulePath $script:testModuleDir.FullName -Credential $script:testCred
            Should -Invoke Write-LogDebug -ParameterFilter { $Message -match '\*\*\*' }
        }
        
        It 'Should warn on module name mismatch' {
            Invoke-Publish -RepositoryName $script:repoName -ModulePath $script:testModuleDir.FullName -ModuleName 'DifferentName' -Credential $script:testCred
            Should -Invoke Write-LogWarning -Times 1 -Exactly
        }
    }
    
    Context 'Missing module manifest' {
        BeforeEach {
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestRepo'
        }
        
        It 'Should throw error when manifest is missing' {
            $emptyDir = New-Item -Path (Join-Path $TestDrive 'EmptyModule') -ItemType Directory -Force
            { Invoke-Publish -RepositoryName $script:repoName -ModulePath $emptyDir.FullName -Credential $script:testCred } | Should -Throw
        }
        
        It 'Should not call Publish-PSResource when manifest is missing' {
            $emptyDir = New-Item -Path (Join-Path $TestDrive 'EmptyModule2') -ItemType Directory -Force
            
            try {
                Invoke-Publish -RepositoryName $script:repoName -ModulePath $emptyDir.FullName -Credential $script:testCred
            }
            catch {
                # Expected to throw
            }
            
            Should -Invoke Publish-PSResource -Times 0 -Exactly -Scope It
        }
        
        It 'Should log error message when manifest is missing' {
            $emptyDir = New-Item -Path (Join-Path $TestDrive 'EmptyModule3') -ItemType Directory -Force
            
            try {
                Invoke-Publish -RepositoryName $script:repoName -ModulePath $emptyDir.FullName -Credential $script:testCred
            }
            catch {
                # Expected to throw
            }
            
            Should -Invoke Write-LogError -Times 1 -Exactly -Scope It
        }
    }
    
    Context 'Error handling' {
        BeforeEach {
            Mock Publish-PSResource { throw "Publish failed" }
            $script:testCred = New-Object System.Management.Automation.PSCredential ('testuser', (ConvertTo-SecureString 'testpass' -AsPlainText -Force))
            $script:repoName = 'TestRepo'
        }
        
        It 'Should propagate errors from Publish-PSResource' {
            { Invoke-Publish -RepositoryName $script:repoName -ModulePath $script:testModuleDir.FullName -Credential $script:testCred } | Should -Throw
        }
    }
}
