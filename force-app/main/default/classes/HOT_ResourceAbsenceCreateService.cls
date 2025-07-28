public without sharing class HOT_ResourceAbsenceCreateService implements Database.Batchable<sObject> {
    public final Datetime timeScope;
    public final String query;

    public HOT_ResourceAbsenceCreateService() {
        List<AsyncApexJob> jobs = [
            SELECT Id, CreatedDate
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex' AND ApexClass.Name = 'HOT_ResourceAbsenceCreateService' AND Status = 'Completed'
            ORDER BY CreatedDate DESC NULLS LAST
            LIMIT 1
        ];
        if (jobs.size() == 1) {
            this.timeScope = jobs[0].CreatedDate.addMinutes(-1);
        } else {
            this.timeScope = Datetime.now().addHours(-1);
        }
        System.debug('timeScope: ' + timeScope);
        this.query = 'SELECT Id, OwnerId, StartDateTime, EndDateTime, ShowAs, Subject FROM Event WHERE RecordType.DeveloperName = \'HOT_Events\' AND What.Type != \'ServiceAppointment\' AND What.Type != \'ResourceAbsence\' AND LastModifiedDate > :timeScope AND ShowAs != \'Free\'';
    }

    public HOT_ResourceAbsenceCreateService(Datetime timeScope) {
        this.timeScope = timeScope;
        this.query = 'SELECT Id, OwnerId, StartDateTime, EndDateTime, ShowAs, Subject FROM Event WHERE RecordType.DeveloperName = \'HOT_Events\' AND What.Type != \'ServiceAppointment\' AND What.Type != \'ResourceAbsence\' AND LastModifiedDate > :timeScope AND ShowAs != \'Free\'';
    }

    public HOT_ResourceAbsenceCreateService(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Event> scope) {
        Set<Id> ownerIds = new Set<Id>();
        for (Event event : scope) {
            ownerIds.add(event.ownerId);
        }

        List<ServiceResource> serviceResourceList = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId IN :ownerIds AND IsActive = TRUE
        ];
        Map<Id, Id> relatedRecordIdToResourceIdMap = new Map<Id, Id>();
        for (ServiceResource serviceResource : serviceResourceList) {
            relatedRecordIdToResourceIdMap.put(serviceResource.RelatedRecordId, serviceResource.Id);
        }

        Id resourceAbsenceRecordTypeId;
        RecordTypeInfo resourceAbsenceRecordTypeInfo = Schema.getGlobalDescribe()
            .get('ResourceAbsence')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Non_Availability');

        if (resourceAbsenceRecordTypeInfo != null) {
            resourceAbsenceRecordTypeId = resourceAbsenceRecordTypeInfo.getRecordTypeId();
        }

        Set<String> resourceAbsenceFields = Schema.SObjectType.ResourceAbsence.fields.getMap().keySet();

        List<ResourceAbsence> resourceAbsenceList = new List<ResourceAbsence>();

        for (Event event : scope) {
            if (relatedRecordIdToResourceIdMap.containsKey(event.OwnerId)) {
                ResourceAbsence resourceAbsence = new ResourceAbsence();
                if (resourceAbsenceRecordTypeId != null) {
                    resourceAbsence.put('RecordTypeId', resourceAbsenceRecordTypeId);
                }
                resourceAbsence.ResourceId = relatedRecordIdToResourceIdMap.get(event.OwnerId);
                resourceAbsence.HOT_EventId__c = event.Id;
                resourceAbsence.FSL__Approved__c = true;

                // All-day events in Salesforce has the same start time and end time
                if (event.StartDateTime == event.EndDateTime) {
                    Integer offset = UserInfo.getTimezone().getOffset(event.StartDateTime);
                    resourceAbsence.Start = event.StartDateTime.addSeconds(-offset / 1000);
                    resourceAbsence.End = event.EndDateTime.addDays(1).addSeconds(-offset / 1000);
                } else {
                    resourceAbsence.Start = event.StartDateTime;
                    resourceAbsence.End = event.EndDateTime;
                }
                resourceAbsence.Type = 'Møte';
                if (resourceAbsenceFields.contains('fsl__ganttlabel__c')) {
                    resourceAbsence.put('FSL__GanttLabel__c', event.Subject);
                }
                if (resourceAbsenceFields.contains('fsl__gantt_color__c') && event.ShowAs == 'OutOfOffice') {
                    resourceAbsence.put('FSL__Gantt_Color__c', '#AF7AC5');
                }
                if (resourceAbsenceFields.contains('fsl__gantt_color__c') && event.ShowAs != 'OutOfOffice') {
                    resourceAbsence.put('FSL__Gantt_Color__c', '');
                }
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
