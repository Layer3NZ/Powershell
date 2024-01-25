# N-Able Uninstaller
# By Hayden Kirk / Layer3
# v1.0
# 15/01/2024
#
# You can search and use wildcards
# APPLICATION NAME AND PUBLISHER
# IE "*Agent*" = @("N-able Technologies","Second Publisher")
#
# You can also use this with -ReadOnly
# Find-And-ProcessPrograms -softwareMap $softwareMap -ReadOnly

$softwareMap = @{
    "File Cache Service Agent" = @("MspPlatform")
    "Patch Management Service Controller" = @("MspPlatform")
    "Request Handler Agent" = @("MspPlatform")
    "EcoSystem Agent" = @("Solarwinds MSP")
    "Windows Agent" = @("N-able Technologies")
}

function Find-And-ProcessPrograms {
    param (
        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$softwareMap,
        [switch]$ReadOnly
    )

    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($pattern in $softwareMap.Keys) {
        $allowedVendors = $softwareMap[$pattern]
        $found = $false

        foreach ($path in $uninstallPaths) {
            $programs = Get-ItemProperty $path
            $matchedPrograms = $programs | Where-Object { $_.DisplayName -like $pattern }

            foreach ($matchedProgram in $matchedPrograms) {
                if ($allowedVendors -contains $matchedProgram.Publisher) {
                    $found = $true
                    $uninstallString = $matchedProgram.UninstallString

                    if ($uninstallString -like "MsiExec.exe*") {
                        $uninstallCommand = "MsiExec.exe"
                        $uninstallArguments = "/X" + ($uninstallString -replace ".*\{", "{") + " /qn"
                    } else {
                        $uninstallCommand = $uninstallString.Trim('"')
                        $uninstallArguments = "/VERYSILENT"
                    }

                    if ($ReadOnly) {
                        Write-Host "Found $($matchedProgram.DisplayName) by $($matchedProgram.Publisher)"
                        Write-Host "Silent Uninstall String: $uninstallCommand $uninstallArguments"
                    } else {
                        Write-Host "Uninstalling $($matchedProgram.DisplayName) by $($matchedProgram.Publisher)..."
                        Write-Host "Executing: $uninstallCommand $uninstallArguments"
                        Start-Process -FilePath $uninstallCommand -ArgumentList $uninstallArguments -Wait
                    }
                }
            }
        }

        if (-not $found) {
            Write-Host "No program found matching the pattern '$pattern' with specified publishers."
        }
    }
}

Find-And-ProcessPrograms -softwareMap $softwareMap
