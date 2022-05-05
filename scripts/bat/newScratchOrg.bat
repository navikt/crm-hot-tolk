echo "Oppretter scratch org"
call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays %2 --setdefaultusername --json --loglevel fatal  --wait 10

echo "Installerer crm-platform-base ver. 0.152"
call sfdx force:package:install --package 04t7U000000Tp27QAC -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-integration ver. 0.78"
call sfdx force:package:install --package 04t7U000000Tp4DQAS -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-access-control ver. 0.90"
call sfdx force:package:install --package 04t7U000000Tp3jQAC -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-community-base ver. 0.63"
call sfdx force:package:install --package 04t7U000000Tp7WQAS -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-platform-reporting ver. 0.25"
call sfdx force:package:install --package 04t2o000000ySIYAA2 -r -k %3 --wait 10 --publishwait 10

echo "Installerer crm-journal-utilities ver. 0.14"
call sfdx force:package:install --package 04t7U000000ToUyQAK -r -k %3 --wait 10 --publishwait 10  

echo "Installerer crm-shared-user-notification ver. 0.15"
call sfdx force:package:install --package 04t7U000000TovBQAS -r -k %3 --wait 10 --publishwait 10  

echo "Installerer crm-shared-flowComponents ver. 0.2"
call sfdx force:package:install --package 04t7U000000ToqLQAS -r -k %3 --wait 10 --publishwait 10

echo "Installer crm-henvendelse ver. 0.55"
call sfdx force:package:install --package 04t7U000000Tp0kQAC -r -k %3 --wait 10 --publishwait 10

echo "Dytter kildekoden til scratch org'en"
call sfdx force:source:push

echo "Tildeler tilatelsessett til brukeren"
call sfdx force:user:permset:assign --permsetname HOT_admin

echo "Oppretter testdata"
call sfdx force:apex:execute -f scripts/apex/createTestData.apex

echo "Ferdig"
