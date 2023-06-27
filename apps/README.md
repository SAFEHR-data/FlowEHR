# 🌺 FlowEHR - Apps

This directory contains the code for deploying and hosting apps that present and work with the transformed FlowEHR data/features/models.

## Getting started

### Configure a GitHub App

For FlowEHR to create and manage repositories for FlowEHR Apps, it requires a [GitHub App](https://docs.github.com/en/apps/creating-github-apps/creating-github-apps/about-apps).

We recommend creating a new GitHub Organization for containing all of the FlowEHR App repositories that will be created and managed by your FlowEHR instance, just so you're not providing unnecessary management access to any other repositories you might have in your main Organization.

#### Create GH app

Once you've done (or not done) that, follow [these instructions](https://docs.github.com/en/apps/creating-github-apps/creating-github-apps/creating-a-github-app) to create a new GitHub App within the organization you wish to host your new FlowEHR apps, with the following properties (leave everything else blank/default):

- `Name`: `{YOUR_ORG}-FlowEHR` or something similar (needs to be globally unique)
- `Homepage URL`: `https://flowehr.io`
- `Webhook`: uncheck the Active checkbox
- `Permissions`
    - `Repository Permissions`
        - `Actions`: `Read-only`
        - `Administration`: `Read and write`
        - `Contents`: `Read and write`
        - `Environments`: `Read and write`
        - `Metadata`: `Read-only`
        - `Secrets`: `Read and write`
        - `Variables`: `Read and write`
        - `Workflows`: `Read and write`
    - `Organization Permissions`
        - `Administration`: `Read and write`
        - `Members`: `Read and write`
- `Where can this GitHub App be installed?`: `Only on this account`

When happy, click `Create GitHub App`. After creation, in your app's settings page, note down the `App Id`.

#### Generate Private Key

In the app settings page, scroll down to near the bottom and find the `Private Keys` section. Click `Generate a private key`. This will download a PEM cert file to your machine. We'll need this later.

#### Install GH app

Once created, you need to the install the app to the organization. [Follow these instructions](https://docs.github.com/en/apps/maintaining-github-apps/installing-github-apps), selecting your organization and choosing `All repositories`.

After installation, stay on the same page and check the URL. It should look like this:

```
https://github.com/organizations/UCLH-Foundry/settings/installations/123456789
```

At the end of the URL after `installations/`, you'll see a number. Record this down - it is your `GitHub App Installation Id`. (Believe it or not this is the easiest way to find it!)

#### Update config

Depending on whether you're configuring this for a local dev deployment, or for CI (or both if you'd like local developers and your testing environments to share a single Organization for test apps) - update the relevant `config.yaml` or `config.{ENVIRONMENT}.yaml` with the GitHub app details in the `serve` block:

```yaml
serve:
    github_owner: name of the GitHub Organisation you created/wish to use for deploying apps into
    github_app_id: your GitHub App's "App Id" from earlier
    github_app_installation_id: your GitHub App's "Installation Id" from earlier
```

#### Store the cert

##### Local development

For developing locally, simply find the PEM file you downloaded earlier, rename it to `github.pem` and drag it into this repo under the `/apps` directory. It will be picked up by Terraform during deployment, and is gitignored so won't be checked in accidentally.

> For other developers who want to use this same app instead of setting up their own, direct them to create and download their own private key from the GitHub App's settings page as you did in a previous step.

##### CI

For use in CI, copy the contents of the PEM file, and paste it into a new GitHub secret called `GH_APP_CERT`. The CICD pipeline will read this into a file to use during deployments.

### Configure FlowEHR apps

Similar to the behaviour of the root FlowEHR config, if the `$ENVIRONMENT` env var is set (typically by CI), FlowEHR will look for the apps configured in a file in the `/apps` directory called `apps.{ENVIRONMENT}.yaml`. If unset, it will look for `apps.local.yaml`.

These config files consist of a map of `app_id` and the config values for that app. It will also look for a matching `app_id` in the `apps.yaml` shared config file, and will merge properties of the two, with environment-specific properties taking precedence. This means you can define common values of an app (like the `owners` and `contributors`) that are common across environments, and only override relevant settings per environment (i.e. `num_of_approvers`).

> Note: FlowEHR will only deploy apps defined in the environment file matching the currently selected environment. If a file doesn't exist for your current environment (i.e. if you're working locally and don't have an `apps.local.yaml`) or is empty, even if there are apps configured in the shared `apps.yaml`, FlowEHR will treat this as there being no apps to deploy. This ensures no apps are deployed accidentally to environment they shouldn't be without it being explicitly set for that environment.

For local deployments, create your config as follows:

1. In this directory (`/apps`), copy the `apps.sample.yaml` to a new `apps.local.yaml` file:

```bash
cp apps.sample.yaml apps.local.yaml
```

2. Then amend the settings as required. Ensure that each key of the apps file is unique - this will be the ID for the app used across its resources.

For CI deployments, it's the same process, just make sure the `apps.{ENVIRONMENT}.yaml` matches the environment name you're deploying.

### Deploy apps

After you've configured your apps, run `make apps` from the root of this repository to deploy the Azure infrastructure and GitHub artifacts for the configured app(s). Then, you can find your newly-created repositories in the GitHub organization you specified.
