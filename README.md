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
- `private_dns_zones_rg` (optional) - if you have the required private dns zones (see [infrastructure/core/locals.tf](infrastructure/core/locals.tf)) already deployed in a network that will be peered to FlowEHR, provide the resource group name and FlowEHR will use those instead of creating its own (which would cause namespace conflicts)

- `transform` (optional)
    - `spark_version` (optional) - the Spark version to install on your local cluster and Databricks clusters
    - `repositories` (optional) - list of Git repositories containing transform artifacts to clone and deploy to FlowEHR

- `serve` (optional)
    - `github_owner` - the GitHub organisation to deploy FlowEHR app repositories to
    - `github_app_id` - a [GitHub App](https://docs.github.com/en/apps/creating-github-apps/creating-github-apps/about-apps) id used for authenticating app artifact creation in GitHub. See [the apps set-up guide](./apps/README.md) for details.
    - `github_app_installation_id` - a GitHub App installation id for the installation of the above GH app. See [the apps set-up guide](./apps/README.md) for details.

- `data_source_connections` (optional) - list of data source objects for configuring in data pipelines. See below for schema:

```yaml
  - data_source_key: # unique key
    name: friendly name
    peering: # Optional config for vnet peering
      virtual_network_name: name of the virtual network
      resource_group_name: resource group name containing vnet
      dns_zones:
        - list of dns zones created in the data source to link to (if private_dns_zones_rg is defined, FlowEHR will look for these in that rg)
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

3. Run `make all`

    To deploy all infrastructure, and any configured pipelines and apps, run:

    ```bash
    make all
    ```

    > For more info on configuring and deploying apps, see the [README](./apps/README.md)

    Alternatively, if you just want to deploy the infrastructure:

    ```bash
    make infrastructure
    ```

    You can also deploy individual infrastructure modules, apps, as well as destroy and other operations. To see all options:

    ```bash
    make help
    ```


### <a name="ci"></a>CI (GitHub Actions)

CI deployment workflows are run in [Github environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment). These should be created in a private repository created from this template repository.

After you've forked this template repository, you will need to check in a config file for the environment you wish to deploy.

This step will create an AAD Application and Service Principal in the specified tenancy, and grant that service principal permissions in Azure and AAD needed for deployment. These are detailed below. 

> _NOTE_: The user following the steps below will need to be an `Owner` of the target Azure Subscription as well as a `Global Administrator` in AAD (and have organization owner permissions on the GitHub orgnization you wish to use to create a token with org scopes).

1. Open this repo in the dev container, and modify the `config.yaml` file as appropriate for all the default values you wish to share across environments.

2. Then, for the environment you wish to deploy (`infra-test` in this example, but you can use whatever name you like, just update the GitHub workflow files in `.github/workflows` to use this environment name, wherever you see `infra-test`), create a config file for that environment in the format `config.{ENVIRONMENT_NAME}.yaml` (so `config.infra-test.yaml`), and populate the relevant settings. Check this into your repo.

> Note: if you want to reference secrets in these files (i.e. a data source password), you can use the syntax: `${MY_SECRET}`. In the CICD workflow, matching GitHub secrets will be searched for and, if found, will replace these tokens before running deployment steps.

3. Create a GitHub PAT (access token)

    We require a GitHub [PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#fine-grained-personal-access-tokens) with scopes to clone any transform repositories defined in `config.infra-test.yaml` (or `config.yaml` if you haven't defined env-specific repositories).

    Follow the instructions [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#fine-grained-personal-access-tokens) to create a token, set a sensible expiration time (you'll need to manually repeat these steps to create a new one after expiry) and set the `Resource Owner` as the organisation containing your FlowEHR fork and any transform pipeline repositories.

    Then provide it repository access to either `All Repositories` (within that org), or `Selected Repositories` and ensure you select the FlowEHR fork as well as any transform repos that will be cloned during deployments.

    Finally, give it the following scopes:

    `Repository Permissions`
    - `Contents`: `Read-only` - required to clone transformation pipeline repos for deployment
    - `Pull Requests`: `Read and write` - required for the PR Bot to work in private forks

    Once done, generate it and copy it for the next step.

    > Note: if you're not an owner of the Organization you defined as Resource Owner for the token, your token won't be active until approved by an owner.

4. Deploy a bootstrap environment

    For CI deployments, due to certain resources being deployed within a Virtual Network with public access disabled, we need to use private build agents (also called self-hosted GitHub runners) to run our CI pipelines. We also need somewhere to store the associated container images and Terraform state within a vnet.

    You can use [the Azure Bootstrap template](https://github.com/UCLH-Foundry/Azure-Bootstrap) to deploy all these resources, or alternatively, you can reference pre-existing resources in the following steps.

5. Create a deployer identity (AAD App Registration/Service Principal) with required AAD permissions: 

    ```bash
    make auth
    ```

    > _NOTE_: CI deployments require a service principal with access to deploy resources in the subscription. See `sp-flowehr-ci-<naming-suffix>` in the [identities section](#identities) for the roles that are assigned to this.

    You will be prompted to enter the `ci_resource_group` and `ci_storage_account` values outputted from the previous step. Once ran, copy the outputted credentials to populate in the next step.

6. Create and populate a GitHub environment

    Add an environment called `infra-test` (or whatever you called your deployment environment earlier) with the following environment variables, using the values outputted from the previous step:

    - `CI_RESOURCE_GROUP`: Resource group for shared CI resources
    - `CI_CONTAINER_REGISTRY`: Name of the Azure Container Registry to use for the devcontainer storage
    - `CI_STORAGE_ACCOUNT`: Storage account for shared CI state storage
    - `CI_PEERING_VNET`: Virtual network for your CI environment which FlowEHR will peer to

    And the following secrets:

    - `ARM_CLIENT_ID`: Client ID of the service principal (outputted from step 3)
    - `ARM_TENANT_ID`: Tenant ID containing the Azure subscription to deploy into (outputted from step 3)
    - `ARM_SUBSCRIPTION_ID`: Subscription ID of the Azure subscription to deploy into (outputted from step 3)
    - `ARM_CLIENT_SECRET`: Client secret of the service principal created in step 3

    > If you used any tokens in your config yaml files, make sure you populate the equivalent GitHub secret with an identical name so that the token replacement step will substitute your secret(s) into the configuration on deploy (e.g. if you put `${SQL_CONN_STRING}` in config.yaml, make sure you have a GitHub secret called `SQL_CONN_STRING` containing the secret value).

    Finally, add a repository-scoped variable for the following (or organization-scoped if you wish to use across multiple repos):

    - `CI_GITHUB_RUNNER_LABEL`: the name of the GitHub runner label outputted from step 4 (bootstrap deployment)

    And secret:

     - `FLOWEHR_REPOSITORIES_GH_TOKEN`: the GitHub PAT token you created in step 3

7. Run `Deploy Infra-Test`

    Trigger a deployment using a workflow dispatch trigger on the `Actions` tab.

### Next steps

- [Deploy a data transformation pipeline](https://github.com/UCLH-Foundry/FlowEHR-Data-Pot/blob/main/README.md)
- [Configure and deploy a FlowEHR app](./apps/README.md)


## <a name="identities"></a> Identities

This table summarises the various authentication identities involved in the deployment and operation of FlowEHR:

| Name | Type | Access Needed | Purpose |
|--|--|--|--|
| Local Developer | User context of developer running `az login` | Azure: `Owner`. <br/> AAD: Either `Global Administrator` or `Priviliged Role Administrator`. | To automate the deployment of resources and identities during development |
| `sp-flowehr-ci-<naming-suffix>` | App / Service Principal | Azure: `Owner`. <br/>AAD: `Application.ReadWrite.All` / `AppRoleAssignment.ReadWrite.All` / `Group.ReadWrite.All` / `Directory.Read` | Context for GitHub runner for CICD. Needs to query apps, create new apps (detailed below), create AD groups and view and assign roles to identities |
| `flowehr-sql-owner-<naming-suffix>` | App / Service Principal | AAD Administrator of SQL Feature Data Store | Used to connect to SQL as a Service Principal, and create logins + users during deployment |
| `flowehr-databricks-datawriter-<naming-suffix>` | App / Service Principal | No access to resources or AAD. Added as a `db_owner` of the Feature Data Store database. Credentials stored in databricks secrets to be used in saving features to SQL |
| `sql-server-features-<naming-suffix>` | System Managed Identity | AAD: `User.Read.All` / `GroupMember.Read.All` / `Application.Read.All` | For SQL to accept AAD connections |
| `sp-flowehr-app-<app_id>` | App / Service Principal | Slot swap action | Per-app identity allowed to run [slot swaps](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots) for that app |

## Common issues

### Inconsistent dependency lock file / backend state has changed

When deploying locally, you might encounter an error message from Terraform saying you have inconsistent lock files, or that your backend state has changed. This is likely due to an update to some of the provider configurations, lock files or folder structure upstream, that when pulled down to your machine, might not match the cached providers and state you have locally from a previous deployment.

The easiest fix is to run `make tf-reinit`, which will re-initialise these caches in all of the Terraform modules to match the lock files. It also passes the `-migrate-state` flag, which if you have mismatched state, you can accept the prompts to try and automatically migrate it. If you don't already have an environment deployed, you can instead do a `make clean` to clean up any old local state so you deploy a fresh environment.
