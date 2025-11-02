<#
.SYNOPSIS
    Removes a registered GitHub Packages repository.

.DESCRIPTION
    Unregisters a previously registered GitHub Packages repository from PSResourceGet.
    Supports ShouldProcess for confirmation.

.PARAMETER RepositoryName
    The name of the repository to remove.

.EXAMPLE
    Invoke-RemoveRepo -RepositoryName 'MyGitHubRepo'

.EXAMPLE
    Invoke-RemoveRepo -RepositoryName 'MyGitHubRepo' -WhatIf

.NOTES
    Requires K.PSGallery.LoggingModule and Microsoft.PowerShell.PSResourceGet modules.
#>
function Invoke-RemoveRepo {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryName
    )
    
    try {
        if ($PSCmdlet.ShouldProcess($RepositoryName, "Unregister repository")) {
            Write-SafeInfoLog -Message "Removing repository: $RepositoryName" -Additional @{
                Repository = $RepositoryName
            }
            
            Unregister-PSResourceRepository -Name $RepositoryName
            
            Write-SafeInfoLog -Message "Successfully removed repository: $RepositoryName" -Additional @{
                Repository = $RepositoryName
            }
        }
    }
    catch {
        Write-SafeErrorLog -Message "Failed to remove repository: $($_.Exception.Message)" -Additional @{
            Repository = $RepositoryName
            Error = $_.Exception.Message
        }
        throw
    }
}
