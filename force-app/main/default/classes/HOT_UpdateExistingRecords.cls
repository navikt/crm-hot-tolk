public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, INT_MunicipalityNumber__c, CRM_Region__c
                FROM Person__c
                WHERE INT_MunicipalityNumber__c != NULL AND INT_IsHasTombstone__c = FALSE
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<Person__c> records) {
        Set<String> regionCodes = new Set<String>();
        for (Person__c p : records) {
            if (p.INT_MunicipalityNumber__c.length() >= 2) {
                regionCodes.add(p.INT_MunicipalityNumber__c.substring(0, 2));
            }
        }

        Map<String, Id> regionAssociations = new Map<String, Id>();
        for (Common_Code__c code : [
            SELECT Id, CRM_Code__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Fylke' AND CRM_Active__c = TRUE AND CRM_Code__c IN :regionCodes
        ]) {
            regionAssociations.put(code.CRM_Code__c, code.Id);
        }

        for (Person__c p : records) {
            if (p.INT_MunicipalityNumber__c.length() >= 2) {
                String regionCode = p.INT_MunicipalityNumber__c.substring(0, 2);
                p.CRM_Region__c = regionAssociations.containsKey(regionCode)
                    ? regionAssociations.get(regionCode)
                    : null;
            } else {
                p.CRM_Region__c = null;
            }
        }

        update records;
    }

    public void finish(Database.BatchableContext bc) {
    }
}
