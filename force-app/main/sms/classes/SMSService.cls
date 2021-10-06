public with sharing class SMSService {
    public static SMS__c createSMSRecord(
        String domain,
        String type,
        Id accountId,
        Id workOrderId,
        String recipient,
        String message
    ) {
        SMS__c sms = new SMS__c();
        sms.Domain__c = domain;
        sms.Type__c = type;
        sms.Account__c = accountID;
        sms.WorkOrder__c = workOrderId;
        sms.Recipient__c = recipient;
        sms.Message__c = message;
        return sms;
    }
}
