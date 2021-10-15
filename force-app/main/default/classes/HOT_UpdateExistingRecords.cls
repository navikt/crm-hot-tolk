public class HOT_UpdateExistingRecords implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        return Database.getQueryLocator(
            'SELECT Id, HOT_TermsOfAgreement__c, ServiceAppointment__r.HOT_TermsOfAgreement__c FROM HOT_InterestedResource__c WHERE HOT_TermsOfAgreement__c = null AND ServiceAppointment__r.HOT_TermsOfAgreement__c != null'
            //           'SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntity.Type = \'HOT_Request__c\''
        );
    }
    public void execute(Database.BatchableContext bc, List<HOT_InterestedResource__c> records) {
        try {
            HOT_InterestedResourceHandler.copyTermsOfAgreementFromSAToIR(records);
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
