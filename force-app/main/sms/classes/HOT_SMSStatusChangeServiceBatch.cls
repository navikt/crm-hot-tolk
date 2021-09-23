public without sharing class HOT_SMSStatusChangeServiceBatch implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        HOT_SMSStatusChangeServiceBatch instance = new HOT_SMSStatusChangeServiceBatch();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        String query = 'SELECT ';
        query += 'Id, AccountId, HOT_Request__r.OrdererPhone__c, HOT_Request__r.Subject__c, Status ';
        query += 'FROM WorkOrder ';
        query += 'WHERE HOT_Request__r.OrdererPhone__c != null ';
        query += 'AND EndDate > :now ';
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
                System.scheduleBatch(
                    new HOT_SMSStatusChangeServiceBatch(),
                    'HOT_SMSStatusChangeServiceBatch',
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
