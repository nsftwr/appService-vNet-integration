// Standard parameters
@description('Parameters defined in the parameters file.')
param params object
@description('Uniquifier that can be added if needed.')
param uniquifier string = ''

// Resource specific parameters
param sku string = 'Basic'
param skuCode string = 'B1'

var name = '${params.locationAbbrv}-${params.env}-asp-${params.app}'
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: empty(uniquifier) ? name : '${name}-${uniquifier}'
  location: params.location
  sku: {
    tier: sku
    name: skuCode
  }
  properties: {
    targetWorkerCount: 1
  }
}

output id string = appServicePlan.id
