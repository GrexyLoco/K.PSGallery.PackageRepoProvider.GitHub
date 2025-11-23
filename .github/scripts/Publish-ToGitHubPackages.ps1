<#
.SYNOPSIS
    Publish GitHub Provider to GitHub Packages
.DESCRIPTION
    Registers repository, publishes package, and generates GitHub Actions summaries
.PARAMETER SecureToken
    GitHub token for authentication (from GITHUB_TOKEN secret)
.PARAMETER Version
    Version to publish (from workflow input or release tag)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [SecureString]$SecureToken,
    
    [Parameter(Mandatory)]
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
    
    $modulePath = Join-Path $PSScriptRoot '..\..'
    
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
    
    $registryUri = Register-GitHubPackagesRepo -Token $SecureToken
    Publish-GitHubProvider -Token $SecureToken -Version $Version -RegistryUri $registryUri
    Write-PublishSummary -Version $Version -RegistryUri $registryUri
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "✅ Publish complete! Phase 2 finished." -ForegroundColor Green
    
} catch {
    Write-Host "❌ Publish failed: $_" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    throw
}
