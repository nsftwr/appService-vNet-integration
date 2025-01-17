// Standard parameters
@description('Parameters defined in the parameters file.')
param params object
@description('Uniquifier that can be added if needed.')
param uniquifier string = ''

// Resource specific parameters
@description('List of subnets to create.')
param subnets array
@description('Address space of the virtual network.')
param addressSpace string

var name = '${params.locationAbbrv}-${params.env}-vnet-${params.app}'
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: empty(uniquifier) ? name : '${name}-${uniquifier}'
  location: params.location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        natGateway: subnet.properties.?natGateway ?? null
        networkSecurityGroup: subnet.properties.?networkSecurityGroup ?? null
        addressPrefix: subnet.properties.addressPrefix
        delegations: subnet.properties.?delegations ?? []
        serviceEndpoints: subnet.?serviceEndpoints ?? []
      }
    }]
  }
}

output id string = virtualNetwork.id
