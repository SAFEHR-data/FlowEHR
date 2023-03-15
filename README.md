# 🌺 FlowEHR
FlowEHR is a safe, secure &amp; cloud-native development &amp; deployment platform for digital healthcare research &amp; innovation.

> **Warning**
> This repository is a _work in progress_. We're working towards a v0.1.0 release


## Getting started

This repository includes a [Dev Container](https://code.visualstudio.com/docs/devcontainers/containers) to avoid "it works on my machine" scenarios.

Simply create a private fork of this repo, clone it to your machine, then open it in [VS Code](https://code.visualstudio.com). When prompted, click to "Open in Container" (make sure Docker is running on your host first). This will create a container with all the required packages for developing this repository.


## Configuring

The root `config.yaml` file defines common settings across all your FlowEHR environments. These values can be overidden by an environment-specific config file with the format `config.{ENVIRONMENT_NAME}.yaml`. When an `$ENVIRONMENT` env var is present with an environment name (typically populated in CI), FlowEHR will look for a config file for that environment before getting default values from `config.yaml`.

For CI-deployed environments, you should check those environment files into source control so that your CICD pipelines can use them. Follow the [CI section](#ci) for more info.

### Locally

When working locally and with the `$ENVIRONMENT` env var unset, FlowEHR will look for a file called `config.local.yaml`. This is gitignored by default, so we can create one now for our own environment locally without worrying about accidentally checking it in:

```bash
cp config.sample.yaml config.local.yaml
```

Once you've created it, specify the following values:

- `flowehr_id` - a unique identifier to apply to all deployed resources (i.e. `myflwr`)
- `environment` - a name for your environment (set this to `local`)
- `location` - the [Azure region](https://azuretracks.com/2021/04/current-azure-region-names-reference/) you wish to deploy resources to
- `core_address_space` (optional) - override the default core address space, e.g. `10.1.0.0/24`

- `transform` (optional)
    - `spark_version` (optional) - the Spark version to install on your local cluster and Databricks clusters
    - `repositories` (optional) - list of Git repositories containing transform artifacts to clone and deploy to FlowEHR

- `serve` (optional)
    - `github_owner` - the GitHub organisation to deploy FlowEHR app repositories to
    - `github_token` (local only) - a GitHub PAT for authenticating to GitHub. See the [apps README](./apps/README.md) for details.

- `data_source_connections` (optional) - list of data source objects for configuring in data pipelines. See below for schema:

```yaml
  - data_source_key: # unique key
    name: friendly name
    peering: # Optional config for vnet peering
      virtual_network_name: name of the virtual network
      resource_group_name: resource group name containing vnet
      dns_zones:
        - list of dns zones
    fqdn: fqdn for the datasource (e.g. asqlserver.database.windows.net)
    database: database name
    username: db username
    password: db password
```

## Deploying

### Locally

1. Log in to Azure

    Run `az login` to authenticate to Azure

2. Select your subscription

    If you're deploying to a subscription that isn't your default, switch to it:

    ```bash
    az account set -s SUB_NAME_OR_ID
    ```

3. Run `make infrastructure`

    To bootstrap Terraform, and deploy all infrastructure, run

    ```bash
    make infrastructure
    ```

    Alternatively, if you just want to deploy transform infrastructure but not serve:

    ```bash
    make infrastructure-transform
    ```

    You can also deploy other individual infrastructure modules, as well as destroy and other operations. To see all options:

    ```bash
    make help
    ```

4. (Optional) Deploy FlowEHR apps

    You can run `make apps` to deploy any configured apps to the FlowEHR infrastructure.

    > For more info on configuring and deploying apps, see the [README](./apps/README.md)


### <a name="ci"></a>CI (GitHub Actions)

CI deployment workflows are run in [Github environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment). These should be created in a private repository created from this template repository.

After you've forked this template repository, you will need to check in a config file for the environment you wish to deploy.

This step will create an AAD Application and Service Principal in the specified tenancy, and grant that service principal permissions in Azure and AAD needed for deployment. These are detailed below. 

> _NOTE_: The user following the steps below will need to be an `Owner` of the target Azure Subscription as well as a `Global Administrator` in AAD (and have organization owner permissions on the GitHub orgnization you wish to use to create a token with org scopes).

1. Open this repo in the dev container, and modify the `config.yaml` file as appropriate for all the default values you wish to share across environments.

2. Then, for the environment you wish to deploy (`infra-test` in this example, but you can use whatever name you like, just update the GitHub workflow files in `.github/workflows` to use this environment name, wherever you see `infra-test`), create a config file for that environment in the format `config.{ENVIRONMENT_NAME}.yaml` (so `config.infra-test.yaml`), and populate the relevant settings. Check this into your repo.

> Note: if you want to reference secrets in these files (i.e. a data source password), you can use the syntax: `${MY_SECRET}`. In the CICD workflow, matching GitHub secrets will be searched for and, if found, will replace these tokens before running deployment steps.

3. Create the CI resources and service principal with required AAD permissions: 

    ```bash
    make ci
    ```

    _NOTE_: CI deployments require a service principal with access to deploy resources in the subscription, and the following permissions within the associated AAD tenancy:
    - `Application.ReadWrite.All`: Required to query the directory for the MSGraph app, and create applications used to administer the SQL Server.   
    - `AppRoleAssignment.ReadWrite.All`: Required to assign the following permissions to the System Managed Identity for SQL Server. 

    - Copy the outputted values to populate in step 5

4. Create GitHub PATs (access tokens)

    We require a GitHub [Classic PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#personal-access-tokens-classic) with scopes to clone any transform repositories defined in `config.infra-test.yaml`, as well as scopes to create and manage repositories within your org for deploying FlowEHR applications, and to deploy GitHub runners for executing CI deployments.

    Follow the instructions [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#personal-access-tokens-classic) to create a classic token (fine-grained tokens don't currently support the GitHub GraphQL API which we require).

    Then, make sure you have enabled the following permissions:

    - `repo` - read/write repositories
    - `admin:org` - manage team memberships and runners
    - `delete_repo` - delete repositories

    Finally, generate it and copy it for the next step.

5. Create and populate a GitHub environment

    Add an environment called `infra-test` (or whatever you called your deployment environment earlier) with the following environment variables:

    - `CI_RESOURCE_GROUP`: Resource group for shared CI resources (outputted from step 3)
    - `CI_CONTAINER_REGISTRY`: Name of the Azure Container Registry to use for the devcontainer storage (outputted from step 3)
    - `CI_STORAGE_ACCOUNT`: Storage account for shared CI state storage (outputted from step 3)

    And the following secrets:

    - `ARM_CLIENT_ID`: Client ID of the service principal (outputted from step 3)
    - `ARM_TENANT_ID`: Tenant ID containing the Azure subscription to deploy into (outputted from step 3)
    - `ARM_SUBSCRIPTION_ID`: Subscription ID of the Azure subscription to deploy into (outputted from step 3)
    - `ARM_CLIENT_SECRET`: Client secret of the service principal created in step 3
    - `ORG_GITHUB_TOKEN`: The token you created in the previous step (this may be added as a repository or organisation secret rather than environment secret and be re-used betweeen environments if you prefer)

> If you used any tokens in your config yaml files, make sure you populate the equivalent GitHub secret with an identical name so that the token replacement step will substitute your secret(s) into the configuration on deploy (e.g. if you put `${SQL_CONN_STRING}` in config.yaml, make sure you have a GitHub secret called `SQL_CONN_STRING` containing the secret value).

6. Run `Deploy Infra-Test`

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
| `sp-flowehr-app-<app_id>` | App / Service Principal | Slot swap action | Per-app identity allowed to run [slot swaps](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots) for that app |

## Common issues

### Inconsistent dependency lock file

When deploying locally, you might encounter an error message from Terraform saying you have inconsistent lock files. This is likely due to an update to some of the provider configurations and lock files upstream, that when pulled down to your machine, might not match the cached providers you have locally from a previous deployment.

The easiest fix is to run `make tf-init`, which will re-initialise these caches in all of the Terraform modules to match the lock files.
