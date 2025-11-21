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
$InformationPreference = 'Continue'

function Register-BootstrapRepository {
    [CmdletBinding()]
    param()
    
    Write-Information "📦 Registering GitHub Packages repository for bootstrap..."
    
    Register-PSResourceRepository -Name 'GitHubPackages' `
        -Uri 'https://nuget.pkg.github.com/GrexyLoco/index.json' `
        -Trusted `
        -Verbose
    
    Write-Information "✅ Repository registered"
}

function Import-LocalPackageRepoProvider {
    [CmdletBinding()]
    param()
    
    $providerPath = Join-Path $PSScriptRoot '..\..\K.PSGallery.PackageRepoProvider\K.PSGallery.PackageRepoProvider.psd1'
    
    if (-not (Test-Path $providerPath)) {
        throw "PackageRepoProvider not found at expected path: $providerPath`nDid the workflow checkout the repository?"
    }
    
    Write-Information "📦 Importing PackageRepoProvider from LOCAL checkout..."
    Write-Information "   Path: $providerPath"
    
    Import-Module $providerPath -Force -Verbose
    
    Write-Information "✅ PackageRepoProvider loaded (LOCAL mode)"
}

function Import-LocalGitHubProvider {
    [CmdletBinding()]
    param()
    
    $githubProviderPath = Join-Path $PSScriptRoot '..\..\K.PSGallery.PackageRepoProvider.GitHub.psd1'
    
    if (-not (Test-Path $githubProviderPath)) {
        throw "GitHub Provider manifest not found at: $githubProviderPath"
    }
    
    Write-Information "📦 Importing GitHub Provider from LOCAL checkout..."
    Write-Information "   Path: $githubProviderPath"
    
    Import-Module $githubProviderPath -Force -Verbose
    
    Write-Information "✅ GitHub Provider loaded (LOCAL mode)"
}

function Test-ModulesLoaded {
    [CmdletBinding()]
    param()
    
    Write-Information "🔍 Verifying modules are loaded..."
    
    $packageRepoProvider = Get-Module -Name 'K.PSGallery.PackageRepoProvider'
    $githubProvider = Get-Module -Name 'K.PSGallery.PackageRepoProvider.GitHub'
    
    if (-not $packageRepoProvider) {
        throw "PackageRepoProvider not loaded!"
    }
    
    if (-not $githubProvider) {
        throw "GitHub Provider not loaded!"
    }
    
    Write-Information "✅ Both modules verified loaded"
    Write-Information "   PackageRepoProvider: $($packageRepoProvider.Version)"
    Write-Information "   GitHub Provider: $($githubProvider.Version)"
}

try {
    Write-Information "🚀 LOCAL Bootstrap Mode - GitHub Provider Publishing"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Warning "Phase 2 Bootstrap: Provider publishes itself using LOCAL mode"
    Write-Information ""
    
    Register-BootstrapRepository
    Import-LocalPackageRepoProvider
    Import-LocalGitHubProvider
    Test-ModulesLoaded
    
    Write-Information ""
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "✅ LOCAL Bootstrap complete - ready to publish!"
    
} catch {
    Write-Error "LOCAL Bootstrap failed: $_"
    throw
}
