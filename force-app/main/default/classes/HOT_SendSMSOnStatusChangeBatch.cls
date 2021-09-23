// TODO: Figure out which statuses to filter (if any) - Ask Svenn Terje
// TODO: Figure out how often to run (every hour?) Ask Vegard about getMinutes()

public without sharing class HOT_SendSMSOnStatusChangeBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_SendSMSOnStatusChangeBatch instance = new HOT_SendSMSOnStatusChangeBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        Date horizonDate = Date.today().addDays(2);
        if (now.format('EEEE') == 'Friday') {
            horizonDate = Date.today().addDays(4);
        }
        String query = 'SELECT ';
        query += 'Id, AccountId, HOT_Request__r.OrdererPhone__c, StartDate, EndDate, Status ';
        query += 'FROM WorkOrder ';
        query += 'WHERE HOT_Request__r.OrdererPhone__c != null ';
        query += 'AND HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c = TRUE ';
        query += 'AND HOT_StatusChanged__c = TRUE';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<WorkOrder> records) {
        HOT_ReminderSMSService.sendSMSToOtherOrdererOnStatusUpdate(records);
    }

    public void finish(Database.BatchableContext bc) {
        Long minutes = getMinutes();
        if (!Test.isRunningTest()) {
            try {
                // TODO: Will this pick up fields from above or new fields with HOT_StatusChanged__c set to false again?
                System.scheduleBatch(
                    new HOT_SendSMSOnStatusChangeBatch(),
                    'HOT_SendSMSOnStatusChangeBatch',
                    (Integer) minutes,
                    10
                );
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
        if (isLast) {
            Datetime nextDay = Datetime.newInstance(now.addDays(1).date(), Time.newInstance(9, 0, 0, 0));
            minutes = (nextDay.getTime() - now.getTime()) / 60000;
            if (isFriday) {
                Datetime monday = Datetime.newInstance(now.addDays(3).date(), Time.newInstance(9, 0, 0, 0));
                minutes = (monday.getTime() - now.getTime()) / 60000;
            }
        } else if (isLastIsNext) {
            minutes = (datetime_1600.getTime() - now.getTime()) / 60000;
        }
        return minutes;
    }
}
