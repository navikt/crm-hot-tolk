# [PUSH] Deploy to Dev

|               |                              |
| ------------- | ---------------------------- |
| **Initiator** | Pushing to Dev branch        | 
| **Type**      | Source Deploy                |

# Intro

This workflows automatically runs whenever someone pushes or merges a PR into the `dev` branch. It's a simple `sfdx force:source:deploy`, so no packages. However, dependant packages are installed to make sure the metadata will deploy.

## Secrets

- Environment secrets
    - `secrets.CRM_PROD_SFDX_URL`
    - `secrets.CRM_DEV_SFDX_URL`
    - `secrets.CRM_PACKAGE_KEY`
        - Needed to install dependant packages