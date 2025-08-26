echo "Oppretter scratch org"
call sf org create scratch --definition-file config\project-scratch-def.json --alias %1 --duration-days %2 --set-default --json --wait 30

echo "Installer crm-platform-base ver. 0.279"
call sf package install --package 04tQC000000uij7YAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-shared-flowComponents ver. 0.4"
call sf package install --package 04t7U0000008qz4QAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-henvendelse-base ver. 0.41"
call sf package install --package 04tQC000000rfppYAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-platform-integration ver. 0.158"
call sf package install --package 04tQC000000uiG5YAI --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-platform-access-control ver. 0.162"
call sf package install --package 04tQC000000tlPhYAI --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-community-base ver. 0.128"
call sf package install --package 04tQC000000ocOfYAI --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-platform-reporting ver. 0.41"
call sf package install --package 04tKB000000YAWDYA4 --no-prompt --installation-key %3 --wait 30 --publish-wait 30

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
