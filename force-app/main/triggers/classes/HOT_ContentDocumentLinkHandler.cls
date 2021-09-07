public with sharing class HOT_ContentDocumentLinkHandler extends MyTriggers {
    // Har lagt til to triggere. Den ene skal brukes til TOLK-190, den andre til TOLK-1588.
    // Hvilken skal brukes hvor?
    public override void onBeforeInsert() {
        List<ContentDocumentLink> contentDocumentLinks = (List<ContentDocumentLink>) records;

    }
    
    public override void onAfterInsert() {
        List<ContentDocumentLink> contentDocumentLinks = (List<ContentDocumentLink>) records;
        
    }

    /*

    public void appendContentDocumentLinksToSA(List<ContentDocumentLink> contentDocumentLinks){

        List<ContentDocumentLink> cliLinkedToRequest = new List<contentDocumentLink>();
        List<HOT_Request__c> requestsWithCli = new List<HOT_Request__c>();
    

        HOT_Request__c requestObject = new HOT_Request__c();


        for (ContentDocumentLink cli : contentDocumentLinks){
             if (cli.LinkedEntityId.getSObjectType() == requestObject.getSObjectType()){
                cliLinkedToRequest.add(cli);
                requestsWithCli.add(cli.LinkedEntityId);
             }
        }

        */
        

        //List<HOT_Request__c> requests = [SELECT Id, ContentDocumentLinks  FROM HOT_Request__c WHERE Id IN :requestsWithCli] //AND Status__c = 'Godkjent']; //Active requests


        //List<ServiceAppointment> serviceAppointments = [SELECT Id, ContentDocumentLinks, HOT_Request__c FROM ServiceAppointment WHERE HOT_Request__c in :requests]; //ServiceAppointment-children to the active requests



    //}
    

}

