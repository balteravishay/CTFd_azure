# CTFd PaaS on Azure

Deploy [CTFd](https://github.com/CTFd/CTFd) to Azure using PaaS services, using [Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep)

## Run the deployment locally

```bash
export DB_PASSWORD='YOUR PASSWORD'

az deployment group create --resource-group avbalter-bicep-vnet --template-file ctfd.bicep --parameters administratorLoginPassword=$DB_PASSWORD 
```

## Template Parameters

- **vnet** - Determine if the resources are deployed with a VNet, default is false (boolean).
- **redisServerName** - Name of Redis cache (string).
- **mariaServerName** - Name of MariaDB (string).
- **administratorLogin** - MariaDB admin name (string).
- **administratorLoginPassword** - MariaDB admin password, the only required parameter (string).
- **appServicePlanName** - Name of app service plan (string).
- **webAppName** - Name of app service webapp (string).
- **virtualNetworkName** - Name of virtual network (string).
- **resourcesLocation** - Location of resources, defaults to the resource group location (string).
