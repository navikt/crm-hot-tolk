public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator(
            'SELECT Id, HOT_TermsOfAgreement__c, ServiceAppointment__r.HOT_TermsOfAgreement__c FROM HOT_InterestedResource__c WHERE HOT_TermsOfAgreement__c = null AND ServiceAppointment__r.HOT_TermsOfAgreement__c != null'
        );
    }

    public void execute(Database.BatchableContext bc, List<HOT_InterestedResource__c> irList) {
        for (HOT_InterestedResource__c ir : irList) {
            ir.HOT_TermsOfAgreement__c = ir.ServiceAppointment__r.HOT_TermsOfAgreement__c;
        }

        try {
            update irList;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}
