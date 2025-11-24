<#
.SYNOPSIS
    Determines the final version for the release based on manual override or auto-detection.

.DESCRIPTION
    This script evaluates whether a manual version was provided or uses the auto-detected
    version from the K.Actions.NextVersion action. It outputs the final version and whether
    a release should be created.

.PARAMETER ManualVersion
    Optional manual version override (e.g., "1.2.3").

.PARAMETER AutoBumpType
    The bump type detected by K.Actions.NextVersion (major, minor, patch, none).

.PARAMETER AutoNewVersion
    The new version calculated by K.Actions.NextVersion.

.OUTPUTS
    Sets GitHub Action outputs:
    - final-version: The version to use for the release
    - should-release: Whether a release should be created (true/false)

.EXAMPLE
    ./Get-NextVersion.ps1 -ManualVersion "1.0.0"
    # Uses manual version override

.EXAMPLE
    ./Get-NextVersion.ps1 -AutoBumpType "minor" -AutoNewVersion "1.1.0"
    # Uses auto-detected version
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$ManualVersion = '',

    [Parameter()]
    [string]$AutoBumpType = '',

    [Parameter()]
    [string]$AutoNewVersion = ''
)

if ($ManualVersion) {
    Write-Output "🎯 Manual version override: $ManualVersion"
    "final-version=$ManualVersion" >> $env:GITHUB_OUTPUT
    "should-release=true" >> $env:GITHUB_OUTPUT
    "## 📌 Manual Version Override" >> $env:GITHUB_STEP_SUMMARY
    "**Override Version:** ``$ManualVersion``" >> $env:GITHUB_STEP_SUMMARY
}
else {
    Write-Output "🔍 Auto-detected: $AutoNewVersion ($AutoBumpType)"
    "final-version=$AutoNewVersion" >> $env:GITHUB_OUTPUT

    if ($AutoBumpType -eq 'none') {
        "should-release=false" >> $env:GITHUB_OUTPUT
        "## 🔁 No Release Required" >> $env:GITHUB_STEP_SUMMARY
        "No version changes detected." >> $env:GITHUB_STEP_SUMMARY
    }
    else {
        "should-release=true" >> $env:GITHUB_OUTPUT
        "## ⬆️ Version Bump Detected" >> $env:GITHUB_STEP_SUMMARY
        "**Bump Type:** ``$AutoBumpType``" >> $env:GITHUB_STEP_SUMMARY
        "**New Version:** ``$AutoNewVersion``" >> $env:GITHUB_STEP_SUMMARY
    }
}
