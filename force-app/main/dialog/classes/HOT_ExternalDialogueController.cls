public with sharing class HOT_ExternalDialogueController {
    
    @AuraEnabled(cacheable=true)
    public static List<Message__c> getMessagesFromThread(Id threadId) {
        try {
            List<Message__c> msgList = new List<Message__c>();
            for (Message__c m : [
                SELECT
                    Id,
                    CRM_Message_Text__c,
                    CRM_Type__c,
                    CRM_Event_Type__c,
                    CRM_Sent_date__c,
                    CRM_From_User__c,
                    CRM_From_Contact__c,
                    CRM_From_First_Name__c,
                    CRM_External_Message__c,
                    CRM_From_Label__c,
                    HOT_UserRole__c
                FROM Message__c
                WHERE CRM_Thread__c = :threadId
                ORDER BY CRM_Sent_date__c ASC
            ]) {
                if (m.CRM_Message_Text__c != null) {
                    msgList.add(m);
                }
            }
            return msgList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
}
