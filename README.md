> **Warning**
> This repository is a _work in progress_. We're working towards a v0.1.0 release

# 🌺 FlowEHR
FlowEHR is a safe, secure &amp; cloud-native development &amp; deployment platform for digital healthcare research &amp; innovation.


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

<!-- 
very much a work in progress here...
-->
