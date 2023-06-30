public without sharing class HOT_DisableFreelanceSchedulable implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_DisableFreelanceSchedulable instance = new HOT_DisableFreelanceSchedulable();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime oneYearAgo = Datetime.now().addDays(-2);

        return Database.getQueryLocator(
            [
            SELECT Id, Name, AccountId
            FROM ServiceResource
            WHERE
            IsActive = TRUE
            AND CRM_Domain__c = 'HOT'
            AND HOT_IsFreelanceInterpreter__c = TRUE
            AND CreatedDate <=:oneYearAgo
            AND Id NOT IN (
            SELECT ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE CreatedDate >=:oneYearAgo)
            ]
        );
    }
    public void execute(Database.BatchableContext bc, List<ServiceResource> records) {
        if (records.size() > 0) {
            Set<Id> srAccointIdsToDelete = new Set<Id>();
            for (ServiceResource sr : records) {
                    srAccointIdsToDelete.add(sr.AccountId);
            }
            List<User> users = [
                SELECT Id, ProfileId
                FROM User
                WHERE Profile.Name = 'NAV Samhandler' AND AccountId IN :srAccointIdsToDelete
            ];

            List<ServiceResource> serviceResource = [
                SELECT Id, RelatedRecordId
                FROM ServiceResource
                WHERE RelatedRecordId IN :users AND HOT_IsFreelanceInterpreter__c = TRUE AND IsActive = TRUE
            ];
            if (serviceResource.size() > 0) {
                for (ServiceResource sr : serviceResource) {
                    sr.IsActive = false;
                }
                try {
                    update serviceResource;
                } catch (Exception e) {
                    LoggerUtility logger = new LoggerUtility();
                    logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                    logger.publish();
                }
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
        HOT_DisableFreelancePart2Schedulable instance = new HOT_DisableFreelancePart2Schedulable();
        database.executebatch(instance, 10);
    }
}
