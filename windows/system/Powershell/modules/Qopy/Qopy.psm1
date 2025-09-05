function Qopy {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,

        [Parameter(Mandatory=$true)]
        [string]$DestinationPath,

        [Parameter(Mandatory=$true)]
        [string]$LogFile,

        [Parameter(Mandatory=$true)]
        [string]$MD5Csv = "C:\Temp\MD5_Tracking.csv"
    )

    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory | Out-Null
    }

    function Get-MD5($path) {
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $stream = [System.IO.File]::OpenRead($path)
        $hash = $md5.ComputeHash($stream)
        $stream.Close()
        return ([BitConverter]::ToString($hash) -replace '-', '').ToLower()
    }

    # Load or create CSV
    if (Test-Path $MD5Csv) {
        $fileList = Import-Csv $MD5Csv
    } else {
        $sourceFiles = Get-ChildItem -Path $SourcePath -Recurse -File
        $fileList = $sourceFiles | ForEach-Object {
            [PSCustomObject]@{
                Source      = $_.FullName
                Destination = $_.FullName.Replace($SourcePath, $DestinationPath)
                SourceMD5   = ""
                DestMD5     = ""
                Status      = "Pending"
            }
        }
        $fileList | Export-Csv $MD5Csv -NoTypeInformation
    }

    # Filter files to copy (Pending, Missing, Mismatch)
    $filesToCopy = $fileList | Where-Object { $_.Status -ne "OK" } 

    foreach ($file in $filesToCopy) {
        $destDir = Split-Path $file.Destination
        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory | Out-Null
        }

        # Copy single file with Robocopy
        robocopy (Split-Path $file.Source) $destDir $(Split-Path $file.Source -Leaf) /Z /R:3 /W:5 /LOG:$LogFile /TEE | Out-Null

        # MD5 verification
        if (Test-Path $file.Destination) {
            $file.SourceMD5 = Get-MD5 $file.Source
            $file.DestMD5   = Get-MD5 $file.Destination
            if ($file.SourceMD5 -eq $file.DestMD5) {
                $file.Status = "OK"
                Write-Host "MD5 OK: $($file.Source)"
            } else {
                $file.Status = "Mismatch"
                Write-Host "MD5 MISMATCH: $($file.Source)"
            }
        } else {
            $file.Status = "Missing"
            Write-Host "MISSING: $($file.Source)"
        }

        # Save progress after each file
        $fileList | Export-Csv $MD5Csv -NoTypeInformation
    }

    Write-Host "Verification complete. Check $MD5Csv for details."
}
