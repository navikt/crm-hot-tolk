echo "Oppretter scratch org"
call sf org create scratch --definition-file config\project-scratch-def.json --alias %1 --duration-days %2 --set-default --json --wait 30

echo "Installer crm-platform-base ver. 0.293"
call sf package install --package 04tQC0000012Y8HYAU --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-shared-flowComponents ver. 0.4"
call sf package install --package 04t7U0000008qz4QAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-henvendelse-base ver. 0.36"
call sf package install --package 04tQC000000uSXtYAM --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installing platform-data-model ver. 0.1.2"
call sf package install --package 04tQC000000oHLpYAM --no-prompt --wait 30 --publish-wait 30

echo "Installing custom-metadata-dao ver. 1.2"
call sf package install --package 04tQC000000oHKDYA2 --no-prompt --wait 30 --publish-wait 30

echo "Installing custom-permission-helper ver. 0.1.2"
call sf package install --package 04tQC000000oGw2YAE --no-prompt --wait 30 --publish-wait 30

echo "Installing feature-toggle ver. 0.1.3"
call sf package install --package 04tQC000000oHP3YAM --no-prompt --wait 30 --publish-wait 30

echo "Installer crm-platform-integration ver. 0.162"
call sf package install --package 04tQC000000xwmMYAQ --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-platform-access-control ver. 0.162"
call sf package install --package 04tQC000000tlPhYAI --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-community-base ver. 0.133"
call sf package install --package 04tQC0000012ZXNYA2 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-platform-reporting ver. 0.41"
call sf package install --package 04tKB000000YAWDYA4 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-hot-felles ver. 0.5"
call sf package install --package 04tQC0000012uGrYAI --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Dytter kildekoden til scratch org'en"
call sf project deploy start

echo "Tildeler tilatelsessett til brukeren"
call sf org assign permset --name HOT_Admin
call sf org assign permset --name HOT_Config

echo "Publish Experience Site"
call sf community publish --name Tolketjenesten

echo "Oppretter testdata"
call sf apex run --file scripts/apex/createTestData.apex

echo "Ferdig"
