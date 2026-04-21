public without sharing class HOT_WorkOrderHandler extends MyTriggers {
    private static Map<Id, HOT_Request__c> requestById = new Map<Id, HOT_Request__c>();

    private static Map<Id, HOT_Request__c> getRequestsById(List<WorkOrder> workOrders) {
        Set<Id> requestIds = new Set<Id>();
        for (WorkOrder workOrder : workOrders) {
            if (workOrder.HOT_Request__c != null) {
                requestIds.add(workOrder.HOT_Request__c);
            }
        }
        cacheRequestsById(requestIds);

        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>();
        for (Id requestId : requestIds) {
            requests.put(requestId, requestById.get(requestId));
        }
        return requests;
    }

    private static Set<Id> getUncachedRequestIds(Set<Id> requestIds) {
        Set<Id> uncachedRequestIds = new Set<Id>();
        for (Id requestId : requestIds) {
            if (!requestById.containsKey(requestId)) {
                uncachedRequestIds.add(requestId);
            }
        }
        return uncachedRequestIds;
    }

    private static void cacheRequestsById(Set<Id> requestIds) {
        Set<Id> uncachedRequestIds = getUncachedRequestIds(requestIds);
        if (uncachedRequestIds.isEmpty()) {
            return;
        }

        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(
            [
                SELECT
                    Id,
                    Status__c,
                    InterpretationMethod__c,
                    InterpretationMethod__r.Id,
                    InterpretationMethodSecondary__c,
                    InterpretationMethodSecondary__r.Id,
                    NumberOfInterpreters__c,
                    NumberOfInterpretersSecondary__c,
                    ServiceTerritory__c,
                    OwnerId,
                    Subject__c,
                    Description__c,
                    Account__c,
                    Account__r.PersonContactId,
                    HOT_PersonContactId__c,
                    InterpretationStreet__c,
                    InterpretationPostalCode__c,
                    InterpretationPostalCity__c,
                    MeetingStreet__c,
                    MeetingPostalCity__c,
                    MeetingPostalCode__c,
                    CanceledDate__c
                FROM HOT_Request__c
                WHERE Id IN :uncachedRequestIds
            ]
        );

        for (Id requestId : uncachedRequestIds) {
            requestById.put(requestId, requests.get(requestId));
        }
    }

    public override void onBeforeInsert() {
        setDefaultFields((List<WorkOrder>) records);
        setDuration((List<WorkOrder>) records);
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<WorkOrder> avlystWorkOrder = new List<WorkOrder>();
        List<WorkOrder> workOrdersToChangeOwnerToArchive = new List<WorkOrder>();
        List<WorkOrder> setDurationWorkOrders = new List<WorkOrder>();

        for (WorkOrder workorder : (List<WorkOrder>) records) {
            if (workorder.Status != triggerOldMap.get(workorder.Id).get('Status') && workorder.Status == 'Canceled') {
                avlystWorkOrder.add(workorder);
            }
            if (
                workorder.StartDate != triggerOldMap.get(workorder.Id).get('StartDate') ||
                workorder.EndDate != triggerOldMap.get(workorder.Id).get('EndDate')
            ) {
                setDurationWorkOrders.add(workorder);
            }
            if (
                triggerOldMap.get(workOrder.Id).get('HOT_DelPol_IsHideRecord__c') !==
                workOrder.HOT_DelPol_IsHideRecord__c && workOrder.HOT_DelPol_IsHideRecord__c
            ) {
                workOrdersToChangeOwnerToArchive.add(WorkOrder);
            }
        }
        if (avlystWorkOrder.size() > 0) {
            setCancelDate(avlystWorkOrder);
        }
        if (workOrdersToChangeOwnerToArchive.size() > 0) {
            HOT_Utility.setArchiveAsOwner(workOrdersToChangeOwnerToArchive);
        }
        if (setDurationWorkOrders.size() > 0) {
            setDuration(setDurationWorkOrders);
        }
    }

    public override void onAfterInsert() {
        List<Id> workOrdersWithoutRequests = new List<Id>();
        Map<Id, HOT_Request__c> requests = getRequestsById((List<WorkOrder>) records);

        for (WorkOrder workOrder : (List<WorkOrder>) records) {
            if (workOrder.HOT_Request__c == null) {
                workOrdersWithoutRequests.add(workOrder.Id);
            }
        }

        List<WorkOrder> approvedWorkOrders = new List<WorkOrder>();
        if (!requests.isEmpty()) {
            for (WorkOrder workOrder : (List<WorkOrder>) records) {
                HOT_Request__c request = requests.get(workOrder.HOT_Request__c);
                if (
                    request != null &&
                    request.Status__c != 'Åpen' &&
                    request.Status__c != 'Avlyst' &&
                    request.Status__c != 'Annullert'
                ) {
                    approvedWorkOrders.add(workOrder);
                }
            }
        }
        if (approvedWorkOrders.size() > 0) {
            createChildRecords(approvedWorkOrders);
        }
        updateRequests((List<WorkOrder>) records);

        if (workOrdersWithoutRequests.size() > 0) {
            Database.delete(workOrdersWithoutRequests, false);
        }
    }

    //Issue 10 i MyTriggers-rammeverket fører til en feil ved manuel testing, hvor kun HOT_WorkOrderStatusHandler.onAfterUpdate blir kjørt.
    //Vi gjør derfor om denne "trigger"-metoden til en statisk metode, og kaller på den fra HOT_WorkOrderStatusHandler.onAfterUpdate.
    public static void onAfterUpdateTemp(Map<Id, sObject> triggerOldMap, List<WorkOrder> records) {
        List<WorkOrder> updatedWorkOrders = new List<WorkOrder>();

        //Om status eller tidspunkt på WorkOrder er endret, kan det ha ført til at den førstkommende, ikke-avlyste WorkOrderen har endret seg
        for (WorkOrder record : records) {
            if (
                record.Status != triggerOldMap.get(record.Id).get('Status') ||
                record.StartDate != triggerOldMap.get(record.Id).get('StartDate') ||
                record.EndDate != triggerOldMap.get(record.Id).get('EndDate')
            ) {
                updatedWorkOrders.add(record);
            }
        }

        if (updatedWorkOrders.size() > 0) {
            updateRequests(updatedWorkOrders);
        }
    }
    public override void onAfterDelete() {
        updateRequests((List<WorkOrder>) records);
    }
    public override void onAfterUndelete() {
        updateRequests((List<WorkOrder>) records);
    }

    public static void createChildRecords(List<WorkOrder> workOrders) {
        Map<Id, HOT_Request__c> requests = getRequestsById(workOrders);

        //Each workOrder should have 1 or more childs (workOrderLineItems)
        List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
        for (WorkOrder workOrder : workOrders) {
            HOT_Request__c request = requests.get(workOrder.HOT_Request__c);
            if (request == null) {
                continue;
            }

            //Check if status New

            //Fetching the workTypes from parent requests. If the request only has 1 workType, only one child workOrderLineItem should be created
            Map<Id, Decimal> workTypes = new Map<Id, Decimal>();
            workTypes.put(request.InterpretationMethod__r.Id, request.NumberOfInterpreters__c);
            if (request.InterpretationMethodSecondary__c != null) {
                workTypes.put(request.InterpretationMethodSecondary__r.Id, request.NumberOfInterpretersSecondary__c);
            }

            //If there are no child workOrderLineItems for this workOrder, they should be created
            if (workOrder.LineItemCount == 0) {
                for (Id workTypeId : workTypes.keySet()) {
                    WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem();
                    workOrderLineItem.WorkOrderId = workOrder.Id;
                    workOrderLineItem.City = workOrder.City;
                    workOrderLineItem.Description = workOrder.Description;
                    workOrderLineItem.EndDate = workOrder.EndDate;
                    workOrderLineItem.HOT_InterpretationPostalCity__c = workOrder.HOT_InterpretationPostalCity__c;
                    workOrderLineItem.HOT_InterpretationPostalCode__c = workOrder.HOT_InterpretationPostalCode__c;
                    workOrderLineItem.HOT_InterpretationPostalStreet__c = workOrder.HOT_InterpretationStreet__c;
                    workOrderLineItem.PostalCode = workOrder.PostalCode;
                    workOrderLineItem.StartDate = workOrder.StartDate;
                    workOrderLineItem.Street = workOrder.Street;
                    workOrderLineItem.Subject = workOrder.Subject;
                    workOrderLineItem.WorkTypeId = workTypeId;
                    workOrderLineItem.HOT_NumberOfInterpreters__c = workTypes.get(workTypeId);

                    workOrderLineItems.add(workOrderLineItem);
                }
            }
        }
        insert workOrderLineItems;
    }

    public static void setDefaultFields(List<WorkOrder> workOrders) {
        Map<Id, HOT_Request__c> requests = getRequestsById(workOrders);
        for (WorkOrder workOrder : workOrders) {
            //Setting default status for WorkOrder
            workOrder.Status = 'New';
            if (workOrder.HOT_Request__c != null) {
                HOT_Request__c request = requests.get(workOrder.HOT_Request__c);
                if (request == null) {
                    continue;
                }

                //Setting owner of WorkOrder based on owner of Request
                workOrder.OwnerId = workOrder.HOT_RequestOwnerId__c;

                //Setting fields of WorkOrder based on Request, if the fields are not filled in, and the fields on Request have values.
                if (workOrder.ServiceTerritory == null && request.ServiceTerritory__c != null) {
                    workOrder.ServiceTerritoryId = request.ServiceTerritory__c;
                }
                if (workOrder.Subject == null && request.Subject__c != null) {
                    workOrder.Subject = request.Subject__c;
                }
                if (workOrder.Description == null && request.Description__c != null) {
                    workOrder.Description = request.Description__c;
                }
                if (workOrder.AccountId == null && request.Account__c != null) {
                    workOrder.AccountId = request.Account__c;
                }
                if (
                    workOrder.ContactId == null &&
                    request.Account__c != null &&
                    request.Account__r.PersonContactId != null
                ) {
                    workOrder.ContactId = request.Account__r.PersonContactId;
                }
                if (workOrder.HOT_InterpretationStreet__c == null && request.InterpretationStreet__c != null) {
                    workOrder.HOT_InterpretationStreet__c = request.InterpretationStreet__c;
                }
                if (workOrder.HOT_InterpretationPostalCode__c == null && request.InterpretationPostalCode__c != null) {
                    workOrder.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
                }
                if (workOrder.HOT_InterpretationPostalCity__c == null && request.InterpretationPostalCity__c != null) {
                    workOrder.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
                }
                if (workOrder.Street == null && request.MeetingStreet__c != null) {
                    workOrder.Street = request.MeetingStreet__c;
                }
                if (workOrder.City == null && request.MeetingPostalCity__c != null) {
                    workOrder.City = request.MeetingPostalCity__c;
                }
                if (workOrder.PostalCode == null && request.MeetingPostalCode__c != null) {
                    workOrder.PostalCode = request.MeetingPostalCode__c;
                }
            }
        }
    }

    public static void updateRequests(List<WorkOrder> workOrders) {
        Set<Id> requestIds = new Set<Id>();
        for (WorkOrder wo : workOrders) {
            if (wo.HOT_Request__c != null) {
                requestIds.add(wo.HOT_Request__c);
            }
        }

        if (requestIds.isEmpty()) {
            return;
        }

        List<HOT_Request__c> requests = [
            SELECT
                Id,
                NumberOfWorkOrders__c,
                StartTime__c,
                EndTime__c,
                SeriesStartDate__c,
                SeriesEndDate__c,
                Status__c,
                (
                    SELECT Id, StartDate, EndDate, Status
                    FROM Work_Orders__r
                    WHERE Status != 'Annul'
                    ORDER BY StartDate ASC
                )
            FROM HOT_Request__c
            WHERE Id IN :requestIds
        ];

        for (HOT_Request__c request : requests) {
            if (request.NumberOfWorkOrders__c != request.Work_Orders__r.size()) {
                request.NumberOfWorkOrders__c = request.Work_Orders__r.size();
            }

            Datetime minStart;
            Datetime minEnd;
            Date minDate;
            Date maxDate;

            for (WorkOrder wo : request.Work_Orders__r) {
                if (wo.Status == 'Canceled') {
                    continue;
                }

                // StartTime (minste datetime)
                if (wo.StartDate != null && (minStart == null || wo.StartDate < minStart)) {
                    minStart = wo.StartDate;
                }

                // EndTime (minste datetime)
                if (wo.EndDate != null && (minEnd == null || wo.EndDate < minEnd)) {
                    minEnd = wo.EndDate;
                }

                // SeriesStartDate (minste dato)
                if (wo.StartDate != null) {
                    Date startDateOnly = wo.StartDate.date();
                    if (minDate == null || startDateOnly < minDate) {
                        minDate = startDateOnly;
                    }
                }

                // SeriesEndDate (største dato)
                if (wo.EndDate != null) {
                    Date endDateOnly = wo.EndDate.date();
                    if (maxDate == null || endDateOnly > maxDate) {
                        maxDate = endDateOnly;
                    }
                }
            }

            if (minStart != null) {
                request.StartTime__c = minStart;
            }

            if (minEnd != null) {
                request.EndTime__c = minEnd;
            }

            if (minDate != null) {
                request.SeriesStartDate__c = minDate;
            }

            if (maxDate != null) {
                request.SeriesEndDate__c = maxDate;
            }
        }

        try {
            update requests;
        } catch (Exception e) {
            if (!e.getMessage().contains('Slutt tid må være etter start tid')) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }

    public static void updateWorkOrders(List<WorkOrder> workOrders) {
        updateWorkOrders(workOrders, getRequestsById(workOrders));
    }

    public static void updateWorkOrders(List<WorkOrder> workOrders, Map<Id, HOT_Request__c> requests) {
        if (requests == null) {
            requests = new Map<Id, HOT_Request__c>();
        }

        for (WorkOrder workOrder : workOrders) {
            HOT_Request__c request = requests.get(workOrder.HOT_Request__c);
            if (request == null) {
                continue;
            }

            workOrder.AccountId = request.Account__c;
            workOrder.City = request.MeetingPostalCity__c;
            workOrder.ContactId = request.HOT_PersonContactId__c;
            workOrder.Description = request.Description__c;
            workOrder.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
            workOrder.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
            workOrder.HOT_InterpretationStreet__c = request.InterpretationStreet__c;
            workOrder.OwnerId = request.OwnerId;
            workOrder.PostalCode = request.MeetingPostalCode__c;
            workOrder.Street = request.MeetingStreet__c;
            workOrder.Subject = request.Subject__c;
            workOrder.ServiceTerritoryId = request.ServiceTerritory__c;
        }
        update workOrders;
    }

    public static void setCancelDate(List<WorkOrder> workorders) {
        Map<Id, HOT_Request__c> requests = getRequestsById(workorders);
        for (WorkOrder workOrder : workorders) {
            HOT_Request__c request = requests.get(workOrder.HOT_Request__c);
            if (workOrder.CanceledDate__c == null) {
                if (request != null && request.CanceledDate__c != null) {
                    workOrder.CanceledDate__c = request.CanceledDate__c;
                } else {
                    workOrder.CanceledDate__c = Datetime.now();
                }
            }
        }
    }

    public static List<WorkOrder> resetNotifyDispatcher(List<WorkOrder> workOrders) {
        for (WorkOrder workOrder : workOrders) {
            workOrder.HOT_IsNotifyDispatcher__c = false;
        }
        return workOrders;
    }

    public static void setDuration(List<workOrder> workOrders) {
        for (WorkOrder workOrder : workOrders) {
            workOrder.Duration =
                ((Double) workOrder.EndDate.getTime() - (Double) workOrder.StartDate.getTime()) / 3600000;
        }
    }

    public static WorkOrder getWorkOrder(HOT_Request__c request) {
        return [SELECT Id, HOT_Request__c FROM WorkOrder WHERE HOT_Request__c = :request.Id LIMIT 1];
    }
}
