@{
    RootModule = 'K.PSGallery.PackageRepoProvider.GitHub.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = '1d70f'
    CompanyName = '1d70f'
    Copyright = '(c) 1d70f. All rights reserved.'
    Description = 'GitHub Packages provider backend for K.PSGallery.PackageRepoProvider. Enables seamless PowerShell module publishing and installation via GitHub Packages NuGet registry.'
    PowerShellVersion = '7.0'
    
    RequiredModules = @(
        # @{ ModuleName = 'K.PSGallery.LoggingModule'; ModuleVersion = '1.1.48' }
        @{ ModuleName = 'Microsoft.PowerShell.PSResourceGet'; ModuleVersion = '1.0.0' }
    )
    
    # Functions exported by this module (manifest-only strategy)
    FunctionsToExport = @(
        'Invoke-RegisterRepo',
        'Invoke-Publish',
        'Invoke-Install',
        'Invoke-Import',
        'Invoke-RemoveRepo'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('GitHub', 'Packages', 'NuGet', 'PSGallery', 'Provider')
            LicenseUri = 'https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider.GitHub/blob/main/LICENSE'
            ProjectUri = 'https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider.GitHub'
            IconUri = ''
            ReleaseNotes = 'Initial release of GitHub Packages Provider'
        }
    }
}
