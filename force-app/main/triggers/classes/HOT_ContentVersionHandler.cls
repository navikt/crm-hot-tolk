public without sharing class HOT_ContentVersionHandler extends MyTriggers {
    public HOT_ContentVersionHandler() {
    }
    public override void onAfterInsert() {
        List<ContentVersion> cvs = ((List<ContentVersion>) records);
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
            insert cdls;
        }
    }
}
