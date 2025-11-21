<#
.SYNOPSIS
    Write error summary to GitHub Actions
.DESCRIPTION
    Generates formatted error summary for GitHub Provider publish workflow failures
.PARAMETER ErrorMessage
    The error message to display
.PARAMETER Version
    Attempted version
.PARAMETER RegistryUri
    Target registry URI
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ErrorMessage,
    
    [Parameter(Mandatory)]
    [string]$Version,
    
    [Parameter(Mandatory)]
    [string]$RegistryUri
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$errorSummary = @"
# ❌ GitHub Provider Publish Failed

## 🚨 Error Details

**Error Message:**
``````
$ErrorMessage
``````

## 📦 Attempted Publish

| Property | Value |
|----------|-------|
| 📦 Module | **K.PSGallery.PackageRepoProvider.GitHub** |
| 🏷️ Version | **$Version** |
| 🔗 Registry | ``$RegistryUri`` |
| 🏗️ Load Mode | LOCAL Bootstrap |

## 💡 Troubleshooting

1. **Check LOCAL Bootstrap**
   - Verify PackageRepoProvider was checked out from Git
   - Confirm both modules imported successfully
   
2. **Verify GITHUB_TOKEN Permissions**
   - Token needs ``packages:write`` permission
   - Check repository secrets configuration
   
3. **Validate Module Manifest**
   - Run ``Test-ModuleManifest`` on ``.psd1``
   - Verify all required fields are present
   
4. **Review Workflow Logs**
   - Check detailed error information in workflow output
   - Look for specific PSResourceGet errors

## 🔗 Useful Links

- [📋 Issue #6 - Bootstrap Strategy](https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider/issues/6)
- [🎯 Issue #3 - Release Pipeline](https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider.GitHub/issues/3)
- [📖 GitHub Packages Documentation](https://docs.github.com/en/packages)
"@

$errorSummary | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Encoding utf8
Write-Error "❌ Error summary written"
