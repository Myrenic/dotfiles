function Show-GitHubTree {
    param(
        [Parameter(Mandatory=$true)]
        [string]$GitUrl,
        [string]$Token,
        [string]$OutputFile,
        [switch]$Override
    )

    # Normalize input to owner/repo
    if ($GitUrl -match "(?:https?://)?(?:www\.)?github\.com/([^/]+)/([^/]+)") {
        $owner = $matches[1]
        $repo = $matches[2] -replace "/.*",""
    } elseif ($GitUrl -match "^([^/]+)/([^/]+)$") {
        $owner = $matches[1]
        $repo = $matches[2]
    } else {
        throw "Invalid GitHub URL or format"
    }

    $baseUrl = "$owner/$repo"

    # Check if repo already exists in file
    if ($OutputFile -and (Test-Path $OutputFile)) {
        $fileContent = Get-Content $OutputFile -Raw
        if ($fileContent -match [regex]::Escape($baseUrl)) {
            Write-Host "Repository $baseUrl is already in the file."
            return
        }
    }

    # Prepare API call
    $apiUrl = "https://api.github.com/repos/$owner/$repo"
    $headers = @{
        "Accept" = "application/vnd.github.v3+json"
    }
    if ($Token) { $headers["Authorization"] = "token $Token" }

    # 1. Get default branch
    $repoInfo = Invoke-RestMethod -Uri $apiUrl -Headers $headers
    $branch = $repoInfo.default_branch

    # 2. Get latest commit SHA for branch
    $branchInfo = Invoke-RestMethod -Uri "$apiUrl/branches/$branch" -Headers $headers
    $commitSha = $branchInfo.commit.sha

    # 3. Get commit object to find tree SHA
    $commit = Invoke-RestMethod -Uri "$apiUrl/git/commits/$commitSha" -Headers $headers
    $treeSha = $commit.tree.sha

    # 4. Get recursive tree
    $tree = Invoke-RestMethod -Uri "$($baseUrl)/git/trees/$($treeSha)?recursive=1" -Headers $headers

    # 5. Prepare output
    $urls = $tree.tree | ForEach-Object {
        if ($_.type -eq "blob") {
            "https://raw.githubusercontent.com/$owner/$repo/$branch/$($_.path)"
        }
    }

    if ($OutputFile) {
        if ($Override -or -not (Test-Path $OutputFile)) {
            $urls | Out-File -FilePath $OutputFile -Encoding utf8
        } else {
            $urls | Out-File -FilePath $OutputFile -Encoding utf8 -Append
        }
    } else {
        $urls
    }
}

Export-ModuleMember -Function Show-GitHubTree
