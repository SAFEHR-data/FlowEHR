# 🌺 FlowEHR
FlowEHR is a safe, secure &amp; cloud-native development &amp; deployment platform for digital healthcare research &amp; innovation.

> **Warning**
> This repository is a _work in progress_. We're working towards a v0.1.0 release


## Deployment

### Local

0. <details>
    <summary>Open this repository in a devcontainer</summary>

    Clone the repo with
    ```bash
    git clone https://github.com/UCLH-Foundry/FlowEHR
    ```

    and open it inside [Visual Studio Code](https://code.visualstudio.com/)
    [devcontainer](https://code.visualstudio.com/docs/devcontainers/tutorial)
    for a consistent developer environment.

</details>

1. <details>
    <summary>Login to azure</summary>

    Use the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) to login to an Azure
    subscription

    ```bash
    az login
    ```
</details>


2. <details>
    <summary>Copy and edit the sample configuration file</summary>

    Local deployment i.e. non CI/CD requires a `config.yaml` file. Copy and edit as appropriate.
    For example, adding a naming prefix

    ```bash
    cp config.sample.yaml config.yaml
    ```
</details>


3. <details>
    <summary>Run a `make` command</summary>

    For example, to make the core infrastructure

    ```bash
    make core
    ```

    to see all options

    ```bash
    make help
    ```
</details>


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
