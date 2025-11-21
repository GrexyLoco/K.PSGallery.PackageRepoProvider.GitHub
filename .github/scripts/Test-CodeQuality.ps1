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

function Test-FolderWithAnalyzer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$FolderName
    )
    
    Write-Host "🔍 Analyzing $FolderName folder..." -ForegroundColor Cyan
    
    $results = Invoke-ScriptAnalyzer -Path $Path -Recurse -Severity Error, Warning
    
    if ($results) {
        Write-Host "❌ Found $($results.Count) issue(s) in $FolderName" -ForegroundColor Red
        $results | ForEach-Object {
            Write-Host "  [$($_.Severity)] $($_.RuleName): $($_.Message) at $($_.ScriptPath):$($_.Line)" -ForegroundColor Yellow
        }
        return $false
    } else {
        Write-Host "✅ No issues found in $FolderName" -ForegroundColor Green
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
        Write-Host "⚠️  Public folder not found - skipping" -ForegroundColor Yellow
    }
    
    if (Test-Path $privatePath) {
        $privateOK = Test-FolderWithAnalyzer -Path $privatePath -FolderName 'Private'
    } else {
        Write-Host "⚠️  Private folder not found - skipping" -ForegroundColor Yellow
    }
    
    if (-not $publicOK -or -not $privateOK) {
        throw "PSScriptAnalyzer found issues - please fix them before publishing"
    }
}

try {
    Write-Host "🚀 GitHub Provider - Code Quality Analysis" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    Test-AllCodeQuality
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "✅ Code quality validation passed!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Code quality validation failed: $_" -ForegroundColor Red
    throw
}
