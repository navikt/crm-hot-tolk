# [HELPER] Deployment

|               |                       |
| ------------- | --------------------- |
| **Initiator** | Manual                | 
| **Type**      | Package Install       |

# Intro

This workflows' only goal is to deploy packages to sandboxes or production. Literally any package can be deployed (regardless of which repository it's being executed from).

## Input

- Package ID
    - 18 digit Unlocked Package ID (or even managed packages)
    - Can be found from the Release page on each GitHub repository
- Org name
    - Every repo have `prod`, `preprod` & `sit`
    - Every repo can also include a voluntary `dev` or `uat` sandbox to deploy to (see Environments part below)

## Output

After the deployment, the package submitted will be installed if the workflow succeeds.

## Jobs

- Debug Information (`debug`)
    - Prints the input information (in case you forgot).
- Deploy Package (`deploy-package`)
    - Basic `sfdx force:package:install`
    - Will also deploy metadata as source (`sfdx force:source:deploy`) from folder `./force-app/unpackagable-with-auto-deploy` (if it exists)

## Secrets

- Environment secrets (corresponds with the input variables)
    - `secrets.CRM_PROD_SFDX_URL`
    - `secrets.CRM_PREPROD_SFDX_URL`
    - `secrets.DEV_SFDX_URL`
    - `secrets.CRM_UAT_SFDX_URL`
    - `secrets.CRM_SIT_SFDX_URL`
    - `secrets.CRM_PACKAGE_KEY`
        - Needed to install dependant packages

## Environments

Every repo must have `CRM_PROD_SFDX_URL`, `CRM_PREPROD_SFDX_URL` & `CRM_SIT_SFDX_URL` secrets to work. Thus, these environments are always available to deploy to. However, for this workflow, `DEV_SFDX_URL` & `CRM_UAT_SFDX_URL` are voluntary secrets that can be changed for each repository. This way, you can have separate dev environments for each team or repo and deploy to them manually. A repo does not explicitly need them, though.