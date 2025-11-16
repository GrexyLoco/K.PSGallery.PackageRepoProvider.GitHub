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
                Write-SafeWarningLog -Message "ModuleName mismatch: Expected '$ModuleName', found '$($manifestData.RootModule)'" -Additional @{
                    Expected = $ModuleName
                    Found = $manifestData.RootModule
                }
            }
        }
        
        Write-SafeInfoLog -Message "Publishing module from: $ModulePath to repository: $RepositoryName" -Additional @{
            ModulePath = $ModulePath
            Repository = $RepositoryName
        }
        Write-SafeDebugLog -Message "Publish authentication configured" -Additional @{
            Manifest = $manifest.Name
            User = $Credential.UserName
            Secret = '***'
        }
        
        # Diagnostics: Output PSResourceGet version information
        $psResourceGetModule = Get-Module -Name 'Microsoft.PowerShell.PSResourceGet' -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
        $publishPSResourceCmd = Get-Command -Name 'Publish-PSResource' -ErrorAction SilentlyContinue
        
        if ($psResourceGetModule -and $publishPSResourceCmd) {
            Write-SafeInfoLog "🔍 PSResourceGet Diagnostics:"
            Write-SafeInfoLog "   Installed Version: $($psResourceGetModule.Version)"
            Write-SafeInfoLog "   Command Source: $($publishPSResourceCmd.Source)"
            Write-SafeInfoLog "   Command Version: $($publishPSResourceCmd.Version)"
            
            Write-SafeInfoLog -Message "PSResourceGet version check" -Additional @{
                InstalledVersion = if ($psResourceGetModule.Version) { $psResourceGetModule.Version.ToString() } else { 'N/A' }
                CommandSource = if ($publishPSResourceCmd.Source) { $publishPSResourceCmd.Source } else { 'N/A' }
                CommandVersion = if ($publishPSResourceCmd.Version) { $publishPSResourceCmd.Version.ToString() } else { 'N/A' }
            }
        }
        
        # NuGet-Paket erstellen und publishen
        # Direct parameter passing (no splatting) - workaround for potential splatting issues
        # SkipModuleManifestValidate: Workaround for PSResourceGet 1.1.1 PowerShell Runspace bug
        # Root cause: Utils.ValidateModuleManifest() uses [PowerShell]::Create() runspace to call Test-ModuleManifest
        #            → PSModuleInfo.Author property is NOT properly deserialized in runspace context (returns empty string)
        #            → Direct Test-ModuleManifest call works: Author='GrexyLoco' ✅
        #            → Runspace Test-ModuleManifest call fails: Author='' ❌
        #            → Code at Utils.cs:1403 checks string.IsNullOrWhiteSpace(psModuleInfoObj.Author) → FALSE POSITIVE!
        # See: https://github.com/PowerShell/PSResourceGet/blob/master/src/code/Utils.cs#L1388-1403
        Publish-PSResource -Path $ModulePath -Repository $RepositoryName -Credential $Credential -SkipDependenciesCheck -SkipModuleManifestValidate -Verbose
        
        Write-SafeInfoLog -Message "Successfully published module to GitHub Packages: $RepositoryName" -Additional @{
            ModulePath = $ModulePath
            Repository = $RepositoryName
        }
    }
    catch {
        # Diagnostic: Validate manifest to provide detailed error information
        Write-SafeInfoLog "🔍 Running diagnostic: Test-ModuleManifest..."
        try {
            $manifestValidation = Test-ModuleManifest -Path $manifest.FullName -ErrorAction Stop
            Write-SafeInfoLog "✅ Manifest validation passed:"
            Write-SafeInfoLog "   Name: $($manifestValidation.Name)"
            Write-SafeInfoLog "   Version: $($manifestValidation.Version)"
            Write-SafeInfoLog "   Author: '$($manifestValidation.Author)'"
            Write-SafeInfoLog "   Description: $($manifestValidation.Description)"
            Write-SafeInfoLog "   GUID: $($manifestValidation.Guid)"
        }
        catch {
            Write-SafeInfoLog "❌ Manifest validation failed: $($_.Exception.Message)"
        }       
        
        Write-SafeErrorLog -Message "Failed to publish to GitHub Packages: $($_.Exception.Message)" -Additional @{
            ModulePath = $ModulePath
            Repository = $RepositoryName
            Error = $_.Exception.Message
        }      
        throw
    }
}
