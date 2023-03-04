# 🌺 FlowEHR
FlowEHR is a safe, secure &amp; cloud-native development &amp; deployment platform for digital healthcare research &amp; innovation.

> **Warning**
> This repository is a _work in progress_. We're working towards a v0.1.0 release


## Getting started

This repository includes a [Dev Container](https://code.visualstudio.com/docs/devcontainers/containers) to avoid "it works on my machine" scenarios. 

Simply clone this repo:

```bash
git clone https://github.com/UCLH-Foundry/FlowEHR
```
Then open it in [VS Code](https://code.visualstudio.com) and, when prompted, click to "Open in Container" (make sure Docker is running on your host first). This will create a container with all the required packages for developing this repository.

## Configuring

Deployment requires a `config.tfvars` file in the root. Copy the `config.example.tfvars` file and save it as `config.tfvars`.

```bash
cp config.sample.tfvars config.tfvars
```

Then edit `config.tfvars` and specify the following values:

- `suffix` - a suffix to apply to all deployed resources (i.e. `flowehr-uclh`)
- `environment` - a unique name for your environment (i.e. `jgdev`)
- `location` - the [Azure region](https://azuretracks.com/2021/04/current-azure-region-names-reference/) you wish to deploy resources to

## Deploying
### Locally

1. Log in to Azure

    Run `az login` to authenticate to Azure

2. Select your subscription

    If you're deploying to a subscription that isn't your default, switch to it:

    ```bash
    az account set -s SUB_NAME_OR_ID
    ```

3. Run `make all`

    To bootstrap Terraform, and deploy all infrastructure and apps, run

    ```bash
    make all
    ```

    > For more info on configuring and deploying apps, see the [README](./apps/README.md)

    Alternatively, you can deploy just infrastructure:

    ```bash
    make infrastructure
    ```

    You can also deploy individual infrastructure modules, as well as destroy and other operations. To see all options:

    ```bash
    make help
    ```

### CI (GitHub Actions)

CI deployment workflows are run in [Github environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment). These should
be created in a private repository created from this template repository.

This step will create an AAD Application and Service Principal in the specified tenancy, and grant that service principal permissions in Azure and AAD needed for deployment. These are detailed below. 

> _NOTE_: The user following the steps below will need to be an `Owner` of the target Azure Subscription as well as a `Global Administrator` in AAD.

1. Open this repo in the dev container, and create the `config.yaml` file as outlined above.

2. Create the service principal with required AAD permissions: 

    ```bash
    make ci-auth
    ```

    _NOTE_: CI deployments require a service principal with access to deploy resources
    in the subscription, and the following permissions within the associated AAD tenancy:
    - `Application.ReadWrite.All`: Required to query the directory for the MSGraph app, and create applications used to administer the SQL Server.   
    - `AppRoleAssignment.ReadWrite.All`: Required to assign the following permissions to the System Managed Identity for SQL Server. 

    - Copy the block of JSON from the terminal for the next step.

1. Create and populate a GitHub environment

    Add an environment called `Infra-Test` with the following secrets:

    - `ARM_CLIENT_ID`: Client ID of the service pricipal created in step 2
    - `ARM_CLIENT_SECRET`: Client secret of the service pricipal created in step 2
    - `ARM_TENANT_ID`: Tennant ID containing the Azure subscription to deploy into
    - `ARM_SUBSCRIPTION_ID`: Subscription ID of the Azure subscription to deploy into
    - `SUFFIX`: Suffix used for naming resources. Must be unique to this repository e.g. `abcd`
    - `LOCATION`: Name of an Azure location e.g. `uksouth`. These can be listed with `az account list-locations -o table`
    - `ENVIRONMENT`: Name of the environment e.g. `dev`, also used to name resources
    - `DEVCONTAINER_ACR_NAME`: Name of the Azure Container Registry to use for the devcontainer build. This may or may not exist. e.g. `flowehrmgmtacr`
    - `ORG_GH_TOKEN`: GitHub [PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with scopes to clone any repositories defined in `config.transform.yaml`. This may be added as a repository rather than envrionment secret and be reused betweeen envrionments
    - `GH_RUNNER_CREATE_TOKEN` Similar to `ORG_GH_TOKEN` but with scopes: "Read access to metadata" and "Read and Write access to administration" on this repository
    - [Optional] `DATA_SOURCE_CONNECTIONS`: *single line* json containing connectivity information to data sources in the format:

    ```json
    [
    {
        "name": "xxx",
        "peering": {
            "virtual_network_name": "xxx",
            "resource_group_name": "xxx",
            "dns_zones": [
                "privatelink.xxx.xxx.azure.com"
            ]
        },
        "fqdn": "<fqdn>",
        "database_name": "<database_name>",
        "username": "username",
        "password": "password"
    }
    ]
    ```

3. Run `Deploy Infra-Test`

    Trigger a deployment using a workflow dispatch trigger on the `Actions` tab.

## Identities

This table summarises the various authentication identities involved in the deployment and operation of FlowEHR:

| Name | Type | Access Needed | Purpose |
|--|--|--|--|
| Local Developer | User context of developer running `az login` | Azure: `Owner`. <br/> AAD: Either `Global Administrator` or `Priviliged Role Administrator`. | To automate the deployment of resources and identities during development |
| `sp-flowehr-cicd-<naming-suffix>` | App / Service Principal | Azure: `Owner`. <br/>AAD: `Application.ReadWrite.All` / `AppRoleAssignment.ReadWrite.All` | Context for GitHub runner for CICD. Needs to query apps, create new apps (detailed below), and assign roles to identities |
| `flowehr-sql-owner-<naming-suffix>` | App / Service Principal | AAD Administrator of SQL Feature Data Store | Used to connect to SQL as a Service Principal, and create logins + users during deployment |
| `flowehr-databricks-datawriter-<naming-suffix>` | App / Service Principal | No access to resources or AAD. Added as a `db_owner` of the Feature Data Store database. Credentials stored in databricks secrets to be used in saving features to SQL |
| `sql-server-features-<naming-suffix>` | System Managed Identity | AAD: `User.Read.All` / `GroupMember.Read.All` / `Application.Read.All` | For SQL to accept AAD connections |

## Common issues

### Inconsistent dependency lock file

When deploying locally, you might encounter an error message from Terraform saying you have inconsistent lock files. This is likely due to an update to some of the provider configurations and lock files upstream, that when pulled down to your machine, might not match the cached providers you have locally from a previous deployment.

The easiest fix is to run `make tf-init`, which will re-initialise these caches in all of the Terraform modules to match the lock files.
