# 🌺 FlowEHR - Apps

This directory contains the code for deploying and hosting apps that present and work with the transformed FlowEHR data/features/models.

## Getting started

### Local deployment

#### Configure GitHub permissions

For FlowEHR to create and manage repositories for FlowEHR Apps, it needs a [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) to be set in your `config.yaml` in the root of the repo.

> You will need the appropriate permissions to create PATs in the scope of your organisation.

Follow the instructions [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token#personal-access-tokens-classic) to create a classic token (fine-grained tokens don't currently support the GitHub GraphQL API which we require).

Then, make sure you have enabled the following permissions:

- `repo`
- `write:org`
- `delete_repo`
- `workflow`

When ready, click `Generate` and copy the token. Paste it into the `github_token` field in your `config.local.yaml`.

> This is only for local deployment. In CI, the token will be added as an environment secret and should never be checked into your repo.

#### Deploy apps

1. First, to configure which apps you'd like to deploy, copy the `apps.sample.yaml` to a new `apps.local.yaml` file:

```bash
cp apps.sample.yaml apps.yaml
```

2. Then amend the settings as required. Ensure that each key of the apps file is unique - this will be the ID for the app used across its resources.

3. Finally, run `make apps` from the root of this repository to deploy the infrastructure for the configured app(s).
