# Path to the package.json file
$packageJsonPath = "$PSScriptRoot/package.json"

# Function to install a package using winget
function Install-Package {
    param (
        [string]$PackageIdentifier,
        [string]$Version
    )
    Write-Host "Installing $PackageIdentifier version $Version..."
    winget install --id $PackageIdentifier --version $Version --accept-source-agreements --accept-package-agreements
}

# Read the package.json file
$packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json

# Iterate over each package and install it using winget
foreach ($package in $packageJson.Packages) {
    Install-Package -PackageIdentifier $package.PackageIdentifier -Version $package.Version
}

Write-Host "All packages installed!"
