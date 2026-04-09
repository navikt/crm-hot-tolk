public without sharing class HOT_HighlightPanelController {
    @AuraEnabled(cacheable=true)
    public static Account getAccountPersonDetails(Id recordId) {
        Account acc = [
            SELECT
                Id,
                CRM_Person__c,
                CRM_Person__r.INT_Confidential__c,
                CRM_Person__r.INT_IsNavEmployee__c,
                CRM_Person__r.INT_ActorId__c,
                CRM_Person__r.INT_FirstName__c,
                CRM_Person__r.Name,
                CRM_Person__r.INT_LastName__c,
                CRM_Person__r.INT_Citizenships__c,
                CRM_Person__r.INT_LegalStatus__c,
                CRM_Person__r.CRM_Municipality__r.Name,
                CRM_Person__r.CRM_District__r.Name,
                CRM_Person__r.HOT_DegreeOfHearingAndVisualImpairment__c,
                CRM_Person__r.INT_IsDeceased__c,
                CRM_Person__r.NKS_Full_Name__c,
                CRM_Person__r.INT_Sex__c,
                CRM_Person__r.CRM_Age__c
            FROM Account
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (acc.CRM_Person__c == null) {
            return acc;
        }

        Id personId = acc.CRM_Person__c;

        Boolean hasAccess = HOT_TindAccessErrorController.hasAccess(personId);

        Person__c personSafe;
        if (acc.CRM_Person__r == null || !hasAccess) {
            personSafe = [
                SELECT INT_Confidential__c, INT_IsNavEmployee__c, INT_IsDeceased__c
                FROM Person__c
                WHERE Id = :personId
                LIMIT 1
            ];
        }

        if (hasAccess) {
            return acc;
        }

        // No access → return masked Person details but keep access flags for badge visibility
        Person__c fakePerson = new Person__c();
        fakePerson.Id = personId;
        fakePerson.INT_Confidential__c = (personSafe != null) ? personSafe.INT_Confidential__c : null;
        fakePerson.INT_IsNavEmployee__c = (personSafe != null) ? personSafe.INT_IsNavEmployee__c : null;
        fakePerson.INT_IsDeceased__c = (personSafe != null) ? personSafe.INT_IsDeceased__c : null;
        fakePerson.Name = 'Skjermet person';
        fakePerson.put('INT_FirstName__c', 'Skjermet');
        fakePerson.put('INT_LastName__c', 'person');

        acc.putSObject('CRM_Person__r', fakePerson);

        return acc;
    }
}
