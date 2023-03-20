# Center for Internet Security (CIS) Adherence

This document outlines the adherence of the FlowEHR components to the Microsoft Azure Foundations Benchmark v2.0 - downloadable from the CIS website [here](https://downloads.cisecurity.org/).


## Note on Maintenance of this Document

This document exists in this repo, and not elsewhere, in order to keep it closer to the resource definitions that it references, and easier to update as resources are added or changed. It is suggested that when a resource is added, this document is updated to reference the new resource and ensure that appropriate security settings have been applied to it.


## Identity Management (`CIS 1.1` | `CIS 1.2`)

FlowEHR utilises Azure Active Directory for all user management. Further, all user accounts are stored and managed in source AAD tenancies, such as UCLH and NHS.net. These accounts will be guested in to the FlowEHR development and production tenancies as needed. All conditional access, password management, risky login and MFA policies are owned and managed by the host organisation(s), and not by FlowEHR.

In rare and exceptional cases (such as limited access test accounts), user accounts may be created directly within the FlowEHR tenancies - but these will be carefully managed and are outside the scope of this document.

The default mode of authentication between Azure resources within FlowEHR is Azure Active Directory - either by Managed System Identity (MSI), or Service Principal (SPN). These settings are detailed below. For details on which automation accounts are used, along with their privileges, please see the primary [README](./README.md) document.


## FlowEHR Deployment

FlowEHR is composed of a number of deployment 'layers': `Core`, `Transform` and `Serve`.

All Azure services are deployed either into a private Virtual Network (VNET) owned by FlowEHR, or have internet access disabled with communication made possible via Private Endpoints (PE) into the FlowEHR VNET. This ensures that no data is accessible over the public internet, even if the user has valid credentials.


### FlowEHR 'bootstrap'

FlowEHR is deployed using Terraform. Terraform maintains a text based state file in Azure Storage, which contains a number of keys and secrets, and should be treated as such. 

| Azure Resource | CIS Reference | Adherence | Notes |
|--|--|--|--|
| Azure Storage Account for FlowEHR management: <br/>`stgmgmt<suffix>` | `CIS 3` | [main.tf](./bootstrap/shared/management/main.tf) | Issues summarised https://github.com/UCLH-Foundry/FlowEHR/issues/176 |
| | `CIS 3.1`: Ensure 'Secure Transfer Required' set to 'Enabled' | Y | |
| | `CIS 3.2`: Ensure 'Enable Infrastructure Encryption' set to 'Enabled' | TODO |  |
| | `CIS 3.3`: Enable key rotation reminders for each storage account | N | Storage keys are not used for authentication |
| | `CIS 3.4`: Ensure that Storage Account Access keys are periodically regenerated | N | Storage keys are not used for authentication |
| | `CIS 3.7`: Ensure 'Public Access Level' is disabled | Discuss | |
| | `CIS 3.8`: Ensure Default Network Access Rule is set to 'Deny' | Discuss |  |
| | `CIS 3.9`: Ensure 'Trusted Azure Services' can access the storage account | Discuss |  |
| | `CIS 3.10`: Ensure Private Endpoints are used to access storage accounts | Discuss |  |
| | `CIS 3.11`: Ensure Soft Delete is enabled | TODO |  |
| | `CIS 3.12`: Ensure storage is encrypted with Customer Managed Keys | N | Will use Microsoft Managed Keys to reduce management overhead |
| | `CIS: 3.13`: Ensure Storage Logging is enabled for 'read', 'write' and 'delete' requests | TODO | | 
| | `CIS 3.15`: Ensure Minimum TLS Version is set to 1.2 | Y | |


### FlowEHR Core & Azure Subscription

This layer deploys the core components required for other layers, including a number of shared components.

| Azure Resource | CIS Reference | Adherence | Notes |
|--|--|--|--|
| Core Virtual Network: <br/>`vnet-<suffix>` | `CIS 6` | [network.tf](./infrastructure/core/network.tf) | Allows other resources to remain non-internet-accessible |
| | `CIS 5.1.6`: Ensure NSG Flow Logs are captured and sent to Log Analytics | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/187 |
| | `CIS 6.6`: Ensure 'Network Watcher' is enabled for all networks | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/187 |
| Azure Storage Account for FlowEHR management: <br/>`strg<suffix>` | `CIS 3` | [main.tf](./infrastructure/core/main.tf) | Issues summarised https://github.com/UCLH-Foundry/FlowEHR/issues/176 |
| | `CIS 3.1`: Ensure 'Secure Transfer Required' set to 'Enabled' | Y | |
| | `CIS 3.2`: Ensure 'Enable Infrastructure Encryption' set to 'Enabled' | TODO |  |
| | `CIS 3.3`: Enable key rotation reminders for each storage account | N | Storage keys are not used for authentication |
| | `CIS 3.4`: Ensure that Storage Account Access keys are periodically regenerated | N | Storage keys are not used for authentication |
| | `CIS 3.7`: Ensure 'Public Access Level' is disabled | TODO | |
| | `CIS 3.8`: Ensure Default Network Access Rule is set to 'Deny' | Y | |
| | `CIS 3.9`: Ensure 'Trusted Azure Services' can access the storage account | Y | |
| | `CIS 3.10`: Ensure Private Endpoints are used to access storage accounts | n/a | Using VNET integration |
| | `CIS 3.11`: Ensure Soft Delete is enabled | TODO | |
| | `CIS 3.12`: Ensure storage is encrypted with Customer Managed Keys | N | Will use Microsoft Managed Keys to reduce management overhead |
| | `CIS: 3.13`: Ensure Storage Logging is enabled for 'read', 'write' and 'delete' requests | TODO | | 
| | `CIS 3.15`: Ensure Minimum TLS Version is set to 1.2 | Y | |
| Azure Key Vault: <br/>`kv-<suffix>` | `CIS 8` | [main.tf](./infrastructure/core/main.tf)  | |
| | `CIS 8.5`: Ensure the key vault is recoverable | Y  | - Soft delete enabled (7 days) <br/> - Purge protection enabled | 
| | `CIS 8.6`: Ensure RBAC enabled for Azure Key Vault | Y | | 
| | `CIS 8.7`: Ensure Private Endpoints are used for Azure Key Vault | Y | Public internet access disabled, PE into VNET |
| | `CIS 10.1`: Ensure that resource locks are set for critical resources | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/124 |
| Microsoft Defender for Cloud | `CIS 2.1` | N | TODO: Enable MS Defender for Cloud https://github.com/UCLH-Foundry/FlowEHR/issues/174 | 
| | `CIS 2.1.2`: Ensure Microsoft Defender for App Services is set to 'On' | TODO | |
| | `CIS 2.1.4`: Ensure Microsoft Defender for Azure SQL Databases is set to 'On' | TODO | |
| | `CIS 2.1.5`: Ensure Microsoft Defender for Azure SQL Servers is set to 'On' | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/173 |
| | `CIS 2.1.7`: Ensure Microsoft Defender for Storage is set to 'On' | TODO | |
| | `CIS 2.1.8`: Ensure Microsoft Defender for Containers is set to 'On' | TODO | |
| | `CIS 2.1.9`: Ensure Microsoft Defender for Azure Cosmos DB is set to 'On' | TODO | |
| | `CIS 2.1.10`: Ensure Microsoft Defender for Key Vault is set to 'On' | TODO | |
| Azure Log Analytics: <br/>`log-<suffix>` | `CIS 5` | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/187 |
| | `CIS 5.1.1`: Ensure Diagnostic setting exists (per resource) | TODO | |
| | `CIS 5.1.2`: Ensure Diagnostic setting captures appropriate categories | TODO | |
| | `CIS 5.1.4`: Ensure Diagnostic log storage container is encrypted with Customer Managed Key | N | System managed keys chosen to reduce management burden |
| | `CIS 5.2`: Activity Log Alerts | TODO | Discuss: https://github.com/UCLH-Foundry/FlowEHR/issues/188 |


### FlowEHR Data Transformation

This layer deploys components required to ingest data, transform data, and save data.

| Azure Resource | CIS Reference | Adherence | Notes |
|--|--|--|--|
| Azure SQL Server:<br/> `sql-server-features-suffix` | [feature-data-store.tf](./infrastructure/core/feature-data-store.tf) | |
| | `CIS 4.1.1`: Ensure auditing is set to 'on' | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/172 |
| | `CIS 4.1.2`: Ensure no SQL databases allow ingress from 0.0.0.0/0 (any IP) | Y | All public access disabled |
| | `CIS 4.1.3`: Ensure SQL uses Transparent Data Encryption with customer managed key | N | Decision was made to use Service Managed Key to decrease management overhead |
| | `CIS 4.1.4`: Ensure AAD admin is configured | Y | Owner is an auto-created Service Principal account, with credentials saved in key vault | 
| | `CIS 4.1.5`: Ensure 'Data encryption' is set to 'on' | Y | Service Managed Key |
| | `CIS 4.1.6`: Ensure that 'Auditing Retention' is set to 'Greater than 90 days' | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/172 |
| | `CIS 4.2.1`: Ensure Microsoft Defender for SQL is set to 'on' | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/173 |
| | `CIS 4.2.2 -> CIS 4.2.5`: Ensure Vulnerability Assessment is enabled by setting a storage account | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/173 | 
| Azure Key Vault Secrets | | [secrets.tf](./infrastructure/transform/secrets.tf) |
| | `CIS 8.3`: Ensure expiration is set for all secrets in RBAC vaults | Discuss | No automated secret rotation in place as of yet. To discuss. | 


### FlowEHR App / Model Serving

| Azure Resource | CIS Reference | Adherence | Notes |
|--|--|--|--|
| Azure App Service: <br/>`asp-serve-<suffix>` | `CIS 9` | | [app_service.tf](./infrastructure/serve/app_service.tf) / [platform.tf](./apps/app/platform.tf) |
| | `CIS 9.1`: Ensure App Service Authentication is set up | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/175 |
| | `CIS 9.2`: Ensure all HTTP traffic is redirected to HTTPS | Y | | 
| | `CIS 9.3`: Ensure web apps are using latest version of TLS | Y | |
| | `CIS 9.4`: Ensure web apps have 'Incoming Client Certificates' set to 'On' | N | Choice made not to use client cert auth due to a number of overheads |
| | `CIS 6.4`: Ensure HTTPS access from the internet is evaluated and restricted | TODO | https://github.com/UCLH-Foundry/FlowEHR/issues/109 |
| | `CIS 9.5`: Ensure that 'Registed with AAD' is 'On' | Y | MSI used for container registry |
| | `CIS 9.10`: Ensure that FTP is disabled | Y | |
| | `CIS 9.11`: Ensure Key Vaults are used to store secrets | Y | |
| Azure Cosmos DB: <br/>`cosmos-serve-<suffix>` | `CIS 4.5` | | [cosmos.tf](./infrastructure/serve/cosmos.tf) |
| | `CIS 4.5.1`: Ensure 'Firewalls & Networks' is limited | Y | |
| | `CIS 4.5.2`: Ensure Private Endpoints are used where possible | Y | |
| | `CIS 4.5.3`: Ensure AAD Client Auth & RBAC are used where possible | Y | |
| App Insights: <br/>`ai-<suffix>` | | | |
| | `CIS 5.3.1`: Ensure App Insights are configured | Y | |
