function Get-User {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SamAccountName,
        [string]$Server = 'emea.thermo.com'
    )

    # Show progress bar while retrieving
    $Activity = "Retrieving AD User"
    $Status   = "Querying $SamAccountName..."
    for ($i = 1; $i -le 100; $i += 20) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $i
        Start-Sleep -Milliseconds 100
    }

    try {
        if ($Server) {
            $User = Get-ADUser -Identity $SamAccountName -Server $Server -Properties * -ErrorAction Stop
        } else {
            $User = Get-ADUser -Identity $SamAccountName -Properties * -ErrorAction Stop
        }
    }
    catch {
        Write-Progress -Activity $Activity -Completed
        Write-Host "❌ Could not find user $SamAccountName" -ForegroundColor Red
        return
    }

    # Clear progress
    Write-Progress -Activity $Activity -Completed

    # Output formatted details
    Write-Host "==================== User Info ====================" -ForegroundColor Cyan
    Write-Host "Display Name   : $($User.DisplayName)"
    Write-Host "Username       : $($User.SamAccountName)"
    Write-Host "Email          : $($User.UserPrincipalName)"
    Write-Host "Full Name      : $($User.DistinguishedName)"
    Write-Host "Title          : $($User.Title)"
    Write-Host "Site           : $($User.l)"
    Write-Host "Enabled        : $($User.Enabled)"
    Write-Host "Locked Out     : $($User.LockedOut)"
    Write-Host "Last Logon     : $($User.LastLogonDate)"
    Write-Host "Bad Passwords  : $($User.BadLogonCount)"
    Write-Host "Last Bad Pwd   : $($User.LastBadPasswordAttempt)"
    Write-Host "Pwd Last Set   : $($User.PasswordLastSet)"
    Write-Host "Pwd Expired    : $($User.PasswordExpired)"
    Write-Host "Department     : $($User.Department)"
    Write-Host "Title          : $($User.Title)"
    Write-Host "Employee No    : $($User.extensionAttribute6)"
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Cyan
}




Export-ModuleMember -Function Get-User
