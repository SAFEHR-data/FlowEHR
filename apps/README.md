# 🌺 FlowEHR - Apps

This directory contains the code for deploying and hosting apps that present and work with the transformed FlowEHR data/features/models.

## Getting started

1. First, to configure which apps you'd like to deploy, copy the `apps.sample.yaml` to a new `apps.yaml` file:

```bash
cp apps.sample.yaml apps.yaml
```

2. Then amend the settings as required. Ensure that each key of the apps file is unique - this will be the ID for the app used across its resources.

3. Finally, run `make apps` from the root of this repository to deploy the infrastructure for the configured app(s).
