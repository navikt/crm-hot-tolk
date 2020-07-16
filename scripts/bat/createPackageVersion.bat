:: Flytt mapper og filer som ikke kan ligge i pakken til en temp mappe
call move force-app\unpackagable temp

:: Opprett en pakkeversjon
call sfdx force:package:version:create -f config/project-scratch-def.json -k navcrm -p crm-hot --wait 60
:: for ($i=1; $i -le 100; $i++) {sfdx force:package:version:create:report -i XXX}

:: Flytt mapper og filer tilbake
call move temp force-app\unpackagable

:: Innstaller pakken i PREPROD
:: sfdx force:package:install -u carl.huseby.fosli@nav.no.preprod -p XXX -k navcrm --wait 10 --publishwait 10
:: sfdx force:package:version:promote -p 04t...