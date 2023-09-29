public without sharing class HOT_RequestStatusHandler extends MyTriggers {
    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<HOT_Request__c> updateStatusRequests = new List<HOT_Request__c>();

        for (SObject record : records) {
            System.debug('record: ' + record);
            if (
                record.getSObjectType() == Schema.HOT_Request__c.getSObjectType() &&
                record.get('IsUpdateStatus__c') == true
            ) {
                updateStatusRequests.add((HOT_Request__c) record);
            }
        }

        if (updateStatusRequests.size() > 0) {
            updateRequestStatus(updateStatusRequests);
        }
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<HOT_Request__c> avlystRequests = new List<HOT_Request__c>();
        List<HOT_Request__c> annullertRequests = new List<HOT_Request__c>();
        List<HOT_Request__c> avslaattRequests = new List<HOT_Request__c>();
        List<HOT_Request__c> cannotCompleteRequests = new List<HOT_Request__c>();

        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
            // Filter for Avlyst requests
            if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Avlyst') {
                avlystRequests.add(request);
            }
            // Filter for Annullert requests
            if (
                request.Status__c != triggerOldMap.get(request.Id).get('Status__c') &&
                request.Status__c == 'Annullert'
            ) {
                annullertRequests.add(request);
            }
            if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Avslått') {
                avslaattRequests.add(request);
            }
            if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Udekket') {
                cannotCompleteRequests.add(request);
            }
        }
        if (avlystRequests.size() > 0) {
            updateChildRecords(avlystRequests, 'Canceled');
        }
        if (annullertRequests.size() > 0) {
            updateChildRecords(annullertRequests, 'Annul');
        }
        if (avslaattRequests.size() > 0) {
            updateChildRecords(avslaattRequests, 'Denied');
        }
        if (cannotCompleteRequests.size() > 0) {
            updateServiceAppointments(cannotCompleteRequests, 'Cannot Complete');
        }
    }

    private static void updateRequestStatus(List<HOT_Request__c> requests) {
        Map<String, String> statusMap = new Map<String, String>(); // Map<Work Order Status, Request Status>
        statusMap.put('New', 'Godkjent');
        statusMap.put('Scheduled', 'Godkjent');
        statusMap.put('Dispatched', 'Tildelt');
        statusMap.put('Completed', 'Dekket');
        statusMap.put('Partially Complete', 'Delvis dekket');
        statusMap.put('Cannot Complete', 'Udekket');
        statusMap.put('Canceled', 'Avlyst');

        List<WorkOrder> workOrders = [
            SELECT HOT_Request__c, Status
            FROM WorkOrder
            WHERE HOT_Request__c IN :requests AND Status != 'Annul'
        ];
        Map<Id, List<WorkOrder>> workOrdersMaps = new Map<Id, List<WorkOrder>>();

        for (WorkOrder workOrder : workOrders) {
            if (workOrdersMaps.containsKey(workOrder.HOT_Request__c)) {
                workOrdersMaps.get(workOrder.HOT_Request__c).add(workOrder);
            } else {
                List<WorkOrder> workOrderList = new List<WorkOrder>();
                workOrderList.add(workOrder);
                workOrdersMaps.put(workOrder.HOT_Request__c, workOrderList);
            }
        }

        for (HOT_Request__c request : requests) {
            request.IsUpdateStatus__c = false;

            if (workOrdersMaps.get(request.Id) != null) {
                Integer numberOfWorkOrder = workOrdersMaps.get(request.Id).size();
                Integer numberOfNew = 0;
                Integer numberOfScheduled = 0;
                Integer numberOfDispatched = 0;
                Integer numberOfCompleted = 0;
                Integer numberOfPartiallyComplete = 0;
                Integer numberOfCannotComplete = 0;
                Integer numberOfCanceled = 0;

                for (WorkOrder workOrder : workOrdersMaps.get(request.Id)) {
                    if (workOrder.Status == 'New') {
                        numberOfNew++;
                    }
                    if (workOrder.Status == 'Scheduled') {
                        numberOfScheduled++;
                    }
                    if (workOrder.Status == 'Dispatched') {
                        numberOfDispatched++;
                    }
                    if (workOrder.Status == 'Completed') {
                        numberOfCompleted++;
                    }
                    if (workOrder.Status == 'Partially Complete') {
                        numberOfPartiallyComplete++;
                    }
                    if (workOrder.Status == 'Cannot Complete') {
                        numberOfCannotComplete++;
                    }
                    if (workOrder.Status == 'Canceled') {
                        numberOfCanceled++;
                    }
                }

                System.debug('numberOfWorkOrder: ' + numberOfWorkOrder);
                System.debug('numberOfNew: ' + numberOfNew);
                System.debug('numberOfScheduled: ' + numberOfScheduled);
                System.debug('numberOfDispatched: ' + numberOfDispatched);
                System.debug('numberOfCompleted: ' + numberOfCompleted);
                System.debug('numberOfPartiallyComplete: ' + numberOfPartiallyComplete);
                System.debug('numberOfCannotComplete: ' + numberOfCannotComplete);
                System.debug('numberOfCanceled: ' + numberOfCanceled);
                if (numberOfCanceled == numberOfWorkOrder) {
                    request.Status__c = statusMap.get('Canceled');
                    continue;
                }
                if (request.Status__c != 'Åpen') {
                    if (numberOfNew > 0 || numberOfScheduled > 0) {
                        request.Status__c = statusMap.get('New');
                        continue;
                    }
                    if (
                        numberOfDispatched > 0 &&
                        (numberOfDispatched + numberOfCanceled + numberOfCannotComplete + numberOfCompleted +
                        numberOfPartiallyComplete == numberOfWorkOrder)
                    ) {
                        request.Status__c = statusMap.get('Dispatched');
                        continue;
                    }
                    if (numberOfCompleted > 0 && (numberOfCompleted + numberOfCanceled == numberOfWorkOrder)) {
                        request.Status__c = statusMap.get('Completed');
                        continue;
                    }
                    if (numberOfCannotComplete + numberOfCanceled == numberOfWorkOrder) {
                        request.Status__c = statusMap.get('Cannot Complete');
                        continue;
                    }
                    if (
                        numberOfCompleted > 0 && numberOfCannotComplete > 0 &&
                        (numberOfCannotComplete + numberOfCompleted + numberOfCanceled == numberOfWorkOrder) ||
                        numberOfPartiallyComplete > 0 &&
                        (numberOfPartiallyComplete + numberOfCannotComplete + numberOfCompleted + numberOfCanceled ==
                        numberOfWorkOrder)
                    ) {
                        request.Status__c = statusMap.get('Partially Complete');
                        continue;
                    }
                }
            }
        }
    }

    private static void updateChildRecords(List<HOT_Request__c> changedRequests, String newStatus) {
        List<WorkOrder> workOrders = [
            SELECT Status, StartDate
            FROM WorkOrder
            WHERE
                HOT_Request__c IN :changedRequests
                AND Status != :newStatus
                AND Status != 'Annul'
                AND Status != 'Completed'
                AND Status != 'Partially Complete'
        ];

        for (WorkOrder workOrder : workOrders) {
            if (workOrder.StartDate > Datetime.now()) {
                workOrder.Status = newStatus;
            }
        }
        if (workOrders.size() > 0) {
            update workOrders;
        }
    }
    private static void updateServiceAppointments(List<HOT_Request__c> changedRequests, String newStatus) {
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, Status, HOT_Request__c
            FROM ServiceAppointment
            WHERE HOT_Request__c IN :changedRequests AND Status != 'Canceled' AND Status != 'Annul'
        ];
        Map<Id, ServiceAppointment> serviceAppointmentMap = new Map<Id, ServiceAppointment>(serviceAppointments);

        List<WorkOrder> workOrders = [
            SELECT Id, Status, HOT_Request__c
            FROM WorkOrder
            WHERE HOT_Request__c IN :changedRequests AND Status != 'Canceled' AND Status != 'Annul'
        ];
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(workOrders);

        for (HOT_Request__c request : changedRequests) {
            Integer numberOfReleasedToFreelance = 0;
            Integer numberOfServiceAppointments = 0;
            for (Id saId : serviceAppointmentMap.keySet()) {
                ServiceAppointment sa = serviceAppointmentMap.get(saId);
                if (sa.HOT_Request__c == request.Id) {
                    if (sa.Status == 'Released to Freelance' || sa.Status == 'Cannot Complete') {
                        numberOfReleasedToFreelance++;
                    }
                    numberOfServiceAppointments++;
                }
            }
            Integer numberOfOpenWorkOrders = 0;
            Integer numberOfWorkOrders = 0;
            for (Id woId : workOrderMap.keySet()) {
                WorkOrder wo = workOrderMap.get(woId);
                if (wo.HOT_Request__c == request.Id) {
                    if (wo.Status == 'New' || wo.Status == 'Cannot Complete') {
                        numberOfOpenWorkOrders++;
                    }
                    numberOfWorkOrders++;
                }
            }

            if (
                numberOfServiceAppointments == numberOfReleasedToFreelance ||
                numberOfOpenWorkOrders == numberOfWorkOrders
            ) {
                for (Id saId : serviceAppointmentMap.keySet()) {
                    ServiceAppointment sa = serviceAppointmentMap.get(saId);
                    if (sa.HOT_Request__c == request.Id) {
                        sa.Status = 'Cannot Complete';
                    }
                }
                update serviceAppointmentMap.values();
            } else {
                request.addError(
                    'Alle oppdrag må være Frigitt til frilans, eller alle arbeidsordre må være Åpen for at du skal kunne sette hele forespørselen til Udekket.'
                );
            }
        }
    }
}
