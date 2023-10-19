echo "Oppretter scratch org"
call sf org create scratch --definition-file config\project-scratch-def.json --alias %1 --duration-days %2 --set-default --json --wait 30

echo "Installerer crm-platform-base ver. 0.198"
call sf package install --package 04t7U000000LPIYQA4 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-henvendelse-base ver. 0.16"
call sf package install --package 04t7U0000000RX4QAM --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-integration ver. 0.101"
call sf package install --package 04t7U000000om5FQAQ --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-access-control ver. 0.113"
call sf package install --package 04t7U0000004e8tQAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-community-base ver. 0.86"
call sf package install --package 04t7U0000004duXQAQ --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-reporting ver. 0.31"
call sf package install --package 04t7U0000008rBAQAY --no-prompt --installation-key %3 --wait 30 --publish-wait 30

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
