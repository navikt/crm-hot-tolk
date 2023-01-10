/**
 * Helper class for the Messaging solution
 * @Author Lars Petter Johnsen
 * @Date 20.05.2021
 */
public with sharing class HOT_MessageHelper {
    @AuraEnabled(cacheable=true)
    public static String getRecordObjectType(Id recordId) {
        String objectType = recordId.getSObjectType().getDescribe().getName();
        return objectType;
    }

    @AuraEnabled
    public static string getUserContactId() {
        return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()]?.ContactId;
    }
    @AuraEnabled (cacheable=true)
    public static Id getRequestId(Id recordId) {
        return [SELECT Id FROM WorkOrder WHERE WorkOrder.HOT_Request__r.Thread__c=:recordId]?.Id;
    }

    @AuraEnabled(cacheable=true)
    public static Id getAccountOnRequest(Id recordId) {
        return [SELECT Account__c FROM HOT_Request__c WHERE Id = :recordId]?.Account__c;
    }

    @AuraEnabled(cacheable=true)
    public static Id getAccountOnWorkOrder(Id recordId) {
        return [SELECT AccountId FROM WorkOrder WHERE Id = :recordId]?.AccountId;
    }

    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getThreadsCollection(Id recordId, Boolean singleThread) {
        //Sjekker om bruker har tillatelse til å se samtalen
        if (recordId.getSobjectType() == WorkOrder.sObjectType) {
            User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
            ServiceResource serviceResource =[Select Id, AccountId FROM ServiceResource WHERE AccountId=:currentUser.AccountId];
            if(serviceResource!=null){
                List<ServiceAppointment> serviceAppointments=[Select HOT_WorkOrderLineItem__r.WorkOrderId FROM ServiceAppointment WHERE HOT_ServiceResource__c=:serviceResource.Id AND HOT_WorkOrderLineItem__r.WorkOrderId=:recordId];
                if(serviceAppointments.size()==0){
                    throw new AuraHandledException('Du har ikke tilgang til denne samtalen');
                }
            }
        }
        // ---//
        if (singleThread == false) {
            return getThreads(recordId);
        } else {
            List<Thread__c> tList = new List<Thread__c>();
            tList.add(getSingleThread(recordId));
            return tList;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getThreads(Id recordId) {
        List<Thread__c> threadList;
        try {
            threadList = [
                SELECT Id, CRM_Number_of_External_Messages__c, CRM_Related_Object__c, CRM_isActive__c
                FROM Thread__c
                WHERE CRM_Related_Object__c = :recordId AND (CRM_Type__c = 'HOT_BRUKER-FORMIDLER' OR CRM_Type__c = 'HOT_BRUKER-TOLK')
            ];
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
        return threadList;
    }
    @AuraEnabled(cacheable=true)
    public static Thread__c getSingleThread(Id recordId) {
        try {
            if (recordId.getSobjectType() == Thread__c.sObjectType) {
                return getThreadFromThreadId(recordId);
            }
            Thread__c t = [
                SELECT Id, CRM_Number_of_External_Messages__c, CRM_Related_Object__c, CRM_isActive__c
                FROM Thread__c
                WHERE CRM_Related_Object__c = :recordId AND (CRM_Type__c = 'HOT_BRUKER-FORMIDLER' OR CRM_Type__c = 'HOT_BRUKER-TOLK')
                LIMIT 1
            ];

            return t;
        } catch (Exception e) {
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Thread__c getThreadFromThreadId(Id recordId) {
        try {
            Thread__c t = [
                SELECT Id, CRM_Number_of_External_Messages__c, CRM_Related_Object__c, CRM_isActive__c
                FROM Thread__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            return t;
        } catch (Exception e) {
            return null;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Thread__c createThread(Id recordId, Id accountId) {
       
        Thread__c thread = new Thread__c();
        String objectType=String.valueOf(recordId.getsobjecttype());
        if(objectType=='WorkOrder'){
            WorkOrder workOrder=[SELECT Subject FROM WorkOrder WHERE Id=:recordId LIMIT 1];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
            thread.CRM_Account__c = accountId;
            thread.HOT_Subject__c='Samtale tolk: '+workOrder.Subject;
            thread.HOT_WorkOrder__c=recordId;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if(objectType=='HOT_Request__c'){
            HOT_Request__c request=[SELECT Subject__c FROM HOT_Request__c WHERE Id=:recordId LIMIT 1];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
            thread.CRM_Account__c = accountId;
            thread.HOT_Subject__c= request.Subject__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if(objectType=='ServiceAppointment'){
            ServiceAppointment serviceAppointment=[SELECT Subject, HOT_Account__c, HOT_WorkOrderLineItem__r.WorkOrderId FROM ServiceAppointment WHERE Id=:recordId LIMIT 1];
            thread.CRM_Related_Object__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
            thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
            thread.CRM_Account__c = serviceAppointment.HOT_Account__c; //?
            thread.HOT_Subject__c= 'Samtale frilanstolk: '+serviceAppointment.Subject;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        //Finne ut om det er request eller workorder object
        return thread;
    }

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
    @AuraEnabled(cacheable=true)
    public static string getUserLisenceType(Id userId) {
        try {
            String userLicenseType = [SELECT UserType FROM User WHERE Id = :userId LIMIT 1].UserType;
            return userLicenseType;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * Method for marking unread messages - called onload fromt the end user perspective. Does only represent customer read.
     * @Lars Petter Johnsen
     * @Date 31052021
     */
    @AuraEnabled
    public static void markAsRead(Id threadId) {
        List<Message__c> msgList = [
            SELECT Id, CRM_Read__c, CRM_Read_Datetime__c
            FROM Message__c
            WHERE CRM_Read__c = FALSE AND CRM_Thread__c = :threadId
        ];
        for (Message__c msg : msgList) {
            msg.CRM_Read__c = true;
            msg.CRM_Read_Datetime__c = DateTime.now();
        }
        try {
            update msgList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
     @AuraEnabled
    public static boolean isUserOwnerOfLastMessage(Id threadId) {
        Message__c message=[SELECT Id, CRM_From_Contact__c FROM Message__c WHERE CRM_Thread__c=:threadId ORDER BY Id DESC LIMIT 1];
        User user = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if(message.CRM_From_Contact__c==user.ContactId){
            return true;
        }
        return false;
    }
    /**
     * Method for marking unread messages by NAV
     * @Eirik Fladby
     * @Date 06.05.2022
     */
    @AuraEnabled
    public static void markAsReadByNav(Id threadId) {
        List<Message__c> msgList = [
            SELECT Id, CRM_Read_By_Nav__c, CRM_Read_By_Nav_Datetime__c
            FROM Message__c
            WHERE CRM_Read_By_Nav__c = FALSE AND CRM_Thread__c = :threadId
        ];
        for (Message__c msg : msgList) {
            msg.CRM_Read_By_Nav__c = true;
            msg.CRM_Read_By_Nav_Datetime__c = DateTime.now();
        }
        try {
            update msgList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Creates a message
     * Used in the community components
     * @Author Lars Petter Johnsen
     */
    @AuraEnabled
    public static Boolean createMessage(Id threadId, String messageText, Id fromContactId) {
        Message__c m = new Message__c();
        m.CRM_Message_Text__c = messageText;
        m.CRM_Thread__c = threadId;
        m.CRM_From_Contact__c = fromContactId;

        
        m.CRM_Read__c = false;
        m.CRM_Read_Datetime__c = DateTime.now();

        Thread__c t = [SELECT Id, CRM_isActive__c FROM Thread__c WHERE Id = :threadId LIMIT 1][0];
        if (!t.CRM_isActive__c) {
            return false;
        }

        try {
            insert m;
            return true;
        
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void setLastMessageFrom(String threadId, String fromContactId) {
        Thread__c t = [SELECT Id, HOT_Last_message_from__c FROM Thread__c WHERE Id = :threadId];
        if(fromContactId=='tolk'){
            t.HOT_Last_message_from__c=null;
        }
        else{
            t.HOT_Last_message_from__c=fromContactId;
        }
        update t;
    }
}
