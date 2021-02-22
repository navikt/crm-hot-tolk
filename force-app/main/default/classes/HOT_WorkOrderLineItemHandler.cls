public without sharing class HOT_WorkOrderLineItemHandler extends MyTriggers {
    public override void onBeforeInsert() {
        setDefaultFields((List<WorkOrderLineItem>) records);
    }

    public override void onAfterInsert() {
        createChildRecords((List<WorkOrderLineItem>) records);
        updateNumberOfWOLIonWO((List<WorkOrderLineItem>) records);
    }
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<WorkOrderLineItem> statusChangedToAnnul = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> numberOfSAUpdated = new List<WorkOrderLineItem>();
        for (WorkOrderLineItem workOrderLineItem : (List<WorkOrderLineItem>) records) {
            if (
                workOrderLineItem.Status == 'Annul' &&
                triggerOldMap.get(workOrderLineItem.Id).get('Status') != workOrderLineItem.Status
            ) {
                statusChangedToAnnul.add(workOrderLineItem);
            }
            if (
                triggerOldMap.get(workOrderLineItem.Id).get('HOT_NumberOfServiceAppointments__c') !=
                workOrderLineItem.HOT_NumberOfServiceAppointments__c
            ) {
                numberOfSAUpdated.add(workOrderLineItem);
            }
        }
        if (statusChangedToAnnul.size() > 0) {
            updateNumberOfWOLIonWO(statusChangedToAnnul);
        }
        if (numberOfSAUpdated.size() > 0) {
            updateNumberOfSAonWO(numberOfSAUpdated);
        }
    }
    public override void onAfterDelete() {
        updateNumberOfWOLIonWO((List<WorkOrderLineItem>) records);
    }
    public override void onAfterUndelete() {
        updateNumberOfWOLIonWO((List<WorkOrderLineItem>) records);
    }

    public static void updateNumberOfWOLIonWO(List<WorkOrderLineItem> workOrderLineItems) {
        Set<Id> workOrderIds = new Set<Id>();
        List<Id> deletedWorkOrderLineItems = new List<Id>();
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            workOrderIds.add(workOrderLineItem.WorkOrderId);
            if (workOrderLineItem.IsDeleted) {
                deletedWorkOrderLineItems.add(workOrderLineItem.Id);
            }
        }
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                HOT_NumberOfWorkOrderLineItems__c,
                (
                    SELECT Id, Status
                    FROM WorkOrder.WorkOrderLineItems
                    WHERE Id NOT IN :deletedWorkOrderLineItems AND Status != 'Annul'
                )
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ];
        for (WorkOrder workOrder : workOrders) {
            if (workOrder.HOT_NumberOfWorkOrderLineItems__c != workOrder.WorkOrderLineItems.size()) {
                workOrder.HOT_NumberOfWorkOrderLineItems__c = workOrder.WorkOrderLineItems.size();
            }
        }
        update workOrders;
    }
    public static void updateNumberOfSAonWO(List<WorkOrderLineItem> workOrderLineItems) {
        Set<Id> workOrderIds = new Set<Id>();
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            workOrderIds.add(workOrderLineItem.WorkOrderId);
        }
        List<WorkOrder> workOrders = [
            SELECT
                Id,
                HOT_NumberOfServiceAppointments__c,
                (
                    SELECT Id, HOT_NumberOfServiceAppointments__c
                    FROM WorkOrder.WorkOrderLineItems
                    WHERE Status != 'Annul'
                )
            FROM WorkOrder
            WHERE Id IN :workOrderIds
        ];
        for (WorkOrder workOrder : workOrders) {
            Integer numberOfServiceAppointments = 0;
            for (WorkOrderLineItem workOrderLineItem : workOrder.WorkOrderLineItems) {
                numberOfServiceAppointments += (Integer) workOrderLineItem.HOT_NumberOfServiceAppointments__c;
            }
            if (workOrder.HOT_NumberOfServiceAppointments__c != numberOfServiceAppointments) {
                workOrder.HOT_NumberOfServiceAppointments__c = numberOfServiceAppointments;
            }
        }
        update workOrders;
    }

    public static void createChildRecords(List<WorkOrderLineItem> workOrderLineItems) {
        List<Id> workOrderIds = new List<Id>();
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            workOrderIds.add(workOrderLineItem.WorkOrderId);
        }
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(
            [
                SELECT
                    Id,
                    OwnerId,
                    HOT_Request__c,
                    HOT_Request__r.PreferredResource1__c,
                    HOT_Request__r.PreferredResource2__c,
                    HOT_Request__r.PreferredResource3__c,
                    HOT_Request__r.InterpretationMethod__c,
                    HOT_Request__r.IsScreenInterpreter__c
                FROM WorkOrder
                WHERE Id IN :workOrderIds
            ]
        );

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            for (
                Integer numberOfInterpreters = 0;
                numberOfInterpreters < workOrderLineItem.HOT_NumberOfInterpreters__c;
                numberOfInterpreters++
            ) {
                ServiceAppointment serviceAppointment = new ServiceAppointment();

                serviceAppointment.ParentRecordId = workOrderLineItem.Id;
                serviceAppointment.City = workOrderLineItem.City;
                serviceAppointment.Description = workOrderLineItem.Description;
                serviceAppointment.DueDate = workOrderLineItem.EndDate;
                serviceAppointment.HOT_InterpretationPostalCity__c = workOrderLineItem.HOT_InterpretationPostalCity__c;
                serviceAppointment.HOT_InterpretationPostalCode__c = workOrderLineItem.HOT_InterpretationPostalCode__c;
                serviceAppointment.HOT_InterpretationStreet__c = workOrderLineItem.HOT_InterpretationPostalStreet__c;
                serviceAppointment.OwnerId = workOrders.get(workOrderLineItem.WorkOrderId).OwnerId;
                serviceAppointment.PostalCode = workOrderLineItem.PostalCode;
                serviceAppointment.EarliestStartTime = workOrderLineItem.StartDate;
                serviceAppointment.Street = workOrderLineItem.Street;
                serviceAppointment.Subject = workOrderLineItem.Subject;
                serviceAppointment.SchedStartTime = workOrderLineItem.StartDate;
                serviceAppointment.SchedEndTime = workOrderLineItem.EndDate;
                serviceAppointment.HOT_Request__c = workOrders.get(workOrderLineItem.WorkOrderId).HOT_Request__c;
                serviceAppointment.HOT_WorkOrderLineItem__c = workOrderLineItem.Id;
                serviceAppointment.HOT_IsScreenInterpreterNew__c = workOrders.get(workOrderLineItem.WorkOrderId)
                    .HOT_Request__r.IsScreenInterpreter__c;
                if (
                    workOrderLineItem.WorkTypeId ==
                    workOrders.get(workOrderLineItem.WorkOrderId).HOT_Request__r.InterpretationMethod__c
                ) {
                    if (
                        numberOfInterpreters == 2 &&
                        workOrders.get(workOrderLineItem.WorkOrderId).HOT_Request__r.PreferredResource3__c != null
                    ) {
                        serviceAppointment.HOT_PreferredResource__c = workOrders.get(workOrderLineItem.WorkOrderId)
                            .HOT_Request__r.PreferredResource3__c;
                    } else if (
                        numberOfInterpreters == 1 &&
                        workOrders.get(workOrderLineItem.WorkOrderId).HOT_Request__r.PreferredResource2__c != null
                    ) {
                        serviceAppointment.HOT_PreferredResource__c = workOrders.get(workOrderLineItem.WorkOrderId)
                            .HOT_Request__r.PreferredResource2__c;
                    } else if (numberOfInterpreters == 0) {
                        serviceAppointment.HOT_PreferredResource__c = workOrders.get(workOrderLineItem.WorkOrderId)
                            .HOT_Request__r.PreferredResource1__c;
                    }
                }

                serviceAppointments.add(serviceAppointment);
            }
        }
        insert serviceAppointments;
    }

    public static void setDefaultFields(List<WorkOrderLineItem> workOrderLineItems) {
        List<Id> workOrderIds = new List<Id>();
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            workOrderIds.add(workOrderLineItem.WorkOrderId);
        }
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(
            [
                SELECT
                    Id,
                    OwnerId,
                    Subject,
                    Description,
                    StartDate,
                    EndDate,
                    Street,
                    City,
                    PostalCode,
                    HOT_InterpretationPostalCity__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_InterpretationStreet__c
                FROM WorkOrder
                WHERE Id IN :workOrderIds
            ]
        );
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            workOrderLineItem.Status = 'New';
            if (workOrderLineItem.WorkOrderId != null) {
                if (
                    workOrderLineItem.Subject == null &&
                    workOrders.get(workOrderLineItem.WorkOrderId).Subject != null
                ) {
                    workOrderLineItem.Subject = workOrders.get(workOrderLineItem.WorkOrderId).Subject;
                }
                if (
                    workOrderLineItem.Description == null &&
                    workOrders.get(workOrderLineItem.WorkOrderId).Description != null
                ) {
                    workOrderLineItem.Description = workOrders.get(workOrderLineItem.WorkOrderId).Description;
                }
                if (
                    workOrderLineItem.StartDate == null &&
                    workOrders.get(workOrderLineItem.WorkOrderId).StartDate != null
                ) {
                    workOrderLineItem.StartDate = workOrders.get(workOrderLineItem.WorkOrderId).StartDate;
                }
                if (
                    workOrderLineItem.EndDate == null &&
                    workOrders.get(workOrderLineItem.WorkOrderId).EndDate != null
                ) {
                    workOrderLineItem.EndDate = workOrders.get(workOrderLineItem.WorkOrderId).EndDate;
                }
                if (
                    workOrderLineItem.HOT_InterpretationPostalCity__c == null &&
                    workOrders.get(workOrderLineItem.WorkOrderId).HOT_InterpretationPostalCity__c != null
                ) {
                    workOrderLineItem.HOT_InterpretationPostalCity__c = workOrders.get(workOrderLineItem.WorkOrderId)
                        .HOT_InterpretationPostalCity__c;
                }
                if (
                    workOrderLineItem.HOT_InterpretationPostalCode__c == null &&
                    workOrders.get(workOrderLineItem.WorkOrderId).HOT_InterpretationPostalCode__c != null
                ) {
                    workOrderLineItem.HOT_InterpretationPostalCode__c = workOrders.get(workOrderLineItem.WorkOrderId)
                        .HOT_InterpretationPostalCode__c;
                }
                if (
                    workOrderLineItem.HOT_InterpretationPostalStreet__c == null &&
                    workOrders.get(workOrderLineItem.WorkOrderId).HOT_InterpretationStreet__c != null
                ) {
                    workOrderLineItem.HOT_InterpretationPostalStreet__c = workOrders.get(workOrderLineItem.WorkOrderId)
                        .HOT_InterpretationStreet__c;
                }
                if (
                    workOrderLineItem.PostalCode == null &&
                    workOrders.get(workOrderLineItem.WorkOrderId).PostalCode != null
                ) {
                    workOrderLineItem.PostalCode = workOrders.get(workOrderLineItem.WorkOrderId).PostalCode;
                }
                if (workOrderLineItem.Street == null && workOrders.get(workOrderLineItem.WorkOrderId).Street != null) {
                    workOrderLineItem.Street = workOrders.get(workOrderLineItem.WorkOrderId).Street;
                }
                if (workOrderLineItem.City == null && workOrders.get(workOrderLineItem.WorkOrderId).City != null) {
                    workOrderLineItem.City = workOrders.get(workOrderLineItem.WorkOrderId).City;
                }
            }
        }
    }
}
