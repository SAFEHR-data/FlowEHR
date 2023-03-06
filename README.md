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

Deployment requires a `config.yaml` file in the root. Copy the `config.example.yaml` file and save it as `config.yaml`.

```bash
cp config.sample.yaml config.yaml
```

Then edit `config.yaml` and specify the following values:

- `id` - a unique identifier to apply to all deployed resources (i.e. `flwruclh`)
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

3. Run `make infrastructure`

    To bootstrap Terraform, and deploy all infrastructure and apps, run

    ```bash
    make infrastructure
    ```

    Alternatively, you can deploy just core infrastructure:

    ```bash
    make infrastructure-core
    ```

    You can also deploy other individual infrastructure modules, as well as destroy and other operations. To see all options:

    ```bash
    make help
    ```

4. (Optional) Deploy FlowEHR apps

    You can run `make apps` to deploy any configured apps to the FlowEHR infrastructure.

    > For more info on configuring and deploying apps, see the [README](./apps/README.md)


### CI (GitHub Actions)

CI deployment workflows are run in [Github environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment). These should be created in a private repository created from this template repository.

This step will create an AAD Application and Service Principal in the specified tenancy, and grant that service principal permissions in Azure and AAD needed for deployment. These are detailed below. 

> _NOTE_: The user following the steps below will need to be an `Owner` of the target Azure Subscription as well as a `Global Administrator` in AAD (and have organization owner permissions on the GitHub orgnization you wish to use to create a token with org scopes).

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

3. Create GitHub PATs (access tokens)

    We require a GitHub [Classic PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#personal-access-tokens-classic) with scopes to clone any transform repositories defined in `config.yaml`, as well as scopes to create and manage repositories within your org for deploying FlowEHR applications, and to deploy GitHub runners for executing CI deployments.

    Follow the instructions [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#personal-access-tokens-classic) to create a classic token (fine-grained tokens don't currently support the GitHub GraphQL API which we require).

    Then, make sure you have enabled the following permissions:

    - `repo` - read/write repositories
    - `admin:org` - manage team memberships and runners
    - `delete_repo` - delete repositories

    Finally, generate it and copy it for the next step.

3. Create and populate a GitHub environment

    Add an environment called `Infra-Test` with the following secrets:

    - `ARM_CLIENT_ID`: Client ID of the service pricipal created in step 2
    - `ARM_CLIENT_SECRET`: Client secret of the service pricipal created in step 2
    - `ARM_TENANT_ID`: Tenant ID containing the Azure subscription to deploy into
    - `ARM_SUBSCRIPTION_ID`: Subscription ID of the Azure subscription to deploy into
    - `DEVCONTAINER_ACR_NAME`: Name of the Azure Container Registry to use for the devcontainer build. This may or may not exist. e.g. `flowehrmgmtacr`
    - `GITHUB_TOKEN`: The token you created in the previous step (this may be added as a repository or organisation secret rather than environment secret and be re-used betweeen environments if you prefer)

4. Run `Deploy Infra-Test`

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
