call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays 2 --setdefaultusername --json --loglevel fatal  --wait 10
call sfdx force:package:install --package 04t2o000001MxPAAA0  -k navcrm --wait 10 --publishwait 10
call sfdx force:package:install --package 04t2o000001MxQhAAK  -k navcrm --wait 10 --publishwait 10
:: call sfdx force:source:deploy -p C:\dev\workspace\crm-platform-unpackaged\force-app\main\default\objects\PersonAccount
call sfdx force:source:push
call sfdx force:user:permset:assign --permsetname HOT_admin
if %2==imp call sfdx force:data:tree:import --plan data-source/data-import-plan.json
