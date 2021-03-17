#requires -modules Az.Resources,Az.ResourceGraph
param (
    [int]$SubscriptionCount,
    [string]$Path = 'Offers.csv',
    [int]$ThrottleLimit = 10
)

if (-not (Get-AzContext)) {
    Connect-AzAccount
}
#Start stopwatch
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()

#Get All Subscriptions
if ($SubscriptionCount -gt 0) {
    $Subscriptions = Get-AzSubscription | Select-Object -First $SubscriptionCount
}
else {
    $Subscriptions = Get-AzSubscription
}


Write-Host "- Found $($Subscriptions.Count) subscriptions" -ForegroundColor Yellow
$i = 0

$OfferList = $subscriptions | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
    Write-Host "- Processing subscription $($_.Name)/$($_.Id)"
    $Offers = ((Invoke-AzRestMethod -Path "/subscriptions/$($_.Id)/providers/Microsoft.MarketplaceOrdering/agreements?api-version=2015-06-01" -Method GET).Content | ConvertFrom-Json -Depth 100 ).Value
    if ($Offers) {
        Write-Host "- Found $($Offers.count) marketplace items in $($_.Name)/$($_.Id)"
        foreach ($Offer in $Offers) {
            #Find resources with offer
            $subResources = ''
            $subResources = Search-AzGraph -Query "resources | where subscriptionId == '$($_.Id)' | extend publisher = tostring(parse_json(plan).publisher)| extend product = tostring(parse_json(plan).product) | where product == '$($Offer.properties.offer)'"
            try {
                $offerDetails = Invoke-RestMethod -Method GET -Uri "https://catalogapi.azure.com/offers/$($offer.properties.publisher).$($offer.properties.offer)?api-version=2018-08-01-beta" -ErrorAction Ignore
            }
            catch {
                $offerDetails = "NotFoundInCatalog"
            }

            [PSCustomObject]@{
                SubscriptionName     = $_.Name
                Publisher            = $offer.properties.publisher
                Offer                = $offer.properties.offer
                Sku                  = $offer.name
                State                = $offer.properties.state
                SignDate             = $offer.properties.SignDate
                DeployedRG           = $subResources.resourceGroup -join "|"
                DeployedResourceID   = $subResources.id -join "|"
                PrivacyPolicyUri     = $offerDetails.PrivacyPolicyUri
                supportUri           = $offerDetails.supportUri
                legalTermsUri        = $offerDetails.legalTermsUri
                PublisherDisplayName = $offerDetails.PublisherDisplayName
                OfferSummary         = if ($offerDetails.summary) { $offerDetails.summary } else { $offerDetails }

            }
        }
    }
}

$OfferList | Sort-Object -Property SubscriptionName | Export-Csv -Path $Path -NoTypeInformation -Delimiter ";"

$StopWatch.Stop()
Write-host -ForegroundColor Yellow "Time elapsed: $($stopwatch.elapsed)"