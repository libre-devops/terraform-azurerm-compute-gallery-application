param(
    [string]$action = "install",
    [string]$version = "latest"
)

function Get-LatestPowerShellCoreVersion {
    $apiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
    $latestRelease = Invoke-RestMethod -Uri $apiUrl
    return $latestRelease.tag_name
}

function Download-PowerShellCore {
    param(
        [string]$version
    )

    $downloadUrl = $null

    if ($version -eq "latest") {
        $version = Get-LatestPowerShellCoreVersion
    }

    $releasesUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/tags/$version"
    $release = Invoke-RestMethod -Uri $releasesUrl
    $asset = $release.assets | Where-Object { $_.name -like "*-win-x64.msi" }

    if ($null -ne $asset) {
        $downloadUrl = $asset.browser_download_url
    }

    if ($null -ne $downloadUrl) {
        $outputPath = "$env:TEMP\PowerShell-$version-win-x64.msi"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath
        return $outputPath
    } else {
        Write-Error "Failed to find PowerShell Core MSI download URL."
        exit
    }
}

function Install-PowerShellCore {
    param(
        [string]$installerPath
    )

    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet" -Wait
}

function Remove-PowerShellCore {
    $productCode = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE 'PowerShell%7-%x64'" | Select-Object -ExpandProperty IdentifyingNumber
    if ($productCode) {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x `"$productCode`" /quiet" -Wait
    } else {
        Write-Host "PowerShell Core is not installed."
    }
}

function Update-PowerShellCore {
    Remove-PowerShellCore
    $installerPath = Download-PowerShellCore -version $version
    Install-PowerShellCore -installerPath $installerPath
}

switch ($action) {
    "install" {
        $installerPath = Download-PowerShellCore -version $version
        Install-PowerShellCore -installerPath $installerPath
    }
    "remove" {
        Remove-PowerShellCore
    }
    "update" {
        Update-PowerShellCore
    }
    default {
        Write-Host "Invalid action. Please specify 'install', 'remove', or 'update'."
    }
}
