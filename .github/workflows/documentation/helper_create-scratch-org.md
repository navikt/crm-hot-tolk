# [HELPER] Create Scratch Org

|               |                        |
| ------------- | ---------------------- |
| **Initiator** | Manual                 | 
| **Type**      | Scratch Org Creation   |

# Intro

This workflows does the following: 

- Create a scratch org directly from Github
    - Installs dependant packages
    - Deploys metadata
    - Assign Permission Sets defined in [ssdx-config.json](config/ssdx-config.json)
- Pulls metadata from the scratch org every minute
    - Pushes the metadata to a branch chosen in the input parameter
    - Is active for 5.5 hours until the scratch org is deleted (the branch remains)

## Input

- Choose an existing branch from the dropdown menu
- Or type a new branch name in the input field

## Output

A branch with metadata that has been automatically pulled after changes in a scratch org. A link inside the log output gives you login information.

## Jobs

- Print Parameters (`print`)
    - Prints the input information (in case you forgot).
- Create Scratch Org (`setup`)
    - Creates a scratch org directly from the repo.
    - Installs all dependant packages.
    - Pushes all metadata.
    - Assign permsets defined in [ssdx-config.json](config/ssdx-config.json).
    - The scratch org login information is saved using [actions/upload-artifact](https://github.com/actions/upload-artifact), so that the scratch org is available in the next steps which needs to login, pull metadata and lastly, delete the scratch org.
- Click Here to Login (`login`)
    - Prints an instant login URL to the scratch org (only works for 1 hour), but it also inlcudes a username and password.
- Pull Metadata (`pull-metadata`)
    - Pulls metadata using `sfdx force:source:pull -f` every minute.
    - If new metadata is found, the script commits and pushes the metadata to the branch that was specified in the input.
    - This has the benefit of pulling often, so if some metadata breaks the pull process, you'll have all the metadata saved until that point (less rework & easier debugging of what caused the issue)
    - It is recommended to have the log output for this job open at all times to see whenever new metadata is fetched.
- Delete Scratch Org (`delete-scratch-org`)
    - Deletes the scratch org to avoid having too many active at the same time (max 40 in NAV)
    - If the user cancels the process, the deletion still occurs

## Secrets

- `secrets.CRM_PROD_SFDX_URL`
    - Needed to create scratch orgs
- `secrets.CRM_PACKAGE_KEY`
    - Needed to install dependant packages