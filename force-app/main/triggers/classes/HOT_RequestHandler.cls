public without sharing class HOT_RequestHandler extends MyTriggers {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
    public override void onBeforeInsert() {
        setStatusDefault((List<HOT_Request__c>) records);
        setOrdererField((List<HOT_Request__c>) records);
        setServiceTerritory((List<HOT_Request__c>) records);
        setMeetingStreet((List<HOT_Request__c>) records);
        setFieldsToBlank(
            (List<HOT_Request__c>) records,
            new List<String>{
                'MessageToDispatcher__c',
                'CanceledDate__c',
                'SeriesStartDate__c',
                'SeriesEndDate__c',
                'NumberOfWorkOrders__c'
            }
        );
        //setSourceFieldOnClone((List<HOT_Request__c>) records);
        List<HOT_Request__c> imageInterpreterRequests = new List<HOT_Request__c>();
        List<HOT_Request__c> requestsWithUserInterpretationMethod = new List<HOT_Request__c>();

        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            if (request.Type__c == 'ImageInterpreter') {
                imageInterpreterRequests.add(request);
            }
            if (request.UserInterpretationMethod__c != null && request.Source__c == 'Community') {
                requestsWithUserInterpretationMethod.add(request);
            }
        }
        if (imageInterpreterRequests.size() > 0) {
            setImageInterpreterFields(imageInterpreterRequests);
        }
        if (requestsWithUserInterpretationMethod.size() > 0) {
            setInterpretationMethod(requestsWithUserInterpretationMethod);
        }
    }

    public override void onAfterInsert() {
        List<HOT_Request__c> requestsToGetContactInformationFor = new List<HOT_Request__c>();
        Set<Id> personIdsToUpdate = new Set<Id>();
        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            // Filter for relevant records to initiate callout to Kontakt og Reservasjonsregisteret (KRR)
            if (request.Person__c != null) {
                personIdsToUpdate.add(request.Person__c);
                requestsToGetContactInformationFor.add(request);
            }
        }

        if (requestsToGetContactInformationFor.size() > 0) {
            // Set related Person__c records "KRR Integration Status" field to 'Queued'
            List<Person__c> personsToUpdate = new List<Person__c>();
            for (Id personId : personIdsToUpdate) {
                personsToUpdate.add(new Person__c(Id = personId, INT_KrrIntegrationStatus__c = 'Queued'));
            }
            update personsToUpdate;

            // Call out to KRR through Queuable Apex
            HOT_KRRCalloutQueuable krr = new HOT_KRRCalloutQueuable(requestsToGetContactInformationFor);
            System.enqueueJob(krr);
        }
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<HOT_Request__c> ownerChangedRequests = new List<HOT_Request__c>();
        List<HOT_Request__c> avlystRequests = new List<HOT_Request__c>();
        List<HOT_Request__c> notifyDispatcherRequests = new List<HOT_Request__c>();
        List<HOT_Request__c> requestsToChangeOwnerToArchive = new List<HOT_Request__c>();
        List<HOT_Request__c> ordererRequestsToNotifyUsers = new List<HOT_Request__c>();

        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            // Filter for owner change
            if (request.OwnerId != triggerOldMap.get(request.Id).get('OwnerId')) {
                ownerChangedRequests.add(request);
            }
            // Filter for Avlyst requests
            if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Avlyst') {
                avlystRequests.add(request);
            }
            // Notify Dispatcher: Avlyst requests
            if (
                request.IsNotifyDispatcher__c != triggerOldMap.get(request.Id).get('IsNotifyDispatcher__c') &&
                request.IsNotifyDispatcher__c == true
            ) {
                notifyDispatcherRequests.add(request);
            }
            if (
                triggerOldMap.get(request.Id).get('HOT_DelPol_IsHideRecord__c') !==
                request.HOT_DelPol_IsHideRecord__c && request.HOT_DelPol_IsHideRecord__c
            ) {
                requestsToChangeOwnerToArchive.add(request);
            }
            // Notify user on order
            if (
                triggerOldMap.get(request.Id).get('Status__c') == 'Åpen' &&
                triggerOldMap.get(request.Id).get('Status__c') !== request.Status__c &&
                request.Status__c == 'Godkjent' &&
                !request.IsAccountEqualOrderer__c
            ) {
                ordererRequestsToNotifyUsers.add(request);
            }
        }
        if (ownerChangedRequests.size() > 0) {
            setServiceTerritory(ownerChangedRequests);
        }
        if (avlystRequests.size() > 0) {
            setCancelDate(avlystRequests);
        }
        if (notifyDispatcherRequests.size() > 0) {
            HOT_RequestNotification.notifyDispatchers_requestChanged(notifyDispatcherRequests);
            resetNotifyDispatcher(notifyDispatcherRequests);
        }
        if (requestsToChangeOwnerToArchive.size() > 0) {
            HOT_Utility.setArchiveAsOwner(requestsToChangeOwnerToArchive);
        }
        if (ordererRequestsToNotifyUsers.size() > 0) {
            setNotifyOnUser(ordererRequestsToNotifyUsers);
        }
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<HOT_Request__c> godkjentRequests = new List<HOT_Request__c>();
        List<Hot_Request__c> requestsWithNewSubject = new List<Hot_Request__c>();
        List<Hot_Request__c> requestsWithNewAccount = new List<Hot_Request__c>();
        List<Hot_Request__c> requestsWithUpdatedDispatcher = new List<Hot_Request__c>();
        List<Hot_Request__c> requestsWithUpdatedCompany = new List<Hot_Request__c>();
        List<Hot_Request__c> requestsWithUpdatedMeetingAddress = new List<Hot_Request__c>();
        List<Hot_Request__c> requestsWithUpdatedInterpretationAddress = new List<Hot_Request__c>();
        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            // Filter for Godkjent requests
            if (triggerOldMap.get(request.Id).get('Status__c') == 'Åpen' && request.Status__c == 'Godkjent') {
                godkjentRequests.add(request);
            }
            if (triggerOldMap.get(request.Id).get('Subject__c') !== request.Subject__c) {
                requestsWithNewSubject.add(request);
            }
            if (triggerOldMap.get(request.Id).get('Account__c') !== request.Account__c) {
                requestsWithNewAccount.add(request);
            }
            if (
                triggerOldMap.get(request.Id).get('Dispatcher__c') !== request.Dispatcher__c ||
                triggerOldMap.get(request.Id).get('OwnerId') !== request.OwnerId
            ) {
                requestsWithUpdatedDispatcher.add(request);
            }
            if (triggerOldMap.get(request.Id).get('Company__c') !== request.Company__c) {
                requestsWithUpdatedCompany.add(request);
            }
            if (
                triggerOldMap.get(request.Id).get('MeetingStreet__c') !== request.MeetingStreet__c ||
                triggerOldMap.get(request.Id).get('MeetingPostalCode__c') !== request.MeetingPostalCode__c ||
                triggerOldMap.get(request.Id).get('MeetingPostalCity__c') !== request.MeetingPostalCity__c
            ) {
                requestsWithUpdatedMeetingAddress.add(request);
            }
            if (
                triggerOldMap.get(request.Id).get('InterpretationStreet__c') !== request.InterpretationStreet__c ||
                triggerOldMap.get(request.Id).get('InterpretationPostalCode__c') !==
                request.InterpretationPostalCode__c ||
                triggerOldMap.get(request.Id).get('InterpretationPostalCity__c') !== request.InterpretationPostalCity__c
            ) {
                requestsWithUpdatedInterpretationAddress.add(request);
            }
        }
        if (godkjentRequests.size() > 0) {
            createWOLI_SA(godkjentRequests);
        }
        if (requestsWithNewSubject.size() > 0) {
            updateWorkOrderSubject(requestsWithNewSubject);
        }
        if (requestsWithNewAccount.size() > 0) {
            updateWorkOrderAccount(requestsWithNewAccount);
        }
        if (requestsWithUpdatedDispatcher.size() > 0) {
            updateDispatcherOnThread(requestsWithUpdatedDispatcher);
        }
        if (requestsWithUpdatedCompany.size() > 0) {
            updateCompany(requestsWithUpdatedCompany);
        }
        if (requestsWithUpdatedMeetingAddress.size() > 0) {
            updateMeetingAddress(requestsWithUpdatedMeetingAddress);
        }
        if (requestsWithUpdatedInterpretationAddress.size() > 0) {
            updateInterpretationAddress(requestsWithUpdatedInterpretationAddress);
        }
    }
    private static void updateMeetingAddress(List<HOT_Request__c> requestsWithNewAddress) {
        List<WorkOrder> WorkOrders = [
            SELECT Address, HOT_Request__c
            FROM WorkOrder
            WHERE HOT_Request__c IN :requestsWithNewAddress
        ];
        for (WorkOrder wo : WorkOrders) {
            for (HOT_Request__c request : requestsWithNewAddress) {
                if (wo.HOT_Request__c == request.Id) {
                    wo.Street = request.MeetingStreet__c;
                    wo.City = request.MeetingPostalCity__c;
                    wo.PostalCode = request.MeetingPostalCode__c;
                }
            }
        }
        update WorkOrders;
    }
    private static void updateInterpretationAddress(List<HOT_Request__c> requestsWithNewAddress) {
        List<WorkOrder> WorkOrders = [
            SELECT
                HOT_InterpretationPostalCode__c,
                HOT_InterpretationPostalCity__c,
                HOT_InterpretationStreet__c,
                HOT_Request__c
            FROM WorkOrder
            WHERE HOT_Request__c IN :requestsWithNewAddress
        ];
        for (WorkOrder wo : WorkOrders) {
            for (HOT_Request__c request : requestsWithNewAddress) {
                if (wo.HOT_Request__c == request.Id) {
                    wo.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
                    wo.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
                    wo.HOT_InterpretationStreet__c = request.InterpretationStreet__c;
                }
            }
        }
        update WorkOrders;
    }
    private static void updateCompany(List<HOT_Request__c> requestsWithNewCompany) {
        List<ServiceAppointment> saList = [
            SELECT Id, HOT_Company__c, HOT_Request__c
            FROM ServiceAppointment
            WHERE HOT_Request__c IN :requestsWithNewCompany
        ];

        if (saList.size() > 0) {
            for (ServiceAppointment sa : saList) {
                for (HOT_Request__c request : requestsWithNewCompany) {
                    if (sa.HOT_Request__c == request.Id && request.Company__c != null) {
                        sa.HOT_Company__c = request.Company__c;
                    }
                }
            }
            update saList;
        }
    }
    public static void updateDispatcherOnThread(List<HOT_Request__c> requestsList) {
        Set<Id> requestIds = new Set<Id>();
        for (HOT_Request__c r : requestsList) {
            requestIds.add(r.Id);
        }
        List<HOT_Request__c> requests = [SELECT Id, Dispatcher__c, OwnerId FROM HOT_Request__C WHERE Id IN :requestIds];
        List<WorkOrder> workorders = [
            SELECT Id, HOT_Request__r.Dispatcher__c, HOT_Request__r.OwnerId
            FROM WorkOrder
            WHERE HOT_Request__c IN :requestIds
        ];
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_Request__r.Dispatcher__c, HOT_Request__r.OwnerId
            FROM ServiceAppointment
            WHERE HOT_Request__c IN :requestIds
        ];
        List<HOT_InterestedResource__c> interestedReources = [
            SELECT Id, ServiceAppointment__r.HOT_Request__r.Dispatcher__c, ServiceAppointment__r.HOT_Request__r.OwnerId
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__r.HOT_Request__c IN :requestIds
        ];

        Map<Id, Id> requestDispatcherMap = new Map<Id, Id>();
        Map<Id, Id> requestOwnerMap = new Map<Id, Id>();
        Map<Id, Id> workOrderDispatcherMap = new Map<Id, Id>();
        Map<Id, Id> workOrderOwnerMap = new Map<Id, Id>();
        Map<Id, Id> serviceAppointmentDispatcherMap = new Map<Id, Id>();
        Map<Id, Id> serviceAppointmentOwnerMap = new Map<Id, Id>();
        Map<Id, Id> interestedResourceDispatcherMap = new Map<Id, Id>();
        Map<Id, Id> interestedResourceOwnerMap = new Map<Id, Id>();

        for (HOT_Request__c r : requests) {
            requestDispatcherMap.put(r.Id, r.Dispatcher__c);
            requestOwnerMap.put(r.Id, r.OwnerId);
        }
        Set<Id> woIds = new Set<Id>();
        for (WorkOrder wo : workorders) {
            woIds.add(wo.Id);
            workOrderDispatcherMap.put(wo.Id, wo.HOT_Request__r.Dispatcher__c);
            workOrderOwnerMap.put(wo.Id, wo.HOT_Request__r.OwnerId);
        }
        Set<Id> saIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            saIds.add(sa.Id);
            serviceAppointmentDispatcherMap.put(sa.Id, sa.HOT_Request__r.Dispatcher__c);
            serviceAppointmentOwnerMap.put(sa.Id, sa.HOT_Request__r.OwnerId);
        }
        Set<Id> irIds = new Set<Id>();
        for (HOT_InterestedResource__c ir : interestedReources) {
            irIds.add(ir.Id);
            interestedResourceDispatcherMap.put(ir.Id, ir.serviceAppointment__r.HOT_Request__r.Dispatcher__c);
            interestedResourceOwnerMap.put(ir.Id, ir.ServiceAppointment__r.HOT_Request__r.OwnerId);
        }

        List<Thread__c> threadList = [
            SELECT Id, CRM_Related_Object__c
            FROM Thread__c
            WHERE
                CRM_Related_Object__c IN :requestIds
                OR CRM_Related_Object__c IN :woIds
                OR CRM_Related_Object__c IN :saIds
                OR CRM_Related_Object__c IN :irIds
        ];

        for (Thread__c thread : threadList) {
            Id relatedId = thread.CRM_Related_Object__c;

            if (requestDispatcherMap.containsKey(relatedId)) {
                thread.HOT_Dispatcher__c = requestDispatcherMap.get(relatedId);
                thread.OwnerId = requestOwnerMap.get(relatedId);
            } else if (workOrderDispatcherMap.containsKey(relatedId)) {
                thread.HOT_Dispatcher__c = workOrderDispatcherMap.get(relatedId);
                thread.OwnerId = workOrderOwnerMap.get(relatedId);
            } else if (serviceAppointmentDispatcherMap.containsKey(relatedId)) {
                thread.HOT_Dispatcher__c = serviceAppointmentDispatcherMap.get(relatedId);
                thread.OwnerId = serviceAppointmentOwnerMap.get(relatedId);
            } else if (interestedResourceDispatcherMap.containsKey(relatedId)) {
                thread.HOT_Dispatcher__c = interestedResourceDispatcherMap.get(relatedId);
                thread.OwnerId = interestedResourceOwnerMap.get(relatedId);
            }
        }
        update threadList;
    }

    private static void updateWorkOrderSubject(List<HOT_Request__c> requestsWithNewSubject) {
        List<WorkOrder> workOrders = [
            SELECT Id, Subject, HOT_Request__r.Subject__c
            FROM WorkOrder
            WHERE HOT_Request__c IN :requestsWithNewSubject
        ];

        if (workOrders.size() > 0) {
            for (WorkOrder wo : workOrders) {
                if (wo.HOT_Request__r.Subject__c != null) {
                    wo.Subject = wo.HOT_Request__r.Subject__c;
                }
            }
            update workOrders;
        }
    }

    private static void updateWorkOrderAccount(List<HOT_Request__c> requestsWithNewAccount) {
        List<WorkOrder> workOrders = [
            SELECT Id, AccountId, HOT_Request__r.Account__c
            FROM WorkOrder
            WHERE HOT_Request__c IN :requestsWithNewAccount
        ];

        if (workOrders.size() > 0) {
            for (WorkOrder wo : workOrders) {
                wo.AccountId = wo.HOT_Request__r.Account__c;
            }
            update workOrders;
        }
    }

    private static void createWOLI_SA(List<HOT_Request__c> godkjentRequests) {
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                AccountId,
                HOT_Request__c,
                Subject,
                Description,
                EndDate,
                StartDate,
                Address,
                City,
                PostalCode,
                Street,
                LineItemCount,
                HOT_InterpretationPostalCity__c,
                HOT_InterpretationPostalCode__c,
                HOT_InterpretationStreet__c,
                HOT_NumberOfInterpreters__c,
                WorkTypeId
            FROM WorkOrder
            WHERE HOT_Request__c IN :godkjentRequests AND Status = 'New'
        ];
        if (workOrders.size() > 0) {
            HOT_WorkOrderHandler.updateWorkOrders(workOrders);
            HOT_WorkOrderHandler.createChildRecords(workOrders);
        } else {
            createChildRecords(godkjentRequests);
        }
    }

    @AuraEnabled
    public static void createAndUpdateWorkOrders(Id requestId, Map<String, Map<String, Long>> times) {
        HOT_Request__c request = [
            SELECT
                Id,
                Account__c,
                Account__r.PersonContactId,
                OwnerId,
                ServiceTerritory__c,
                InterpretationMethod__c,
                NumberOfInterpreters__c,
                MeetingPostalCity__c,
                MeetingPostalCode__c,
                MeetingStreet__c,
                InterpretationPostalCity__c,
                InterpretationPostalCode__c,
                InterpretationStreet__c,
                HOT_PersonContactId__c,
                Subject__c,
                Description__c,
                StartTime__c,
                EndTime__c
            FROM HOT_Request__c
            WHERE Id = :requestId
        ];
        List<HOT_Request__c> requests = new List<HOT_Request__c>();
        Map<String, Map<String, Long>> updatedTimesMap = new Map<String, Map<String, Long>>();
        for (String key : times.keySet()) {
            if (times.get(key).get('isNew') == 1) {
                HOT_Request__c newRequest = request.clone(false, true, false, false);
                newRequest.Id = requestId;
                newRequest.OwnerId = UserInfo.getUserId();
                newRequest.StartTime__c = DateTime.newInstance(times.get(key).get('startTime'));
                newRequest.EndTime__c = DateTime.newInstance(times.get(key).get('endTime'));
                requests.add(newRequest);
            } else {
                updatedTimesMap.put(key, times.get(key));
            }
        }
        if (!updatedTimesMap.isEmpty()) {
            updateRelatedWorkOrders(requestId, updatedTimesMap);
        }
        if (!requests.isEmpty()) {
            createChildRecords(requests);
        }
    }

    @AuraEnabled
    public static void updateRelatedWorkOrders(Id requestId, Map<String, Map<String, Long>> times) {
        List<WorkOrder> workOrders = [
            SELECT Id, Status, StartDate, EndDate
            FROM WorkOrder
            WHERE HOT_Request__r.Id = :requestId
        ];
        List<WorkOrder> updatedWorkOrders = new List<WorkOrder>();
        for (WorkOrder workOrder : workOrders) {
            String workOrderId = (String) workOrder.Id;
            if (!times.keySet().contains(workOrderId)) {
                workOrder.Status = 'Canceled';
                updatedWorkOrders.add(workOrder);
            } else if (
                workOrder.StartDate != DateTime.newInstance(times.get(workOrderId).get('startTime')) ||
                workOrder.EndDate != DateTime.newInstance(times.get(workOrder.Id).get('endTime'))
            ) {
                workOrder.StartDate = DateTime.newInstance(times.get(workOrderId).get('startTime'));
                workOrder.EndDate = DateTime.newInstance(times.get(workOrderId).get('endTime'));
                updatedWorkOrders.add(workOrder);
            }
        }
        update updatedWorkOrders;
    }

    public static void createChildRecords(List<HOT_Request__c> requests) {
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (HOT_Request__c request : requests) {
            WorkOrder workOrder = new WorkOrder();

            workOrder.AccountId = request.Account__c;
            workOrder.City = request.MeetingPostalCity__c;
            workOrder.ContactId = request.HOT_PersonContactId__c;
            workOrder.Description = request.Description__c;
            workOrder.EndDate = request.EndTime__c;
            workOrder.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
            workOrder.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
            workOrder.HOT_InterpretationStreet__c = request.InterpretationStreet__c;
            workOrder.HOT_Request__c = request.Id;
            workOrder.OwnerId = request.OwnerId;
            workOrder.PostalCode = request.MeetingPostalCode__c;
            workOrder.StartDate = request.StartTime__c;
            workOrder.Street = request.MeetingStreet__c;
            workOrder.Subject = request.Subject__c;
            workOrder.ServiceTerritoryId = request.ServiceTerritory__c;

            workOrders.add(workOrder);
        }
        insert workOrders;
    }

    public static void setServiceTerritory(List<HOT_Request__c> requests) {
        List<HOT_ServiceTerritoryByQueue__mdt> serviceTerritoryByQueueList = [
            SELECT Queue__c, ServiceTerritory__c
            FROM HOT_ServiceTerritoryByQueue__mdt
        ];
        Map<String, String> serviceTerritoryByQueue = new Map<String, String>();
        for (HOT_ServiceTerritoryByQueue__mdt STbyQ : serviceTerritoryByQueueList) {
            serviceTerritoryByQueue.put(STbyQ.Queue__c, STbyQ.ServiceTerritory__c);
        }
        List<Group> queues = [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName IN :serviceTerritoryByQueue.keySet()
        ];
        List<ServiceTerritory> serviceTerritories = [
            SELECT Id, Name, HOT_DeveloperName__c
            FROM ServiceTerritory
            WHERE HOT_DeveloperName__c IN :serviceTerritoryByQueue.values()
        ];
        Map<Id, Id> serviceTerritoryIdByQueueId = new Map<Id, Id>();
        for (Group queue : queues) {
            for (ServiceTerritory serviceTerritory : serviceTerritories) {
                if (serviceTerritoryByQueue.get(queue.DeveloperName) == serviceTerritory.HOT_DeveloperName__c) {
                    serviceTerritoryIdByQueueId.put(queue.Id, serviceTerritory.Id);
                }
            }
        }
        for (HOT_Request__c request : requests) {
            if (serviceTerritoryIdByQueueId.get(request.OwnerId) != null) {
                request.ServiceTerritory__c = serviceTerritoryIdByQueueId.get(request.OwnerId);
            }
        }
    }

    public static void setCancelDate(List<HOT_Request__c> requests) {
        for (HOT_Request__c request : requests) {
            if (request.CanceledDate__c == null) {
                request.CanceledDate__c = Date.today();
            }
        }
    }

    public static void setStatusDefault(List<HOT_Request__c> requests) {
        for (HOT_Request__c request : requests) {
            request.Status__c = 'Åpen';
        }
    }

    public static void setOrdererField(List<HOT_Request__c> requests) {
        for (HOT_Request__c request : requests) {
            if (request.Type__c == 'Me' && request.Orderer__c == null && request.Account__c != null) {
                request.Orderer__c = request.Account__c;
            }
        }
    }

    public static void setFieldsToBlank(List<HOT_Request__c> requests, List<String> fields) {
        for (HOT_Request__c request : requests) {
            for (String field : fields) {
                if (request.get(field) != null) {
                    request.put(field, null);
                }
            }
        }
    }

    // If Request is cloned we can assume it is Formidler since users can't clone
    public static void setSourceFieldOnClone(List<HOT_Request__c> requests) {
        for (HOT_Request__c request : requests) {
            if (request.isClone()) {
                request.Source__c = 'Dispatcher';
            }
        }
    }

    public static void resetNotifyDispatcher(List<HOT_Request__c> requests) {
        for (HOT_Request__c request : requests) {
            request.IsNotifyDispatcher__c = false;
        }
    }

    public static void setImageInterpreterFields(List<HOT_Request__c> requests) {
        WorkType imageInterpretationMethod = [
            SELECT Id, HOT_DeveloperName__c
            FROM WorkType
            WHERE HOT_DeveloperName__c = 'BTV'
        ];
        for (HOT_Request__c request : requests) {
            request.AssignmentType__c = 'Image Interpreter';
            if (imageInterpretationMethod != null) {
                request.InterpretationMethod__c = imageInterpretationMethod.Id;
            }
        }
    }

    public static void setInterpretationMethod(List<HOT_Request__c> requests) {
        List<String> userInterpretationMethodList = new List<String>();
        for (HOT_Request__c request : requests) {
            userInterpretationMethodList.add(request.UserInterpretationMethod__c);
        }
        Map<String, Id> workTypeIdByDeveloperName = new Map<String, Id>();
        for (WorkType workType : [
            SELECT Id, HOT_DeveloperName__c
            FROM WorkType
            WHERE HOT_DeveloperName__c LIKE :userInterpretationMethodList
        ]) {
            workTypeIdByDeveloperName.put(workType.HOT_DeveloperName__c, workType.Id);
        }
        for (HOT_Request__c request : requests) {
            request.InterpretationMethod__c = workTypeIdByDeveloperName.get(request.UserInterpretationMethod__c);
        }
    }

    public static void setNotifyOnUser(List<HOT_Request__c> requests) {
        for (HOT_Request__C request : requests) {
            request.IsNotifyUserOnOrder__c = true;
        }
    }

    public static void setMeetingStreet(List<HOT_Request__c> requests) {
        for (HOT_Request__C request : requests) {
            if (request.MeetingStreet__c == null && request.InterpretationStreet__c != null) {
                request.MeetingStreet__c = request.InterpretationStreet__c;
                request.MeetingPostalCity__c = request.InterpretationPostalCity__c;
                request.MeetingPostalCode__c = request.InterpretationPostalCode__c;
            }

            if (request.InterpretationStreet__c == null && request.MeetingStreet__c != null) {
                request.InterpretationStreet__c = request.MeetingStreet__c;
                request.InterpretationPostalCity__c = request.MeetingPostalCity__c;
                request.InterpretationPostalCode__c = request.MeetingPostalCode__c;
            }
        }
    }
    @AuraEnabled
    public static boolean isErrorOnRequestCreate(String requestId) {
        Boolean isError = false;
        HOT_Request__c createdRequest = [
            SELECT Id, StartTime__c, EndTime__c, NumberOfWorkOrders__c
            FROM HOT_Request__c
            WHERE Id = :requestId
        ];
        if (createdRequest.StartTime__c == null || createdRequest.EndTime__c == null) {
            isError = true;
        } else {
            List<WorkOrder> createdWorkOrders = [SELECT Id FROM WorkOrder WHERE HOT_Request__c = :requestId];
            if (createdRequest.NumberOfWorkOrders__c != createdWorkOrders.size()) {
                isError = true;
                try {
                    delete createdWorkOrders;
                } catch (Exception e) {
                    handleException(e);
                }
            }
        }
        if (isError) {
            try {
                delete createdRequest;
            } catch (Exception e) {
                handleException(e);
            }
        }
        return isError;
    }
}
