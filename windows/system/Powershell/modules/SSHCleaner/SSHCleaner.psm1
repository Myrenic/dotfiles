function hfix {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IP
    )

    ssh-keygen -f (Get-Item "$env:USERPROFILE\.ssh\known_hosts").FullName -R $IP
}

Export-ModuleMember -Function hfix

