public with sharing class HOT_DisableFreelanceSchedulable implements Database.Batchable<sObject>, Schedulable{
      public void execute(SchedulableContext sc) {
        HOT_DisableFreelanceSchedulable instance = new HOT_DisableFreelanceSchedulable();
        database.executebatch(instance, 10);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime oneYearAgo = Datetime.now().addHours(-2);

         return Database.getQueryLocator(
            [
                SELECT Id, LastLoginDate, ProfileId FROM User WHERE Profile.Name='NAV Samhandler' AND (LastLoginDate <= :oneYearAgo OR LastLoginDate=null)
            ]
        );
    }
public void execute(Database.BatchableContext bc, List<User> records) {
    if (records.size() > 0) {
        List<ServiceResource> serviceResource=[SELECT Id,RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN: records AND HOT_IsFreelanceInterpreter__c=true];
        if(serviceResource.size()>0){
           

            for (ServiceResource sr : serviceResource) {
                sr.IsActive = false;
               
            }
            try{
                update serviceResource;
            }
            catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publish();
                System.debug('feil3'+e);
            }
 
    }

}
}

    public void finish(Database.BatchableContext bc) {
        
    }
}