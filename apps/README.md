# 🌺 FlowEHR - Apps

This directory contains the code for deploying and hosting apps that present and work with the transformed FlowEHR data/features/models.

## Getting started

### Configure GitHub permissions

For FlowEHR to create and manage repositories for FlowEHR Apps, it needs a [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) to be set in your `config.yaml` in the root of the repo.

> You will need the appropriate permissions to create PATs in the scope of your organisation.

Follow the instructions [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#creating-a-fine-grained-personal-access-token) to create a fine-grained token. For `Resource owner`, select the appropriate GitHub organisation which will contain the repositories created by FlowEHR (or select yourself if desired).

Then, make sure you have enabled the following permissions:

#### Repository permissions

- `Administration`: `Read and write`
- `Environments`: `Read and write`
- `Metadata`: `Read`
- `Secrets`: `Read and write`
- `Variables`: `Read and write`

#### Organisation permissions

- `Members`: `Read and write`

When ready, click `Generate` and copy the token. Paste it into the `gh_token` field in your `config.yaml`.

### Deploy apps

1. First, to configure which apps you'd like to deploy, copy the `apps.sample.yaml` to a new `apps.yaml` file:

```bash
cp apps.sample.yaml apps.yaml
```

2. Then amend the settings as required. Ensure that each key of the apps file is unique - this will be the ID for the app used across its resources.

3. Finally, run `make apps` from the root of this repository to deploy the infrastructure for the configured app(s).
