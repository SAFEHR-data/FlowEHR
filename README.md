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

- `prefix` - a prefix (max length 4 chars) to apply to all deployed resources (i.e. `flwr`)
- `environment` - a unique name for your environment (i.e. `jgdev`)
- `location` - the [Azure region](https://azuretracks.com/2021/04/current-azure-region-names-reference/) you wish to deploy resources to
- `arm_subscription_id` - the [Azure subscription id](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id) you wish to deploy to

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

    > Note: If you're deploying for the first time and not using `make all` (i.e. using `make deploy-core`), ensure you have ran `make bootstrap` first.

### CI (GitHub Actions)

CI deployment workflows are run in [Github environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment). These should
be created in a private repository created from this template repository.

<!-- 
very much a work in progress here...
-->
