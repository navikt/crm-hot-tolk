:: Flytt mapper og filer som ikke kan ligge i pakken til en temp mappe
call move force-app\main\default\networks temp
call move force-app\main\default\documents temp
call move force-app\main\default\networkBranding temp
call move force-app\main\default\experiences temp
call move force-app\main\default\siteDotComSites temp
call move force-app\main\default\sites temp
call move force-app\main\default\pages temp
call move force-app\main\default\translations temp
call move force-app\main\default\classes\ChangePasswordController* temp
call move force-app\main\default\classes\CommunitiesLandingController* temp
call move force-app\main\default\classes\MyProfilePageController* temp
call move force-app\main\default\sharingSets temp
call move force-app\main\default\roles temp
call move force-app\main\default\profiles temp
call move force-app\krr-integration\customMetadata temp

call sfdx force:package:version:create -f config/project-scratch-def.json -k navcrm -p crm-hot
:: for ($i=1; $i -le 100; $i++) {sfdx force:package:version:create:report -i XXX}

:: Flytt mapper og filer tilbake
call move temp\networks force-app\main\default\networks
call move temp\documents force-app\main\default\documents
call move temp\networkBranding force-app\main\default\networkBranding
call move temp\experiences force-app\main\default\experiences
call move temp\siteDotComSites force-app\main\default\siteDotComSites
call move temp\sites force-app\main\default\sites
call move temp\pages force-app\main\default\pages
call move temp\translations force-app\main\default\translations
call move temp\ChangePasswordController* force-app\main\default\classes
call move temp\CommunitiesLandingController* force-app\main\default\classes
call move temp\MyProfilePageController* force-app\main\default\classes
call move temp\sharingSets force-app\main\default\sharingSets
call move temp\roles force-app\main\default\roles
call move temp\profiles force-app\main\default\profiles
call move temp\customMetadata force-app\krr-integration\customMetadata

:: Innstaller pakken i PREPROD
:: sfdx force:package:install -u carl.huseby.fosli@nav.no.preprod -p XXX -k navcrm --wait 10 --publishwait 10