public without sharing class HOT_RecalculateManualSharingBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_RecalculateManualSharingBatch instance = new HOT_RecalculateManualSharingBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, HOT_IsRecalculateManualSharing__c, HOT_ServiceResource__r.RelatedRecordId FROM ServiceAppointment WHERE HOT_IsRecalculateManualSharing__c = true';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> records) {
        HOT_ServiceAppointmentsSharingService.recalculateManualSharing(records);
    }

    public void finish(Database.BatchableContext bc) {
    }
}
