call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays 2 --setdefaultusername --json --loglevel fatal  --wait 10
:: Install crm-platform-base 
call sfdx force:package:install --package 04t2o000001MxfhAAC  -k navcrm --wait 10 --publishwait 10
:: Install crm-platform-access-control
call sfdx force:package:install --package 04t2o000001MxeeAAC  -k navcrm --wait 10 --publishwait 10
::call sfdx force:source:deploy -p C:\dev\workspace\crm-platform-unpackaged\force-app\main\default\objects\PersonAccount
::call sfdx force:source:retrieve -u carl.fosli@nav.no.hottest -x fsl-metadata\package.xml
call sfdx force:source:push
call sfdx force:user:permset:assign --permsetname HOT_admin
if %2==imp call sfdx force:data:tree:import --plan data-source/data-import-plan.json
