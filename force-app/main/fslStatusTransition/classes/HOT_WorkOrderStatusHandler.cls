public without sharing class HOT_WorkOrderStatusHandler extends MyTriggers {
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<WorkOrder> changedStatusWorkOrders = new List<WorkOrder>();
        List<WorkOrder> canceledWorkOrders = new List<WorkOrder>();
        List<WorkOrder> annulWorkOrders = new List<WorkOrder>();

        for (WorkOrder workOrder : (List<WorkOrder>) records) {
            // Filter for status change
            if (workOrder.HOT_Request__c != null && workOrder.Status != triggerOldMap.get(workOrder.Id).get('Status')) {
                changedStatusWorkOrders.add(WorkOrder);
            }
            // Filter for canceled work orders
            if (workOrder.Status != triggerOldMap.get(workOrder.Id).get('Status') && workOrder.Status == 'Canceled') {
                canceledWorkOrders.add(workOrder);
            }
            // Filter for annul work orders
            if (workOrder.Status != triggerOldMap.get(workOrder.Id).get('Status') && workOrder.Status == 'Annul') {
                annulWorkOrders.add(workOrder);
            }
        }
        if (canceledWorkOrders.size() > 0) {
            updateChildRecords(canceledWorkOrders, 'Canceled');
        }
        if (annulWorkOrders.size() > 0) {
            updateChildRecords(annulWorkOrders, 'Annul');
        }
        if (changedStatusWorkOrders.size() > 0) {
            updateRequestStatus(changedStatusWorkOrders);
        }
        HOT_WorkOrderHandler.onAfterUpdateTemp(triggerOldMap, (List<WorkOrder>) records);
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<WorkOrder> updateStatusWorkOrders = new List<WorkOrder>();
        List<WorkOrder> canceledWorkOrders = new List<WorkOrder>();
        List<WorkOrder> notifyDispatcherWorkOrders = new List<WorkOrder>();
        List<WorkOrder> changedStatusWorkOrders = new List<WorkOrder>();

        for (SObject record : records) {
            System.debug('record: ' + record);
            if (record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
                changedStatusWorkOrders.add((WorkOrder) record);
            }
            if (
                record.getSObjectType() == Schema.WorkOrder.getSObjectType() &&
                record.get('HOT_IsUpdateStatus__c') == true
            ) {
                updateStatusWorkOrders.add((WorkOrder) record);
            }
            if (record.get('Status') == 'Canceled' && triggerOldMap.get(record.Id).get('Status') != 'Canceled') {
                canceledWorkOrders.add((WorkOrder) record);
            }
            if (
                record.get('HOT_IsNotifyDispatcher__c') !=
                triggerOldMap.get(record.Id).get('HOT_IsNotifyDispatcher__c') &&
                record.get('HOT_IsNotifyDispatcher__c') == true
            ) {
                notifyDispatcherWorkOrders.add((WorkOrder) record);
            }
        }
        if (updateStatusWorkOrders.size() > 0) {
            updateWorkOrderStatus(updateStatusWorkOrders);
            updateStatusChangedFieldOnWorkOrder(updateStatusWorkOrders, triggerOldMap);
        }
        if (notifyDispatcherWorkOrders.size() > 0) {
            HOT_WorkOrderNotification.notifyDispatchers_workOrderChanged(notifyDispatcherWorkOrders, triggerOldMap);
            HOT_WorkOrderHandler.resetNotifyDispatcher(notifyDispatcherWorkOrders);
        }
        if (changedStatusWorkOrders.size() > 0) {
            updateStatusChangedFieldOnWorkOrder(changedStatusWorkOrders, triggerOldMap);
        }
    }

    private static void updateRequestStatus(List<WorkOrder> changedWorkOrders) {
        List<HOT_Request__c> requestsToUpdate = new List<HOT_Request__c>();
        for (WorkOrder workOrder : changedWorkOrders) {
            HOT_Request__c requestToAdd = new HOT_Request__c(Id = workOrder.HOT_Request__c, IsUpdateStatus__c = true);
            if (!requestsToUpdate.contains(requestToAdd)) {
                requestsToUpdate.add(requestToAdd);
            }
        }
        update requestsToUpdate;
    }

    private static void updateStatusChangedFieldOnWorkOrder(
        List<WorkOrder> changedWorkOrders,
        Map<Id, sObject> triggerOldMap
    ) {
        for (WorkOrder workOrder : changedWorkOrders) {
            if (
                triggerOldMap.get(workOrder.Id).get('Status') != workOrder.Status &&
                (workOrder.Status == 'Dispatched' ||
                workOrder.Status == 'Cannot Complete')
            )
                workOrder.HOT_SendSMSNotificationOnStatusChanged__c = true;
        }
    }

    private static void updateWorkOrderStatus(List<WorkOrder> workOrders) {
        List<WorkOrderLineItem> workOrderLineItems = [
            SELECT WorkOrderId, Status
            FROM WorkOrderLineItem
            WHERE WorkOrderId IN :workOrders AND Status != 'Annul'
        ];
        Map<Id, List<WorkOrderLineItem>> workOrderLineItemsMaps = new Map<Id, List<WorkOrderLineItem>>();

        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            if (workOrderLineItemsMaps.containsKey(workOrderLineItem.WorkOrderId)) {
                workOrderLineItemsMaps.get(workOrderLineItem.WorkOrderId).add(workOrderLineItem);
            } else {
                List<WorkOrderLineItem> workOrderLineItemList = new List<WorkOrderLineItem>();
                workOrderLineItemList.add(workOrderLineItem);
                workOrderLineItemsMaps.put(workOrderLineItem.WorkOrderId, workOrderLineItemList);
            }
        }

        for (WorkOrder workOrder : workOrders) {
            workOrder.HOT_IsUpdateStatus__c = false;

            if (workOrderLineItemsMaps.get(workOrder.Id) != null) {
                Integer numberOfWorkOrderLineItem = workOrderLineItemsMaps.get(workOrder.Id).size();
                Integer numberOfNew = 0;
                Integer numberOfScheduled = 0;
                Integer numberOfDispatched = 0;
                Integer numberOfCompleted = 0;
                Integer numberOfPartiallyComplete = 0;
                Integer numberOfCannotComplete = 0;
                Integer numberOfCanceled = 0;

                for (WorkOrderLineItem workOrderLineItem : workOrderLineItemsMaps.get(workOrder.Id)) {
                    if (workOrderLineItem.Status == 'New') {
                        numberOfNew++;
                    }
                    if (workOrderLineItem.Status == 'Scheduled') {
                        numberOfScheduled++;
                    }
                    if (workOrderLineItem.Status == 'Dispatched') {
                        numberOfDispatched++;
                    }
                    if (workOrderLineItem.Status == 'Completed') {
                        numberOfCompleted++;
                    }
                    if (workOrderLineItem.Status == 'Partially Complete') {
                        numberOfPartiallyComplete++;
                    }
                    if (workOrderLineItem.Status == 'Cannot Complete') {
                        numberOfCannotComplete++;
                    }
                    if (workOrderLineItem.Status == 'Canceled') {
                        numberOfCanceled++;
                    }
                }

                System.debug('numberOfWorkOrderLineItem: ' + numberOfWorkOrderLineItem);
                System.debug('numberOfNew: ' + numberOfNew);
                System.debug('numberOfScheduled: ' + numberOfScheduled);
                System.debug('numberOfDispatched: ' + numberOfDispatched);
                System.debug('numberOfCompleted: ' + numberOfCompleted);
                System.debug('numberOfPartiallyComplete: ' + numberOfPartiallyComplete);
                System.debug('numberOfCannotComplete: ' + numberOfCannotComplete);
                System.debug('numberOfCanceled: ' + numberOfCanceled);

                if (numberOfNew == numberOfWorkOrderLineItem) {
                    workOrder.Status = 'New';
                    continue;
                }
                if (
                    (numberOfScheduled > 0 && numberOfNew + numberOfScheduled == numberOfWorkOrderLineItem) ||
                    (numberOfNew + numberOfScheduled > 0 &&
                    numberOfNew + numberOfScheduled + numberOfDispatched + numberOfCannotComplete + numberOfCanceled ==
                    numberOfWorkOrderLineItem)
                ) {
                    workOrder.Status = 'Scheduled';
                    continue;
                }
                if (
                    numberOfDispatched + numberOfCannotComplete + numberOfCanceled == numberOfWorkOrderLineItem &&
                    numberOfDispatched > 0
                ) {
                    workOrder.Status = 'Dispatched';
                    continue;
                }
                if (
                    numberOfCompleted > 0 &&
                    numberOfCompleted + numberOfDispatched + numberOfCanceled == numberOfWorkOrderLineItem
                ) {
                    workOrder.Status = 'Completed';
                    continue;
                }
                if (numberOfCannotComplete == numberOfWorkOrderLineItem) {
                    workOrder.Status = 'Cannot Complete';
                    continue;
                }
                if (numberOfCanceled == numberOfWorkOrderLineItem) {
                    workOrder.Status = 'Canceled';
                    continue;
                }
                if (
                    (numberOfCompleted > 0 &&
                    numberOfCannotComplete > 0 &&
                    numberOfCompleted + numberOfCannotComplete + numberOfDispatched + numberOfCanceled ==
                    numberOfWorkOrderLineItem) ||
                    (numberOfPartiallyComplete > 0 &&
                    numberOfPartiallyComplete + numberOfCompleted + numberOfCannotComplete + numberOfDispatched +
                    numberOfCanceled == numberOfWorkOrderLineItem)
                ) {
                    workOrder.Status = 'Partially Complete';
                    continue;
                }
            }
        }
    }

    private static void updateChildRecords(List<WorkOrder> changedWorkOrders, String newStatus) {
        List<WorkOrderLineItem> workOrderLineItems = [
            SELECT Status
            FROM WorkOrderLineItem
            WHERE
                WorkOrderId IN :changedWorkOrders
                AND Status != :newStatus
                AND Status != 'Annul'
                AND Status != 'Completed'
                AND Status != 'Partially Complete'
        ];

        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            workOrderLineItem.Status = newStatus;
        }
        if (workOrderLineItems.size() > 0) {
            update workOrderLineItems;
        }
    }
}
