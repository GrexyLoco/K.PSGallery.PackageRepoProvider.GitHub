<#
.SYNOPSIS
    Bootstrap PackageRepoProvider and GitHub Provider from LOCAL checkout
.DESCRIPTION
    Implements LOCAL bootstrap mode - loads both modules from Git workspace
    This is CRITICAL for Phase 2: GitHub Provider cannot be its own RequiredModule
.NOTES
    Bootstrap Mode: LOCAL (PackageRepoProvider from Git + GitHub Provider from Git)
    This enables Phase 2 of the 3-phase bootstrap strategy
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Register-BootstrapRepository {
    [CmdletBinding()]
    param()
    
    Write-Information "📦 Registering GitHub Packages repository for bootstrap..." -ForegroundColor Cyan
    
    Register-PSResourceRepository -Name 'GitHubPackages' `
        -Uri 'https://nuget.pkg.github.com/GrexyLoco/index.json' `
        -Trusted `
        -Verbose
    
    Write-Information "✅ Repository registered" -ForegroundColor Green
}

function Import-LocalPackageRepoProvider {
    [CmdletBinding()]
    param()
    
    $providerPath = Join-Path $PSScriptRoot '..\..\..\K.PSGallery.PackageRepoProvider\K.PSGallery.PackageRepoProvider.psd1'
    
    if (-not (Test-Path $providerPath)) {
        throw "PackageRepoProvider not found at expected path: $providerPath`nDid the workflow checkout the repository?"
    }
    
    Write-Information "📦 Importing PackageRepoProvider from LOCAL checkout..." -ForegroundColor Cyan
    Write-Information "   Path: $providerPath" -ForegroundColor Gray
    
    Import-Module $providerPath -Force -Verbose
    
    Write-Information "✅ PackageRepoProvider loaded (LOCAL mode)" -ForegroundColor Green
}

function Import-LocalGitHubProvider {
    [CmdletBinding()]
    param()
    
    $githubProviderPath = Join-Path $PSScriptRoot '..\..\K.PSGallery.PackageRepoProvider.GitHub.psd1'
    
    if (-not (Test-Path $githubProviderPath)) {
        throw "GitHub Provider manifest not found at: $githubProviderPath"
    }
    
    Write-Information "📦 Importing GitHub Provider from LOCAL checkout..." -ForegroundColor Cyan
    Write-Information "   Path: $githubProviderPath" -ForegroundColor Gray
    
    Import-Module $githubProviderPath -Force -Verbose
    
    Write-Information "✅ GitHub Provider loaded (LOCAL mode)" -ForegroundColor Green
}

function Import-LocalSmartagr {
    [CmdletBinding()]
    param()
    
    $smartagrPath = Join-Path $PSScriptRoot '..\..\..\K.PSGallery.Smartagr\K.PSGallery.Smartagr.psd1'
    
    if (-not (Test-Path $smartagrPath)) {
        throw "Smartagr not found at expected path: $smartagrPath`nDid the workflow checkout the repository?"
    }
    
    Write-Information "📦 Importing Smartagr from LOCAL checkout..." -ForegroundColor Cyan
    Write-Information "   Path: $smartagrPath" -ForegroundColor Gray
    
    Import-Module $smartagrPath -Force -Verbose
    
    Write-Information "✅ Smartagr loaded (LOCAL mode)" -ForegroundColor Green
}

function Test-ModulesLoaded {
    [CmdletBinding()]
    param()
    
    Write-Information "🔍 Verifying modules are loaded..." -ForegroundColor Cyan
    
    $packageRepoProvider = Get-Module -Name 'K.PSGallery.PackageRepoProvider'
    $githubProvider = Get-Module -Name 'K.PSGallery.PackageRepoProvider.GitHub'
    $smartagr = Get-Module -Name 'K.PSGallery.Smartagr'
    
    if (-not $packageRepoProvider) {
        throw "PackageRepoProvider not loaded!"
    }
    
    if (-not $githubProvider) {
        throw "GitHub Provider not loaded!"
    }
    
    if (-not $smartagr) {
        throw "Smartagr not loaded!"
    }
    
    Write-Information "✅ All modules verified loaded" -ForegroundColor Green
    Write-Information "   PackageRepoProvider: $($packageRepoProvider.Version)" -ForegroundColor Gray
    Write-Information "   GitHub Provider: $($githubProvider.Version)" -ForegroundColor Gray
    Write-Information "   Smartagr: $($smartagr.Version)" -ForegroundColor Gray
}

try {
    Write-Information "🚀 LOCAL Bootstrap Mode - GitHub Provider Publishing" -ForegroundColor Yellow
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Information "⚠️  Phase 2 Bootstrap: Provider publishes itself using LOCAL mode" -ForegroundColor Yellow
    Write-Information ""
    
    Register-BootstrapRepository
    Import-LocalPackageRepoProvider
    Import-LocalSmartagr
    Import-LocalGitHubProvider
    Test-ModulesLoaded
    
    Write-Information ""
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Information "✅ LOCAL Bootstrap complete - ready to publish!" -ForegroundColor Green
    
} catch {
    Write-Error "❌ LOCAL Bootstrap failed: $_" -ForegroundColor Red
    throw
}
