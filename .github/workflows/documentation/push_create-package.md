# [PUSH] Create Package

|               |                    |
| ------------- | ------------------ |
| **Initiator** | PR Merge           | 
| **Type**      | PAckage Creation   |

# Intro

This workflows is automatically executed whenever a PR is merged into master (or main branch). It does the following:

- Create an unlocked package
- Installs the new package into dev environments
- Create a GitHub release
- Verifies the package in SIT sandbox

## Jobs

- Create Package (`create-package`)
    - The following folders are deleted to avoid packaging unpackagable metadata
        - `./force-app/unpackagable`
        - `./force-app/unpackagable-with-auto-deploy`
        - `./force-app/scratch-org`
    - An unlocked package is created
- Validate install in SIT Sandbox (`validate-in-sit`)
    - The package is installed in the SIT sandbox
    - This is an integration sandbox to test that all of NAV's Salesforce packages can be installed in the same production org
- Report install in SIT Sandbox (`report-sit-status`)
    - If the install in the previous step failed, it is reported here
    - It is reported in a separate steps so that a GitHub release can still be made, despite the installation failing
- Check Deployment Secrets (`check-deployment-secrets`)
    - Pre-deploy job needed to find which environments to install the package afterwards
- Deploy Package to Sandboxes (`deploy-package-to-sandboxes`)
    - If the repo is setup to automatically install the new package in dev environments, it will happen here. See `Environments` below for more details.
- Create release (`create-release`)
    - Create a GitHub Release denoted a "Pre-release" until the package is promoted for full release

## Secrets

- Environment secrets
    - `secrets.CRM_PROD_SFDX_URL`
    - `secrets.CRM_INTEGRATION_SANDBOX_SFDX_URL`
    - `secrets.CRM_UAT_SFDX_URL`
    - `secrets.DEV_SFDX_URL`
    - `secrets.CRM_PACKAGE_KEY`
        - Needed to install dependant packages
- Setting secrets
    - `secrets.DEPLOY_TO_DEV_AFTER_PACKAGE_CREATION`
        - Should be 1 or 0
    - `secrets.DEPLOY_TO_UAT_AFTER_PACKAGE_CREATION`
        - Should be 1 or 0

## Environments

Every repo must have `CRM_PROD_SFDX_URL`, `CRM_PREPROD_SFDX_URL` & `CRM_SIT_SFDX_URL` secrets to work. However, for this workflow, `DEV_SFDX_URL` & `CRM_UAT_SFDX_URL` are voluntary secrets that can be changed for each repository. This way, you can have separate dev environments for team or repo and deploy to them manually. A repo does not explicitly need them, though.

If you set either `secrets.DEPLOY_TO_DEV_AFTER_PACKAGE_CREATION` or `secrets.DEPLOY_TO_UAT_AFTER_PACKAGE_CREATION` to 1, that would cause the workflow to automaticall install the new package into their respective dev environment. This is useful if you'd like a separate dev environment from preprod.