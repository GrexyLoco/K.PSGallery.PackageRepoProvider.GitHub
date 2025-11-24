<#
.SYNOPSIS
    Updates the PowerShell module manifest version using K.PSGallery.ManifestVersioning.

.DESCRIPTION
    This script installs K.PSGallery.ManifestVersioning from PSGallery and uses it to update
    the module manifest (.psd1) version. It handles Git commit/push operations and provides
    detailed output to GitHub Actions step summary.

    The script auto-discovers the .psd1 file in the current directory if not specified.

.PARAMETER NewVersion
    The new semantic version to set (e.g., "1.2.3").

.PARAMETER ManifestPath
    Optional path to the .psd1 manifest file. If not specified, auto-discovers the first
    .psd1 file in the current directory.

.PARAMETER CommitMessage
    Optional custom commit message template. Use {version} as placeholder for the version.
    Default: "🔖 Update module version to {version} [skip ci]"

.PARAMETER SkipCI
    Whether to add [skip ci] to the commit message. Default: $true

.PARAMETER GitUserName
    The Git user name for the commit. Default: "github-actions[bot]"

.PARAMETER GitUserEmail
    The Git user email for the commit. Default: "github-actions[bot]@users.noreply.github.com"

.PARAMETER BranchName
    The branch name to push to. Required for Git push operations.

.OUTPUTS
    Writes status to GitHub Actions step summary ($env:GITHUB_STEP_SUMMARY).
    Throws on failure.

.EXAMPLE
    ./Update-ManifestVersion.ps1 -NewVersion "1.0.0" -BranchName "main"
    # Auto-discovers .psd1 and updates to version 1.0.0

.EXAMPLE
    ./Update-ManifestVersion.ps1 -NewVersion "2.0.0" -ManifestPath "./MyModule.psd1" -BranchName "master"
    # Updates specific manifest file

.NOTES
    Requires: K.PSGallery.ManifestVersioning module (auto-installed from PSGallery)
    Cross-platform: Windows, Linux, macOS
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+(-[\w\.]+)?$')]
    [string]$NewVersion,

    [Parameter()]
    [string]$ManifestPath,

    [Parameter()]
    [string]$CommitMessage = '🔖 Update module version to {version} [skip ci]',

    [Parameter()]
    [bool]$SkipCI = $true,

    [Parameter()]
    [string]$GitUserName = 'github-actions[bot]',

    [Parameter()]
    [string]$GitUserEmail = 'github-actions[bot]@users.noreply.github.com',

    [Parameter(Mandatory)]
    [string]$BranchName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Auto-discover manifest if not specified
if (-not $ManifestPath) {
    $psd1 = Get-ChildItem -Filter '*.psd1' -File | Select-Object -First 1
    if (-not $psd1) {
        throw 'No .psd1 manifest file found in current directory.'
    }
    $ManifestPath = $psd1.FullName
    Write-Verbose "Auto-discovered manifest: $ManifestPath"
}

# Validate manifest exists
if (-not (Test-Path -Path $ManifestPath -PathType Leaf)) {
    throw "Manifest file not found: $ManifestPath"
}

$manifestName = Split-Path -Path $ManifestPath -Leaf

# Install K.PSGallery.ManifestVersioning from PSGallery
Write-Output '📦 Installing K.PSGallery.ManifestVersioning from PSGallery...'
Install-Module -Name K.PSGallery.ManifestVersioning -Scope CurrentUser -Force -AllowClobber
Import-Module K.PSGallery.ManifestVersioning -Force

# Configure Git
Write-Output '🔧 Configuring Git...'
git config user.name $GitUserName
git config user.email $GitUserEmail

# Update manifest version using the module
Write-Output "📝 Updating $manifestName to version $NewVersion"

$result = Update-ModuleManifestVersion `
    -ManifestPath $ManifestPath `
    -NewVersion $NewVersion `
    -CommitChanges $true `
    -SkipCI $SkipCI `
    -CommitMessage $CommitMessage

if (-not $result.Success) {
    $errorMsg = "❌ Version update failed: $($result.ErrorMessage)"
    "## ❌ Version Update Failed" >> $env:GITHUB_STEP_SUMMARY
    "**Error:** $($result.ErrorMessage)" >> $env:GITHUB_STEP_SUMMARY
    throw $errorMsg
}

# Push changes
Write-Output '🚀 Pushing changes to remote...'
git push origin $BranchName

# Write success summary
"## ✅ Module Version Updated" >> $env:GITHUB_STEP_SUMMARY
"**Manifest:** ``$manifestName``" >> $env:GITHUB_STEP_SUMMARY
"**Old Version:** ``$($result.OldVersion)``" >> $env:GITHUB_STEP_SUMMARY
"**New Version:** ``$($result.NewVersion)``" >> $env:GITHUB_STEP_SUMMARY

Write-Output "✅ Successfully updated $manifestName from $($result.OldVersion) to $($result.NewVersion)"
