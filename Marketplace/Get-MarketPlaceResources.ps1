#requires -modules Az.Resources,Az.ResourceGraph
if (-not (Get-AzContext)) {
    Connect-AzAccount
}
#Get All Subscriptions
$Subscriptions = Get-AzSubscription

Write-Output -InputObject "Found $($Subscriptions.Count) subscription"
$i = 0
$OfferList = @()
foreach ($Sub in $Subscriptions) {
    $i++
    Write-Output -InputObject "- Iterating through subscription ($($Sub.Id)/$($Sub.Name)) - ($i/$($subscriptions.count))"
    #Get all offers for subscription
    $Offers = ((Invoke-AzRestMethod -Path "/subscriptions/$($Sub.Id)/providers/Microsoft.MarketplaceOrdering/agreements?api-version=2015-06-01" -Method GET).Content | ConvertFrom-Json -Depth 100 ).Value
    if ($Offers) {
        Write-Output "Found $($Offers.count) marketplace items"
        foreach ($Offer in $Offers) {
            #Find resources with offer
            $subResources = ''
            $subResources = Search-AzGraph -Query "resources | where subscriptionId == '$($Sub.Id)' | extend publisher = tostring(parse_json(plan).publisher)| extend product = tostring(parse_json(plan).product) | where product == '$($Offer.properties.offer)'"
            if ($subResources) {
                Write-Output "$($subResources.id -join ',')"
                Write-Output "$($subResources.resourceGroup -join ',')"
            }
            $vmResources = ''
            $vmResources = Search-AzGraph -Query "resources | where subscriptionId == '$($Sub.Id)' and type == 'microsoft.compute/virtualmachines' | extend sku = tostring(properties.storageProfile.imageReference.sku) | extend Publisher = tostring(properties.storageProfile.imageReference.publisher)| extend Offer = tostring(properties.storageProfile.imageReference.offer) | extend offerType = 'VM'| where Offer != ''"
            if ($vmResources ) {
                Write-Output "$($vmResources.id -join ',')"
                Write-Output "$($vmResources.resourceGroup -join ',')"
            }
            $OfferList += [PSCustomObject]@{
                SubscriptionName   = $sub.Name
                Publisher          = $offer.properties.publisher
                Offer              = $offer.properties.offer
                Sku                = $offer.name
                State              = $offer.properties.state
                DeployedRG         = $subResources.resourceGroup -join ","
                DeployedResourceID = $subResources.id -join ","
            }
        }
    }
}

$OfferList | Export-Csv -Path Offers.csv -NoTypeInformation -Delimiter ";"