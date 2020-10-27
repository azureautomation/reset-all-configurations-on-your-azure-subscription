Function Reset-Azure

{
#We want to see any errors...
$ErrorActionPreference='Continue'

# Store the start time
$starttime = Get-Date

# Remove existing subscriptions and accounts from local PowerShell environment
Write-Host "Removing local Azure subscription certificates..."
foreach ($sub in Get-AzureSubscription)
{
    if ($sub.SubscriptionName)
    {
        Remove-AzureSubscription -SubscriptionName $sub.SubscriptionName -Force
    }
}
Write-Host "Signing out of Azure..."
foreach ($acct in Get-AzureAccount)
{
    Remove-AzureAccount $acct.Id -Force
}

# Sign into Azure
Add-AzureAccount

# Set correct mode ready to delete using service management model first
Switch-AzureMode -Name AzureServiceManagement

# Delete all VMs and cloud services
foreach ($svc in Get-AzureService)
{
    foreach ($vm in Get-AzureVM)
    {
        Stop-AzureVM -ServiceName $svc.ServiceName -Name $vm.Name -Force
        Remove-AzureVM -ServiceName $svc.ServiceName -Name $vm.Name -DeleteVHD
    }

    Remove-AzureService -ServiceName $svc.ServiceName -Force
}

Start-Sleep -Seconds 180 # Wait for previous operations to complete

# Delete all SQL Database servers
foreach ($dbserver in Get-AzureSqlDatabaseServer)
{
	Remove-AzureSqlDatabaseServer -ServerName $dbserver.ServerName -Force
}

# Delete everything else just in case ...
Get-AzureWebsite | Remove-AzureWebsite -Force
Get-AzureTrafficManagerProfile | Remove-AzureTrafficManagerProfile -Force
Get-AzureDisk | Remove-AzureDisk -DeleteVHD
Get-AzureStorageAccount | Remove-AzureStorageAccount
Get-AzureAffinityGroup | Remove-AzureAffinityGroup

# Delete any VPN gateways
# Get an error if there are no gateways, so temporarily change error action...
$ErrorActionPreference='SilentlyContinue'

foreach ($vnet in Get-AzureVNetSite)
{
    if ($vnet)
    {
         Write-Host "Processing " $vnet.Name "virtual network ..."
         Remove-AzureVNetGateway -VNetName $vnet.Name
    }
}

$ErrorActionPreference='Continue'

# Delete all virtual networks, DNS servers etc.
Remove-AzureVNetConfig

# Delete any Media Services accounts
foreach ($ms in Get-AzureMediaServicesAccount)
{
    if ($ms)
    {
         Write-Host "Deleting " $ms.name "Media Services Account..."
         Remove-AzureMediaServicesAccount -Name $ms.name -Force
    }
}

Start-Sleep -Seconds 60 # Wait for previous operations to complete

# Delete all resource groups
Switch-AzureMode AzureResourceManager

foreach ($rg in Get-AzureResourceGroup)
{
    if ($rg)
    {
         Write-Host "Deleting " $rg.ResourceGroupName "resource group..."
         Remove-AzureResourceGroup $rg.ResourceGroupName -Force
    }
}

# Set mode back to service management model
Switch-AzureMode -Name AzureServiceManagement

# Remove local SQL database if you have
Remove-SQLDB

# Display time taken for script to complete
$endtime = Get-Date
Write-Host Started at $starttime -ForegroundColor Magenta
Write-Host Ended at $endtime -ForegroundColor Yellow
Write-Host " "
$elapsed = $endtime - $starttime

If ($elapsed.Hours -ne 0){
  Write-Host Total elapsed time is $elapsed.Hours hours $elapsed.Minutes minutes -ForegroundColor Green
}
Else {
  Write-Host Total elapsed time is $elapsed.Minutes minutes -ForegroundColor Green
}
Write-Host " "

}
