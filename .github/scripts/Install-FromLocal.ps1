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
    
    Write-Host "📦 Registering GitHub Packages repository for bootstrap..." -ForegroundColor Cyan
    
    Register-PSResourceRepository -Name 'GitHubPackages' `
        -Uri 'https://nuget.pkg.github.com/GrexyLoco/index.json' `
        -Trusted `
        -Verbose
    
    Write-Host "✅ Repository registered" -ForegroundColor Green
}

function Import-LocalPackageRepoProvider {
    [CmdletBinding()]
    param()
    
    $providerPath = Join-Path $PSScriptRoot '..\..\..\K.PSGallery.PackageRepoProvider\K.PSGallery.PackageRepoProvider.psd1'
    
    if (-not (Test-Path $providerPath)) {
        throw "PackageRepoProvider not found at expected path: $providerPath`nDid the workflow checkout the repository?"
    }
    
    Write-Host "📦 Importing PackageRepoProvider from LOCAL checkout..." -ForegroundColor Cyan
    Write-Host "   Path: $providerPath" -ForegroundColor Gray
    
    Import-Module $providerPath -Force -Verbose
    
    Write-Host "✅ PackageRepoProvider loaded (LOCAL mode)" -ForegroundColor Green
}

function Import-LocalGitHubProvider {
    [CmdletBinding()]
    param()
    
    $githubProviderPath = Join-Path $PSScriptRoot '..\..\K.PSGallery.PackageRepoProvider.GitHub.psd1'
    
    if (-not (Test-Path $githubProviderPath)) {
        throw "GitHub Provider manifest not found at: $githubProviderPath"
    }
    
    Write-Host "📦 Importing GitHub Provider from LOCAL checkout..." -ForegroundColor Cyan
    Write-Host "   Path: $githubProviderPath" -ForegroundColor Gray
    
    Import-Module $githubProviderPath -Force -Verbose
    
    Write-Host "✅ GitHub Provider loaded (LOCAL mode)" -ForegroundColor Green
}

function Import-LocalSmartagr {
    [CmdletBinding()]
    param()
    
    $smartagrPath = Join-Path $PSScriptRoot '..\..\..\K.PSGallery.Smartagr\K.PSGallery.Smartagr.psd1'
    
    if (-not (Test-Path $smartagrPath)) {
        throw "Smartagr not found at expected path: $smartagrPath`nDid the workflow checkout the repository?"
    }
    
    Write-Host "📦 Importing Smartagr from LOCAL checkout..." -ForegroundColor Cyan
    Write-Host "   Path: $smartagrPath" -ForegroundColor Gray
    
    Import-Module $smartagrPath -Force -Verbose
    
    Write-Host "✅ Smartagr loaded (LOCAL mode)" -ForegroundColor Green
}

function Test-ModulesLoaded {
    [CmdletBinding()]
    param()
    
    Write-Host "🔍 Verifying modules are loaded..." -ForegroundColor Cyan
    
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
    
    Write-Host "✅ All modules verified loaded" -ForegroundColor Green
    Write-Host "   PackageRepoProvider: $($packageRepoProvider.Version)" -ForegroundColor Gray
    Write-Host "   GitHub Provider: $($githubProvider.Version)" -ForegroundColor Gray
    Write-Host "   Smartagr: $($smartagr.Version)" -ForegroundColor Gray
}

try {
    Write-Host "🚀 LOCAL Bootstrap Mode - GitHub Provider Publishing" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "⚠️  Phase 2 Bootstrap: Provider publishes itself using LOCAL mode" -ForegroundColor Yellow
    Write-Host ""
    
    Register-BootstrapRepository
    Import-LocalPackageRepoProvider
    Import-LocalSmartagr
    Import-LocalGitHubProvider
    Test-ModulesLoaded
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "✅ LOCAL Bootstrap complete - ready to publish!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ LOCAL Bootstrap failed: $_" -ForegroundColor Red
    throw
}
