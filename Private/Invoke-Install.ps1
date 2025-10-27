<#
.SYNOPSIS
    Installs a PowerShell module from GitHub Packages.

.DESCRIPTION
    Installs a PowerShell module from GitHub Packages NuGet registry.
    Supports flexible version parsing:
    - 'v1' or '1' -> '1.*' (Major-Latest)
    - '1.2' -> '1.2.*' (Minor-Latest)
    - '1.2.3' -> '1.2.3' (Exact)
    - null -> Latest

.PARAMETER RepositoryName
    The name of the registered repository to install from.

.PARAMETER ModuleName
    The name of the module to install.

.PARAMETER Version
    Optional. Version specification (supports v1, 1.2, 1.2.3 formats).

.PARAMETER Credential
    Credentials for authentication. Username should be the GitHub Owner/Organization,
    Password should be a Personal Access Token (PAT) with read:packages scope.

.PARAMETER Scope
    Installation scope: CurrentUser or AllUsers. Default is CurrentUser.

.PARAMETER ImportAfterInstall
    Automatically import the module after installation.

.EXAMPLE
    $cred = Get-Credential
    Invoke-Install -RepositoryName 'MyGitHubRepo' -ModuleName 'MyModule' -Version 'v1' -Credential $cred

.NOTES
    Requires K.PSGallery.LoggingModule and Microsoft.PowerShell.PSResourceGet modules.
#>
function Invoke-Install {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryName,

        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter()]
        [string]$Version,

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',

        [switch]$ImportAfterInstall
    )
    
    try {
        Write-LogInfo "Installing module: $ModuleName from repository: $RepositoryName"
        
        # Version-Parsing (v1, 1.2, 1.2.3)
        $versionParam = if ($Version) {
            # Remove 'v'-Prefix if present
            $cleanVersion = $Version -replace '^v', ''
            
            # Check format
            if ($cleanVersion -match '^\d+$') {
                # Major-Latest: 1 -> 1.*
                "$cleanVersion.*"
            }
            elseif ($cleanVersion -match '^\d+\.\d+$') {
                # Minor-Latest: 1.2 -> 1.2.*
                "$cleanVersion.*"
            }
            else {
                # Exakt oder Wildcard: 1.2.3 oder 1.2.*
                $cleanVersion
            }
        } else {
            # Latest
            $null
        }
        
        Write-LogDebug "Repository: $RepositoryName, Module: $ModuleName, Version: $($versionParam ?? 'Latest'), Scope: $Scope"
        
        # Installation
        $installParams = @{
            Name       = $ModuleName
            Repository = $RepositoryName
            Credential = $Credential
            Scope      = $Scope
        }
        
        if ($versionParam) {
            $installParams['Version'] = $versionParam
        }
        
        Install-PSResource @installParams
        
        Write-LogInfo "Successfully installed module: $ModuleName"
        
        # Optional: Import after install
        if ($ImportAfterInstall) {
            Import-Module -Name $ModuleName -Force
            Write-LogInfo "Successfully imported module: $ModuleName"
        }
    }
    catch {
        Write-LogError "Failed to install from GitHub Packages: $($_.Exception.Message)"
        throw
    }
}
