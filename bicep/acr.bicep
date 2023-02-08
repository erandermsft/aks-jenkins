param name string
param location string = resourceGroup().location

var acrRoleDefId = '7f951dda-4ed3-4680-a7ca-43fe172d538d' // Acr Pull

resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'umi-${name}'
}

resource acr 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name:replace('acr${name}','-','')
  location:location
  sku:{
    name:'Standard'
  }
}



resource setAcrRbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: acr
  name: guid(umi.id, acrRoleDefId, name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', acrRoleDefId)
    principalId: umi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output acrId string = acr.id
