
# Deploy
```
az deployment sub create --location westeurope --template-file "subscription.json" --parameters @subscription.parameters.json

az deployment sub create --location westeurope --template-file "subscription_pim.json" --parameters @subscription_pim.parameters.json
```
