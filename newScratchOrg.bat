call sfdx force:org:create -f config\project-scratch-def.json --setalias %1 --durationdays 2 --setdefaultusername --json --loglevel fatal  --wait 10
call sfdx force:package:install --package 04t2o000001MxPAAA0  -k navcrm --wait 10 --publishwait 10
call sfdx force:package:install --package 04t2o000001MxQhAAK  -k navcrm --wait 10 --publishwait 10
call sfdx force:source:push
