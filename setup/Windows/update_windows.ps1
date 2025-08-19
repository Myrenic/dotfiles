# Import the module

$dotfilesRoot = "../../"

Import-Module $dotfilesRoot/Windows/system/Powershell/modules/SymlinkTools -Force


# Define source/target pairs
$symlinks = @(
    @{ Target = "$dotfilesRoot/windows/system/Powershell"; Link = (Split-Path -Path $PROFILE -Parent) },
    @{ Target = "$dotfilesRoot/common/apps/git/.gitconfig"; Link = "$env:USERPROFILE\.gitconfig" },
    @{ Target = "$dotfilesRoot/common/apps/vscode/settings.json"; Link = "$env:APPDATA\Code\User\settings.json" },
    @{ Target = "$dotfilesRoot/common/apps/vscode/keybindings.json"; Link = "$env:APPDATA\Code\User\keybindings.json" },
    @{ Target = "$dotfilesRoot/common/apps/vscode/extensions.json"; Link = "$env:USERPROFILE\.vscode\extensions\extensions.json" }
    @{ Target = "$dotfilesRoot/windows/apps/WindowsTerminal/settings.json"; Link = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" }
    @{ Target = "$dotfilesRoot/windows/apps/PowerToys/settings.json"; Link = "$env:LOCALAPPDATA\Microsoft\PowerToys\settings.json" }
    )

# Call the helper function
New-Symlinks -Links $symlinks