function Qopy {
    [CmdletBinding()]
    param (
        # Mandatory: path to the source folder containing files to copy
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        # Mandatory: path to the destination folder where files will be copied
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        # Optional: CSV file to track file copies and MD5 checksums, defaults to "./file_tracking.csv"
        [Parameter(Mandatory = $false)]
        [string]$MD5Csv = "./file_tracking.csv"
    )

    Begin {
        # Ensure the destination folder exists
        if (-not (Test-Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory | Out-Null
        }

        # Convert paths to absolute paths for consistent handling
        $absSource = (Get-Item -LiteralPath $SourcePath).FullName.TrimEnd('\', '/')
        $absDest   = (Get-Item -LiteralPath $DestinationPath).FullName.TrimEnd('\', '/')

        # Prepare to handle any leftover partial CSV files from previous runs
        $baseName = [IO.Path]::GetFileNameWithoutExtension($MD5Csv)
        $dir      = Split-Path $MD5Csv -Parent
        if (-not $dir) { $dir = Get-Location }

        $partialFiles = Get-ChildItem -Path $dir -Filter "$baseName.*.partial" -ErrorAction SilentlyContinue
        if ($partialFiles) {
            Write-Host "Found leftover partial files — merging..."
            $merged = @()
            foreach ($pf in $partialFiles) {
                Write-Host "- $($pf.Name)"
                $merged += Import-Csv $pf
            }

            # Merge with existing main CSV if it exists
            if (Test-Path $MD5Csv) {
                $existing = Import-Csv $MD5Csv
                $merged   = $existing + $merged | Sort-Object Source -Unique
            }

            $merged | Export-Csv $MD5Csv -NoTypeInformation

            # Remove old partial files
            foreach ($pf in $partialFiles) { Remove-Item $pf -Force }
            Write-Host "Merged partial files into $MD5Csv."
        }

        # Load existing CSV or create a new one listing all files
        if (Test-Path $MD5Csv) {
            $fileList = Import-Csv $MD5Csv
        } else {
            $sourceFiles = Get-ChildItem -Path $absSource -Recurse -File
            $fileList    = $sourceFiles | ForEach-Object {
                [PSCustomObject]@{
                    Source      = $_.FullName
                    Destination = $_.FullName.Replace($absSource, $absDest)
                    SourceMD5   = ""      # placeholder for source file hash
                    DestMD5     = ""      # placeholder for destination file hash
                    Status      = "Pending"
                }
            }
            $fileList | Export-Csv $MD5Csv -NoTypeInformation
        }

        # Only process files that are not already verified as copied
        $filesToCopy = $fileList | Where-Object { $_.Status -ne "OK" }
    }

    Process {
        # Process files in parallel to speed up copying
        $filesToCopy | ForEach-Object -Parallel {
            # Function to calculate MD5 checksum of a file, get-filehash does not always work.
            function Get-MD5($path) {
                $md5    = [System.Security.Cryptography.MD5]::Create()
                $stream = [System.IO.File]::OpenRead($path)
                $hash   = $md5.ComputeHash($stream)
                $stream.Close()
                return ([BitConverter]::ToString($hash) -replace '-', '').ToLower()
            }

            # Prepare a unique partial CSV file for this parallel thread
            $guid       = [guid]::NewGuid().ToString()
            $partialCsv = Join-Path $using:dir "$($using:baseName).$guid.partial"
            $destDir    = Split-Path $_.Destination

            # Ensure the destination folder exists
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory | Out-Null
            }

            # Copy the file using robocopy with retry and restart options
            robocopy (Split-Path $_.Source) $destDir (Split-Path $_.Source -Leaf) /Z /R:3 /W:5 | Out-Null

            # Verify file copy by comparing MD5 checksums
            if (Test-Path $_.Destination) {
                $_.SourceMD5 = Get-MD5 $_.Source
                $_.DestMD5   = Get-MD5 $_.Destination
                $_.Status    = if ($_.SourceMD5 -eq $_.DestMD5) { "OK" } else { "Mismatch" }
                Write-Host "$($_.Status): $($_.Source)"
            } else {
                $_.Status = "Missing"
                Write-Host "MISSING: $($_.Source)"
            }

            # Save progress to partial CSV in case of interruption
            $_ | Export-Csv $partialCsv -Append -NoTypeInformation
        } -ThrottleLimit 16
    }

    End {
        # Merge all partial CSVs into the main CSV at the end of the run
        $partialFiles = Get-ChildItem -Path $dir -Filter "$baseName.*.partial" -ErrorAction SilentlyContinue
        if ($partialFiles) {
            Write-Host "Merging partial files..."
            $merged = @()
            foreach ($pf in $partialFiles) { $merged += Import-Csv $pf }

            if (Test-Path $MD5Csv) {
                $existing     = Import-Csv $MD5Csv
                $existingDict = @{}
                foreach ($item in $existing) { $existingDict[$item.Source] = $item }

                # Overwrite with latest data from partial files
                foreach ($item in $merged) { $existingDict[$item.Source] = $item }

                $merged = $existingDict.Values
            }

            $merged | Export-Csv $MD5Csv -NoTypeInformation
            Write-Host "Merged all partial CSVs into $MD5Csv."
        }

        # Clean up any remaining partial files
        foreach ($pf in $partialFiles) { Remove-Item $pf -Force }

        Write-Host "Verification complete. Check $MD5Csv for details."
    }
}