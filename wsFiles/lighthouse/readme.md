
# Deploy
```
az deployment sub create --location westeurope --template-file "subscription.bicep" --parameters @subscription.parameters.json

az deployment sub create --location westeurope --template-file "subscription_pim.bicep" --parameters @subscription_pim.parameters.json
```
