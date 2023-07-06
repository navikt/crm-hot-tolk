/**
 * Helper class for the Messaging solution
 * @Author Lars Petter Johnsen
 * @Date 20.05.2021
 */
public without sharing class HOT_MessageHelper {
    @AuraEnabled(cacheable=true)
    public static String getRecordObjectType(Id recordId) {
        String objectType = recordId.getSObjectType().getDescribe().getName();
        return objectType;
    }

    @AuraEnabled
    public static string getUserContactId() {
        return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()]?.ContactId;
    }
    @AuraEnabled
    public static String getAccountOnThread(Id recordId) {
        Thread__c thread= [SELECT CRM_Account__r.Name, CRM_Related_Object__c FROM Thread__c WHERE Id = :recordId LIMIT 1];
        Id search=thread.CRM_Related_Object__c;
        String objectType=String.valueOf(search.getsobjecttype());
        String result;
        if(objectType=='WorkOrder'){
            WorkOrder wo=[SELECT Id, HOT_Interpreters__c FROM WorkOrder WHERE Id=:search];
            result=wo.HOT_Interpreters__c;
        }
        else{
            result=thread.CRM_Account__r.Name;
        }
        return result;
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
    public static List<Thread__c> getThreadsCollection(Id recordId, Boolean singleThread, String type) {
        //Sjekker om bruker har tillatelse til å se samtalen
        // if (recordId.getSobjectType() == WorkOrder.sObjectType) {
        //     User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
        //     ServiceResource serviceResource =[Select Id, AccountId FROM ServiceResource WHERE AccountId=:currentUser.AccountId];
        //     if(serviceResource!=null){
        //         List<ServiceAppointment> serviceAppointments=[Select HOT_WorkOrderLineItem__r.WorkOrderId FROM ServiceAppointment WHERE HOT_ServiceResource__c=:serviceResource.Id AND HOT_WorkOrderLineItem__r.WorkOrderId=:recordId];
        //         if(serviceAppointments.size()==0){
        //             throw new AuraHandledException('Du har ikke tilgang til denne samtalen');
        //         }
        //     }
        // }
        String objectType=String.valueOf(recordId.getsobjecttype());
        if(objectType=='Thread__c'){
            return getThreadFromThreadId(recordId);
        }
        if (singleThread == true && type!='') {
            return getSingleThread(recordId, type);
        } else {
            return getThreads(recordId);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getThreads(Id recordId) {
        List<Thread__c> threadList;
        try {
            threadList = [
                SELECT Id, CRM_Number_of_External_Messages__c, CRM_Related_Object__c, CRM_isActive__c, CRM_Type__c
                FROM Thread__c
                WHERE CRM_Related_Object__c = :recordId AND (CRM_Type__c = 'HOT_BRUKER-FORMIDLER' OR CRM_Type__c = 'HOT_BRUKER-TOLK' OR CRM_Type__c = 'HOT_BESTILLER-FORMIDLER' OR CRM_Type__c = 'HOT_TOLK-FORMIDLER' OR CRM_Type__c = 'HOT_TOLK-RESSURSKONTOR' OR CRM_Type__c='HOT_BRUKER-BESTILLER' OR CRM_Type__c='HOT_TOLK-TOLK')
            ];
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
        return threadList;
    }
    @AuraEnabled(cacheable=true)
    public static List<HOT_Request__c> getRequestInformation(Id recordId) {
        List<HOT_Request__c> request= [
                SELECT Id, IsAccountEqualOrderer__c
                FROM HOT_Request__c
                WHERE Id= :recordId
            ];
        return request;
    }
      @AuraEnabled(cacheable=true)
    public static List<WorkOrder> getWorkOrderInformation(Id recordId) {
        List<WorkOrder> wo= [
                SELECT Id, HOT_TotalNumberOfInterpreters__c
                FROM WorkOrder
                WHERE Id= :recordId
            ];
        return wo;
    }
     @AuraEnabled(cacheable=true)
    public static List<Thread__c> getSingleThread(Id recordId, String type) {
        try {
            List<Thread__c> t = [
                SELECT Id, CRM_Number_of_External_Messages__c, CRM_Related_Object__c, CRM_isActive__c
                FROM Thread__c
                WHERE CRM_Related_Object__c = :recordId AND CRM_Type__c =:type
                LIMIT 1
            ];
            return t;
            
        } catch (Exception e) {
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getThreadFromThreadId(Id recordId) {
        try {
            List<Thread__c> t = [
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
    //Orderer, interpreter, user users use this
    @AuraEnabled(cacheable=false)
    public static Thread__c createThread(Id recordId, Id accountId) {
        Thread__c thread = new Thread__c();
        String objectType=String.valueOf(recordId.getsobjecttype());
        if(objectType=='WorkOrder'){
            WorkOrder wo=[SELECT Subject, HOT_Request__r.Dispatcher__c FROM WorkOrder WHERE Id=:recordId LIMIT 1];
            thread.CRM_Related_Object__c = recordId;
            thread.HOT_WorkOrder__c=recordId;
            thread.HOT_Title__c=wo.Subject;
            thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
            thread.CRM_Account__c = accountId;
            thread.HOT_WorkOrder__c=recordId;
            thread.HOT_Dispatcher__c=wo.HOT_Request__r.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if(objectType=='HOT_Request__c'){
            User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            HOT_Request__c request=[SELECT Subject__c, Dispatcher__c, IsAccountEqualOrderer__c, Orderer__c FROM HOT_Request__c WHERE Id=:recordId LIMIT 1];
            thread.CRM_Related_Object__c = recordId;
            if(request.IsAccountEqualOrderer__c==false && request.Orderer__c==currentUser.AccountId){
                thread.CRM_Thread_Type__c = 'HOT_BESTILLER-FORMIDLER';
                accountId = request.Orderer__c;
                thread.HOT_Request__c=recordId;
            }
            else{
                 thread.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
                 thread.HOT_Request__c=recordId;
            }
            thread.CRM_Account__c = accountId;
            thread.HOT_Title__c=request.Subject__c;
            thread.HOT_Dispatcher__c=request.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if(objectType=='ServiceAppointment'){
            ServiceAppointment serviceAppointment=[SELECT Subject, HOT_Account__c, HOT_WorkOrderLineItem__r.WorkOrderId, HOT_Request__r.Dispatcher__c FROM ServiceAppointment WHERE Id=:recordId LIMIT 1];
            thread.CRM_Related_Object__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
            thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
            thread.HOT_Title__c=serviceAppointment.Subject;
            thread.CRM_Account__c = serviceAppointment.HOT_Account__c; //?
            thread.HOT_ServiceAppointment__c=recordId;
            thread.HOT_Dispatcher__c=serviceAppointment.HOT_Request__r.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if(objectType=='HOT_WageClaim__c'){
            HOT_WageClaim__c wc=[SELECT ServiceAppointment__r.Subject FROM HOT_WageClaim__c WHERE Id=:recordId LIMIT 1];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR';
            thread.CRM_Account__c = accountId; //?
            thread.HOT_WageClaim__c=recordId;
            thread.HOT_Title__c=wc.ServiceAppointment__r.Subject;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        return thread;
    }
     //Dispatchers users use this
    @AuraEnabled(cacheable=false)
    public static Thread__c createThreadDispatcher(Id recordId, Id accountId, String type) {
        Thread__c thread = new Thread__c();
        String objectType=String.valueOf(recordId.getsobjecttype());
        if(objectType=='WorkOrder'){
            WorkOrder wo=[SELECT Subject, HOT_Request__r.Dispatcher__c FROM WorkOrder WHERE Id=:recordId LIMIT 1];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = type;
            if(type=='HOT_BRUKER-TOLK'){
                thread.CRM_Account__c = accountId;
            }
            thread.HOT_WorkOrder__c=recordId;
            thread.HOT_Title__c=wo.Subject;
            thread.HOT_Dispatcher__c=wo.HOT_Request__r.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if(objectType=='HOT_Request__c'){
            HOT_Request__c request=[SELECT Subject__c, Dispatcher__c, IsAccountEqualOrderer__c, Orderer__c FROM HOT_Request__c WHERE Id=:recordId LIMIT 1];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = type;
            thread.CRM_Account__c = type == 'HOT_BESTILLER-FORMIDLER' ? request.Orderer__c : accountId;
            thread.HOT_Request__c=recordId;
            thread.HOT_Title__c=request.Subject__c;
            thread.HOT_Dispatcher__c=request.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if(objectType=='ServiceAppointment'){ 
            List<HOT_InterestedResource__c> irList=[SELECT Id, ServiceAppointment__r.Subject, ServiceResource__r.AccountId, ServiceAppointment__r.HOT_Request__r.Dispatcher__c FROM HOT_InterestedResource__c WHERE (ServiceAppointment__c=:recordId AND ServiceAppointment__r.Status='Dispatched' AND Status__c='Assigned') OR (ServiceAppointment__c=:recordId AND Status__c='Canceled') OR (ServiceAppointment__c=:recordId AND Status__c='Canceled by Interpreter')OR (ServiceAppointment__c=:recordId AND Status__c='Cannot Complete') OR (ServiceAppointment__c=:recordId AND ServiceAppointment__r.Status='Completed' AND Status__c='Assigned')];
            if (irList.isEmpty()) {
                //=Ansatt-tolk
                AssignedResource ar=[SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource WHERE ServiceAppointmentId=:recordId];
                //ServiceResource sr=[SELECT Id, AccountId FROM ServiceResource WHERE Id=:ar.ServiceResourceId];
                ServiceAppointment sa=[SELECT Id, Subject, HOT_Request__r.Dispatcher__c FROM ServiceAppointment WHERE Id=:ar.ServiceAppointmentId];
                thread.CRM_Related_Object__c = recordId;
                thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
                //thread.CRM_Account__c = sr.AccountId;
                thread.HOT_Dispatcher__c=sa.HOT_Request__r.Dispatcher__c;
                thread.HOT_IsEmployeeThread__c=true;
                thread.HOT_ServiceAppointment__c=recordId;
                thread.HOT_Title__c=sa.Subject;
                
                HOT_DatabaseOperations.insertRecords(thread);

            } else {
                 thread.CRM_Related_Object__c = recordId;
                 thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
                 thread.CRM_Account__c = irList[0].ServiceResource__r.AccountId;
                 thread.HOT_ServiceAppointment__c=recordId;
                 thread.HOT_Title__c=irList[0].ServiceAppointment__r.Subject;
                 thread.HOT_Dispatcher__c=irList[0].ServiceAppointment__r.HOT_Request__r.Dispatcher__c;
                 HOT_DatabaseOperations.insertRecords(thread);
             }
            
        }
         if(objectType=='HOT_InterestedResource__c'){
            HOT_InterestedResource__c ir=[SELECT Id, ServiceAppointment__r.Subject, ServiceResource__r.AccountId, ServiceAppointment__r.HOT_Request__r.Dispatcher__c FROM HOT_InterestedResource__c WHERE Id=:recordId AND Status__c!='Assigned' AND Status__c!='Canceled' AND Status__c!='Canceled by Interpreter'];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
            thread.CRM_Account__c = ir.ServiceResource__r.AccountId;
            thread.HOT_InterestedResource__c=recordId;
            thread.HOT_Title__c=ir.ServiceAppointment__r.Subject;
            thread.HOT_Dispatcher__c=ir.ServiceAppointment__r.HOT_Request__r.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
         if(objectType=='HOT_WageClaim__c'){
            HOT_WageClaim__c wageClaim = [SELECT ServiceResource__r.AccountId, ServiceAppointment__r.Subject FROM HOT_WageClaim__c WHERE Id=:recordId];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR';
            thread.CRM_Account__c = wageClaim.ServiceResource__r.AccountId;
            thread.HOT_WageClaim__c=recordId;
            thread.HOT_Title__c=wageClaim.ServiceAppointment__r.Subject;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        return thread;
    }
     //Threads between interpreters and dispatcher. Interpreter use this
      @AuraEnabled(cacheable=false)
    public static Thread__c createThreadInterpreter(Id recordId) {
            Thread__c thread = new Thread__c();
            String objectType=String.valueOf(recordId.getsobjecttype());
        if(objectType=='HOT_InterestedResource__c'){
            HOT_InterestedResource__c ir=[SELECT Id, ServiceAppointment__r.Subject, ServiceResource__r.AccountId, ServiceAppointment__r.HOT_Request__r.Dispatcher__c FROM HOT_InterestedResource__c WHERE Id=:recordId];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
            thread.CRM_Account__c = ir.ServiceResource__r.AccountId;
            thread.HOT_InterestedResource__c=recordId;
            thread.HOT_Title__c=ir.ServiceAppointment__r.Subject;
            thread.HOT_Dispatcher__c=ir.ServiceAppointment__r.HOT_Request__r.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if(objectType=='ServiceAppointment'){
            User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            ServiceAppointment sr=[SELECT Subject, HOT_Request__r.Dispatcher__c FROM ServiceAppointment WHERE Id=:recordId];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
            thread.CRM_Account__c = currentUser.AccountId;
            thread.HOT_ServiceAppointment__c=recordId;
            thread.HOT_Title__c=sr.Subject;
            thread.HOT_Dispatcher__c=sr.HOT_Request__r.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        return thread;
    }
     //Threads between user and orderer
      @AuraEnabled(cacheable=false)
    public static Thread__c createThreadOrdererUser(Id recordId) {
            HOT_Request__c request=[SELECT Subject__c, Dispatcher__c, IsAccountEqualOrderer__c, Account__c FROM HOT_Request__c WHERE Id=:recordId LIMIT 1];
            Thread__c thread = new Thread__c();
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_BRUKER-BESTILLER';
            thread.CRM_Account__c = request.Account__c;
            thread.HOT_Request__c=recordId;
            thread.HOT_Title__c=request.Subject__c;
            thread.HOT_Dispatcher__c=request.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        
        return thread;
    }
      @AuraEnabled(cacheable=false)
    public static Thread__c createThreadInterpreters(Id recordId) {
            ServiceAppointment serviceAppointment=[SELECT Subject, HOT_WorkOrderLineItem__r.WorkOrderId, HOT_Request__r.Dispatcher__c FROM ServiceAppointment WHERE Id=:recordId LIMIT 1];
            Thread__c thread = new Thread__c();
            thread.CRM_Related_Object__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-TOLK';
            thread.HOT_Title__c=serviceAppointment.Subject;
            thread.HOT_Dispatcher__c=serviceAppointment.HOT_Request__r.Dispatcher__c;
            thread.HOT_WorkOrder__c=serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
            HOT_DatabaseOperations.insertRecords(thread);
        
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
    public static void markThreadAsRead(Id threadId, String userContactId) {
        Thread__c thread=[SELECT Id, HOT_Thread_read_by__c FROM Thread__c WHERE Id=:threadId];
        if (thread.HOT_Thread_read_by__c.contains(userContactId)){
            
         }
         else{
            thread.HOT_Thread_read_by__c=thread.HOT_Thread_read_by__c+userContactId+';';
         }
        try {
            update thread;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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
        Thread__c t = [SELECT Id, HOT_Last_message_from__c, HOT_Thread_read_by__c, CRM_Latest_Message_Datetime__c FROM Thread__c WHERE Id = :threadId];
        if(fromContactId=='tolk'){
            t.HOT_Last_message_from__c=null;
            t.HOT_Thread_read_by__c=fromContactId;
            t.CRM_Latest_Message_Datetime__c = Datetime.now();

        }
        else{
            t.HOT_Last_message_from__c=fromContactId;
            t.HOT_Thread_read_by__c=fromContactId+';';
            t.CRM_Latest_Message_Datetime__c = Datetime.now();
        }
        update t;
    }
     @AuraEnabled
public static Map<String, String> getRelatedObjectDetails(Id relatedRecordId) {
        Map<String, String> navigationhelp = new Map<String, String>();
        String workorderId;
        String objectType=String.valueOf(relatedRecordId.getsobjecttype());
        if(objectType=='WorkOrder'){
            User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            List<ServiceResource> serviceResource =[Select Id, AccountId FROM ServiceResource WHERE AccountId=:currentUser.AccountId];
            if(serviceResource.size()>0){
                List<ServiceAppointment> sa=[SELECT Id FROM ServiceAppointment WHERE HOT_WorkOrderLineItem__r.WorkOrderId=:relatedRecordId];
                if(sa.size()>0){
                    Boolean irFound = false;
                    for(ServiceAppointment serviceappointment: sa){
                        List<HOT_InterestedResource__c> ir=[SELECT Id, ServiceAppointment__c FROM HOT_InterestedResource__c WHERE (ServiceAppointment__c=:serviceappointment.Id AND ServiceResource__c=:serviceResource[0].Id)];
                        if(ir.size() > 0){
                            irFound = true;
                            navigationhelp.put(serviceappointment.Id,'SA');
                        }
                    }
                    if(!irFound) {
                        workorderId=relatedRecordId;    
                        navigationhelp.put(workorderId,'WO');                
                    }
                }else{
                    workorderId=relatedRecordId;
                    navigationhelp.put(workorderId,'WO');
                }
            }else{
                workorderId=relatedRecordId;
                navigationhelp.put(workorderId,'WO');
            }
        }
        if(objectType=='HOT_Request__c'){
            User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            WorkOrder workOrder=[Select Id, HOT_Request__r.IsAccountEqualOrderer__c, HOT_Request__r.Orderer__c FROM WorkOrder Where HOT_Request__c=:relatedRecordId LIMIT 1];
            HOT_Request__c request=[SELECT IsSerieoppdrag__c FROM HOT_Request__c WHERE Id=:relatedRecordId LIMIT 1];
            workorderId=workOrder.Id;
            if(workOrder.HOT_Request__r.IsAccountEqualOrderer__c==false && workOrder.HOT_Request__r.Orderer__c ==currentUser.AccountId){
                if(request.IsSerieoppdrag__c==false){
                    navigationhelp.put(workorderId,'Andre-WO'); 
                }
                else{
                    navigationhelp.put(workorderId,'Andre-R');
                }
                
            }
            else{
                if(request.IsSerieoppdrag__c==false){
                navigationhelp.put(workorderId,'WO');
            }
            else{
            navigationhelp.put(workorderId,'R'); 
            }
            }
        }
        if(objectType=='HOT_InterestedResource__c'){
            HOT_InterestedResource__c ir=[SELECT ServiceAppointment__c FROM HOT_InterestedResource__c WHERE Id=:relatedRecordId];
            navigationhelp.put(ir.ServiceAppointment__c,'IR'); 
        }
        if(objectType=='ServiceAppointment'){
            navigationhelp.put(relatedRecordId,'SA'); 
        }
        if(objectType=='HOT_WageClaim__c'){
            navigationhelp.put(relatedRecordId,'WC'); 
        }
        return navigationhelp;
}
}

