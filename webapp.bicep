@description('Deploy in VNet')
param vnet bool = false

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

@description('Server Name for Azure cache for Redis')
param redisServerName string

@description('Server Name for Azure database for MariaDB')
param mariaServerName string

@description('Database administrator login name')
@minLength(1)
param administratorLogin string

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string

resource redis_cache 'Microsoft.Cache/redis@2022-06-01' existing = {
  name: redisServerName
}

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
  properties: {
    virtualNetworkSubnetId: (vnet ? resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, integrationSubnetName) : null)
    vnetRouteAllEnabled: (vnet ? true : false)
    siteConfig: {
      
      appSettings: [
        {
          name: 'DATABASE_URL'
          value: 'mysql+pymysql://${administratorLogin}%40${mariaServerName}.mariadb.database.azure.com:${administratorLoginPassword}@${mariaServerName}.mariadb.database.azure.com/ctfd'
        }
        {
          name: 'REDIS_URL'
          value: 'redis://:${redis_cache.listKeys().primaryKey}@${redisServerName}.redis.cache.windows.net'
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
