@{
    RootModule = 'K.PSGallery.PackageRepoProvider.GitHub.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'GrexyLoco'
    CompanyName = 'GrexyLoco'
    Copyright = '(c) GrexyLoco. All rights reserved.'
    Description = 'GitHub Packages provider backend for K.PSGallery.PackageRepoProvider. Enables seamless PowerShell module publishing and installation via GitHub Packages NuGet registry.'
    PowerShellVersion = '7.0'
    
    RequiredModules = @(
        @{ ModuleName = 'K.PSGallery.LoggingModule'; ModuleVersion = '0.1.0' }
        @{ ModuleName = 'Microsoft.PowerShell.PSResourceGet'; ModuleVersion = '1.0.0' }
    )
    
    FunctionsToExport = @()
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
