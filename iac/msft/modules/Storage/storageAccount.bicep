// Standard parameters
@description('Parameters defined in the parameters file.')
param params object
@description('Uniquifier that can be added if needed.')
param uniquifier string = ''

// Resource specific parameters
@description('SKU of the storage account')
param sku string = 'Standard_LRS'
@description('Array of fully qualified virtual network IDs to allow in the storage account firewall.')
param subnetsToAllow array = []
@description('Array of storage account blob containers to create')
param containers array = []

var name = '${params.locationAbbrv}${params.env}st${params.app}'
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  #disable-next-line BCP334 // Silence false positive warning. Reason: Gives a warning how the name may not have enough characters, but in our case it would not be the case since the parameters that make up the name should always be filled in, either manally or programmatically.
  name: take(empty(uniquifier) ? name : '${name}${uniquifier}', 24) // Only take the first 24 characters since storage accounts only support a max of 24 chars.
  location: params.location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: [for subnet in subnetsToAllow: {
          action: 'Allow'
          id: subnet
          state: 'Succeeded'
      }]
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  resource blobStorage 'blobServices' = if (containers != 0) {
    name: 'default'
    properties: {}

    resource blobContainer 'containers' = [for container in containers: {
      name: container
      properties: {
        metadata: {}
        publicAccess: 'None'
      }
    }]
  }
}

output id string   = storageAccount.id
output name string = storageAccount.name
