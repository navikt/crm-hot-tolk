call move force-app\main\default\networks community-up
call move force-app\main\default\networkBranding community-up
call move force-app\main\default\experiences community-up
call move force-app\main\default\siteDotComSites community-up
call move force-app\main\default\sites community-up
call sfdx force:package:version:create -f config/project-scratch-def.json -k navcrm -p crm-hot
call move community-up\networks force-app\main\default\networks
call move community-up\networkBranding force-app\main\default\networkBranding
call move community-up\experiences force-app\main\default\experiences
call move community-up\siteDotComSites force-app\main\default\siteDotComSites
call move community-up\sites force-app\main\default\sites