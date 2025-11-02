# Manifest-only loading strategy
# PowerShell automatically dot-sources Public/*.ps1 files
# Functions are exported via FunctionsToExport in manifest (.psd1)
# No manual Export-ModuleMember needed

# Dot-source all public functions
$PublicFunctions = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
foreach ($file in $PublicFunctions) {
    try {
        . $file.FullName
    }
    catch {
        Write-Error "Failed to import function $($file.FullName): $_"
    }
}
