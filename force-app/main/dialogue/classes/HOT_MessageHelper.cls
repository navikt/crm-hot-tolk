public without sharing class HOT_MessageHelper {
    @AuraEnabled(cacheable=true)
    public static String getRecordObjectType(Id recordId) {
        String objectType = recordId.getSObjectType().getDescribe().getName();
        return objectType;
    }

    @AuraEnabled(cacheable=true)
    public static string getUserContactId() {
        return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()]?.ContactId;
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
        String objectType = String.valueOf(recordId.getsobjecttype());
        if (objectType == 'Thread__c') {
            return getThreadFromThreadId(recordId);
        }
        if (singleThread == true && type != '') {
            return getSingleThread(recordId, type);
        } else {
            return getThreads(recordId);
        }
    }

    public static List<Thread__c> getThreads(Id recordId) {
        List<Thread__c> threadList;
        try {
            threadList = [
                SELECT Id, CRM_Number_of_External_Messages__c, CRM_Related_Object__c, CRM_isActive__c, CRM_Type__c
                FROM Thread__c
                WHERE
                    CRM_Related_Object__c = :recordId
                    AND (CRM_Type__c = 'HOT_BRUKER-FORMIDLER'
                    OR CRM_Type__c = 'HOT_BRUKER-TOLK'
                    OR CRM_Type__c = 'HOT_BESTILLER-FORMIDLER'
                    OR CRM_Type__c = 'HOT_TOLK-FORMIDLER'
                    OR CRM_Type__c = 'HOT_TOLK-RESSURSKONTOR'
                    OR CRM_Type__c = 'HOT_BRUKER-BESTILLER'
                    OR CRM_Type__c = 'HOT_TOLK-TOLK')
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
        //sjekke om det er formidler
        List<HOT_Request__c> request = [
            SELECT Id, IsAccountEqualOrderer__c, Account__c, Orderer__c
            FROM HOT_Request__c
            WHERE Id = :recordId
        ];
        return request;
    }
    @AuraEnabled(cacheable=true)
    public static List<WorkOrder> getWorkOrderInformation(Id recordId) {
        List<WorkOrder> wo = [SELECT Id, HOT_TotalNumberOfInterpreters__c FROM WorkOrder WHERE Id = :recordId];
        return wo;
    }
    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getSingleThread(Id recordId, String type) {
        try {
            List<Thread__c> t = [
                SELECT Id, CRM_Number_of_External_Messages__c, CRM_Related_Object__c, CRM_isActive__c
                FROM Thread__c
                WHERE CRM_Related_Object__c = :recordId AND CRM_Type__c = :type
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
    /**
     * @description geting recordtype id for HOT Thread
     * @return Id
     */
    public static Id getHOTThreadRecordType() {
        return Schema.SObjectType.Thread__c.getRecordTypeInfosByDeveloperName().get('HOT_Thread').getRecordTypeId();
    }
    //Orderer, interpreter, user users use this
    @AuraEnabled(cacheable=false)
    public static Thread__c createThread(Id recordId, Id accountId) {
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        String objectType = String.valueOf(recordId.getsobjecttype());
        if (objectType == 'WorkOrder') {
            WorkOrder wo = [SELECT Subject, HOT_Request__r.Dispatcher__c FROM WorkOrder WHERE Id = :recordId LIMIT 1];
            thread.CRM_Related_Object__c = recordId;
            thread.HOT_WorkOrder__c = recordId;
            thread.HOT_Title__c = wo.Subject;
            thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
            thread.CRM_Account__c = accountId;
            thread.HOT_WorkOrder__c = recordId;
            thread.HOT_Dispatcher__c = wo.HOT_Request__r.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if (objectType == 'HOT_Request__c') {
            User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            HOT_Request__c request = [
                SELECT Subject__c, Dispatcher__c, IsAccountEqualOrderer__c, Orderer__c
                FROM HOT_Request__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            thread.CRM_Related_Object__c = recordId;
            if (request.IsAccountEqualOrderer__c == false && request.Orderer__c == currentUser.AccountId) {
                thread.CRM_Thread_Type__c = 'HOT_BESTILLER-FORMIDLER';
                accountId = request.Orderer__c;
                thread.HOT_Request__c = recordId;
            } else {
                thread.CRM_Thread_Type__c = 'HOT_BRUKER-FORMIDLER';
                thread.HOT_Request__c = recordId;
            }
            thread.CRM_Account__c = accountId;
            thread.HOT_Title__c = request.Subject__c;
            thread.HOT_Dispatcher__c = request.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if (objectType == 'ServiceAppointment') {
            ServiceAppointment serviceAppointment = [
                SELECT Subject, HOT_Account__c, HOT_WorkOrderLineItem__r.WorkOrderId, HOT_Request__r.Dispatcher__c
                FROM ServiceAppointment
                WHERE Id = :recordId
                LIMIT 1
            ];
            thread.CRM_Related_Object__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
            thread.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
            thread.HOT_Title__c = serviceAppointment.Subject;
            thread.CRM_Account__c = serviceAppointment.HOT_Account__c; //?
            thread.HOT_ServiceAppointment__c = recordId;
            thread.HOT_Dispatcher__c = serviceAppointment.HOT_Request__r.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if (objectType == 'HOT_WageClaim__c') {
            HOT_WageClaim__c wc = [
                SELECT ServiceAppointment__r.Subject
                FROM HOT_WageClaim__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR';
            thread.CRM_Account__c = accountId; //?
            thread.HOT_WageClaim__c = recordId;
            thread.HOT_Title__c = wc.ServiceAppointment__r.Subject;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        return thread;
    }
    //Dispatchers users use this
    @AuraEnabled(cacheable=false)
    public static Thread__c createThreadDispatcher(Id recordId, Id accountId, String type) {
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        String objectType = String.valueOf(recordId.getsobjecttype());
        if (objectType == 'WorkOrder') {
            WorkOrder wo = [SELECT Subject, HOT_Request__r.Dispatcher__c FROM WorkOrder WHERE Id = :recordId LIMIT 1];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = type;
            if (type == 'HOT_BRUKER-TOLK') {
                thread.CRM_Account__c = accountId;
            }
            thread.HOT_WorkOrder__c = recordId;
            thread.HOT_Title__c = wo.Subject;
            thread.HOT_Dispatcher__c = wo.HOT_Request__r.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if (objectType == 'HOT_Request__c') {
            HOT_Request__c request = [
                SELECT Subject__c, Dispatcher__c, IsAccountEqualOrderer__c, Orderer__c
                FROM HOT_Request__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = type;
            thread.CRM_Account__c = type == 'HOT_BESTILLER-FORMIDLER' ? request.Orderer__c : accountId;
            thread.HOT_Request__c = recordId;
            thread.HOT_Title__c = request.Subject__c;
            thread.HOT_Dispatcher__c = request.Dispatcher__c;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        if (objectType == 'ServiceAppointment') {
            List<HOT_InterestedResource__c> irList = [
                SELECT
                    Id,
                    ServiceAppointment__r.Subject,
                    ServiceResource__r.AccountId,
                    ServiceAppointment__r.HOT_Request__r.Dispatcher__c
                FROM HOT_InterestedResource__c
                WHERE
                    (ServiceAppointment__c = :recordId
                    AND ServiceAppointment__r.Status = 'Dispatched'
                    AND Status__c = 'Assigned')
                    OR (ServiceAppointment__c = :recordId
                    AND ServiceAppointment__r.Status = 'Completed'
                    AND Status__c = 'Assigned')
            ];
            if (irList.isEmpty()) {
                //=Ansatt-tolk
                List<HOT_InterestedResource__c> existingIrNoEmployeeList = [
                    SELECT
                        Id,
                        ServiceAppointment__r.Subject,
                        ServiceResource__c,
                        ServiceAppointment__r.HOT_Request__r.Dispatcher__c
                    FROM HOT_InterestedResource__c
                    WHERE ServiceAppointment__c = :recordId
                ];

                AssignedResource ar = [
                    SELECT Id, ServiceAppointmentId, ServiceResourceId
                    FROM AssignedResource
                    WHERE ServiceAppointmentId = :recordId
                ];
                for (HOT_InterestedResource__c ir : existingIrNoEmployeeList) {
                    if (ir.ServiceResource__c == ar.ServiceResourceId) {
                        throw new AuraHandledException('no employee');
                    }
                }
                ServiceAppointment sa = [
                    SELECT Id, Subject, HOT_Request__r.Dispatcher__c, HOT_ServiceResource__c
                    FROM ServiceAppointment
                    WHERE Id = :ar.ServiceAppointmentId
                ];
                thread.CRM_Related_Object__c = recordId;
                thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
                thread.HOT_Dispatcher__c = sa.HOT_Request__r.Dispatcher__c;
                thread.HOT_IsEmployeeThread__c = true;
                thread.HOT_ServiceResource__c = sa.HOT_ServiceResource__c;
                thread.HOT_ServiceAppointment__c = recordId;
                thread.HOT_Title__c = sa.Subject;

                HOT_DatabaseOperations.insertRecords(thread);
            } else {
                thread.CRM_Related_Object__c = recordId;
                thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
                thread.CRM_Account__c = irList[0].ServiceResource__r.AccountId;
                thread.HOT_ServiceAppointment__c = recordId;
                thread.HOT_Title__c = irList[0].ServiceAppointment__r.Subject;
                thread.HOT_Dispatcher__c = irList[0].ServiceAppointment__r.HOT_Request__r.Dispatcher__c;
                HOT_DatabaseOperations.insertRecords(thread);
            }
        }
        if (objectType == 'HOT_InterestedResource__c') {
            HOT_InterestedResource__c ir = [
                SELECT
                    Id,
                    ServiceAppointment__r.Subject,
                    ServiceResource__r.AccountId,
                    ServiceAppointment__r.HOT_Request__r.Dispatcher__c,
                    ServiceAppointment__c
                FROM HOT_InterestedResource__c
                WHERE Id = :recordId AND Status__c != 'Assigned' AND Status__c != 'Reserved'
            ];
            List<Thread__c> checkExistingThreads = [
                SELECT Id, CRM_Account__c, HOT_ServiceAppointment__c
                FROM Thread__c
                WHERE
                    CRM_Account__c = :ir.ServiceResource__r.AccountId
                    AND HOT_ServiceAppointment__c = :ir.ServiceAppointment__c
            ];
            if (checkExistingThreads.size() == 0) {
                thread.CRM_Related_Object__c = recordId;
                thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
                thread.CRM_Account__c = ir.ServiceResource__r.AccountId;
                thread.HOT_InterestedResource__c = recordId;
                thread.HOT_Title__c = ir.ServiceAppointment__r.Subject;
                thread.HOT_Dispatcher__c = ir.ServiceAppointment__r.HOT_Request__r.Dispatcher__c;
                HOT_DatabaseOperations.insertRecords(thread);
            } else {
                throw new AuraHandledException('thread exist');
            }
        }
        if (objectType == 'HOT_WageClaim__c') {
            HOT_WageClaim__c wageClaim = [
                SELECT ServiceResource__r.AccountId, ServiceAppointment__r.Subject
                FROM HOT_WageClaim__c
                WHERE Id = :recordId
            ];
            thread.CRM_Related_Object__c = recordId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-RESSURSKONTOR';
            thread.CRM_Account__c = wageClaim.ServiceResource__r.AccountId;
            thread.HOT_WageClaim__c = recordId;
            thread.HOT_Title__c = wageClaim.ServiceAppointment__r.Subject;
            HOT_DatabaseOperations.insertRecords(thread);
        }
        return thread;
    }
    //Threads between interpreters and dispatcher. Interpreter use this
    @AuraEnabled(cacheable=false)
    public static Thread__c createThreadInterpreter(Id recordId) {
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

        Set<Id> srIdList = new Map<ID, ServiceResource>(
                [SELECT Id, HOT_IsEmployedInterpreter__c FROM ServiceResource WHERE RelatedRecordId = :currentUser.Id]
            )
            .keySet();
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        String objectType = String.valueOf(recordId.getsobjecttype());
        if (objectType == 'HOT_InterestedResource__c') {
            HOT_InterestedResource__c ir = [
                SELECT
                    Id,
                    ServiceAppointment__r.Subject,
                    ServiceResource__c,
                    ServiceResource__r.AccountId,
                    ServiceAppointment__r.HOT_Request__r.Dispatcher__c
                FROM HOT_InterestedResource__c
                WHERE Id = :recordId
            ];
            if (srIdList.contains(ir.ServiceResource__c)) {
                thread.CRM_Related_Object__c = recordId;
                thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
                thread.CRM_Account__c = ir.ServiceResource__r.AccountId;
                thread.HOT_InterestedResource__c = recordId;
                thread.HOT_Title__c = ir.ServiceAppointment__r.Subject;
                thread.HOT_Dispatcher__c = ir.ServiceAppointment__r.HOT_Request__r.Dispatcher__c;
                HOT_DatabaseOperations.insertRecords(thread);
            }
        }
        if (objectType == 'ServiceAppointment') {
            HOT_InterestedResource__c interestedResource = [
                SELECT
                    Id,
                    Status__c,
                    ServiceResource__c,
                    ServiceAppointment__c,
                    ServiceAppointment__r.Subject,
                    ServiceAppointment__r.HOT_Request__r.Dispatcher__c
                FROM HOT_InterestedResource__c
                WHERE ServiceResource__c IN :srIdList AND ServiceAppointment__c = :recordId
            ];
            if (interestedResource.Status__c == 'Assigned') {
                ServiceAppointment sr = [
                    SELECT Subject, HOT_Request__r.Dispatcher__c
                    FROM ServiceAppointment
                    WHERE Id = :recordId
                ];
                thread.CRM_Related_Object__c = recordId;
                thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
                thread.CRM_Account__c = currentUser.AccountId;
                thread.HOT_ServiceAppointment__c = recordId;
                thread.HOT_Title__c = sr.Subject;
                thread.HOT_Dispatcher__c = sr.HOT_Request__r.Dispatcher__c;
                HOT_DatabaseOperations.insertRecords(thread);
            } else {
                thread.CRM_Related_Object__c = interestedResource.Id;
                thread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
                thread.CRM_Account__c = currentUser.AccountId;
                thread.HOT_InterestedResource__c = interestedResource.Id;
                thread.HOT_Title__c = interestedResource.ServiceAppointment__r.Subject;
                thread.HOT_Dispatcher__c = interestedResource.ServiceAppointment__r.HOT_Request__r.Dispatcher__c;
                HOT_DatabaseOperations.insertRecords(thread);
            }
        }
        return thread;
    }
    //Threads between user and orderer
    //DENNE DIALOGTYPEN ER IKKE I BRUK MEN LIGGER KLAR.
    @AuraEnabled(cacheable=false)
    public static Thread__c createThreadOrdererUser(Id recordId) {
        HOT_Request__c request = [
            SELECT Subject__c, Dispatcher__c, IsAccountEqualOrderer__c, Account__c
            FROM HOT_Request__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Related_Object__c = recordId;
        thread.CRM_Thread_Type__c = 'HOT_BRUKER-BESTILLER';
        thread.CRM_Account__c = request.Account__c;
        thread.HOT_Request__c = recordId;
        thread.HOT_Title__c = request.Subject__c;
        thread.HOT_Dispatcher__c = request.Dispatcher__c;
        HOT_DatabaseOperations.insertRecords(thread);

        return thread;
    }
    @AuraEnabled(cacheable=false)
    public static Thread__c createThreadInterpreters(Id recordId) {
        List<ServiceResource> serviceResourceList = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];

        ServiceAppointment serviceAppointment = [
            SELECT Subject, HOT_WorkOrderLineItem__r.WorkOrderId, HOT_Request__r.Dispatcher__c
            FROM ServiceAppointment
            WHERE Id = :recordId
            LIMIT 1
        ];
        List<AssignedResource> arList = [
            SELECT ServiceResourceId, ServiceAppointmentId
            FROM AssignedResource
            WHERE ServiceResourceId IN :serviceResourceList AND ServiceAppointmentId = :serviceAppointment.Id
        ];
        if (arList.size() != 0) {
            Thread__c thread = new Thread__c();
            thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
            thread.CRM_Related_Object__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
            thread.CRM_Thread_Type__c = 'HOT_TOLK-TOLK';
            thread.HOT_Title__c = serviceAppointment.Subject;
            thread.HOT_Dispatcher__c = serviceAppointment.HOT_Request__r.Dispatcher__c;
            thread.HOT_WorkOrder__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
            HOT_DatabaseOperations.insertRecords(thread);

            return thread;
        } else {
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Message__c> getMessagesFromThread(Id threadId) {
        if (HOT_ThreadDetailController.checkAccess(threadId)) {
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
                        CRM_From_User__r.Name,
                        CRM_From_Contact__c,
                        CRM_From_Contact__r.Name,
                        CRM_From_First_Name__c,
                        CRM_External_Message__c,
                        CRM_From_Label__c,
                        HOT_User_Role__c
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
        } else {
            return null;
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
    @AuraEnabled
    public static void markAsRead(Id threadId) {
        if (HOT_ThreadDetailController.checkAccess(threadId)) {
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
    }
    @AuraEnabled
    public static void markThreadAsRead(Id threadId, String userContactId) {
        if (threadId == null || String.isBlank(userContactId)) {
            return;
        }
        if (!HOT_ThreadDetailController.checkAccess(threadId)) {
            return;
        }
        Thread__c thread = [SELECT Id, HOT_Thread_read_by__c FROM Thread__c WHERE Id = :threadId];
        if (String.isBlank(thread.HOT_Thread_read_by__c) || !thread.HOT_Thread_read_by__c.contains(userContactId)) {
            thread.HOT_Thread_read_by__c = (thread.HOT_Thread_read_by__c ?? '') + userContactId + ';';
            try {
                update thread;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }

    @AuraEnabled
    public static void markThreadAsReadEmployee(Id threadId) {
        User user = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        Thread__c thread = [
            SELECT Id, HOT_Thread_read_by__c, HOT_ParticipantIds__c
            FROM Thread__c
            WHERE Id = :threadId
        ];

        if (
            (String.isBlank(thread.HOT_Thread_read_by__c) || !thread.HOT_Thread_read_by__c.contains(user.Id)) &&
            (user.Profile.Name == 'HOT Tolk Formidler' ||
            (!String.isBlank(thread.HOT_ParticipantIds__c) && thread.HOT_ParticipantIds__c.contains(user.Id)))
        ) {
            thread.HOT_Thread_read_by__c = (thread.HOT_Thread_read_by__c ?? '') + user.Id + ';';
            try {
                update thread;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }

    @AuraEnabled
    public static void markAsReadByNav(Id threadId) {
        if (!HOT_ThreadDetailController.checkAccess(threadId)) {
            return;
        }
        List<Thread__c> thread = [
            SELECT Id, CRM_Related_Object__c, HOT_ServiceAppointment__c, HOT_ParticipantIds__c
            FROM Thread__c
            WHERE Id = :threadId
        ];
        if (thread.size() == 0) {
            return;
        }
        Thread__c t = thread[0];
        if (t.HOT_ServiceAppointment__c == null) {
            markMessagesAsReadByNav(threadId);
            return;
        }

        List<AssignedResource> ar = [
            SELECT ServiceAppointmentId, ServiceResourceId
            FROM AssignedResource
            WHERE
                ServiceAppointmentId = :t.CRM_Related_Object__c
                AND ServiceResource.RelatedRecordId = :UserInfo.getUserId()
        ];
        if (ar.size() != 0) {
            return;
        }
        Boolean isParticipant =
            t.HOT_ParticipantIds__c != null && t.HOT_ParticipantIds__c.contains(UserInfo.getUserId());
        if (isParticipant) {
            return;
        }

        markMessagesAsReadByNav(threadId);
    }

    public static void markMessagesAsReadByNav(Id threadId) {
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
    @AuraEnabled
    public static String getUserNameRole() {
        String userNameRole = '';
        User user = [SELECT Id, FirstName, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        if (user.Profile.Name == 'HOT Tolk Formidler') {
            userNameRole = user.FirstName + ', Formidler';
        } else if (user.Profile.Name == 'HOT Tolk Ansatt') {
            userNameRole = user.FirstName + ', Tolk';
        } else if (user.Profile.Name == 'NAV Samhandler') {
            userNameRole = user.FirstName + ', Tolk';
        } else if (user.Profile.Name == 'NAV Bruker') {
            userNameRole = user.FirstName + ', Tolkebruker';
        } else if (user.Profile.Name == 'NAV Bruker Plus') {
            userNameRole = user.FirstName + ', Tolkebruker';
        } else {
            userNameRole = user.FirstName + ', Administrator';
        }
        return userNameRole;
    }
    @AuraEnabled
    public static String getUserProfileAndName(String threadType) {
        User user = [SELECT Id, FirstName, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        if (user.Profile.Name == 'HOT Tolk Formidler') {
            return user.FirstName + ', Formidler';
        } else if (user.Profile.Name == 'HOT Tolk Ansatt') {
            return user.FirstName + ', Tolk';
        } else if (user.Profile.Name == 'NAV Samhandler' && threadType == 'HOT_BESTILLER-FORMIDLER') {
            return user.FirstName + ', Bestiller';
        } else if (user.Profile.Name == 'NAV Bruker' && threadType == 'HOT_BRUKER-FORMIDLER') {
            return user.FirstName + ', Tolkebruker';
        } else if (user.Profile.Name == 'NAV Bruker' && threadType == 'HOT_BESTILLER-FORMIDLER') {
            return user.FirstName + ', Bestiller';
        } else if (user.Profile.Name == 'NAV Bruker Plus' && threadType == 'HOT_BRUKER-FORMIDLER') {
            return user.FirstName + ', Tolkebruker';
        } else if (user.Profile.Name == 'NAV Bruker Plus' && threadType == 'HOT_BESTILLER-FORMIDLER') {
            return user.FirstName + ', Bestiller';
        } else if (user.Profile.Name == 'NAV Samhandler') {
            return user.FirstName + ', Tolk';
        } else if (user.Profile.Name == 'NAV Bruker') {
            return user.FirstName + ', Tolkebruker';
        } else if (user.Profile.Name == 'NAV Bruker Plus') {
            return user.FirstName + ', Tolkebruker';
        } else {
            return user.FirstName + ', Administrator';
        }
    }
    @AuraEnabled
    public static Boolean createMessage(Id threadId, String messageText, Id fromContactId) {
        if (HOT_ThreadDetailController.checkAccess(threadId)) {
            Thread__c t = [
                SELECT Id, CRM_isActive__c, CRM_Thread_Type__c
                FROM Thread__c
                WHERE Id = :threadId
                LIMIT 1
            ][0];
            Message__c m = new Message__c();
            m.CRM_Message_Text__c = messageText;
            m.CRM_Thread__c = threadId;
            m.CRM_From_Contact__c = fromContactId;
            m.CRM_Read__c = false;
            m.HOT_User_Role__c = getUserProfileAndName(t.CRM_Thread_Type__c);
            m.CRM_Read_Datetime__c = DateTime.now();

            if (!t.CRM_isActive__c) {
                return false;
            }

            try {
                insert m;
                return true;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        } else {
            return false;
        }
    }
    public static Message__c createMessages(Id threadId, String messageText, Id fromContactId) {
        Thread__c t = [SELECT Id, CRM_Thread_Type__c FROM Thread__c WHERE Id = :threadId LIMIT 1][0];

        Message__c m = new Message__c();
        m.CRM_Message_Text__c = messageText;
        m.CRM_Thread__c = threadId;
        m.CRM_From_Contact__c = fromContactId;
        m.CRM_Read__c = false;
        m.CRM_Read_Datetime__c = DateTime.now();
        m.HOT_User_Role__c = getUserProfileAndName(t.CRM_Thread_Type__c);
        return m;
    }
    @AuraEnabled
    public static void setLastMessageFrom(String threadId, String fromContactId) {
        Thread__c t = [
            SELECT Id, CRM_Related_Object__c, HOT_Thread_read_by__c, CRM_Latest_Message_Datetime__c
            FROM Thread__c
            WHERE
                Id = :threadId
                AND CRM_Type__c IN :new Set<String>{
                    'HOT_BRUKER-FORMIDLER',
                    'HOT_BRUKER-TOLK',
                    'HOT_BESTILLER-FORMIDLER',
                    'HOT_TOLK-FORMIDLER',
                    'HOT_TOLK-RESSURSKONTOR',
                    'HOT_BRUKER-BESTILLER',
                    'HOT_TOLK-TOLK'
                }
        ];
        t.CRM_Latest_Message_Datetime__c = Datetime.now();
        t.HOT_Thread_read_by__c = ((fromContactId == 'ansatt/formidler') ? UserInfo.getUserId() : fromContactId) + ';';
        update t;
    }
    @AuraEnabled
    public static Map<String, String> getRelatedObjectDetails(Id relatedRecordId) {
        Map<String, String> navigationhelp = new Map<String, String>();
        String objectType = String.valueOf(relatedRecordId.getsobjecttype());
        if (objectType == 'WorkOrder') {
            User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            for (HOT_InterestedResource__c ir : [
                SELECT Id, ServiceAppointment__c
                FROM HOT_InterestedResource__c
                WHERE
                    ServiceAppointment__c IN (
                        SELECT Id
                        FROM ServiceAppointment
                        WHERE HOT_WorkOrderLineItem__r.WorkOrderId = :relatedRecordId
                    )
                    AND ServiceResource__r.AccountId = :currentUser.AccountId
            ]) {
                navigationhelp.put(ir.ServiceAppointment__c, 'SA');
            }
            if (navigationhelp.size() == 0) {
                navigationhelp.put(relatedRecordId, 'WO');
            }
        }
        if (objectType == 'HOT_Request__c') {
            User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            WorkOrder workOrder = [
                SELECT
                    Id,
                    HOT_Request__r.IsAccountEqualOrderer__c,
                    HOT_Request__r.Orderer__c,
                    HOT_Request__r.IsSerieoppdrag__c
                FROM WorkOrder
                WHERE HOT_Request__c = :relatedRecordId
                LIMIT 1
            ];
            if (
                workOrder.HOT_Request__r.IsAccountEqualOrderer__c == false &&
                workOrder.HOT_Request__r.Orderer__c == currentUser.AccountId
            ) {
                if (workOrder.HOT_Request__r.IsSerieoppdrag__c == false) {
                    navigationhelp.put(workOrder.Id, 'Andre-WO');
                } else {
                    navigationhelp.put(workOrder.Id, 'Andre-R');
                }
            } else {
                if (workOrder.HOT_Request__r.IsSerieoppdrag__c == false) {
                    navigationhelp.put(workOrder.Id, 'WO');
                } else {
                    navigationhelp.put(workOrder.Id, 'R');
                }
            }
        }
        if (objectType == 'HOT_InterestedResource__c') {
            HOT_InterestedResource__c ir = [
                SELECT ServiceAppointment__c
                FROM HOT_InterestedResource__c
                WHERE Id = :relatedRecordId
            ];
            navigationhelp.put(ir.ServiceAppointment__c, 'IR');
        }
        if (objectType == 'ServiceAppointment') {
            navigationhelp.put(relatedRecordId, 'SA');
        }
        if (objectType == 'HOT_WageClaim__c') {
            navigationhelp.put(relatedRecordId, 'WC');
        }
        return navigationhelp;
    }

    public class ReadByEntry {
        @AuraEnabled
        public Id threadId;
        @AuraEnabled
        public String displayName;
        @AuraEnabled
        public Boolean isSystemAdmin;
        @AuraEnabled
        public Boolean isFormidlerRole;

        public ReadByEntry(Id threadId, String displayName, Boolean isSystemAdmin, Boolean isFormidlerRole) {
            this.threadId = threadId;
            this.displayName = displayName;
            this.isSystemAdmin = isSystemAdmin;
            this.isFormidlerRole = isFormidlerRole;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<ReadByEntry> resolveReadByEntries(List<Id> threadIds) {
        List<ReadByEntry> results = new List<ReadByEntry>();
        if (threadIds == null || threadIds.isEmpty())
            return results;

        Set<Id> userIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        for (Id pid : threadIds) {
            if (pid == null)
                continue;
            String s = String.valueOf(pid);
            if (s.startsWith('005'))
                userIdSet.add(pid);
            else if (s.startsWith('003'))
                contactIdSet.add(pid);
        }

        // Users: include Formidler as "Formidler", exclude System Administrators
        if (!userIdSet.isEmpty()) {
            for (User u : [SELECT Id, Name, Profile.Name, NKS_FullName__c FROM User WHERE Id IN :userIdSet]) {
                Boolean isAdmin = (u.Profile != null && u.Profile.Name == 'System Administrator');
                if (isAdmin)
                    continue;

                Boolean isFormidler = (u.Profile != null && u.Profile.Name == 'HOT Tolk Formidler');
                if (isFormidler) {
                    // Show as "Formidler" instead of personal name
                    results.add(new ReadByEntry(u.Id, 'Formidler', false, true));
                } else {
                    String display = !String.isBlank(u.NKS_FullName__c) ? u.NKS_FullName__c : u.Name;
                    results.add(new ReadByEntry(u.Id, display, false, false));
                }
            }
        }

        // Contacts: show contact name
        if (!contactIdSet.isEmpty()) {
            for (Contact c : [SELECT Id, Name FROM Contact WHERE Id IN :contactIdSet]) {
                results.add(new ReadByEntry(c.Id, c.Name, false, false));
            }
        }
        return results;
    }

    @AuraEnabled(cacheable=false)
    public static List<ReadByEntry> buildReadByEntriesForThread(Id threadId) {
        Thread__c t = [SELECT HOT_Thread_read_by__c FROM Thread__c WHERE Id = :threadId LIMIT 1];

        // Use HOT_Thread_read_by__c to build the list
        List<Id> parsedIds = new List<Id>();
        if (!String.isBlank(t.HOT_Thread_read_by__c)) {
            for (String s : t.HOT_Thread_read_by__c.split(';')) {
                if (!String.isBlank(s))
                    parsedIds.add((Id) s);
            }
        }
        return resolveReadByEntries(parsedIds);
    }
}
