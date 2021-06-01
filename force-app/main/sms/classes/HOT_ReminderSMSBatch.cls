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
        String CRON_EXP = getCronExpression();

        if (!Test.isRunningTest()) {
            try {
                System.schedule('HOT_ReminderSMSBatch', CRON_EXP, new HOT_ReminderSMSBatch());
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }

    private String getCronExpression() {
        Datetime now = Datetime.now();
        Datetime datetime_1600 = Datetime.newInstance(Date.today(), Time.newInstance(16, 0, 0, 0));
        Boolean isLast = (datetime_1600.getTime() - Datetime.now().getTime()) < 1800000;
        Integer hour = (now.hour() + 1);
        Integer daysUntilNextSchedule = (now.format('EEEE') == 'Friday' ? 3 : 1);
        Integer day = (isLast ? now.day() + daysUntilNextSchedule : now.day());
        Integer month = now.addDays(daysUntilNextSchedule).month();
        Integer year = now.addDays(daysUntilNextSchedule).year();
        return '0 0 ' +
            String.valueOf(hour) +
            ' ' +
            String.valueOf(day) +
            ' ' +
            String.valueOf(month) +
            ' ' +
            String.valueOf(year);
    }
}
