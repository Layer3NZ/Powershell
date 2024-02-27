# N-Able Uninstaller
# By Hayden Kirk / Layer3
# v1.1
# 27/01/2024
#
# You can search and use wildcards
# APPLICATION NAME AND PUBLISHER
# IE "*Agent*" = @("N-able Technologies","Second Publisher")
#
# You can also use this with -ReadOnly
# Find-And-ProcessPrograms -softwareMap $softwareMap -ReadOnly
#
# Update Log
# v1.1 - Added the ability to remove the old Automation Manager Service

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

# Remove software
Find-And-ProcessPrograms -softwareMap $softwareMap

# Remove old automation manager service
$serviceName = "AutomationManagerAgent"

# Check if the service exists
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service) {
    Write-Output "Service '$serviceName' found. Attempting to delete..."

    # Attempt to stop the service in case it is running
    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
    
    # Wait a bit for the service to stop
    Start-Sleep -Seconds 5

    # Delete the service
    sc.exe delete $serviceName

    Write-Output "Service '$serviceName' has been deleted."
} else {
    Write-Output "Service '$serviceName' does not exist."
}