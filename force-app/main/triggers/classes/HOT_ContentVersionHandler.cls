/**
 * @description Class for handling the trigger on ContentVersion, used to share files to related records.
 */
public without sharing class HOT_ContentVersionHandler extends MyTriggers {
    /**
     * @description onAfterInsert trigger action
     */
    public override void onAfterInsert() {
        HOT_ContentVersionHandler.createDocumentLinks(((List<ContentVersion>) records));
    }
    /**
     * @descrioton method for creating ContentDocumentLink records related to HOT_Request__c records
     * when user is not an Orderer
     */
    @TestVisible
    private static void createDocumentLinks(List<ContentVersion> cvs) {
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        for (ContentVersion cv : cvs) {
            if (
                cv.HOT_RelatedRecordId_fileupload__c == null ||
                ((Id) cv.HOT_RelatedRecordId_fileupload__c).getSObjectType() != Schema.HOT_Request__c.getSObjectType()
            ) {
                continue;
            }
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = cv.HOT_RelatedRecordId_fileupload__c;
            cdl.Visibility = 'AllUsers';
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdls.add(cdl);
        }
        if (cdls.size() > 0) {
            insert cdls; //NOPMD
        }
    }
}
