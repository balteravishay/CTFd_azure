@description('Deploy in VNet')
param vnet bool = false

@description('Server Name for Azure cache for Redis')
param redisServerName string

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the resources subnet')
param resourcesSubnetName string

@description('Location for all resources.')
param location string

resource redis_cache 'Microsoft.Cache/redis@2022-06-01' = {
  name: redisServerName
  location: location
  properties: {
    enableNonSslPort: true
    publicNetworkAccess: (vnet ? 'Disabled' : 'Enabled') 
    sku: {
      capacity: 0
      family: 'C'
      name: 'Basic'
    }
  }
}

resource redis_privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (vnet) {
  name: 'redis_private_endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, resourcesSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'redis_private_endpoint'
        properties: {
          privateLinkServiceId: redis_cache.id
          groupIds: [
            'redisCache'
          ]
        }
      }
    ]
  }
}

resource redis_privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (vnet) {
  name: 'privatelink.redis.cache.windows.net'
  location: 'global'
  properties: {}
}

resource redis_privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (vnet) {
  parent: redis_privateDnsZone
  name: 'privatelink.redis.cache.windows.net-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
  }
}

resource redis_pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = if (vnet) {
  name: 'redis_private_endpoint/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: redis_privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    redis_privateEndpoint
  ]
}

