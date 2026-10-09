public without sharing class HOT_TLUserInformationController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource getCurrentUserServiceResource() {
        List<ServiceResource> resources = getCurrentUserResources();
        return resources.isEmpty() ? null : resources[0];
    }

    @AuraEnabled
    public static void updatePreferredRegions(List<String> selectedRegions) {
        List<ServiceResource> resources = getCurrentUserResources();
        if (resources.isEmpty()) {
            throw new AuraHandledException('Fant ingen tjenesteleverandør profil.');
        }

        Set<String> validRegionValues = new Set<String>();
        for (Schema.PicklistEntry option : ServiceResource.HOT_PreferredRegions__c.getDescribe().getPicklistValues()) {
            if (option.isActive()) {
                validRegionValues.add(option.getValue());
            }
        }

        List<String> regionsToSave = new List<String>();
        Set<String> seenRegions = new Set<String>();
        for (String region : selectedRegions == null ? new List<String>() : selectedRegions) {
            if (!validRegionValues.contains(region)) {
                throw new AuraHandledException('Ugyldig region valgt.');
            }
            if (seenRegions.add(region)) {
                regionsToSave.add(region);
            }
        }

        ServiceResource resource = resources[0];
        resource.HOT_PreferredRegions__c = regionsToSave.isEmpty() ? null : String.join(regionsToSave, ';');
        update resource;
    }

    private static List<ServiceResource> getCurrentUserResources() {
        List<ServiceResource> resources = [
            SELECT Id, HOT_PreferredRegions__c, HOT_IsTjenesteleverandorDispatcher__c
            FROM ServiceResource
            WHERE
                RelatedRecordId = :UserInfo.getUserId()
                AND CRM_Domain__c = 'HOT'
                AND CRM_Subdomain__c = 'Tolketjenesten'
                AND IsActive = TRUE
            LIMIT 1
        ];

        if (!resources.isEmpty() && resources[0].HOT_IsTjenesteleverandorDispatcher__c != true) {
            throw new AuraHandledException('Denne brukeren er ikke tjenesteleverandør.');
        }

        return resources;
    }
}
