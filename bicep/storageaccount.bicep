
param name string
param location string

var stgRoleDefId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' //Storage Blob Data Reader

resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'umi-${name}'
}

resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: uniqueString(resourceGroup().id)
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

// Storage account Blobservice
resource blobservice 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  name: 'default'
  parent: stg
}

// Storage account blob container
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: 'vmconfig'
  parent: blobservice
}

resource setStorageAccountRbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: stg
  name: guid(umi.id, stgRoleDefId, name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', stgRoleDefId)
    principalId: umi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output storageAccountName string = stg.name
