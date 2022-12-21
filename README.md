# CTFd PaaS on Azure

Deploy [CTFd](https://github.com/CTFd/CTFd) to Azure PaaS services, using [Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep)

## Deploy to Azure

To deploy the bicep template to Azure, use the following script:

```bash
export DB_PASSWORD='YOUR PASSWORD'
export RESOURCE_GROUP_NAME='RESOURCE GROUP NAME'

az deployment group create --resource-group $RESOURCE_GROUP_NAME --template-file ctfd.bicep --parameters administratorLoginPassword=$DB_PASSWORD 
```

## Template Parameters

- **vnet** - Determine if the resources are deployed with a VNet, default is true (boolean).
- **redisServerName** - Name of Redis cache (string).
- **mariaServerName** - Name of MariaDB (string).
- **administratorLogin** - MariaDB admin name (string).
- **administratorLoginPassword** - MariaDB admin password, the only required parameter (string).
- **appServicePlanName** - Name of app service plan (string).
- **webAppName** - Name of app service webapp (string).
- **virtualNetworkName** - Name of virtual network (string).
- **resourcesLocation** - Location of resources, defaults to the resource group location (string).
