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

Local deployment (i.e. non CI/CD) requires a `config.yaml` file in the root. Copy the `config.sample.yaml` file and save it as `config.yaml`.

```bash
cp config.sample.yaml config.yaml
```

Then edit `config.yaml` and specify the following values:

- `prefix` - a prefix to apply to all deployed resources (i.e. `flowehr-uclh`)
- `environment` - a unique name for your environment (i.e. `jgdev`)
- `location` - the [Azure region](https://azuretracks.com/2021/04/current-azure-region-names-reference/) you wish to deploy resources to
- `arm_subscription_id` - the [Azure subscription id](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id) you wish to deploy to

For the full reference of possible configuration values, see the [config schema file](./config_schema.json).

## Deploying
### Locally

1. Log in to Azure

    Run `az login` to authenticate to Azure

    ```bash
    az login
    ```

2. Run `make all`

    To bootstrap Terraform, and deploy all infrastructure, run

    ```bash
    make all
    ```

    Alternatively, you can deploy individual modules separately with their corresponding make command:

    ```bash
    make deploy-core
    ```

    To see all options:

    ```bash
    make help
    ```

### CI (GitHub Actions)

CI deployment workflows are run in [Github environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment). These should
be created in a private repository created from this template repository.

0. <details>
    <summary>Create a service principal</summary>

    CI deployments require a service principal with access to deploy resources
    in the subscription. Follow the steps above and then run

    ```bash
    make auth
    ```

    The output will be used in the next step.

</details>


1. <details>
    <summary>Create and populate a GitHub environment</summary>

    Add an envrionment called `Infra-Test` with following secrets

    - `AZURE_CREDENTIALS`: json containing the credentials of the service principal in the format

    ```json
    {
    "clientId": "xxx",
    "clientSecret": "xxx",
    "tenantId": "xxx",
    "subscriptionId": "xxx",
    "resourceManagerEndpointUrl": "management.azure.com"
    }
    ```

    - `PREFIX`: Prefix used for naming resources. Must be unique to this repository e.g. `abcd`
    - `LOCATION`: Name of an Azure location e.g. `uksouth`. These can be listed with `az account list-locations -o table`
    - `ENVIRONMENT`: Name of the envrionment e.g. `dev`, also used to name resources
    - `DEVCONTAINER_ACR_NAME`: Name of the azure container registry to use for the devcontainer build. This may or may not exist. e.g. `flowehrmgmtacr`

</details>


2. <details>
    <summary>Run `Deploy infra test`</summary>

    Trigger a deployment using a workflow dispatch trigger on the `Actions` tab.
</details>
