<#
.SYNOPSIS
    Write success summary to GitHub Actions
.DESCRIPTION
    Generates formatted success summary for GitHub Provider publish workflow
.PARAMETER Version
    Published version
.PARAMETER RegistryUri
    Target registry URI
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Version,
    
    [Parameter(Mandatory)]
    [string]$RegistryUri
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

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
1. Update ``K.PSGallery.PackageRepoProvider.psd1``:
   - Add ``RequiredModules = @('K.PSGallery.PackageRepoProvider.GitHub')``
   - Remove temporary ``Install-FromGitHubPackages.ps1``
   - Remove temporary ``Install-FromLocal.ps1``
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
Write-Information "✅ Success summary written"
