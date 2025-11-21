<#
.SYNOPSIS
    Run Pester tests for GitHub Provider
.DESCRIPTION
    Executes all Pester tests with optional PesterTestDiscovery integration
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Import-PesterTestDiscovery {
    [CmdletBinding()]
    param()
    
    $discoveryPath = Join-Path $PSScriptRoot '..\..\K.PSGallery.PesterTestDiscovery\K.PSGallery.PesterTestDiscovery.psd1'
    
    if (Test-Path $discoveryPath) {
        Write-Host "🔍 Loading K.PSGallery.PesterTestDiscovery from workspace..." -ForegroundColor Cyan
        Import-Module $discoveryPath -Force -Verbose
        return $true
    } else {
        Write-Host "⚠️  K.PSGallery.PesterTestDiscovery not found - using standard Pester" -ForegroundColor Yellow
        return $false
    }
}

function Invoke-PesterWithDiscovery {
    [CmdletBinding()]
    param()
    
    Write-Host "🧪 Running Pester with Test Discovery..." -ForegroundColor Cyan
    
    $config = New-PesterConfiguration
    $config.Run.Path = 'Tests'
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.CodeCoverage.Enabled = $false
    
    $result = Invoke-Pester -Configuration $config
    
    if ($result.FailedCount -gt 0) {
        throw "Pester tests failed: $($result.FailedCount) failed out of $($result.TotalCount)"
    }
    
    Write-Host "✅ All Pester tests passed ($($result.PassedCount)/$($result.TotalCount))" -ForegroundColor Green
}

function Invoke-PesterManual {
    [CmdletBinding()]
    param()
    
    Write-Host "🧪 Running Pester tests (standard)..." -ForegroundColor Cyan
    
    $config = New-PesterConfiguration
    $config.Run.Path = 'Tests'
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
    
    $hasDiscovery = Import-PesterTestDiscovery
    
    if ($hasDiscovery) {
        Invoke-PesterWithDiscovery
    } else {
        Invoke-PesterManual
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "✅ All tests passed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Test execution failed: $_" -ForegroundColor Red
    throw
}
