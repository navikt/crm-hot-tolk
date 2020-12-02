:: Opprett en scratch org
call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays %2 --setdefaultusername --json --loglevel fatal  --wait 10

:: Installer crm-platform-base ver. 0.43
call sfdx force:package:install --package 04t2o000000yQJ4AAM -r -k navcrm --wait 10 --publishwait 10

:: Installer crm-platform-access-control ver. 0.42
call sfdx force:package:install --package 04t2o000000yQRNAA2 -r -k navcrm --wait 10 --publishwait 10

:: Installer crm-community-base ver. 0.14
call sfdx force:package:install --package 04t2o000000yQbIAAU -r -k navcrm --wait 10 --publishwait 10

:: Dytt kildekoden til scratch org'en
call sfdx force:source:push

:: Tildel tilatelsessett til brukeren
call sfdx force:user:permset:assign --permsetname HOT_admin

:: Opprett testdata
call sfdx force:apex:execute -f scripts/apex/createTestData.apex

:: Hent kildekoden til scratch org'en (for å nullstille)
call sfdx force:source:pull
