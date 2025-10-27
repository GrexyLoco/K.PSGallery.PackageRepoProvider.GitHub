# Import all private functions
$privateFunctions = @(Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue)

foreach ($function in $privateFunctions) {
    try {
        . $function.FullName
    }
    catch {
        Write-Error "Failed to import function $($function.FullName): $_"
    }
}

# Export module members (currently none as all functions are private)
Export-ModuleMember -Function @()
