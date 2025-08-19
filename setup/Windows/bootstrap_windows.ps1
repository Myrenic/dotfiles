$account = "Myrenic"
$repo    = "dotfiles"
$branch  = "main"

$dotfilesTempDir = Join-Path $env:TEMP "dotfiles"
if (![System.IO.Directory]::Exists($dotfilesTempDir)) {[System.IO.Directory]::CreateDirectory($dotfilesTempDir)}
$sourceFile = Join-Path $dotfilesTempDir "dotfiles.zip"
$dotfilesInstallDir = Join-Path $dotfilesTempDir "$repo-$branch"

function Download-File {
  param (
    [string]$url,
    [string]$file
  )
  Write-Host "Downloading $url to $file"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $url -OutFile $file
}

function Unzip-File {
    param (
        [string]$File,
        [string]$Destination = (Get-Location).Path
    )

    $filePath = Resolve-Path $File
    $destinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

    If (($PSVersionTable.PSVersion.Major -ge 3) -and
        (
            [version](Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Version -ge [version]"4.5" -or
            [version](Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" -ErrorAction SilentlyContinue).Version -ge [version]"4.5"
        )) {
        try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$filePath", "$destinationPath")
        } catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    } else {
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.Namespace($destinationPath).copyhere(($shell.NameSpace($filePath)).items())
        } catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    }
}

function Git-CloneOrPull {
    param (
        [string]$repoDir,
        [string]$repoUrl,
        [string]$branch
    )

    if (Test-Path "$repoDir\.git") {
        Write-Host "Repository already exists. Pulling latest changes..."
        Push-Location $repoDir
        git pull origin $branch
        Pop-Location
    } else {
        Write-Host "Cloning repository..."
        git clone -b $branch $repoUrl $repoDir
    }
}

$gitInstalled = Get-Command git -ErrorAction SilentlyContinue

if ($gitInstalled) {
    Write-Host "Git is installed. Using git clone/pull method."
    $repoUrl = "https://github.com/$account/$repo.git"
    Git-CloneOrPull $dotfilesInstallDir $repoUrl $branch
} else {
    Write-Host "Git is not installed. Using download and unzip method."
    Download-File "https://github.com/$account/$repo/archive/$branch.zip" $sourceFile
    if ([System.IO.Directory]::Exists($dotfilesInstallDir)) {[System.IO.Directory]::Delete($dotfilesInstallDir, $true)}
    Unzip-File $sourceFile $dotfilesTempDir
}

Push-Location $dotfilesInstallDir
& .\setup\Windows\install_windows.ps1
