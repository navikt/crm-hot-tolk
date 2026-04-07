public without sharing class HOT_HighlightPanelController {
    @AuraEnabled(cacheable=true)
    public static Person__c getPerson(Id recordId) {
        Person__c person = [
            SELECT Id, INT_Confidential__c, INT_IsNavEmployee__c
            FROM Person__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return person;
    }
}
