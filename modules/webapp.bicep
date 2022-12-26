@description('Deploy in VNet')
param vnet bool

@description('Server Name for Azure app service')
param appServicePlanName string

@description('Name for Azure Web app')
param webAppName string

@description('Location for all resources.')
param location string

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the integration subnet')
param integrationSubnetName string

@description('Name of azure key vault')
param keyVaultName string

@description('Secret Name of the ctf database url in key vault')
param ctfDatabaseUrlSecretName string

@description('Secret Name of the ctf cache url in key vault')
param ctfCacheUrlSecretName string


resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }	
  sku:  {
  	name: 'B1'
    tier: 'Basic'
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    virtualNetworkSubnetId: (vnet ? resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, integrationSubnetName) : null)
    vnetRouteAllEnabled: (vnet ? true : false)
    siteConfig: {
      
      appSettings: [
        {
          name: 'DATABASE_URL'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${ctfDatabaseUrlSecretName}/)'
        }
        {
          name: 'REDIS_URL'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${ctfCacheUrlSecretName}/)'
        }
        {
          name: 'REVERSE_PROXY'
          value: 'False'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://index.docker.io'
        }
      ]
      linuxFxVersion: 'DOCKER|ctfd/ctfd:latest'
    }
    serverFarmId: appServicePlan.id
  }
}

output servicePrincipalId string = webApp.identity.principalId
