<#
.SYNOPSIS
    Publish GitHub Provider to GitHub Packages
.DESCRIPTION
    Registers repository, publishes package, and generates GitHub Actions summaries
.PARAMETER SecureToken
    GitHub token for authentication (from GITHUB_TOKEN secret)
.PARAMETER Version
    Optional version to publish. If provided and higher than manifest version, updates manifest.
    If not provided, uses the version from the module manifest.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [SecureString]$SecureToken,
    
    [Parameter(Mandatory = $false)]
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ManifestVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath
    )
    
    if (-not (Test-Path $ManifestPath)) {
        throw "Manifest file not found: $ManifestPath"
    }
    
    $manifestData = Import-PowerShellDataFile -Path $ManifestPath
    return $manifestData.ModuleVersion
}

function Compare-Versions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version1,
        
        [Parameter(Mandatory)]
        [string]$Version2
    )
    
    try {
        $v1 = [System.Version]::Parse($Version1)
        $v2 = [System.Version]::Parse($Version2)
        return $v1.CompareTo($v2)
    } catch {
        throw "Invalid version format. Expected format: Major.Minor[.Build[.Revision]] (e.g., 1.0, 0.1.0, or 1.0.0.0)"
    }
}

function Update-ManifestVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,
        
        [Parameter(Mandatory)]
        [string]$NewVersion
    )
    
    Write-Information "📝 Updating manifest version to $NewVersion..." -InformationAction Continue
    
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewVersion
    
    Write-Information "✅ Manifest updated successfully!" -InformationAction Continue
}

function Register-GitHubPackagesRepo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [SecureString]$Token
    )
    
    Write-Host "📦 Registering GitHub Packages repository..." -ForegroundColor Cyan
    
    $registryUri = 'https://nuget.pkg.github.com/GrexyLoco/index.json'
    
    Register-PackageRepo -Uri $registryUri -SecureToken $Token -Verbose
    
    Write-Host "✅ Repository registered: $registryUri" -ForegroundColor Green
    return $registryUri
}

function Publish-GitHubProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [SecureString]$Token,
        
        [Parameter(Mandatory)]
        [string]$Version,
        
        [Parameter(Mandatory)]
        [string]$RegistryUri
    )
    
    $modulePath = Join-Path $PSScriptRoot '../..'
    
    Write-Host "📦 Publishing K.PSGallery.PackageRepoProvider.GitHub v$Version..." -ForegroundColor Cyan
    Write-Host "   Source: $modulePath" -ForegroundColor Gray
    Write-Host "   Target: $RegistryUri" -ForegroundColor Gray
    
    Publish-Package -Path $modulePath -RegistryUri $RegistryUri -SecureToken $Token -Verbose
    
    Write-Host "✅ Package published successfully!" -ForegroundColor Green
}

function Write-PublishSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version,
        
        [Parameter(Mandatory)]
        [string]$RegistryUri
    )
    
    $summary = @"
# ✅ GitHub Provider Published Successfully!

## 📦 Package Information

| Property | Value |
|----------|-------|
| 📦 Module | **K.PSGallery.PackageRepoProvider.GitHub** |
| 🏷️ Version | **$Version** |
| 🔗 Registry | ``$RegistryUri`` |
| 🏗️ Load Mode | **LOCAL Bootstrap** |

## 🎯 What's Next?

### Phase 2 Complete! ✅
The GitHub Provider is now published and available from GitHub Packages.

### Phase 3: Activate RequiredModules Migration
1. Update `K.PSGallery.PackageRepoProvider.psd1`:
   - Add `RequiredModules = @('K.PSGallery.PackageRepoProvider.GitHub')`
   - Remove temporary `Install-FromGitHubPackages.ps1`
   - Remove temporary `Install-FromLocal.ps1`
2. Update workflows to use standard installation
3. Remove bootstrap workarounds

## 📦 Installation

``````powershell
# Install from GitHub Packages
Install-PSResource -Name K.PSGallery.PackageRepoProvider.GitHub ``
    -Version $Version ``
    -Repository GitHubPackages ``
    -Credential (Get-Credential)
``````

## 🔗 Useful Links

- [📦 GitHub Packages](https://github.com/orgs/GrexyLoco/packages?repo_name=K.PSGallery.PackageRepoProvider.GitHub)
- [📋 Issue #6 - Bootstrap Strategy](https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider/issues/6)
- [🎯 Issue #3 - Release Pipeline](https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider.GitHub/issues/3)
"@

    $summary | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Encoding utf8
    Write-Host "✅ Summary written to GitHub Actions" -ForegroundColor Green
}

try {
    Write-Host "🚀 Publishing GitHub Provider to GitHub Packages" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    # Determine manifest path and read current version
    $modulePath = Join-Path $PSScriptRoot '../..'
    $manifestPath = Join-Path $modulePath 'K.PSGallery.PackageRepoProvider.GitHub.psd1'
    $manifestVersion = Get-ManifestVersion -ManifestPath $manifestPath
    
    Write-Information "📋 Current manifest version: $manifestVersion" -InformationAction Continue
    
    # Determine which version to publish
    $versionToPublish = $manifestVersion
    
    if ($Version) {
        Write-Information "🔍 Validating provided version: $Version" -InformationAction Continue
        
        # Compare versions
        $comparison = Compare-Versions -Version1 $Version -Version2 $manifestVersion
        
        if ($comparison -gt 0) {
            # Provided version is higher - update manifest
            Write-Information "✅ Provided version ($Version) is higher than manifest version ($manifestVersion)" -InformationAction Continue
            Update-ManifestVersion -ManifestPath $manifestPath -NewVersion $Version
            $versionToPublish = $Version
        } elseif ($comparison -eq 0) {
            # Versions are equal - proceed with manifest version
            Write-Information "ℹ️  Provided version matches manifest version - proceeding with $manifestVersion" -InformationAction Continue
        } else {
            # Provided version is lower - exit with error
            Write-Information "" -InformationAction Continue
            Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
            Write-Information "❌ VERSION VALIDATION FAILED" -InformationAction Continue
            Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
            Write-Information "" -InformationAction Continue
            Write-Information "The provided version ($Version) is LOWER than the current manifest version ($manifestVersion)." -InformationAction Continue
            Write-Information "" -InformationAction Continue
            Write-Information "🔧 Solution Options:" -InformationAction Continue
            Write-Information "" -InformationAction Continue
            Write-Information "  1️⃣  Provide a HIGHER version number:" -InformationAction Continue
            Write-Information "      - Update your workflow input to use a version higher than $manifestVersion" -InformationAction Continue
            Write-Information "      - Example: 0.2.0, 0.1.1, or 1.0.0" -InformationAction Continue
            Write-Information "" -InformationAction Continue
            Write-Information "  2️⃣  Use the manifest version:" -InformationAction Continue
            Write-Information "      - Don't provide a version parameter in the workflow" -InformationAction Continue
            Write-Information "      - The script will automatically use version $manifestVersion from the manifest" -InformationAction Continue
            Write-Information "" -InformationAction Continue
            Write-Information "  3️⃣  Update the manifest first:" -InformationAction Continue
            Write-Information "      - Manually update ModuleVersion in K.PSGallery.PackageRepoProvider.GitHub.psd1" -InformationAction Continue
            Write-Information "      - Commit the change, then run the workflow again" -InformationAction Continue
            Write-Information "" -InformationAction Continue
            Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
            
            throw "Version validation failed: Provided version ($Version) must be higher than manifest version ($manifestVersion)"
        }
    } else {
        Write-Information "ℹ️  No version provided - using manifest version: $manifestVersion" -InformationAction Continue
    }
    
    Write-Information "📦 Publishing version: $versionToPublish" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    
    $registryUri = Register-GitHubPackagesRepo -Token $SecureToken
    Publish-GitHubProvider -Token $SecureToken -Version $versionToPublish -RegistryUri $registryUri
    Write-PublishSummary -Version $versionToPublish -RegistryUri $registryUri
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "✅ Publish complete! Phase 2 finished." -ForegroundColor Green
    
} catch {
    Write-Host "❌ Publish failed: $_" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    throw
}
