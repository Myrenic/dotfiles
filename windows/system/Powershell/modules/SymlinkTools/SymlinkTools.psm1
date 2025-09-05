function New-Symlink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Target,
        
        [Parameter(Mandatory=$true)]
        [string]$Link
    )
    if (-Not (Test-Path $Target)) {
        Write-Host "Source file does not exist: $Target"
        return
    }
    
    if (Test-Path $Link) {
        Remove-Item -Path $Link -Force -ErrorAction SilentlyContinue -Confirm:$false -Recurse
    }
    New-Item -ItemType SymbolicLink -Path $Link -Target $Target -ErrorAction SilentlyContinue
}

function New-Symlinks {
    param (
        [Parameter(Mandatory=$true)]
        [Array]$Links
    )

    foreach ($link in $Links) {
	write-host $link.Target
        New-Symlink -Target $link.Target -Link $link.Link
    }
}

function Get-Symlink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Link
    )
    if (-Not (Test-Path $Link)) {
        Write-Host "Symlink does not exist: $Link"
        return
    }
    
    $linkInfo = Get-Item -Path $Link
    Write-Host "Symlink: $Link"
    Write-Host "Target: $($linkInfo.Target)"
}

function Remove-Symlink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Link
    )
    if (-Not (Test-Path $Link)) {
        Write-Host "Symlink does not exist: $Link"
        return
    }
    
    Remove-Item -Path $Link -Force
    Write-Host "Deleted symlink: $Link"
}

Export-ModuleMember -Function New-Symlink, Get-Symlink, Remove-Symlink



Export-ModuleMember -Function New-Symlink, New-Symlinks, Get-Symlink, Remove-Symlink
