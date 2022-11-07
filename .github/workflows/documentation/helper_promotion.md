# [HELPER] Promotion

|               |                         |
| ------------- | ----------------------- |
| **Initiator** | Manual                  | 
| **Type**      | Package Promotion       |

# Intro

This workflows does the following: 

- Promotes an unlocked package
- Creates a new GitHub Release
- Adjusts the version number on the minor
    - 1.7.0 would become 1.8.0
- Installs the package in preprod

## Input

- Package ID
    - 18 digit Unlocked Package ID (or even managed packages)
    - Can be found from the Release page on each GitHub repository
- Description field used in the GitHub Release

## Jobs

- Debug Information (`debug`)
    - Prints the input information (in case you forgot).
- Promote Package (`promote-package`)
    - Basic `sfdx force:package:version:promote`
- Install Package in Preprod (`install-package-preprod`)
    - Basic `sfdx force:package:install`
- Push new version number to master (`push-new-version-number-to-master`)
    - Uses [navikt/github-action-sfdx-version-updater](https://github.com/navikt/github-action-sfdx-version-updater) (GitHub Actions plugin) to update the version number in `sfdx-project.json` (e.g., 1.7.0 => 1.8.0)
    - Creates a pull request that is instantly merged (to avoid GitHub which blocks pushing to master)
    - Needs a GitHub personal access token from an admin to merge (see secrets below)
- Create GitHub Release (`create-release`)
    - Contains the version number, package ID, code coverage, changelog, author and basic description of changes

## Secrets

- Environment secrets
    - `secrets.CRM_PROD_SFDX_URL`
    - `secrets.CRM_PREPROD_SFDX_URL`
    - `secrets.CRM_PACKAGE_KEY`
        - Needed to install dependant packages
    - `secrets.CRM_DEPLOYMENT_PAT`
        - Needed to force merge PR's without all tests
        - Forced because the ony changes are the version number changes so that users don't have to remember to update manually
        - [Create a PAT](https://docs.github.com/en/enterprise/2.17/user/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) with "REPO" access to get a working secret