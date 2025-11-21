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
    
    $discoveryPath = Join-Path $PSScriptRoot '..\..\..\K.PSGallery.PesterTestDiscovery\K.PSGallery.PesterTestDiscovery.psd1'
    
    if (Test-Path $discoveryPath) {
        Write-Information "🔍 Loading K.PSGallery.PesterTestDiscovery from workspace..." -InformationAction Continue
        Import-Module $discoveryPath -Force -Verbose
        return $true
    } else {
        Write-Information "⚠️  K.PSGallery.PesterTestDiscovery not found - using standard Pester" -InformationAction Continue
        return $false
    }
}

function Invoke-PesterWithDiscovery {
    [CmdletBinding()]
    param()
    
    Write-Information "🧪 Running Pester with Test Discovery..." -InformationAction Continue
    
    $config = New-PesterConfiguration
    $config.Run.Path = 'Tests'
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.CodeCoverage.Enabled = $false
    
    $result = Invoke-Pester -Configuration $config
    
    if ($result.FailedCount -gt 0) {
        throw "Pester tests failed: $($result.FailedCount) failed out of $($result.TotalCount)"
    }
    
    Write-Information "✅ All Pester tests passed ($($result.PassedCount)/$($result.TotalCount))" -InformationAction Continue
}

function Invoke-PesterManual {
    [CmdletBinding()]
    param()
    
    Write-Information "🧪 Running Pester tests (standard)..." -InformationAction Continue
    
    $config = New-PesterConfiguration
    $config.Run.Path = 'Tests'
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.CodeCoverage.Enabled = $false
    
    $result = Invoke-Pester -Configuration $config
    
    if ($result.FailedCount -gt 0) {
        throw "Pester tests failed: $($result.FailedCount) failed out of $($result.TotalCount)"
    }
    
    Write-Information "✅ All Pester tests passed ($($result.PassedCount)/$($result.TotalCount))" -InformationAction Continue
}

try {
    Write-Information "🚀 GitHub Provider - Pester Test Execution" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    
    $hasDiscovery = Import-PesterTestDiscovery
    
    if ($hasDiscovery) {
        Invoke-PesterWithDiscovery
    } else {
        Invoke-PesterManual
    }
    
    Write-Information "" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    Write-Information "✅ All tests passed successfully!" -InformationAction Continue
    
} catch {
    Write-Information "❌ Test execution failed: $_" -InformationAction Continue
    throw
}
