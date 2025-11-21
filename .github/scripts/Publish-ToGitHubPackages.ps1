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
    
    Write-Information "📦 Registering GitHub Packages repository..." -InformationAction Continue
    
    $registryUri = 'https://nuget.pkg.github.com/GrexyLoco/index.json'
    
    Register-PackageRepo -Uri $registryUri -SecureToken $Token -Verbose
    
    Write-Information "✅ Repository registered: $registryUri" -InformationAction Continue
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
    
    Write-Information "📦 Publishing K.PSGallery.PackageRepoProvider.GitHub v$Version..." -InformationAction Continue
    Write-Information "   Source: $modulePath" -InformationAction Continue
    Write-Information "   Target: $RegistryUri" -InformationAction Continue
    
    Publish-Package -Path $modulePath -RegistryUri $RegistryUri -SecureToken $Token -Verbose
    
    Write-Information "✅ Package published successfully!" -InformationAction Continue
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
    Write-Information "✅ Summary written to GitHub Actions" -InformationAction Continue
}

try {
    Write-Information "🚀 Publishing GitHub Provider to GitHub Packages" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    
    $registryUri = Register-GitHubPackagesRepo -Token $SecureToken
    Publish-GitHubProvider -Token $SecureToken -Version $Version -RegistryUri $registryUri
    Write-PublishSummary -Version $Version -RegistryUri $registryUri
    
    Write-Information "" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    Write-Information "✅ Publish complete! Phase 2 finished." -InformationAction Continue
    
} catch {
    Write-Information "❌ Publish failed: $_" -InformationAction Continue
    Write-Information "Stack Trace: $($_.ScriptStackTrace)" -InformationAction Continue
    throw
}
