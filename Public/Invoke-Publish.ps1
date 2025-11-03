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
        
        Write-SafeInfoLog "🔍 PSResourceGet Diagnostics:" -ForegroundColor Cyan
        Write-SafeInfoLog "   Installed Version: $($psResourceGetModule.Version)" -ForegroundColor Cyan
        Write-SafeInfoLog "   Command Source: $($publishPSResourceCmd.Source)" -ForegroundColor Cyan
        Write-SafeInfoLog "   Command Version: $($publishPSResourceCmd.Version)" -ForegroundColor Cyan
        
        Write-SafeInfoLog -Message "PSResourceGet version check" -Additional @{
            InstalledVersion = $psResourceGetModule.Version.ToString()
            CommandSource = $publishPSResourceCmd.Source
            CommandVersion = $publishPSResourceCmd.Version.ToString()
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
        Write-SafeInfoLog "🔍 Running diagnostic: Test-ModuleManifest..." -ForegroundColor Yellow
        try {
            $manifestValidation = Test-ModuleManifest -Path $manifest.FullName -ErrorAction Stop
            Write-SafeInfoLog "✅ Manifest validation passed:" -ForegroundColor Green
            Write-SafeInfoLog "   Name: $($manifestValidation.Name)" -ForegroundColor Cyan
            Write-SafeInfoLog "   Version: $($manifestValidation.Version)" -ForegroundColor Cyan
            Write-SafeInfoLog "   Author: '$($manifestValidation.Author)'" -ForegroundColor Cyan
            Write-SafeInfoLog "   Description: $($manifestValidation.Description)" -ForegroundColor Cyan
            Write-SafeInfoLog "   GUID: $($manifestValidation.Guid)" -ForegroundColor Cyan
        }
        catch {
            Write-SafeInfoLog "❌ Manifest validation failed: $($_.Exception.Message)" -ForegroundColor Red
        }       
        
        Write-SafeErrorLog -Message "Failed to publish to GitHub Packages: $($_.Exception.Message)" -Additional @{
            ModulePath = $ModulePath
            Repository = $RepositoryName
            Error = $_.Exception.Message
        }      
        throw
    }
}
