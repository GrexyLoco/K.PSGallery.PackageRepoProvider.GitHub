# K.PSGallery.PackageRepoProvider.GitHub

GitHub Packages provider backend for K.PSGallery.PackageRepoProvider. Enables seamless PowerShell module publishing and installation via GitHub Packages NuGet registry.

## 📋 Features

- ✅ Register GitHub Packages repositories
- ✅ Publish PowerShell modules as NuGet packages
- ✅ Install modules with flexible version parsing (v1, 1.2, 1.2.3)
- ✅ Import modules into current session
- ✅ Remove registered repositories
- ✅ Secure credential handling with logging masking
- ✅ Full PSResourceGet integration

## 📦 Installation

```powershell
# Install from PowerShell Gallery (when available)
Install-PSResource -Name K.PSGallery.PackageRepoProvider.GitHub

# Or install manually
git clone https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider.GitHub.git
Import-Module ./K.PSGallery.PackageRepoProvider.GitHub/K.PSGallery.PackageRepoProvider.GitHub.psd1
```

## 🔑 GitHub Personal Access Token Setup

To use GitHub Packages, you need a Personal Access Token (PAT) with appropriate scopes:

### Creating a PAT

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Name: `GitHub Packages Access`
4. Scopes:
   - ✅ `read:packages` - Download packages from GitHub Packages
   - ✅ `write:packages` - Upload packages to GitHub Packages
   - ✅ `delete:packages` - Delete packages from GitHub Packages (optional)
5. Click "Generate token" and copy the token immediately

### Credential Format

- **Username**: Your GitHub username or organization name
- **Password**: Your Personal Access Token (PAT)

```powershell
# Create credential object
$username = 'your-github-username'
$token = 'ghp_YourPersonalAccessToken'
$secureToken = ConvertTo-SecureString $token -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $secureToken)
```

## 🚀 Usage

### 1. Register a GitHub Packages Repository

```powershell
# Create credentials
$cred = Get-Credential  # Username: github-owner, Password: PAT

# Register repository
Invoke-RegisterRepo `
    -RepositoryName 'MyGitHubPackages' `
    -RegistryUri 'https://nuget.pkg.github.com/myorg/index.json' `
    -Credential $cred `
    -Trusted
```

**Registry URL Format**: `https://nuget.pkg.github.com/<OWNER>/index.json`

Where `<OWNER>` is your GitHub username or organization name.

### 2. Publish a Module

```powershell
# Publish module to GitHub Packages
Invoke-Publish `
    -RepositoryName 'MyGitHubPackages' `
    -ModulePath './MyModule' `
    -Credential $cred
```

### 3. Install a Module

```powershell
# Install latest version
Invoke-Install `
    -RepositoryName 'MyGitHubPackages' `
    -ModuleName 'MyModule' `
    -Credential $cred

# Install specific major version (e.g., latest 1.x.x)
Invoke-Install `
    -RepositoryName 'MyGitHubPackages' `
    -ModuleName 'MyModule' `
    -Version 'v1' `
    -Credential $cred

# Install specific minor version (e.g., latest 1.2.x)
Invoke-Install `
    -RepositoryName 'MyGitHubPackages' `
    -ModuleName 'MyModule' `
    -Version '1.2' `
    -Credential $cred

# Install exact version
Invoke-Install `
    -RepositoryName 'MyGitHubPackages' `
    -ModuleName 'MyModule' `
    -Version '1.2.3' `
    -Credential $cred

# Install and import automatically
Invoke-Install `
    -RepositoryName 'MyGitHubPackages' `
    -ModuleName 'MyModule' `
    -Credential $cred `
    -ImportAfterInstall
```

### 4. Import a Module

```powershell
# Import by name
Invoke-Import -ModuleName 'MyModule' -Force

# Import by path
Invoke-Import -ModulePath './MyModule' -PassThru
```

### 5. Remove a Repository

```powershell
# Remove repository registration
Invoke-RemoveRepo -RepositoryName 'MyGitHubPackages'

# Preview what would be removed
Invoke-RemoveRepo -RepositoryName 'MyGitHubPackages' -WhatIf
```

## 📖 Version Parsing

The module supports flexible version parsing for installations:

| Input    | Parsed Version | Description           |
|----------|----------------|-----------------------|
| `v1`     | `1.*`          | Latest 1.x.x version  |
| `1`      | `1.*`          | Latest 1.x.x version  |
| `1.2`    | `1.2.*`        | Latest 1.2.x version  |
| `1.2.3`  | `1.2.3`        | Exact version         |
| (none)   | (latest)       | Latest available      |

## 🔒 Security & Logging

### Safe Credential Logging

All functions use safe logging patterns that mask sensitive credentials:

```powershell
# ✅ Logged: User: myusername, Secret: ***
# ❌ NOT Logged: Actual password/token
```

### Logging Functions

The module requires `K.PSGallery.LoggingModule` for:
- `Write-LogInfo` - General information
- `Write-LogDebug` - Detailed debug information
- `Write-LogWarning` - Warnings
- `Write-LogError` - Error messages

## 🧪 Testing

The module includes comprehensive Pester tests:

```powershell
# Run all tests
Invoke-Pester -Path ./Tests/

# Run specific test file
Invoke-Pester -Path ./Tests/Invoke-RegisterRepo.Tests.ps1

# Run integration tests
Invoke-Pester -Path ./Tests/Integration.Tests.ps1
```

## 📁 Module Structure

```
K.PSGallery.PackageRepoProvider.GitHub/
├── Private/
│   ├── Invoke-RegisterRepo.ps1    # Repository registration
│   ├── Invoke-Publish.ps1          # Module publishing
│   ├── Invoke-Install.ps1          # Module installation
│   ├── Invoke-Import.ps1           # Module importing
│   └── Invoke-RemoveRepo.ps1       # Repository removal
├── Tests/
│   ├── Invoke-RegisterRepo.Tests.ps1
│   ├── Invoke-Publish.Tests.ps1
│   ├── Invoke-Install.Tests.ps1
│   └── Integration.Tests.ps1
├── K.PSGallery.PackageRepoProvider.GitHub.psd1
├── K.PSGallery.PackageRepoProvider.GitHub.psm1
└── README.md
```

## 🔗 Dependencies

### Required Modules

- **K.PSGallery.LoggingModule** (>= 0.1.0) - Safe logging with credential masking
- **Microsoft.PowerShell.PSResourceGet** (>= 1.0.0) - PSResourceGet cmdlets

### PowerShell Version

- **PowerShell 7.0+** required

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the terms specified in the LICENSE file.

## 🔗 Related Projects

- **Parent Project**: [K.PSGallery.PackageRepoProvider](https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider)
- **Epic**: [K.PSGallery](https://github.com/GrexyLoco/K.PSGallery)

## 📞 Support

For issues and questions:
- Open an issue on [GitHub Issues](https://github.com/GrexyLoco/K.PSGallery.PackageRepoProvider.GitHub/issues)
- Reference the parent project for broader context
