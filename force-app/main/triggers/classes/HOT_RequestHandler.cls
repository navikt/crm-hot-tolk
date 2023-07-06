public without sharing class HOT_RequestHandler extends MyTriggers {
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
                triggerOldMap.get(request.Id).get('Status__c') !==
                request.Status__c && request.Status__c == 'Godkjent' && !request.IsAccountEqualOrderer__c
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
            HOT_RequestNotification.notifyDispatchers_requestChanged(notifyDispatcherRequests, triggerOldMap);
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
        List<Hot_Request__c> requestsWithUpdatedDispatcher = new List<Hot_Request__c>();


        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            // Filter for Godkjent requests
            if (triggerOldMap.get(request.Id).get('Status__c') == 'Åpen' && request.Status__c == 'Godkjent') {
                godkjentRequests.add(request);
            }
            if (triggerOldMap.get(request.Id).get('Subject__c') !== request.Subject__c) {
                requestsWithNewSubject.add(request);
            }
            if (triggerOldMap.get(request.Id).get('Dispatcher__c') !== request.Dispatcher__c) {
            requestsWithUpdatedDispatcher.add(request);
            }
        }
        if (godkjentRequests.size() > 0) {
            createWOLI_SA(godkjentRequests);
        }
        if (requestsWithNewSubject.size() > 0) {
            updateWorkOrderSubject(requestsWithNewSubject);
        }
        if (requestsWithUpdatedDispatcher.size() > 0) {
             updateDispatcherOnThread(requestsWithUpdatedDispatcher);
        }
    }
    public static void updateDispatcherOnThread(List<HOT_Request__c>  requestsList){
        Set<Id> requestIds=new Set<Id>();
        for(HOT_Request__c r:requestsList ){
            requestIds.add(r.Id);
        }
        List<HOT_Request__c> requests=[SELECT Id, Dispatcher__c FROM HOT_Request__C WHERE Id IN :requestIds];
        List<WorkOrder> workorders=[SELECT Id, HOT_Request__r.Dispatcher__c FROM WorkOrder WHERE HOT_Request__c IN :requestIds];
        List<ServiceAppointment> serviceAppointments=[SELECT Id, HOT_Request__r.Dispatcher__c FROM ServiceAppointment WHERE HOT_Request__c IN :requestIds];
        List<HOT_InterestedResource__c> interestedReources=[SELECT Id, ServiceAppointment__r.HOT_Request__r.Dispatcher__c FROM HOT_InterestedResource__c WHERE ServiceAppointment__r.HOT_Request__c IN :requestIds];
        
        
     Map<Id, Id> requestMap = new Map<Id, Id>();
     Map<Id, Id> workOrderMap = new Map<Id, Id>();
     Map<Id, Id> serviceApppointmentMap = new Map<Id, Id>();
     Map<Id, Id> interestedResourceMap = new Map<Id, Id>();
        for(HOT_Request__c r: requests){
            requestMap.put(r.Id, r.Dispatcher__c);
        }
        Set<Id> woIds=new Set<Id>();
        for(WorkOrder wo: workorders){
            woIds.add(wo.Id);
            workOrderMap.put(wo.Id, wo.HOT_Request__r.Dispatcher__c);
        }
        Set<Id> saIds=new Set<Id>();
        for(ServiceAppointment sa: serviceAppointments){
            saIds.add(sa.Id);
            serviceApppointmentMap.put(sa.Id, sa.HOT_Request__r.Dispatcher__c);
        }
        Set<Id> irIds=new Set<Id>();
        for(HOT_InterestedResource__c ir: interestedReources){
            irIds.add(ir.Id);
            interestedResourceMap.put(ir.Id, ir.serviceAppointment__r.HOT_Request__r.Dispatcher__c);
        }

        List<Thread__c> threadList=[SELECT Id, CRM_Related_Object__c FROM Thread__c WHERE CRM_Related_Object__c IN:requestIds OR CRM_Related_Object__c IN:woIds OR CRM_Related_Object__c IN: saIds OR CRM_Related_Object__c IN: irIds];

        for (Thread__c thread : threadList) {
            if (requestMap.containsKey(thread.CRM_Related_Object__c)) {
                thread.HOT_Dispatcher__c = requestMap.get(thread.CRM_Related_Object__c);
            } else if (workOrderMap.containsKey(thread.CRM_Related_Object__c)) {
                thread.HOT_Dispatcher__c = workOrderMap.get(thread.CRM_Related_Object__c);
            } else if (serviceApppointmentMap.containsKey(thread.CRM_Related_Object__c)) {
                thread.HOT_Dispatcher__c = serviceApppointmentMap.get(thread.CRM_Related_Object__c);
            } else if (interestedResourceMap.containsKey(thread.CRM_Related_Object__c)) {
                thread.HOT_Dispatcher__c = interestedResourceMap.get(thread.CRM_Related_Object__c);
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
            HOT_WorkOrderHandler.notifyOnOrderer(workorders);
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
}
