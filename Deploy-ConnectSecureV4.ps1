# ConnectSecure v4 Agent Download and Install
# Hayden Kirk
# Layer3 / www.layer3.nz
# 19/02/2024
# v1.0

if ($env:companyid -eq $null -or $env:tenantid -eq $null) {
    Write-Host "Environment variables not set, exiting";
    return 1;
}

# Check service
$serviceName = "CyberCNSAgent";
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue;
if ($service -eq $null) {
    Write-Host "Service not found, downloading and installing...";
} else {
    Write-Host "Service found, exiting";
    return 1;
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; 
$source = (Invoke-RestMethod -Method "Get" -URI "https://configuration.myconnectsecure.com/api/v4/configuration/agentlink?ostype=windows");
$destination = 'cybercnsagent.exe';
Invoke-WebRequest -Uri $source -OutFile $destination;
./cybercnsagent.exe -c $env:companyid -e $env:tenantid -i