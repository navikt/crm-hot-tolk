echo "Oppretter scratch org"
call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays %2 --setdefaultusername --json --loglevel fatal  --wait 10

echo "Installerer crm-platform-base ver. 0.177"
call sfdx force:package:install --package 04t7U0000008qY8QAI -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-integration ver. 0.91"
call sfdx force:package:install --package 04t7U0000008qXUQAY -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-access-control ver. 0.101"
call sfdx force:package:install --package 04t7U000000TpqbQAC -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-community-base ver. 0.71"
call sfdx force:package:install --package 04t7U000000TqLFQA0 -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-reporting ver. 0.25"
call sfdx force:package:install --package 04t2o000000ySIYAA2 -r -k %3 --wait 10 --publishwait 10

echo "Installer crm-henvendelse-base ver. 0.11"
call sfdx force:package:install --package 04t7U000000Tqf5QAC -r -k %3 --wait 10 --publishwait 10

echo "Dytter kildekoden til scratch org'en"
call sfdx force:source:push

echo "Tildeler tilatelsessett til brukeren"
call sfdx force:user:permset:assign --permsetname HOT_admin, HOT_Config

echo "Publish Experience Site"
call sfdx force:community:publish --name Tolketjenesten

echo "Oppretter testdata"
call sfdx force:apex:execute -f scripts/apex/createTestData.apex

echo "Ferdig"
