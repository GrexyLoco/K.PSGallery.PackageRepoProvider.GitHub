<#
.SYNOPSIS
    Run Pester tests for GitHub Provider
.DESCRIPTION
    Executes all Pester tests using PesterTestDiscovery for smart test file detection
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Import-PesterTestDiscovery {
    [CmdletBinding()]
    param()
    
    $discoveryPath = Join-Path $PSScriptRoot '..\..\..\K.PSGallery.PesterTestDiscovery\K.PSGallery.PesterTestDiscovery.psd1'
    
    if (-not (Test-Path $discoveryPath)) {
        throw "K.PSGallery.PesterTestDiscovery not found at: $discoveryPath`nDid the workflow checkout the repository?"
    }
    
    Write-Host "🔍 Loading K.PSGallery.PesterTestDiscovery from workspace..." -ForegroundColor Cyan
    Import-Module $discoveryPath -Force -Verbose
    
    Write-Host "✅ PesterTestDiscovery loaded" -ForegroundColor Green
}

function Invoke-PesterTests {
    [CmdletBinding()]
    param()
    
    Write-Host "🔍 Discovering test files using PesterTestDiscovery..." -ForegroundColor Cyan
    
    # Use PesterTestDiscovery to find test files
    $discovery = Invoke-TestDiscovery -TestPath 'Tests' -Detailed
    
    if ($discovery.TestFilesCount -eq 0) {
        Write-Host "⚠️  No test files discovered - skipping Pester tests" -ForegroundColor Yellow
        return
    }
    
    Write-Host "✅ Found $($discovery.TestFilesCount) test file(s)" -ForegroundColor Green
    foreach ($path in $discovery.DiscoveredPaths) {
        Write-Host "   📁 $path" -ForegroundColor Gray
    }
    
    Write-Host "🧪 Running Pester tests..." -ForegroundColor Cyan
    
    $config = New-PesterConfiguration
    $config.Run.Path = $discovery.DiscoveredPaths
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.CodeCoverage.Enabled = $false
    
    $result = Invoke-Pester -Configuration $config
    
    if ($result.FailedCount -gt 0) {
        throw "Pester tests failed: $($result.FailedCount) failed out of $($result.TotalCount)"
    }
    
    Write-Host "✅ All Pester tests passed ($($result.PassedCount)/$($result.TotalCount))" -ForegroundColor Green
}

try {
    Write-Host "🚀 GitHub Provider - Pester Test Execution" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    Import-PesterTestDiscovery
    Invoke-PesterTests
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "✅ All tests passed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Test execution failed: $_" -ForegroundColor Red
    throw
}
