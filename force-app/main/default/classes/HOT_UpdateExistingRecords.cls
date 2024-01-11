public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();

        return Database.getQueryLocator(
            'SELECT Id, HOT_Participants__c, CRM_Related_Object__c, CRM_Thread_Type__c, CreatedDate FROM Thread__c WHERE CRM_Thread_Type__c = \'HOT_TOLK-FORMIDLER\' AND CreatedDate = \'LAST_N_DAYS:90\''
        );
    }

    public void execute(Database.BatchableContext bc, List<Thread__c> records) {
        Set<Id> threadRelatedObjectId = new Set<Id>();
        for (Thread__c thread : records) {
            threadRelatedObjectId.add(thread.CRM_Related_Object__c);
        }

        List<ServiceAppointment> saList = [
            SELECT Id, HOT_ServiceResource__r.RelatedRecordId
            FROM ServiceAppointment
            WHERE Id IN :threadRelatedObjectId
        ];
        List<HOT_InterestedResource__c> irList = [
            SELECT Id, ServiceResource__r.RelatedRecordId
            FROM HOT_InterestedResource__c
            WHERE Id IN :threadRelatedObjectId
        ];
        if (saList.size() > 0) {
            for (Thread__c thread : records) {
                for (ServiceAppointment sa : saList) {
                    if (thread.CRM_Related_Object__c == sa.Id) {
                        thread.HOT_Participants__c = sa.HOT_ServiceResource__r.RelatedRecordId;
                    }
                }
            }
        }
        if (irList.size() > 0) {
            for (Thread__c thread : threads) {
                for (HOT_InterestedResource__c ir : irList) {
                    if (thread.CRM_Related_Object__c == ir.Id) {
                        thread.HOT_Participants__c = ir.ServiceResource__r.RelatedRecordId;
                    }
                }
            }
        }
        update records;
    }
    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
