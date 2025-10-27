<#
.SYNOPSIS
    Publishes a PowerShell module to GitHub Packages.

.DESCRIPTION
    Publishes a PowerShell module to GitHub Packages NuGet registry.
    Validates the module manifest exists and optionally checks the module name.

.PARAMETER RepositoryName
    The name of the registered repository to publish to.

.PARAMETER ModulePath
    Path to the module directory containing the manifest (.psd1).

.PARAMETER ModuleName
    Optional. Expected module name for validation.

.PARAMETER Credential
    Credentials for authentication. Username should be the GitHub Owner/Organization,
    Password should be a Personal Access Token (PAT) with write:packages scope.

.EXAMPLE
    $cred = Get-Credential
    Invoke-Publish -RepositoryName 'MyGitHubRepo' -ModulePath './MyModule' -Credential $cred

.NOTES
    Requires K.PSGallery.LoggingModule and Microsoft.PowerShell.PSResourceGet modules.
#>
function Invoke-Publish {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryName,

        [Parameter(Mandatory)]
        [string]$ModulePath,

        [Parameter()]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )
    
    try {
        # Manifest-Validierung
        $manifestPath = Join-Path $ModulePath '*.psd1'
        $manifest = Get-Item $manifestPath -ErrorAction Stop | Select-Object -First 1
        
        if (-not $manifest) {
            throw "No module manifest (.psd1) found in: $ModulePath"
        }
        
        # Optional: ModuleName-Validierung
        if ($ModuleName) {
            $manifestData = Import-PowerShellDataFile $manifest.FullName
            if ($manifestData.RootModule -and $manifestData.RootModule -notmatch $ModuleName) {
                Write-LogWarning "ModuleName mismatch: Expected '$ModuleName', found '$($manifestData.RootModule)'"
            }
        }
        
        Write-LogInfo "Publishing module from: $ModulePath to repository: $RepositoryName"
        Write-LogDebug "Manifest: $($manifest.Name), User: $($Credential.UserName), Secret: ***"
        
        # NuGet-Paket erstellen und publishen
        $publishParams = @{
            Path       = $ModulePath
            Repository = $RepositoryName
            Credential = $Credential
        }
        
        Publish-PSResource @publishParams
        
        Write-LogInfo "Successfully published module to GitHub Packages: $RepositoryName"
    }
    catch {
        Write-LogError "Failed to publish to GitHub Packages: $($_.Exception.Message)"
        throw
    }
}
