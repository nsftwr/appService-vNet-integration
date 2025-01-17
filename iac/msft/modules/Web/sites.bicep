// Standard parameters
@description('Parameters defined in the parameters file.')
param params object
@description('Uniquifier that can be added if needed.')
param uniquifier string = ''

// Resource specific parameters
param serverFarmId string
param virtualNetworkSubnetId string
param storageAccount object
param kind string = 'functionapp'

var name = '${params.locationAbbrv}-${params.env}-func-${params.app}'
resource azureFunction 'Microsoft.Web/sites@2024-04-01' = {
  name: empty(uniquifier) ? name : '${name}-${uniquifier}'
  identity: {
    type: 'SystemAssigned'
  }
  location: params.location
  kind: kind
  properties: {
    serverFarmId: serverFarmId
    clientAffinityEnabled: false
    virtualNetworkSubnetId: virtualNetworkSubnetId
    httpsOnly: true
    siteConfig: {
      ftpsState: 'FtpsOnly'
      netFrameworkVersion: 'v8.0'
      alwaysOn: true
      appSettings: [
        {
          name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
          value: '1'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys('${storageAccount.id}', '2023-05-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
      ]
    }
  }
}

output managedIdentityId string = azureFunction.identity.principalId
