public with sharing class DisableFreelanceUsersSchedulable implements Database.Batchable<sObject>, Schedulable{
      public void execute(SchedulableContext sc) {
        DisableFreelanceUsersSchedulable instance = new DisableFreelanceUsersSchedulable();
        database.executebatch(instance, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        Datetime oneYearAgo = now.addYears(-1);
         return Database.getQueryLocator(
            [
                SELECT Id, LastLoginDate FROM User WHERE Profile.Name='NAV Samhandler' AND LastLoginDate <= :oneYearAgo
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<User> records) {
        if (records.size() > 0) {
            for (User user : records) {
                user.IsActive = false;
            }
            
            try {
                update records;
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        
    }
}