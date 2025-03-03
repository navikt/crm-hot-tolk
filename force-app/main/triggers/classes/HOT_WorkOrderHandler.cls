public without sharing class HOT_WorkOrderHandler extends MyTriggers {
    private class WorkOrderException extends Exception {
    }

    @Future
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
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
        List<Id> accountIds = new List<Id>();
        List<Id> requestIds = new List<Id>();

        for (WorkOrder workOrder : (List<WorkOrder>) records) {
            if (workOrder.HOT_Request__c == null) {
                workOrdersWithoutRequests.add(workOrder.Id);
                WorkOrderException woException = new WorkOrderException(
                    'Request on Work Order should not be empty! Work Order details: ' + workOrder
                );
                handleException(woException);
            }

            requestIds.add(workOrder.HOT_Request__c);
            accountIds.add(workOrder.AccountId);
        }

        List<WorkOrder> approvedWorkOrders = new List<WorkOrder>();
        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(
            [SELECT Id, Status__c FROM HOT_Request__c WHERE Id IN :requestIds]
        );
        if (requests.size() > 0) {
            for (WorkOrder workOrder : (List<WorkOrder>) records) {
                if (
                    requests.get(workOrder.HOT_Request__c).Status__c != 'Åpen' &&
                    requests.get(workOrder.HOT_Request__c).Status__c != 'Avlyst' &&
                    requests.get(workOrder.HOT_Request__c).Status__c != 'Annullert'
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
        //Getting parent requests
        List<Id> requestIds = new List<Id>();
        for (WorkOrder workOrder : workOrders) {
            requestIds.add(workOrder.HOT_Request__c);
        }
        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(
            [
                SELECT
                    Id,
                    InterpretationMethod__r.Id,
                    InterpretationMethodSecondary__r.Id,
                    NumberOfInterpreters__c,
                    NumberOfInterpretersSecondary__c
                FROM HOT_Request__c
                WHERE Id IN :requestIds
            ]
        );

        //Each workOrder should have 1 or more childs (workOrderLineItems)
        List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
        for (WorkOrder workOrder : workOrders) {
            //Check if status New

            //Fetching the workTypes from parent requests. If the request only has 1 workType, only one child workOrderLineItem should be created
            Map<Id, Decimal> workTypes = new Map<Id, Decimal>();
            workTypes.put(
                requests.get(workOrder.HOT_Request__c).InterpretationMethod__r.Id,
                requests.get(workOrder.HOT_Request__c).NumberOfInterpreters__c
            );
            if (requests.get(workOrder.HOT_Request__c).InterpretationMethodSecondary__c != null) {
                workTypes.put(
                    requests.get(workOrder.HOT_Request__c).InterpretationMethodSecondary__r.Id,
                    requests.get(workOrder.HOT_Request__c).NumberOfInterpretersSecondary__c
                );
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
        List<Id> requestIds = new List<Id>();
        for (WorkOrder workOrder : workOrders) {
            requestIds.add(workOrder.HOT_Request__c);
        }
        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(
            [
                SELECT
                    Id,
                    ServiceTerritory__c,
                    Status__c,
                    OwnerId,
                    Subject__c,
                    Description__c,
                    Account__c,
                    Account__r.PersonContactId,
                    InterpretationStreet__c,
                    InterpretationPostalCode__c,
                    InterpretationPostalCity__c,
                    MeetingStreet__c,
                    MeetingPostalCity__c,
                    MeetingPostalCode__c
                FROM HOT_Request__c
                WHERE Id IN :requestIds
            ]
        );
        for (WorkOrder workOrder : workOrders) {
            //Setting default status for WorkOrder
            workOrder.Status = 'New';
            if (workOrder.HOT_Request__c != null) {
                //Setting owner of WorkOrder based on owner of Request
                workOrder.OwnerId = workOrder.HOT_RequestOwnerId__c;
                System.debug('workOrder.OwnerId: ' + workOrder.OwnerId);

                //Setting fields of WorkOrder based on Request, if the fields are not filled in, and the fields on Request have values.
                if (
                    workOrder.ServiceTerritory == null &&
                    requests.get(workOrder.HOT_Request__c).ServiceTerritory__c != null
                ) {
                    workOrder.ServiceTerritoryId = requests.get(workOrder.HOT_Request__c).ServiceTerritory__c;
                }
                if (workOrder.Subject == null && requests.get(workOrder.HOT_Request__c).Subject__c != null) {
                    workOrder.Subject = requests.get(workOrder.HOT_Request__c).Subject__c;
                }
                if (workOrder.Description == null && requests.get(workOrder.HOT_Request__c).Description__c != null) {
                    workOrder.Description = requests.get(workOrder.HOT_Request__c).Description__c;
                }
                if (workOrder.AccountId == null && requests.get(workOrder.HOT_Request__c).Account__c != null) {
                    workOrder.AccountId = requests.get(workOrder.HOT_Request__c).Account__c;
                }
                if (
                    workOrder.ContactId == null &&
                    requests.get(workOrder.HOT_Request__c).Account__c != null &&
                    requests.get(workOrder.HOT_Request__c).Account__r.PersonContactId != null
                ) {
                    workOrder.ContactId = requests.get(workOrder.HOT_Request__c).Account__r.PersonContactId;
                }
                if (
                    workOrder.HOT_InterpretationStreet__c == null &&
                    requests.get(workOrder.HOT_Request__c).InterpretationStreet__c != null
                ) {
                    workOrder.HOT_InterpretationStreet__c = requests.get(workOrder.HOT_Request__c)
                        .InterpretationStreet__c;
                }
                if (
                    workOrder.HOT_InterpretationPostalCode__c == null &&
                    requests.get(workOrder.HOT_Request__c).InterpretationPostalCode__c != null
                ) {
                    workOrder.HOT_InterpretationPostalCode__c = requests.get(workOrder.HOT_Request__c)
                        .InterpretationPostalCode__c;
                }
                if (
                    workOrder.HOT_InterpretationPostalCity__c == null &&
                    requests.get(workOrder.HOT_Request__c).InterpretationPostalCity__c != null
                ) {
                    workOrder.HOT_InterpretationPostalCity__c = requests.get(workOrder.HOT_Request__c)
                        .InterpretationPostalCity__c;
                }
                if (workOrder.Street == null && requests.get(workOrder.HOT_Request__c).MeetingStreet__c != null) {
                    workOrder.Street = requests.get(workOrder.HOT_Request__c).MeetingStreet__c;
                }
                if (workOrder.City == null && requests.get(workOrder.HOT_Request__c).MeetingPostalCity__c != null) {
                    workOrder.City = requests.get(workOrder.HOT_Request__c).MeetingPostalCity__c;
                }
                if (
                    workOrder.PostalCode == null &&
                    requests.get(workOrder.HOT_Request__c).MeetingPostalCode__c != null
                ) {
                    workOrder.PostalCode = requests.get(workOrder.HOT_Request__c).MeetingPostalCode__c;
                }
            }
        }
    }

    public static void updateRequests(List<WorkOrder> workOrders) {
        Set<Id> requestIds = new Set<Id>();
        for (WorkOrder workOrder : workOrders) {
            requestIds.add(workOrder.HOT_Request__c);
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
                    FROM HOT_Request__c.Work_Orders__r
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

            if (request.Status__c != 'Avlyst') {
                request.StartTime__c = null;
                request.EndTime__c = null;
                request.SeriesStartDate__c = null;
                request.SeriesEndDate__c = null;
            }
            for (WorkOrder workOrder : request.Work_Orders__r) {
                if (workOrder.Status != 'Canceled') {
                    if (
                        workOrder.StartDate != null &&
                        (workOrder.StartDate < request.StartTime__c ||
                        request.StartTime__c == null)
                    ) {
                        request.StartTime__c = workOrder.StartDate;
                        request.EndTime__c = workOrder.EndDate;
                    }
                    if (
                        workOrder.StartDate.date() != null &&
                        (workOrder.StartDate.date() < request.SeriesStartDate__c ||
                        request.SeriesStartDate__c == null)
                    ) {
                        request.SeriesStartDate__c = workOrder.StartDate.date();
                    }
                    if (
                        workOrder.EndDate.date() != null &&
                        (workOrder.EndDate.date() > request.SeriesEndDate__c ||
                        request.SeriesEndDate__c == null)
                    ) {
                        request.SeriesEndDate__c = workOrder.EndDate.date();
                    }
                }
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
        Set<Id> requestIds = new Set<Id>();
        for (WorkOrder workOrder : workOrders) {
            requestIds.add(workOrder.HOT_Request__c);
        }
        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(
            [
                SELECT
                    Id,
                    Account__c,
                    MeetingPostalCity__c,
                    HOT_PersonContactId__c,
                    Description__c,
                    InterpretationPostalCity__c,
                    InterpretationPostalCode__c,
                    InterpretationStreet__c,
                    OwnerId,
                    MeetingPostalCode__c,
                    MeetingStreet__c,
                    Subject__c,
                    ServiceTerritory__c
                FROM HOT_Request__c
                WHERE Id IN :requestIds
            ]
        );

        for (WorkOrder workOrder : workOrders) {
            workOrder.AccountId = requests.get(workOrder.HOT_Request__c).Account__c;
            workOrder.City = requests.get(workOrder.HOT_Request__c).MeetingPostalCity__c;
            workOrder.ContactId = requests.get(workOrder.HOT_Request__c).HOT_PersonContactId__c;
            workOrder.Description = requests.get(workOrder.HOT_Request__c).Description__c;
            workOrder.HOT_InterpretationPostalCity__c = requests.get(workOrder.HOT_Request__c)
                .InterpretationPostalCity__c;
            workOrder.HOT_InterpretationPostalCode__c = requests.get(workOrder.HOT_Request__c)
                .InterpretationPostalCode__c;
            workOrder.HOT_InterpretationStreet__c = requests.get(workOrder.HOT_Request__c).InterpretationStreet__c;
            workOrder.OwnerId = requests.get(workOrder.HOT_Request__c).OwnerId;
            workOrder.PostalCode = requests.get(workOrder.HOT_Request__c).MeetingPostalCode__c;
            workOrder.Street = requests.get(workOrder.HOT_Request__c).MeetingStreet__c;
            workOrder.Subject = requests.get(workOrder.HOT_Request__c).Subject__c;
            workOrder.ServiceTerritoryId = requests.get(workOrder.HOT_Request__c).ServiceTerritory__c;
        }
        update workOrders;
    }

    public static void setCancelDate(List<WorkOrder> workorders) {
        List<Id> requestIds = new List<Id>();
        for (WorkOrder workOrder : workOrders) {
            requestIds.add(workOrder.HOT_Request__c);
        }
        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(
            [SELECT Id, CanceledDate__c FROM HOT_Request__c WHERE Id IN :requestIds]
        );
        for (WorkOrder workOrder : workorders) {
            if (workOrder.CanceledDate__c == null) {
                if (requests.get(workOrder.HOT_Request__c).CanceledDate__c != null) {
                    workOrder.CanceledDate__c = requests.get(workOrder.HOT_Request__c).CanceledDate__c;
                } else {
                    workOrder.CanceledDate__c = Date.today();
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
