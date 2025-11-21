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


function Import-LocalPackageRepoProvider {
    [CmdletBinding()]
    param()
    
    $providerPath = Join-Path $PSScriptRoot '..\..\..\K.PSGallery.PackageRepoProvider\K.PSGallery.PackageRepoProvider.psd1'
    
    if (-not (Test-Path $providerPath)) {
        throw "PackageRepoProvider not found at expected path: $providerPath`nDid the workflow checkout the repository?"
    }
    
    Write-Information "📦 Importing PackageRepoProvider from LOCAL checkout..." -InformationAction Continue
    Write-Information "   Path: $providerPath" -InformationAction Continue
    
    Import-Module $providerPath -Force -Verbose
    
    Write-Information "✅ PackageRepoProvider loaded (LOCAL mode)" -InformationAction Continue
}

function Import-LocalGitHubProvider {
    [CmdletBinding()]
    param()
    
    $githubProviderPath = Join-Path (Join-Path $PSScriptRoot '..\..') 'K.PSGallery.PackageRepoProvider.GitHub.psd1'
    
    if (-not (Test-Path $githubProviderPath)) {
        throw "GitHub Provider manifest not found at: $githubProviderPath"
    }
    
    Write-Information "📦 Importing GitHub Provider from LOCAL checkout..." -InformationAction Continue
    Write-Information "   Path: $githubProviderPath" -InformationAction Continue
    
    Import-Module $githubProviderPath -Force -Verbose
    
    Write-Information "✅ GitHub Provider loaded (LOCAL mode)" -InformationAction Continue
}

function Test-ModulesLoaded {
    [CmdletBinding()]
    param()
    
    Write-Information "🔍 Verifying modules are loaded..." -InformationAction Continue
    
    $packageRepoProvider = Get-Module -Name 'K.PSGallery.PackageRepoProvider'
    $githubProvider = Get-Module -Name 'K.PSGallery.PackageRepoProvider.GitHub'
    
    if (-not $packageRepoProvider) {
        throw "PackageRepoProvider not loaded!"
    }
    
    if (-not $githubProvider) {
        throw "GitHub Provider not loaded!"
    }
    
    Write-Information "✅ Both modules verified loaded" -InformationAction Continue
    Write-Information "   PackageRepoProvider: $($packageRepoProvider.Version)" -InformationAction Continue
    Write-Information "   GitHub Provider: $($githubProvider.Version)" -InformationAction Continue
}

try {
    Write-Information "🚀 LOCAL Bootstrap Mode - GitHub Provider Publishing" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    Write-Information "⚠️  Phase 2 Bootstrap: Provider publishes itself using LOCAL mode" -InformationAction Continue
    Write-Information "" -InformationAction Continue
    
    Register-BootstrapRepository
    Import-LocalPackageRepoProvider
    Import-LocalGitHubProvider
    Test-ModulesLoaded
    
    Write-Information "" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    Write-Information "✅ LOCAL Bootstrap complete - ready to publish!" -InformationAction Continue
    
} catch {
    Write-Information "❌ LOCAL Bootstrap failed: $_" -InformationAction Continue
    throw
}
