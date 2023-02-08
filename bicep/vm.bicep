param name string
param vm_size string = 'Standard_D4s_v4'
param subnetid string
param allowedhostIp string
param location string
param storageAccountName string
param utcValue string = utcNow()

param vm_username string = 'vmadmin'
@secure()
param vm_pwd string

resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'umi-${name}'
}

resource vm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: 'vm-${name}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umi.id}': {}
    }
  }
  properties: {

    osProfile: {
      computerName: 'vm-${name}'
      adminUsername: vm_username
      adminPassword: vm_pwd
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    hardwareProfile: {
      vmSize: vm_size
    }

    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-11'
        sku: 'win11-22h2-ent'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: 'nic-vm-${name}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetid
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-vm-${name}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-vm-${name}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-rdp'
        properties: {
          priority: 1000
          sourceAddressPrefix: allowedhostIp
          protocol: 'Tcp'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: 'cse-${name}'
  parent: vm
  location: location
  properties: {
    forceUpdateTag: utcValue
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true

    protectedSettings: {
      fileUris: [
        'https://${storageAccountName}.blob.${environment().suffixes.storage}/vmconfig/setup.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy bypass -File setup.ps1'
      managedIdentity: {
        clientId: umi.properties.clientId
      }
    }

  }
}
