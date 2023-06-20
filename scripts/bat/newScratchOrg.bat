echo "Oppretter scratch org"
call sfdx org:create:scratch -f config\project-scratch-def.json --setalias %1 --durationdays %2 --setdefaultusername --json --loglevel fatal  --wait 10

echo "Installerer crm-platform-base ver. 0.195"
call sfdx package:install --package 04t7U0000000Rf8QAE -r -k %3 --wait 10 --publish-wait 10

echo "Installer crm-henvendelse-base ver. 0.16"
call sfdx package:install --package 04t7U0000000RX4QAM -r -k %3 --wait 10 --publish-wait 10

echo "Installerer crm-platform-integration ver. 0.100"
call sfdx package:install --package 04t7U0000000RhYQAU -r -k %3 --wait 10 --publish-wait 10

echo "Installerer crm-platform-access-control ver. 0.113"
call sfdx package:install --package 04t7U0000004e8tQAA -r -k %3 --wait 10 --publish-wait 10

echo "Installerer crm-community-base ver. 0.86"
call sfdx package:install --package 04t7U0000004duXQAQ -r -k %3 --wait 10 --publish-wait 10

echo "Installerer crm-platform-reporting ver. 0.31"
call sfdx package:install --package 04t7U0000008rBAQAY -r -k %3 --wait 10 --publish-wait 10

echo "Dytter kildekoden til scratch org'en"
call sfdx force:source:push

echo "Tildeler tilatelsessett til brukeren"
call sfdx force:user:permset:assign --perm-set-name "HOT_admin, HOT_Config"

echo "Publish Experience Site"
call sfdx community:publish --name Tolketjenesten

echo "Oppretter testdata"
call sfdx apex run -f scripts/apex/createTestData.apex

echo "Ferdig"
