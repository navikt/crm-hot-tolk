public without sharing class HOT_InvoiceHandler extends MyTriggers {
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<HOT_Invoice__c> invoicesToNotify = new List<HOT_Invoice__c>();
        System.debug('går du inn her i trigger?');

        for (HOT_Invoice__c invoice : (List<HOT_Invoice__c>) records) {
            if (
                (triggerOldMap.get(invoice.Id).get('Status__c') != invoice.Status__c) &&
                (invoice.Status__c == 'Sent In Return')
            ) {
                invoicesToNotify.add(invoice);
            }
        }
        HOT_InvoiceNotification.sendInvoiceNotification(
            invoicesToNotify,
            'Sent In Return');
    }
}
