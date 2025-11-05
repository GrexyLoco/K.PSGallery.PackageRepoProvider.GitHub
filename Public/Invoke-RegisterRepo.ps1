<#
.SYNOPSIS
    Registers a GitHub Packages repository for PSResourceGet.

.DESCRIPTION
    Registers a GitHub Packages NuGet registry as a PSResourceRepository.
    Validates that the URL points to nuget.pkg.github.com and uses the provided
    credentials for authentication.

.PARAMETER RepositoryName
    The name to register the repository under.

.PARAMETER RegistryUri
    The GitHub Packages registry URL (format: https://nuget.pkg.github.com/<OWNER>/index.json).

.PARAMETER Credential
    Credentials for authentication. Username should be the GitHub Owner/Organization,
    Password should be a Personal Access Token (PAT) with read:packages and write:packages scopes.

.PARAMETER Trusted
    Marks the repository as trusted.

.EXAMPLE
    $cred = Get-Credential
    Invoke-RegisterRepo -RepositoryName 'MyGitHubRepo' -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json' -Credential $cred
.EXAMPLE
    $token = $GITHUB_TOKEN
    Invoke-RegisterRepo -RepositoryName 'MyGitHubRepo' -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json' -Token $token -Trusted

.NOTES
    Requires K.PSGallery.LoggingModule and Microsoft.PowerShell.PSResourceGet modules.
#>
function Invoke-RegisterRepo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryName,

        [Parameter(Mandatory)]
        [uri]$RegistryUri,

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [switch]$Trusted
    )
    
    try {
        # Validierung: URL muss nuget.pkg.github.com enthalten
        if ($RegistryUri.Host -ne 'nuget.pkg.github.com') {
            throw "Invalid GitHub Packages URL. Expected: https://nuget.pkg.github.com/<OWNER>/index.json"
        }
        
        # Logging (mit Credential-Maskierung)
        Write-SafeInfoLog -Message "Registering GitHub Packages repository: $RepositoryName" -Additional @{
            Repository = $RepositoryName
            Uri = $RegistryUri.ToString()
        }
        Write-SafeDebugLog -Message "Registry authentication configured" -Additional @{
            Uri = $RegistryUri.ToString()
            User = $Credential.UserName
            Secret = '***'
        }
        
        # Don't pass credentials during registration - they'll be provided at publish time
        # This avoids the "Vault token does not exist in registry" error in CI/CD
        # when SecretManagement vault is not configured
        $registerParams = @{
            Name           = $RepositoryName
            Uri            = $RegistryUri
            Trusted        = $Trusted.IsPresent
        }
        
        Register-PSResourceRepository @registerParams
        
        Write-SafeInfoLog -Message "Successfully registered GitHub Packages repository: $RepositoryName" -Additional @{
            Repository = $RepositoryName
            Uri = $RegistryUri.ToString()
        }
    }
    catch {
        Write-SafeErrorLog -Message "Failed to register GitHub Packages repository: $($_.Exception.Message)" -Additional @{
            Repository = $RepositoryName
            Uri = $Uri
            Error = $_.Exception.Message
        }
        throw
    }
}
