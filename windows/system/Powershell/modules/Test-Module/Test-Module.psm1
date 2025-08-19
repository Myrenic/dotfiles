function Get-Greeting {
    param (
        [string]$Name
    )
    return "Hello, $Name!"
}

function Get-Farewell {
    param (
        [string]$Name
    )
    return "Goodbye, $Name!"
}

Export-ModuleMember -Function Get-Greeting, Get-Farewell