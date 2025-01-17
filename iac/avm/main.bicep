targetScope = 'resourceGroup'
param params object

/* Virtual Network */
module network 'br/public:avm/res/network/virtual-network:0.5.2' = {
  name: 'network'
  params: {
    name: '${params.locationAbbrv}-${params.env}-vnet-${params.app}'
    addressPrefixes: ['10.0.0.0/8']
    subnets: [
      {
        name: 'service-subnet'
        addressPrefix: '10.0.0.0/24'
        serviceEndpoints: ['Microsoft.Storage']
        delegation: 'Microsoft.Web/serverFarms'
      }
    ]
  }
}

/* Storage account that will be used by the end-user via the Function App */
module dataStorage 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: 'dataStorage'
  params: {
    name: take('${params.locationAbbrv}${params.env}st${params.app}data', 24)
    kind: 'BlobStorage'
    skuName: 'Standard_LRS'
    roleAssignments: [
      {
        principalId: functionApp.outputs.systemAssignedMIPrincipalId!
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Blob Data Reader'
      }
    ]
    blobServices: {
      containers: [
        {
          name: 'blobs'
        }
      ]
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: network.outputs.subnetResourceIds[0]
        }
      ]
    }
  }
}

/* Function App Resources */
module functionAppStorage 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: 'functionAppStorage'
  params: {
    name: take('${params.locationAbbrv}${params.env}st${params.app}appservice', 24)
    skuName: 'Standard_LRS'
  }
}

module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'appServicePlan'
  params: {
    name: '${params.locationAbbrv}-${params.env}-asp-${params.app}'
    kind: 'windows'
    skuName: 'B1'
    targetWorkerCount: 1
  }
}

module functionApp 'br/public:avm/res/web/site:0.13.1' = {
  name: 'functionApp'
  params: {
    name: '${params.locationAbbrv}-${params.env}-func-${params.app}'
    kind: 'functionapp'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    appSettingsKeyValuePairs: {
      WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED: '1'
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
    }
    storageAccountResourceId: functionAppStorage.outputs.resourceId
    managedIdentities: {
      systemAssigned: true
    }
    virtualNetworkSubnetId: network.outputs.subnetResourceIds[0]
  }
}
