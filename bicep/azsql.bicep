param name string
param location string
@secure()
param sqlpwd string

// Azure SQL server
resource sqlsrv 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: 'sqlsrv-${name}'
  location: location
  properties: {
    administratorLogin: 'sqleverestadmin'
    administratorLoginPassword: sqlpwd
    publicNetworkAccess: 'Enabled'
  }

}

// Azure SQL Server Database
resource sqldb 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlsrv
  name: 'db-${name}'
  location: location
  sku: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
    capacity: 1
    family: 'Gen5'
  }
  properties: {
    minCapacity:1
    
  }
}

// Allow Azure Services
resource SQLAllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2020-11-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlsrv
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}
