# This script is used by DevOps import and export scripts to establish a connection to a developers
# assigned CDS Sandbox Environment.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$credential = (Get-Credential -UserName [myname]@iic.idaho.gov -Message "Enter credentials")
$orgName = "[mydev]" # [mydev].crm.dynamics.com

@{
    CrmConnectionParameter = @{    
        OrganizationName = $orgName
        OnlineType = "Office365"
        DeploymentRegion = "NorthAmerica2"
        Credential = $credential
    }
    PowerAppsConnectionParamter = @{
        EnvironmentName = $orgName
        Username = $credential.UserName
        SecurePassword = $credential.Password
    }
}