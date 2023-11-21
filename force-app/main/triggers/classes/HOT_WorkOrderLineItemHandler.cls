public without sharing class HOT_WorkOrderLineItemHandler extends MyTriggers {
    public override void onBeforeInsert() {
        setDefaultFields((List<WorkOrderLineItem>) records);
        setDuration((List<WorkOrderLineItem>) records);
    }

    public override void onAfterInsert() {
        createChildRecords((List<WorkOrderLineItem>) records);
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<WorkOrderLineItem> setDurationWorkOrderLineItems = new List<WorkOrderLineItem>();
        Map<Id, WorkOrderLineItem> oldMap = (Map<Id, WorkOrderLineItem>) triggerOldMap;

        for (WorkOrderLineItem workOrderLineItem : (List<WorkOrderLineItem>) records) {
            if (
                (workOrderLineItem.StartDate != (oldMap.get(workOrderLineItem.Id).StartDate)) ||
                (workOrderLineItem.EndDate != (oldMap.get(workOrderLineItem.Id).EndDate))
            ) {
                setDurationWorkOrderLineItems.add(workOrderLineItem);
            }
        }

        if (setDurationWorkOrderLineItems.size() > 0) {
            setDuration(setDurationWorkOrderLineItems);
        }
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
                    HOT_Request__r.IsScreenInterpreter__c,
                    HOT_Request__r.Company__c
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
                serviceAppointment.HOT_Company__c = workOrders.get(workOrderLineItem.WorkOrderId)
                    .HOT_Request__r.Company__c;
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
            }
        }
    }

    public static void setDuration(List<workOrderLineItem> workOrderLineItems) {
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            workOrderLineItem.Duration =
                ((Double) workOrderLineItem.EndDate.getTime() - (Double) workOrderLineItem.StartDate.getTime()) /
                3600000;
        }
    }
}
