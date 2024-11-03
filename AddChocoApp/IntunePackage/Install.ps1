[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Packagename,

    [Parameter()]
    [switch]
    $InstallChoco,

    [Parameter()]
    [string]
    $CustomRepo,

    [Parameter()]
    [switch]
    $Trace
)

try {
    if ($Trace) { Start-Transcript -Path (Join-Path $env:windir "\temp\choco-$Packagename-trace.log") }
    $chocoPath = "$($ENV:SystemDrive)\ProgramData\chocolatey\bin\choco.exe"

    # Moved Chocolatey installation check outside of conditional block
    if (-not (Test-Path $chocoPath)) {
        try {
            Write-Host "Chocolatey not found. Installing..."
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            $chocoPath = "$($ENV:SystemDrive)\ProgramData\chocolatey\bin\choco.exe"
            Write-Host "Chocolatey installation completed"
        }
        catch {
            Write-Host "Chocolatey Installation Error: $($_.Exception.Message)"
            throw "Failed to install Chocolatey"
        }
    }

    try {
        $localprograms = & "$chocoPath" list --localonly
        $CustomRepoString = if ($CustomRepo) { "--source $customrepo" } else { $null }
        if ($localprograms -like "*$Packagename*" ) {
            Write-Host "Upgrading $packagename"
            & "$chocoPath" upgrade $Packagename $CustomRepoString
        }
        else {
            Write-Host "Installing $packagename"
            & "$chocoPath" install $Packagename -y $CustomRepoString
        }
        Write-Host 'Completed.'
    }  
    catch {
        Write-Host "Install/upgrade error: $($_.Exception.Message)"
        throw "Failed to install/upgrade package: $($_.Exception.Message)"
    }

}
catch {
    Write-Host "Error encountered: $($_.Exception.Message)"
    throw $_.Exception.Message
}
finally {
    if ($Trace) { Stop-Transcript }
}

exit $?
