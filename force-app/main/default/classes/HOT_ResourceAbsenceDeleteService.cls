public without sharing class HOT_ResourceAbsenceDeleteService implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, HOT_EventId__c FROM ResourceAbsence WHERE HOT_EventId__c != null AND Start > YESTERDAY'
        );
    }

    public void execute(Database.BatchableContext bc, List<ResourceAbsence> scope) {
        Set<Id> eventIds = new Set<Id>();
        for (ResourceAbsence resourceAbsence : scope) {
            eventIds.add(resourceAbsence.HOT_EventId__c);
        }

        List<Event> eventList = [SELECT Id FROM Event WHERE Id IN :eventIds AND ShowAs != 'Free'];
        Map<Id, Event> eventMap = new Map<Id, Event>(eventList);

        List<ResourceAbsence> resourceAbsencesToDelete = new List<ResourceAbsence>();

        for (ResourceAbsence resourceAbsence : scope) {
            if (eventMap.containsKey(resourceAbsence.HOT_EventId__c)) {
                continue;
            } else {
                resourceAbsencesToDelete.add(resourceAbsence);
            }
        }

        if (resourceAbsencesToDelete.size() > 0) {
            try {
                delete resourceAbsencesToDelete;
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
                    new HOT_ResourceAbsenceDeleteService(),
                    'HOT_ResourceAbsenceDeleteService',
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
