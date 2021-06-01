public without sharing class HOT_ReminderSMSBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_ReminderSMSBatch instance = new HOT_ReminderSMSBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        Date horizonDate = Date.today().addDays(2);
        if (now.format('EEEE') == 'Friday') {
            horizonDate = Date.today().addDays(4);
        }
        String query = 'SELECT ';
        query += 'Id, AccountId, Account.CRM_Person__r.INT_KrrMobilePhone__c, StartDate, EndDate ';
        query += 'FROM WorkOrder ';
        query += 'WHERE StartDate < :horizonDate ';
        query += 'AND StartDate > :now ';
        query += 'AND Status = \'Dispatched\' ';
        query += 'AND Account.CRM_Person__r.INT_KrrMobilePhone__c != null ';
        query += 'AND Account.CRM_Person__r.HOT_IsReservationAgainstReminderSMS__c = FALSE ';
        query += 'AND HOT_Request__r.IsReminderSMS__c = TRUE ';
        query += 'AND HOT_IsReminderSMSSendt__c = FALSE';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        HOT_ReminderSMSService.reminderSMS(records);
    }

    public void finish(Database.BatchableContext bc) {
        Long minutes = getMinutes();
        if (!Test.isRunningTest()) {
            try {
                System.scheduleBatch(new HOT_ReminderSMSBatch(), 'HOT_ReminderSMSBatch', (Integer) minutes, 10);
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }

    private Long getMinutes() {
        Long minutes = 60;
        Datetime now = Datetime.now();
        Datetime datetime_1600 = Datetime.newInstance(Date.today(), Time.newInstance(16, 0, 0, 0));
        Boolean isLastIsNext = datetime_1600.getTime() - Datetime.now().getTime() < 3600000;
        Boolean isLast = datetime_1600.getTime() - Datetime.now().getTime() < 600000;
        Boolean isFriday = now.format('EEEE') == 'Friday';
        if (isLastIsNext) {
            minutes = (datetime_1600.getTime() - now.getTime()) / 60000;
        } else if (isLast) {
            Datetime nexDay = Datetime.newInstance(now.addDays(1).date(), Time.newInstance(9, 0, 0, 0));
            minutes = (nexDay.getTime() - now.getTime()) / 60000;
        } else if (isFriday) {
            Datetime monday = Datetime.newInstance(now.addDays(3).date(), Time.newInstance(9, 0, 0, 0));
            minutes = (monday.getTime() - now.getTime()) / 60000;
        }
        return minutes;
    }
}
