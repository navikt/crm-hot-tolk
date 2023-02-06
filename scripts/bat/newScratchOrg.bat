echo "Oppretter scratch org"
call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays %2 --setdefaultusername --json --loglevel fatal  --wait 10

echo "Installerer crm-platform-base ver. 0.185"
call sfdx force:package:install --package 04t7U0000008r3aQAA -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-integration ver. 0.96"
call sfdx force:package:install --package 04t7U0000008r2XQAQ -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-access-control ver. 0.107"
call sfdx force:package:install --package 04t7U0000008r15QAA -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-community-base ver. 0.79"
call sfdx force:package:install --package 04t7U0000008qtVQAQ -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-reporting ver. 0.30"
call sfdx force:package:install --package 04t7U0000008qnNQAQ -r -k %3 --wait 10 --publishwait 10

echo "Installer crm-henvendelse-base ver. 0.14"
call sfdx force:package:install --package 04t7U0000008r4dQAA -r -k %3 --wait 10 --publishwait 10

echo "Dytter kildekoden til scratch org'en"
call sfdx force:source:push

echo "Tildeler tilatelsessett til brukeren"
call sfdx force:user:permset:assign --permsetname "HOT_admin, HOT_Config"

echo "Publish Experience Site"
call sfdx force:community:publish --name Tolketjenesten

echo "Oppretter testdata"
call sfdx force:apex:execute -f scripts/apex/createTestData.apex

echo "Ferdig"
