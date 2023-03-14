[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::'Tls12';

configuration AVD_Deploy_ManagementVM
{
    Import-DscResource -ModuleName NetworkingDsc
    Import-DSCResource -ModuleName xSystemSecurity
	Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName xDnsServer
    Import-DscResource -ModuleName cUserRightsAssignment
    Import-DscResource -ModuleName cNtfsAccessControl
    Import-DscResource -ModuleName xSmbShare
    Import-DscResource -ModuleName cChoco
    Import-DscResource -ModuleName xRemoteDesktopSessionHost
    Import-DscResource -ModuleName xCertificate
	Import-DscResource -ModuleName xRemoteDesktopAdmin
	Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.Where{$_.Role -contains "common"}.Nodename 
    {
        Script UpdatePackManagement {
            GetScript  = { Return @{Return = $null } }
            TestScript = { [bool](Get-Module -Name PackageManagement -ListAvailable | ?{$_.Version -eq '1.4.8.1'}) }
            SetScript  = { Install-Module PackageManagement -RequiredVersion 1.4.8.1  -Repository 'PSGallery' -Scope AllUsers -Force -AllowClobber -Confirm:$False }
            DependsOn  = @()
        }

        Script UpdatePowerShellGet {
            GetScript  = { Return @{Return = $null } }
            TestScript = { [bool](Get-Module -Name PowerShellGet -ListAvailable | ?{$_.Version -eq '2.2.5'}) }
            SetScript  = { Install-Module PowerShellGet -RequiredVersion 2.2.5  -Repository 'PSGallery' -Scope AllUsers -Force -AllowClobber -Confirm:$False }
            DependsOn  = @('[Script]UpdatePackManagement')
        }

        PowerShellExecutionPolicy ExecutionPolicy
        {
            ExecutionPolicyScope = 'LocalMachine'
            ExecutionPolicy      = 'RemoteSigned'
        }

        TimeZone TimeZone
        {
            IsSingleInstance     = 'Yes'
            TimeZone             = 
        }


        Script installModuleAzAccounts {
            GetScript  = { Return @{Return = $null } }
            TestScript = { [bool](Get-Module -name 'Az.Accounts' -ListAvailable) }
            SetScript  = {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::'Tls12';
                Install-Module -name 'Az.Accounts' -Repository 'PSGallery' -Scope AllUsers -Force -AllowClobber -Confirm:$False
            }
        }

        Script installModuleAzKeyVault {
            GetScript  = { Return @{Return = $null } }
            TestScript = { [bool](Get-Module -name 'Az.KeyVault' -ListAvailable) }
            SetScript  = {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::'Tls12';
                Install-Module -name 'Az.KeyVault' -Repository 'PSGallery' -Scope AllUsers -Force -AllowClobber -Confirm:$False
            }
            DependsOn  = @('[Script]installModuleAzAccounts')
        }

        Script installModuleAzResources {
            GetScript  = { Return @{Return = $null } }
            TestScript = { [bool](Get-Module -name 'Az.Resources' -ListAvailable) }
            SetScript  = {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::'Tls12';
                Install-Module -name 'Az.Resources' -Repository 'PSGallery' -Scope AllUsers -Force -AllowClobber -Confirm:$False
            }
            DependsOn  = @('[Script]installModuleAzAccounts')
        }

        Script installModuleAzAutomation {
            GetScript  = { Return @{Return = $null } }
            TestScript = { [bool](Get-Module -name 'Az.Automation' -ListAvailable) }
            SetScript  = {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::'Tls12';
                Install-Module -name 'Az.Automation' -Repository 'PSGallery' -Scope AllUsers -Force -AllowClobber -Confirm:$False
            }
            DependsOn  = @('[Script]installModuleAzAccounts')
        }

        Script installModuleAzCompute {
            GetScript  = { Return @{Return = $null } }
            TestScript = { [bool](Get-Module -name 'Az.Compute' -ListAvailable) }
            SetScript  = {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::'Tls12';
                Install-Module -name 'Az.Compute' -Repository 'PSGallery' -Scope AllUsers -Force -AllowClobber -Confirm:$False
            }
            DependsOn  = @('[Script]installModuleAzAccounts')
        }

        xRemoteDesktopAdmin EnableRDP
        {
			UserAuthentication    = 'NonSecure'
			Ensure                = 'Present'
        } 

        User LocalAdmin
        {
            UserName             = $avdLocalAdmin.UserName
            Description          = 'local administrator'
            Disabled             = $false
            Ensure               = 'Present'
            FullName             = $avdLocalAdmin.UserName
            Password             = $avdLocalAdmin
            PasswordChangeRequired = $false
            PasswordNeverExpires = $true
        }

        cChocoInstaller ChocoInstall
        {
            InstallDir           = 'C:\ProgramData\chocolatey'
        }

		File SystemProfileTemp
        {
            DestinationPath      = 'C:\windows\system32\config\systemprofile\AppData\Local\Temp'
            Ensure               = 'Present'
            Force                = $true
            Type                 = 'Directory'
        }

        WindowsFeatureSet FeatureSet
        {
            Name                 = @(
                                        "NET-Framework-45-Features",
                                        "NET-Framework-45-Core",
                                        "NET-Framework-45-ASPNET",
                                        "NET-WCF-Services45",
                                        "GPMC",
                                        "RSAT-AD-Tools",
                                        "RSAT-AD-PowerShell",
                                        "RSAT-ADDS",
                                        "RSAT-AD-AdminCenter",
                                        "RSAT-ADDS-Tools",
                                        "RSAT-DNS-Server",
                                        "Windows-Defender",
                                        "PowerShellRoot",
                                        "PowerShell",
                                        "PowerShell-ISE"
                                    )
            Ensure               = 'Present'
            DependsOn            = @()
        }

        WindowsFeatureSet FeatureSet2
        {
            Name                 = @(
                                        "NET-Framework-Features",
                                        "NET-Framework-Core",
                                        "PowerShell-V2"
                                    )
            Ensure               = 'Present'
            DependsOn            = @('[WindowsFeatureSet]FeatureSet')
        }
    }

    Node $AllNodes.Where{$_.Role -contains "joinDomain"}.Nodename 
    {


    }

	Node $AllNodes.Where{$_.Role -contains "commonpostdomain"}.Nodename 
    {
        WaitForADDomain WaitForPrimaryDCcommonPost
        {
			DomainName           = $DomainName
			RestartCount         = 6
			WaitTimeout          = 300
            DependsOn            = @()
        }

        Script NetConnectionProfile
        {
            GetScript            = {Return @{Return = $null}}
            TestScript           = {[bool](!(Get-NetConnectionProfile | ?{$_.NetworkCategory -ne 'DomainAuthenticated'}))}
            SetScript            = {Restart-Service NlaSvc -Force}
            DependsOn            = @('[WaitForADDomain]WaitForPrimaryDCcommonPost')
        }
    }
}