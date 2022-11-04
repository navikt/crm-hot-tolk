# [PR] Validation

|               |                       |
| ------------- | --------------------- |
| **Initiator** | Pull Request          | 
| **Type**      | Metadata Validation   |

# Intro

This workflow automatically validates that metadata is valid, tests run successfully and that code coverage is at least 85%. The workflows runs on all Pull Requests, regardless of source and destination. You can also configure GitHub settings to requires some of the jobs (described below) to be passed before a PR can be merged.

## Jobs

- Setup (`setup`)
    - Creates a new scratch org
    - Install all dependant packages
- Compile Metadata (`compile`)
    - Pushes metadata using `sfdx force:source:push`
    - This is a separate step, so that it's easier to spot wether what job potentially failed. If this job failed, it means the metadata is invalid or contains compile errors.
- Run Apex Tests (`run-tests`)
    - Runs the actual tests, but only tests from this repository
    - If this job fails, it means some of the tests did not pass. That probably means it's either missing some setup in the scratch org or that metadata (or potentially data) is missing from the new scratch org
- Validate 85% Code Coverage (`check-code-coverage`)
    - If this job fails, all tests passed but weren't totaling to at least 85% code coverage
- Cleanup (`cleanup`)
    - Deletes the scratch org

## Secrets

- `secrets.CRM_PROD_SFDX_URL`
    - Needed to create scratch orgs
- `secrets.CRM_PACKAGE_KEY`
    - Needed to install dependant packages