param name string
param location string

var containerInsights = {
  name: 'ContainerInsights(la-${name})'
  galleryName: 'ContainerInsights'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: 'la-${name}'
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource solutionsContainerInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: containerInsights.name
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: containerInsights.name
    publisher: 'Microsoft'
    product: 'OMSGallery/${containerInsights.galleryName}'
    promotionCode: ''
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${name}'
  location: location
  kind:'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id 
  }
}

