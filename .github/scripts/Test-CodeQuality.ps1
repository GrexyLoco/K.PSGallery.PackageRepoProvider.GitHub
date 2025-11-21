<#
.SYNOPSIS
    Run PSScriptAnalyzer quality checks for GitHub Provider
.DESCRIPTION
    Validates PowerShell code quality across Public and Private folders
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function Test-FolderWithAnalyzer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$FolderName
    )
    
    Write-Information "🔍 Analyzing $FolderName folder..."
    
    $results = Invoke-ScriptAnalyzer -Path $Path -Recurse -Severity Error, Warning
    
    if ($results) {
        Write-Warning "Found $($results.Count) issue(s) in $FolderName"
        $results | ForEach-Object {
            Write-Warning "  [$($_.Severity)] $($_.RuleName): $($_.Message) at $($_.ScriptPath):$($_.Line)"
        }
        return $false
    } else {
        Write-Information "✅ No issues found in $FolderName"
        return $true
    }
}

function Test-AllCodeQuality {
    [CmdletBinding()]
    param()
    
    $publicPath = Join-Path $PSScriptRoot '..\..\Public'
    $privatePath = Join-Path $PSScriptRoot '..\..\Private'
    
    $publicOK = $true
    $privateOK = $true
    
    if (Test-Path $publicPath) {
        $publicOK = Test-FolderWithAnalyzer -Path $publicPath -FolderName 'Public'
    } else {
        Write-Warning "Public folder not found - skipping"
    }
    
    if (Test-Path $privatePath) {
        $privateOK = Test-FolderWithAnalyzer -Path $privatePath -FolderName 'Private'
    } else {
        Write-Warning "Private folder not found - skipping"
    }
    
    if (-not $publicOK -or -not $privateOK) {
        throw "PSScriptAnalyzer found issues - please fix them before publishing"
    }
}

try {
    Write-Information "🚀 GitHub Provider - Code Quality Analysis"
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    Test-AllCodeQuality
    
    Write-Information ""
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Information "✅ Code quality validation passed!"
    
} catch {
    Write-Error "Code quality validation failed: $_"
    throw
}
