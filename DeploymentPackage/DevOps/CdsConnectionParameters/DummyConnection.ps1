# This script is used by DevOps import and export scripts to establish a connection to a developers
# assigned CDS Sandbox Environment.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12



@{
    CrmConnectionParameter = @{    
        OrganizationName = $null
        OnlineType = "Office365"
        DeploymentRegion = "NorthAmerica"
        Credential = $null
    }
    PowerAppsConnectionParamter = @{
        EnvironmentName = $null
        Username = $null
        SecurePassword = $null
    }
}