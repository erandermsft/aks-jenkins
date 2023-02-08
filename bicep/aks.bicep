// Reqs 
// EncryptionAtHost 
// az feature register --namespace microsoft.compute --name EncryptionAtHost
// az provider register -n microsoft.compute

// Workload identity
// az feature register --namespace "Microsoft.ContainerService" --name "EnableWorkloadIdentityPreview"
// az provider register --namespace Microsoft.ContainerService


// params
param location string
param name string
param nodeResourceGroup string
param dockerBridgeCidr string
param dnsServiceIP string
param serviceCidr string
param aksSubnetId string
param adminGroupObjectIDs string
param privateDnsZoneId string = ''
param podCidr string = ''
param networkPlugin string

// vars
param kubernetesVersion string
var agentVMSize = 'Standard_D2ds_v4'

var managedIdentityOperatorDefId = 'f1a07417-d97a-45cb-824c-7a7467783830' // Managed Identity Operator

// Existing resources
resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'umi-${name}'
}

resource la 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: 'la-${name}'
}

// Azure kubernetes service
resource miOperatorRbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: resourceGroup()
  name: guid(umi.id, managedIdentityOperatorDefId, name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', managedIdentityOperatorDefId)
    principalId: umi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2022-07-02-preview' = {
  name: 'aks-${name}'
  location: location
  
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umi.id}': {}
    }
  }

  properties: {
    
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    disableLocalAccounts: false
    aadProfile: {
      enableAzureRBAC: true
      tenantID: subscription().tenantId
      managed: true
      adminGroupObjectIDs: [
        adminGroupObjectIDs
      ]
    }

    dnsPrefix: 'aks-${name}'
    identityProfile: {
      kubeletidentity: {
        resourceId: umi.id
        clientId: umi.properties.clientId
        objectId: umi.properties.principalId
      }
    }

    
    oidcIssuerProfile: {
      enabled: true
    }

    securityProfile: {
      workloadIdentity: {
        enabled: true

      }
    }

    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 1
        minCount: 1
        maxCount: 5
        availabilityZones: [
        //  '1'
          '2'
          '3'
        ]
        mode: 'System'
        vmSize: agentVMSize
        osDiskSizeGB: 120
        enableEncryptionAtHost: true
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        enableAutoScaling: true
        vnetSubnetID: aksSubnetId
        maxPods: networkPlugin == 'azure' ? 75 : 150
        upgradeSettings: {
          maxSurge: '33%'
        }
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
      {
        name: 'workpool'
        count: 1
        minCount: 1
        maxCount: 5
        availabilityZones: [
        //  '1'
          '2'
          '3'
        ]
        mode: 'User'
        vmSize: agentVMSize
        osDiskSizeGB: 70
        enableEncryptionAtHost: true
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        enableAutoScaling: true
        vnetSubnetID: aksSubnetId
        maxPods: networkPlugin == 'azure' ? 75 : 150
        upgradeSettings: {
          maxSurge: '33%'
        }
      }
    ]

    servicePrincipalProfile: {
      clientId: 'msi'
    }
    nodeResourceGroup: nodeResourceGroup

    networkProfile: {
      networkPlugin: networkPlugin
      loadBalancerSku: 'standard'
      dockerBridgeCidr: dockerBridgeCidr
      dnsServiceIP: dnsServiceIP
      serviceCidr: serviceCidr
      podCidr: networkPlugin == 'azure' ? null : podCidr
      networkPolicy: networkPlugin == 'azure' ? 'azure' : 'calico'
    }
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }

    addonProfiles: {
    
      // omsagent: {
      //   enabled: true
      //   config: {
      //     logAnalyticsWorkspaceResourceID: la.id
      //   }
      // }
      azurepolicy: {
        enabled: true
      }
    }

  }
  dependsOn: [
    miOperatorRbac
  ]

}

// Dapr
resource daprExtension 'Microsoft.KubernetesConfiguration/extensions@2022-04-02-preview' = {
  name: 'dapr'
  scope: aks
  properties: {
    extensionType: 'Microsoft.Dapr'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    configurationSettings: {
      'global.ha.enabled': 'false'
    }
    scope: {
      cluster: {
        releaseNamespace: 'dapr-system'
      }
    }
    configurationProtectedSettings: {}
  }
}
