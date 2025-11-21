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
$InformationPreference = 'Continue'

function Import-PesterTestDiscovery {
    [CmdletBinding()]
    param()
    
    $discoveryPath = Join-Path $PSScriptRoot '..\..\..\K.PSGallery.PesterTestDiscovery\K.PSGallery.PesterTestDiscovery.psd1'
    
    if (Test-Path $discoveryPath) {
        Write-Information "🔍 Loading K.PSGallery.PesterTestDiscovery from workspace..."
        Import-Module $discoveryPath -Force -Verbose
        return $true
    } else {
        Write-Warning "K.PSGallery.PesterTestDiscovery not found - using standard Pester"
        return $false
    }
}

function Invoke-PesterWithDiscovery {
    [CmdletBinding()]
    param()
    
    Write-Information "🧪 Running Pester with Test Discovery..."
    
    $config = New-PesterConfiguration
    $config.Run.Path = 'Tests'
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.CodeCoverage.Enabled = $false
    
    $result = Invoke-Pester -Configuration $config
    
    if ($result.FailedCount -gt 0) {
        throw "Pester tests failed: $($result.FailedCount) failed out of $($result.TotalCount)"
    }
    
    Write-Information "✅ All Pester tests passed ($($result.PassedCount)/$($result.TotalCount))"
}

function Invoke-PesterManual {
    [CmdletBinding()]
    param()
    
    Write-Information "🧪 Running Pester tests (standard)..."
    
    $config = New-PesterConfiguration
    $config.Run.Path = 'Tests'
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.CodeCoverage.Enabled = $false
    
    $result = Invoke-Pester -Configuration $config
    
    if ($result.FailedCount -gt 0) {
        throw "Pester tests failed: $($result.FailedCount) failed out of $($result.TotalCount)"
    }
    
    Write-Information "✅ All Pester tests passed ($($result.PassedCount)/$($result.TotalCount))"
}

try {
    Write-Information "🚀 GitHub Provider - Pester Test Execution"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    $hasDiscovery = Import-PesterTestDiscovery
    
    if ($hasDiscovery) {
        Invoke-PesterWithDiscovery
    } else {
        Invoke-PesterManual
    }
    
    Write-Information ""
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "✅ All tests passed successfully!"
    
} catch {
    Write-Error "Test execution failed: $_"
    throw
}
