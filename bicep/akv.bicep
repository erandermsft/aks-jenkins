
param name string
param location string

var akvRoleDefId = '4633458b-17de-408a-b874-0445c86b69e6' // Secrets user

resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'umi-${name}'
}

resource akv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name : 'akv-${name}'
  location : location
  properties : {
    sku:{
      name:'standard'
      family: 'A'
    }
    enableRbacAuthorization:true
    enabledForTemplateDeployment:true
    tenantId:subscription().tenantId
  }
}

resource setAkvRbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: akv
  name: guid(umi.id, akvRoleDefId, name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', akvRoleDefId)
    principalId: umi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output akvId string = akv.id
