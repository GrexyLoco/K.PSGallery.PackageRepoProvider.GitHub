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
    
    Write-Information "🔍 Analyzing $FolderName folder..." -InformationAction Continue
    
    $results = Invoke-ScriptAnalyzer -Path $Path -Recurse -Severity Error, Warning
    
    if ($results) {
        Write-Information "❌ Found $($results.Count) issue(s) in $FolderName" -InformationAction Continue
        $results | ForEach-Object {
            Write-Information "  [$($_.Severity)] $($_.RuleName): $($_.Message) at $($_.ScriptPath):$($_.Line)" -InformationAction Continue
        }
        return $false
    } else {
        Write-Information "✅ No issues found in $FolderName" -InformationAction Continue
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
        Write-Information "⚠️  Public folder not found - skipping" -InformationAction Continue
    }
    
    if (Test-Path $privatePath) {
        $privateOK = Test-FolderWithAnalyzer -Path $privatePath -FolderName 'Private'
    } else {
        Write-Information "⚠️  Private folder not found - skipping" -InformationAction Continue
    }
    
    if (-not $publicOK -or -not $privateOK) {
        throw "PSScriptAnalyzer found issues - please fix them before publishing"
    }
}

try {
    Write-Information "🚀 GitHub Provider - Code Quality Analysis" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    
    Test-AllCodeQuality
    
    Write-Information "" -InformationAction Continue
    Write-Information "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -InformationAction Continue
    Write-Information "✅ Code quality validation passed!" -InformationAction Continue
    
} catch {
    Write-Information "❌ Code quality validation failed: $_" -InformationAction Continue
    throw
}
