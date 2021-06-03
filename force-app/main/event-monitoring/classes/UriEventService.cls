/* 
convert UriEvent to Log__c record with lookup to Person Ident
Make it possible for NAV's "snokelogg" to get log elemnts
*/
public with sharing class UriEventService {
    public static void addPersonRelatedRecordsToLog(List<UriEvent> uriEvents) {
        List<Log__c> logs = new List<Log__c>();

        Map<Id, UriEvent> uriEventByRecordId = new Map<Id, UriEvent>();

        //record ids for each object we want to log
        Set<Id> hotRequestRecordIds = new Set<Id>();

        //check if object ype should be logged
        for (UriEvent ue : uriEvents) {
            //only standard users are logged
            if (ue.UserType != 'Standard')
                continue;

            switch on ue.QueriedEntities {
                when 'HOT_Request__c' {
                    uriEventByRecordId.put(ue.RecordId, ue);
                    hotRequestRecordIds.add(ue.RecordId);
                }
            }
        }

        //get related person ident for each object
        Map<Id, String> personIdentByRecordId = getPersonIdentsForEachObject(hotRequestRecordIds);

        //add log elemnt with person ident
        for (Id recordId : personIdentByRecordId.keyset()) {
            logs.add(addLogElement(uriEventByRecordId.get(recordId), personIdentByRecordId.get(recordId)));
        }

        if (logs.size() > 0) {
            insert logs;
        }
    }

    private static Map<Id, String> getPersonIdentsForEachObject(Set<Id> hotRequestRecordIds) {
        Map<Id, String> personIdentByRecordId = new Map<Id, String>();

        //HOT Request
        if (hotRequestRecordIds.size() > 0) {
            for (HOT_Request__c req : [
                SELECT Id, Person__r.Name
                FROM HOT_Request__c
                WHERE Id IN :hotRequestRecordIds
            ]) {
                personIdentByRecordId.put(req.Id, req.Person__r.Name);
            }
        }

        return personIdentByRecordId;
    }

    private static Log__c addLogElement(UriEvent ue, String personIdent) {
        return new Log__c(
            CRM_RecordId__c = ue.RecordId,
            CRM_EventDate__c = ue.EventDate,
            CRM_QueriedEntity__c = ue.QueriedEntities,
            CRM_Username__c = ue.Username,
            CRM_Operation__c = ue.Operation,
            CRM_PersonIdent__c = personIdent,
            CRM_Type__c = 'LightningUriEvent',
            CRM_Status__c = 'Completed'
        );
    }
}
