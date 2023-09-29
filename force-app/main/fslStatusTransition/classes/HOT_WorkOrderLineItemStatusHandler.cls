public without sharing class HOT_WorkOrderLineItemStatusHandler extends MyTriggers {
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<WorkOrderLineItem> changedStatusWorkOrderLineItems = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> canceledWorkOrderLineItems = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> annulWorkOrderLineItems = new List<WorkOrderLineItem>();

        for (WorkOrderLineItem workOrderLineItem : (List<WorkOrderLineItem>) records) {
            // Filter for status change
            if (
                workOrderLineItem.WorkOrderId != null &&
                workOrderLineItem.Status != triggerOldMap.get(workOrderLineItem.Id).get('Status')
            ) {
                changedStatusWorkOrderLineItems.add(workOrderLineItem);
            }
            // Filter for canceled work orders
            if (
                workOrderLineItem.Status != triggerOldMap.get(workOrderLineItem.Id).get('Status') &&
                workOrderLineItem.Status == 'Canceled'
            ) {
                canceledWorkOrderLineItems.add(workOrderLineItem);
            }
            // Filter for annul work orders
            if (
                workOrderLineItem.Status != triggerOldMap.get(workOrderLineItem.Id).get('Status') &&
                workOrderLineItem.Status == 'Annul'
            ) {
                annulWorkOrderLineItems.add(workOrderLineItem);
            }
        }
        if (canceledWorkOrderLineItems.size() > 0) {
            updateChildRecords(canceledWorkOrderLineItems, 'Canceled');
        }
        if (annulWorkOrderLineItems.size() > 0) {
            updateChildRecords(annulWorkOrderLineItems, 'Annul');
        }
        if (changedStatusWorkOrderLineItems.size() > 0) {
            updateWorkOrderStatus(changedStatusWorkOrderLineItems);
        }
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<WorkOrderLineItem> updateStatusWorkOrderLineItems = new List<WorkOrderLineItem>();

        for (SObject record : records) {
            if (
                record.getSObjectType() == Schema.WorkOrderLineItem.getSObjectType() &&
                record.get('HOT_IsUpdateStatus__c') == true
            ) {
                updateStatusWorkOrderLineItems.add((WorkOrderLineItem) record);
            }
        }
        if (updateStatusWorkOrderLineItems.size() > 0) {
            updateWorkOrderLineItemStatus(updateStatusWorkOrderLineItems);
        }
    }

    private static void updateWorkOrderStatus(List<WorkOrderLineItem> changedWorkOrderLineItems) {
        List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
        for (WorkOrderLineItem workOrderLineItem : changedWorkOrderLineItems) {
            WorkOrder workOrderToAdd = new WorkOrder(Id = workOrderLineItem.WorkOrderId, HOT_IsUpdateStatus__c = true);
            if (!workOrdersToUpdate.contains(workOrderToAdd)) {
                workOrdersToUpdate.add(workOrderToAdd);
            }
        }
        update workOrdersToUpdate;
    }

    private static void updateWorkOrderLineItemStatus(List<WorkOrderLineItem> workOrderLineItems) {
        List<ServiceAppointment> serviceAppointments = [
            SELECT ParentRecordId, Status
            FROM ServiceAppointment
            WHERE ParentRecordId IN :workOrderLineItems AND Status != 'Annul'
        ];
        Map<Id, List<ServiceAppointment>> serviceAppointmentMaps = new Map<Id, List<ServiceAppointment>>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (serviceAppointmentMaps.containsKey(serviceAppointment.ParentRecordId)) {
                serviceAppointmentMaps.get(serviceAppointment.ParentRecordId).add(serviceAppointment);
            } else {
                List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
                serviceAppointmentList.add(serviceAppointment);
                serviceAppointmentMaps.put(serviceAppointment.ParentRecordId, serviceAppointmentList);
            }
        }

        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            workOrderLineItem.HOT_IsUpdateStatus__c = false;

            if (serviceAppointmentMaps.get(workOrderLineItem.Id) != null) {
                Integer numberOfServiceAppointments = serviceAppointmentMaps.get(workOrderLineItem.Id).size();
                Integer numberOfNone = 0;
                Integer numberOfScheduled = 0;
                Integer numberOfDispatched = 0;
                Integer numberOfCompleted = 0;
                Integer numberOfCannotComplete = 0;
                Integer numberOfCanceled = 0;

                for (ServiceAppointment serviceAppointment : serviceAppointmentMaps.get(workOrderLineItem.Id)) {
                    if (serviceAppointment.Status == 'None' || serviceAppointment.Status == 'Released to Freelance') {
                        numberOfNone++;
                    }
                    if (serviceAppointment.Status == 'Scheduled') {
                        numberOfScheduled++;
                    }
                    if (serviceAppointment.Status == 'Dispatched') {
                        numberOfDispatched++;
                    }
                    if (serviceAppointment.Status == 'Completed') {
                        numberOfCompleted++;
                    }
                    if (serviceAppointment.Status == 'Cannot Complete') {
                        numberOfCannotComplete++;
                    }
                    if (serviceAppointment.Status == 'Canceled') {
                        numberOfCanceled++;
                    }
                }

                System.debug('numberOfServiceAppointments: ' + numberOfServiceAppointments);
                System.debug('numberOfNone: ' + numberOfNone);
                System.debug('numberOfScheduled: ' + numberOfScheduled);
                System.debug('numberOfDispatched: ' + numberOfDispatched);
                System.debug('numberOfCompleted: ' + numberOfCompleted);
                System.debug('numberOfCannotComplete: ' + numberOfCannotComplete);
                System.debug('numberOfCanceled: ' + numberOfCanceled);

                if (numberOfNone == numberOfServiceAppointments) {
                    workOrderLineItem.Status = 'New';
                    continue;
                }
                if (
                    (numberOfScheduled > 0 && numberOfNone + numberOfScheduled == numberOfServiceAppointments) ||
                    (numberOfNone + numberOfScheduled > 0 &&
                    numberOfNone + numberOfScheduled + numberOfDispatched + numberOfCannotComplete + numberOfCanceled ==
                    numberOfServiceAppointments)
                ) {
                    workOrderLineItem.Status = 'Scheduled';
                    continue;
                }
                if (
                    numberOfDispatched + numberOfCannotComplete + numberOfCanceled == numberOfServiceAppointments &&
                    numberOfDispatched > 0
                ) {
                    workOrderLineItem.Status = 'Dispatched';
                    continue;
                }
                if (
                    numberOfCompleted > 0 &&
                    numberOfCompleted + numberOfDispatched + numberOfCanceled == numberOfServiceAppointments
                ) {
                    workOrderLineItem.Status = 'Completed';
                    continue;
                }
                if (numberOfCannotComplete == numberOfServiceAppointments) {
                    workOrderLineItem.Status = 'Cannot Complete';
                    continue;
                }
                if (numberOfCanceled == numberOfServiceAppointments) {
                    workOrderLineItem.Status = 'Canceled';
                    continue;
                }
                if (
                    numberOfCompleted > 0 &&
                    numberOfCannotComplete > 0 &&
                    numberOfCompleted + numberOfCannotComplete + numberOfDispatched + numberOfCanceled ==
                    numberOfServiceAppointments
                ) {
                    workOrderLineItem.Status = 'Partially Complete';
                    continue;
                }
                if (
                    numberOfServiceAppointments > 1 &&
                    numberOfCanceled + numberOfCannotComplete == numberOfServiceAppointments
                ) {
                    workOrderLineItem.Status = 'Cannot Complete';
                    continue;
                }
            }
        }
    }

    private static void updateChildRecords(List<WorkOrderLineItem> changedWorkOrderLineItems, String newStatus) {
        List<ServiceAppointment> serviceAppointments = [
            SELECT Status
            FROM ServiceAppointment
            WHERE
                ParentRecordId IN :changedWorkOrderLineItems
                AND Status != :newStatus
                AND Status != 'Annul'
                AND Status != 'Completed'
        ];

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.Status = newStatus;
        }
        if (serviceAppointments.size() > 0) {
            update serviceAppointments;
        }
    }
}
