public with sharing class HOT_InterpreterWantedChoiceController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_InterestedResource__c> getWantedResource(Id serviceAppointmentId) {
        return [
            SELECT Id, HOT_Wanted_by__c
            FROM HOT_InterestedResource__c
            WHERE
                ServiceAppointment__c = :serviceAppointmentId
                AND ServiceAppointment__c != NULL
                AND ServiceResource__r.RelatedRecordId = :UserInfo.getUserId()
                AND Status__c = 'Wanted'
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static void respond(Id interestedResourceId, String status) {
        if (status != 'Interested' && status != 'Declined') {
            throw new AuraHandledException('Ugyldig svar på ønsket om tolk.');
        }

        List<HOT_InterestedResource__c> resources = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE
                Id = :interestedResourceId
                AND ServiceResource__r.RelatedRecordId = :UserInfo.getUserId()
                AND Status__c = 'Wanted'
            FOR UPDATE
        ];
        if (resources.isEmpty()) {
            throw new AuraHandledException('Du er ikke lenger ønsket til dette oppdraget, eller mangler tilgang.');
        }

        update new HOT_InterestedResource__c(Id = resources[0].Id, Status__c = status);
    }
}
