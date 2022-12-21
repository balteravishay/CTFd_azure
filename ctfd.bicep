@description('Deploy with VNet')
param vnet bool = false

@description('Server Name for Azure cache for Redis')
param redisServerName string = 'ctfd-redis-server'

@description('Server Name for Azure database for MariaDB')
param mariaServerName string = 'ctfd-maria-db-server'

@description('Database administrator login name')
@minLength(1)
param administratorLogin string = 'ctfd'

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string

@description('Server Name for Azure app service')
param appServicePlanName string = 'ctfd-app-server'

@description('Name for Azure Web app')
param webAppName string = 'ctfd-app'

@description('Name of the VNet')
param virtualNetworkName string = 'ctf-vnet'

@description('Location for all resources.')
param resourcesLocation string = resourceGroup().location

var resourcesSubnetName = 'resources_subnet'
var integrationSubnetName = 'integration_subnet'

// Scope
targetScope = 'resourceGroup'

module vnetModule './vnet.bicep' = if (vnet) {
  name: 'vnetDeploy'
  params: {
    location: resourcesLocation
    integrationSubnetName: integrationSubnetName
    resouorcesSubnetName: resourcesSubnetName
    virtualNetworkName: virtualNetworkName
  }
}

module redisModule './redis.bicep' = {
  name: 'redisDeploy'
  dependsOn: [vnetModule]
  params: {
    redisServerName: redisServerName
    virtualNetworkName: virtualNetworkName
    resourcesSubnetName: resourcesSubnetName
    location: resourcesLocation
    vnet: vnet
  }
}

module mariaDbModule './mariadb.bicep' = {
  name: 'mariaDbDeploy'
  dependsOn: [vnetModule]
  params: {
    mariaServerName: mariaServerName
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    virtualNetworkName: virtualNetworkName
    resourcesSubnetName: resourcesSubnetName
    location: resourcesLocation
    vnet: vnet
  }
}

module ctfWebAppModule './webapp.bicep' = {
  name: 'ctfDeploy'
  dependsOn: [
    redisModule
    mariaDbModule
  ]
  params: {
    mariaServerName: mariaServerName
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    virtualNetworkName: virtualNetworkName
    location: resourcesLocation
    redisServerName: redisServerName
    appServicePlanName: appServicePlanName
    integrationSubnetName: integrationSubnetName
    webAppName: webAppName
    vnet: vnet
  }
}
