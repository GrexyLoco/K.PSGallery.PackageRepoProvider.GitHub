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
            Write-LogInfo "Removing repository: $RepositoryName"
            
            Unregister-PSResourceRepository -Name $RepositoryName
            
            Write-LogInfo "Successfully removed repository: $RepositoryName"
        }
    }
    catch {
        Write-LogError "Failed to remove repository: $($_.Exception.Message)"
        throw
    }
}
