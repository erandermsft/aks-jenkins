param name string
param addressprefix string
param subnets array
param location string
param snkubenetAddrPrefix string =  ''
param snPeAddrPrefix string =  ''


var networkContributorRoleDefId = '4d97b98b-1d4f-4787-a291-c67834d212e7'


resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'umi-${name}'
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-${name}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressprefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: 'vnet-${name}-${subnet.name}'
      properties: {
        addressPrefix: subnet.subnetprefix
      }
    }]
  }

  resource subnetakscni 'subnets' existing = {
    name: 'vnet-${name}-sn-aks-cni'
  }

  resource subnetakskubenet 'subnets' existing = {
    name: 'vnet-${name}-sn-aks-kubenet'
  }

  resource subnetvms 'subnets' existing = {
    name: 'vnet-${name}-sn-vms'
  }

  resource subnetpe 'subnets' existing = {
    name: 'vnet-${name}-sn-pe'
  }
  
}

resource snakskubenet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = if(snkubenetAddrPrefix != ''){
  name: 'vnet-${name}-sn-aks-kubenet'
  parent: vnet
  properties: {
    addressPrefix: snkubenetAddrPrefix 
    routeTable: {
      id: rt.id
      location: location
    }
  } 
}

resource snPe 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = if(snPeAddrPrefix != ''){
  name: 'vnet-${name}-sn-pe'
  parent: vnet
  properties: {
    addressPrefix: snPeAddrPrefix 
    privateEndpointNetworkPolicies: 'Enabled'
  } 
}




resource setVnetRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(umi.id, networkContributorRoleDefId, name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', networkContributorRoleDefId)
    principalId: umi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource rt 'Microsoft.Network/routeTables@2022-05-01' = {
  name: 'rt-${vnet::subnetakskubenet.name}'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
    ]
  }
}

output kubenetrtId string = rt.id
output vnetId string = vnet.id
output subnetIdakscni string = vnet::subnetakscni.id 
output subnetIdakskubenet string = vnet::subnetakskubenet.id 
output subnetIdvms string = vnet::subnetvms.id
output subnetIdpe string = vnet::subnetpe.id 
output vnetname string = vnet.name 
