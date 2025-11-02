<#
.SYNOPSIS
    Imports a PowerShell module into the current session.

.DESCRIPTION
    Imports a PowerShell module by name or path into the current session.
    Supports Force and PassThru parameters.

.PARAMETER ModuleName
    The name of the module to import.

.PARAMETER ModulePath
    The path to the module to import.

.PARAMETER Force
    Forces the module to be imported, even if it's already loaded.

.PARAMETER PassThru
    Returns the imported module object.

.EXAMPLE
    Invoke-Import -ModuleName 'MyModule' -Force

.EXAMPLE
    Invoke-Import -ModulePath './MyModule' -PassThru

.NOTES
    Requires K.PSGallery.LoggingModule module.
#>
function Invoke-Import {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ModuleName,

        [Parameter()]
        [string]$ModulePath,

        [switch]$Force,

        [switch]$PassThru
    )
    
    try {
        Write-SafeInfoLog "Importing module: $($ModuleName ?? $ModulePath)"
        
        $importParams = @{}
        if ($ModuleName) { $importParams['Name'] = $ModuleName }
        if ($ModulePath) { $importParams['Path'] = $ModulePath }
        if ($Force) { $importParams['Force'] = $true }
        if ($PassThru) { $importParams['PassThru'] = $true }
        
        $result = Import-Module @importParams
        
        Write-SafeInfoLog "Successfully imported module"
        
        if ($PassThru) {
            return $result
        }
    }
    catch {
        Write-SafeErrorLog "Failed to import module: $($_.Exception.Message)"
        throw
    }
}
