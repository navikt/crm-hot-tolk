public without sharing class HOT_ResourceAbsenceCreateService implements Database.Batchable<sObject> {
    public static Datetime timeScope = Datetime.now().addDays(-1);

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, OwnerId, StartDateTime, EndDateTime FROM Event WHERE RecordType.DeveloperName = \'HOT_Events\' AND WhatId = null AND LastModifiedDate > :timeScope AND ShowAs != \'Free\''
        );
    }

    public void execute(Database.BatchableContext bc, List<Event> scope) {
        Set<Id> ownerIds = new Set<Id>();
        for (Event event : scope) {
            ownerIds.add(event.ownerId);
        }

        List<ServiceResource> serviceResourceList = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId IN :ownerIds
        ];
        Map<Id, Id> relatedRecordIdResourceId = new Map<Id, Id>();
        for (ServiceResource serviceResource : serviceResourceList) {
            relatedRecordIdResourceId.put(serviceResource.RelatedRecordId, serviceResource.Id);
        }

        RecordType resourceAbsenceRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Non_Availability'];

        List<ResourceAbsence> resourceAbsenceList = new List<ResourceAbsence>();

        for (Event event : scope) {
            if (relatedRecordIdResourceId.containsKey(event.OwnerId)) {
                ResourceAbsence resourceAbsence = new ResourceAbsence();
                resourceAbsence.RecordTypeId = resourceAbsenceRecordType.Id;
                resourceAbsence.ResourceId = relatedRecordIdResourceId.get(event.OwnerId);
                resourceAbsence.HOT_EventId__c = event.Id;
                resourceAbsence.Start = event.StartDateTime;
                resourceAbsence.End = event.EndDateTime;
                resourceAbsence.Type = 'Møte';
                resourceAbsenceList.add(resourceAbsence);
            }
        }

        if (resourceAbsenceList.size() > 0) {
            try {
                upsert resourceAbsenceList HOT_EventId__c;
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            try {
                System.scheduleBatch(
                    new HOT_ResourceAbsenceCreateService(),
                    'HOT_ResourceAbsenceCreateService',
                    5,
                    1000
                );
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }
}
