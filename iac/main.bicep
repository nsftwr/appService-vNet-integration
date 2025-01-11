targetScope = 'resourceGroup'
param params object

/* Virtual Network */
module network 'modules/Network/virtualNetwork.bicep' = {
  name: 'network'
  params: {
    params: params
    addressSpace: '10.0.0.0/8'
    subnets: [
      {
        name: 'service-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: [
            {
              name: 'functionAppDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
        serviceEndpoints: [
          {
            service: 'Microsoft.Storage'
            locations: [
                params.location
            ]
          }
        ]
      }
    ]
  }
}

/* Storage account that will be used by the end-user via the Function App */
module dataStorage 'modules/Storage/storageAccount.bicep' = {
  name: 'dataStorage'
  params: {
    params: params
    subnetsToAllow: ['${network.outputs.id}/subnets/service-subnet']
    containers: ['blobs']
    uniquifier: 'data'
  }
}

/* Function App Resources */
module functionAppStorage 'modules/Storage/storageAccount.bicep' = {
  name: 'functionAppStorage'
  params: {
    params: params
    uniquifier: 'appservice'
  }
}

module appServicePlan 'modules/Web/serverfarms.bicep' = {
  name: 'appServicePlan'
  params: {
    params: params
  }
}

module functionApp 'modules/Web/sites.bicep' = {
  name: 'functionApp'
  params: {
    params: params
    serverFarmId: appServicePlan.outputs.id
    virtualNetworkSubnetId: '${network.outputs.id}/subnets/service-subnet'
    storageAccount: {
      id: functionAppStorage.outputs.id
      name: functionAppStorage.outputs.name
    }
  }
}

resource functionAppBlobReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('2a2b9908-6ea1-4ae2-8e65-a410df84e7d1', 'functionAppManagedIdentity', resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
    principalId: functionApp.outputs.managedIdentityId
    principalType: 'ServicePrincipal'
  }
}

