@description('Deploy in VNet')
param vnet bool

@description('Server Name for Azure database for MariaDB')
param mariaServerName string

@description('Database administrator login name')
@minLength(1)
param administratorLogin string

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the resources subnet')
param resourcesSubnetName string

@description('Name of the key vault')
param keyVaultName string

@description('Name of the connection string secret')
param ctfDbSecretName string

@description('Location for all resources.')
param location string


resource mariaDbServer 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: mariaServerName
  location: location
  sku: {
    name: 'GP_Gen5_2'
    tier: 'GeneralPurpose'
    capacity: 2
    size: '5120'
    family: 'Gen5'
  }
  properties: {
    createMode: 'Default'
    version:  '10.3'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    sslEnforcement: 'Disabled'
    publicNetworkAccess: (vnet ? 'Disabled' : 'Enabled') 
    storageProfile: {
      storageMB: 5120
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }

  resource mariadbconfig_char_set 'configurations@2018-06-01' = {
    name: 'character_set_server'
    properties: {
      source: 'user-override'
      value: 'utf8mb4'
    }
  }

  resource mariadbconfig_coallation 'configurations@2018-06-01' = {
    name: 'collation_server'
    properties: {
      source: 'user-override'
      value: 'utf8mb4_unicode_ci'
    }
  }

  resource mariadbconfig_wait_timeout 'configurations@2018-06-01' = {
    name: 'wait_timeout'
    properties: {
      source: 'user-override'
      value: '28800'
    }
  }

  resource allowAllWindowsAzureIps 'firewallRules@2018-06-01' = if (!vnet) {
    name: 'AllowAllWindowsAzureIps' 
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

module privateEndpointModule 'privateendpoint.bicep' = if (vnet) {
  name: 'mariaDbPrivateEndpointDeploy'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: resourcesSubnetName
    resuorceId: mariaDbServer.id
    resuorceGroupId: 'mariadbServer'
    privateDnsZoneName: 'privatelink.mariadb.database.azure.com'
    privateEndpointName: 'mariadb_private_endpoint'
    location: location
  }
}

module cacheSecret 'keyvaultsecret.bicep' = {
  name: 'mariaDbKeyDeploy'
  params: {
    keyVaultName: keyVaultName
    secretName: ctfDbSecretName
    secretValue: 'mysql+pymysql://${administratorLogin}%40${mariaServerName}.mariadb.database.azure.com:${administratorLoginPassword}@${mariaServerName}.mariadb.database.azure.com/ctfd'
  }
}


