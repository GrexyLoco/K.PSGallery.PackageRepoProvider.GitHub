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
        Write-LogInfo "Registering GitHub Packages repository: $RepositoryName"
        Write-LogDebug "Registry URI: $RegistryUri, User: $($Credential.UserName), Secret: ***"
        
        # Convert PSCredential to PSCredentialInfo
        $credentialInfo = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]::new(
            $Credential.UserName,
            $Credential.Password
        )
        
        # PSResourceRepository registrieren
        $registerParams = @{
            Name           = $RepositoryName
            Uri            = $RegistryUri
            Trusted        = $Trusted.IsPresent
            CredentialInfo = $credentialInfo
        }
        
        Register-PSResourceRepository @registerParams
        
        Write-LogInfo "Successfully registered GitHub Packages repository: $RepositoryName"
    }
    catch {
        Write-LogError "Failed to register GitHub Packages repository: $($_.Exception.Message)"
        throw
    }
}
