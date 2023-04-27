echo "Oppretter scratch org"
call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays %2 --setdefaultusername --json --loglevel fatal  --wait 10

echo "Installerer crm-platform-base ver. 0.192"
call sfdx package:install --package 04t7U000000D2HkQAK -r -k %3 --wait 10 --publish-wait 10

echo "Installerer crm-platform-integration ver. 0.99"
call sfdx package:install --package 04t7U0000004dzIQAQ -r -k %3 --wait 10 --publish-wait 10

echo "Installerer crm-platform-access-control ver. 0.113"
call sfdx package:install --package 04t7U0000004e8tQAA -r -k %3 --wait 10 --publish-wait 10

echo "Installerer crm-community-base ver. 0.86"
call sfdx package:install --package 04t7U0000004duXQAQ -r -k %3 --wait 10 --publish-wait 10

echo "Installerer crm-platform-reporting ver. 0.31"
call sfdx package:install --package 04t7U0000008rBAQAY -r -k %3 --wait 10 --publish-wait 10

echo "Installer crm-henvendelse-base ver. 0.15"
call sfdx package:install --package 04t7U000000D2KjQAK -r -k %3 --wait 10 --publish-wait 10

echo "Dytter kildekoden til scratch org'en"
call sfdx force:source:push

echo "Tildeler tilatelsessett til brukeren"
call sfdx force:user:permset:assign --permsetname HOT_admin

echo "Publish Experience Site"
call sfdx force:community:publish --name Tolketjenesten

echo "Oppretter testdata"
call sfdx force:apex:execute -f scripts/apex/createTestData.apex

echo "Ferdig"
