:: Opprett en scratch org
call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays %2 --setdefaultusername --json --loglevel fatal  --wait 10

:: Skru på Field Service (bug)
::call sfdx force:source:deploy -x .\manifests\FieldServiceSettings.xml

:: Installer crm-platform-base ver. 0.81
call sfdx force:package:install --package 04t2o000000yRqoAAE -r -k navcrm --wait 10 --publishwait 10

:: Installer crm-platform-integration ver. 0.34
call sfdx force:package:install --package 04t2o000000yRIgAAM -r -k navcrm --wait 10 --publishwait 10

:: Installer crm-platform-access-control ver. 0.60
call sfdx force:package:install --package 04t2o000000yRbUAAU -r -k navcrm --wait 10 --publishwait 10

:: Installer crm-community-base ver. 0.15
call sfdx force:package:install --package 04t2o000000yRGfAAM -r -k navcrm --wait 10 --publishwait 10

:: Dytt kildekoden til scratch org'en
call sfdx force:source:push

:: Tildel tilatelsessett til brukeren
call sfdx force:user:permset:assign --permsetname HOT_admin

:: Opprett testdata
call sfdx force:apex:execute -f scripts/apex/createTestData.apex

:: Hent kildekoden til scratch org'en (for å nullstille)
call sfdx force:source:pull
