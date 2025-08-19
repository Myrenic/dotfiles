# Import the module
Import-Module ./Windows/system/Powershell/modules/SymlinkTools -Force

winget import -i ./Windows/apps/winget/packages.json --ignore-versions --accept-package-agreements --accept-source-agreements --disable-interactivity --wait

$dotfilesRoot = "$PSScriptRoot"

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

code --list-extensions > extensions.txt
code --list-extensions | ForEach-Object { code --uninstall-extension $_ }
Get-Content extensions.txt | ForEach-Object { code --install-extension $_ }
remove-item extensions.txt

wsl --install
Restart-Computer -Force