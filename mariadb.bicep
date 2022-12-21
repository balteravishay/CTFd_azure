@description('Deploy in VNet')
param vnet bool = false

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

resource mariadb_privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (vnet) {
  name: 'mariadb_private_endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, resourcesSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'mariadb_privateEndpoint'
        properties: {
          privateLinkServiceId: mariaDbServer.id
          groupIds: [
            'mariadbServer'
          ]
        }
      }
    ]
  }
}

resource mariadb_privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (vnet) {
  name: 'privatelink.mariadb.database.azure.com'
  location: 'global'
  properties: {}
}

resource mariadb_privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (vnet) {
  parent: mariadb_privateDnsZone
  name: 'privatelink.mariadb.database.azure.com-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
  }
}

resource mariadb_pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = if (vnet) {
  name: 'mariadb_private_endpoint/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: mariadb_privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    mariadb_privateEndpoint
  ]
}
