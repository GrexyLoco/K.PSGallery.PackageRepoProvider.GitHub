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
$InformationPreference = 'Continue'

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
    
    Write-Information "📝 Updating manifest version to $NewVersion..."
    
    Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewVersion
    
    Write-Information "✅ Manifest updated successfully!"
}

function Register-GitHubPackagesRepo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [SecureString]$Token
    )
    
    Write-Information "📦 Registering GitHub Packages repository..."
    
    $registryUri = 'https://nuget.pkg.github.com/GrexyLoco/index.json'
    
    Register-PackageRepo -Uri $registryUri -SecureToken $Token -Verbose
    
    Write-Information "✅ Repository registered: $registryUri"
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
    
    Write-Information "📦 Publishing K.PSGallery.PackageRepoProvider.GitHub v$Version..."
    Write-Information "   Source: $modulePath"
    Write-Information "   Target: $RegistryUri"
    
    Publish-Package -Path $modulePath -RegistryUri $RegistryUri -SecureToken $Token -Verbose
    
    Write-Information "✅ Package published successfully!"
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
    Write-Information "✅ Summary written to GitHub Actions"
}

try {
    Write-Information "🚀 Publishing GitHub Provider to GitHub Packages"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Determine manifest path and read current version
    $modulePath = Join-Path $PSScriptRoot '../..'
    $manifestPath = Join-Path $modulePath 'K.PSGallery.PackageRepoProvider.GitHub.psd1'
    $manifestVersion = Get-ManifestVersion -ManifestPath $manifestPath
    
    Write-Information "📋 Current manifest version: $manifestVersion"
    
    # Determine which version to publish
    $versionToPublish = $manifestVersion
    
    if ($Version) {
        Write-Information "🔍 Validating provided version: $Version"
        
        # Compare versions
        $comparison = Compare-Versions -Version1 $Version -Version2 $manifestVersion
        
        if ($comparison -gt 0) {
            # Provided version is higher - update manifest
            Write-Information "✅ Provided version ($Version) is higher than manifest version ($manifestVersion)"
            Update-ManifestVersion -ManifestPath $manifestPath -NewVersion $Version
            $versionToPublish = $Version
        } elseif ($comparison -eq 0) {
            # Versions are equal - proceed with manifest version
            Write-Information "ℹ️  Provided version matches manifest version - proceeding with $manifestVersion"
        } else {
            # Provided version is lower - exit with error
            Write-Information ""
            Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            Write-Information "❌ VERSION VALIDATION FAILED"
            Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            Write-Information ""
            Write-Information "The provided version ($Version) is LOWER than the current manifest version ($manifestVersion)."
            Write-Information ""
            Write-Information "🔧 Solution Options:"
            Write-Information ""
            Write-Information "  1️⃣  Provide a HIGHER version number:"
            Write-Information "      - Update your workflow input to use a version higher than $manifestVersion"
            Write-Information "      - Example: 0.2.0, 0.1.1, or 1.0.0"
            Write-Information ""
            Write-Information "  2️⃣  Use the manifest version:"
            Write-Information "      - Don't provide a version parameter in the workflow"
            Write-Information "      - The script will automatically use version $manifestVersion from the manifest"
            Write-Information ""
            Write-Information "  3️⃣  Update the manifest first:"
            Write-Information "      - Manually update ModuleVersion in K.PSGallery.PackageRepoProvider.GitHub.psd1"
            Write-Information "      - Commit the change, then run the workflow again"
            Write-Information ""
            Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            throw "Version validation failed: Provided version ($Version) must be higher than manifest version ($manifestVersion)"
        }
    } else {
        Write-Information "ℹ️  No version provided - using manifest version: $manifestVersion"
    }
    
    Write-Information "📦 Publishing version: $versionToPublish"
    Write-Information ""
    
    $registryUri = Register-GitHubPackagesRepo -Token $SecureToken
    Publish-GitHubProvider -Token $SecureToken -Version $versionToPublish -RegistryUri $registryUri
    Write-PublishSummary -Version $versionToPublish -RegistryUri $registryUri
    
    Write-Information ""
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "✅ Publish complete! Phase 2 finished."
    
} catch {
    Write-Error "Publish failed: $_"
    Write-Error "Stack Trace: $($_.ScriptStackTrace)"
    throw
}
