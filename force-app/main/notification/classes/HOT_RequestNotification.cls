public without sharing class HOT_RequestNotification {
    public static void notifyDispatchers_requestChanged(List<HOT_Request__c> requests, Map<Id, sObject> triggerOldMap) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_Service_Appointment_Changed'
        ];

        requests = checkWorkOrders(requests);

        List<Id> queueIds = new List<Id>();
        for (HOT_Request__c request : requests) {
            queueIds.add(request.OwnerId);
        }
        Map<Id, Id> groupByQueue = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);
        Map<Id, Set<String>> recipientsByGroupId = HOT_NotificationHandler.getUsersInGroup(groupByQueue.values());

        for (HOT_Request__c request : requests) {
            HOT_Request__c oldRequest = (HOT_Request__c) triggerOldMap.get(request.Id);

            Set<String> recipients = recipientsByGroupId.get(groupByQueue.get(request.OwnerId));

            // Varsel ved avlyst av bruker
            if (
                request.Status__c == 'Avlyst' &&
                oldRequest.Status__c != 'Avlyst' &&
                !recipients.contains(request.LastModifiedById)
            ) {
                canceledByUser(notificationType, request, recipients);
            }
        }
    }
    public static void canceledByUser(
        CustomNotificationType notificationType,
        HOT_Request__c request,
        Set<String> recipients
    ) {
        String title = request.Name + ' - ' + request.StartTime__c?.format('d.M.yyyy') + ' - ' + ' Avlyst';
        String body =
            'Forespørselen ' +
            request.Name +
            ' som skulle vært gjennomført ' +
            request.StartTime__c?.format('d.M.yyyy') +
            ' ble avlyst.';

        Id notificationTypeId = notificationType.Id;
        Id targetId = request.Id;
        Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
            title,
            body,
            notificationTypeId,
            targetId
        );
        HOT_NotificationHandler.sendNotification(notification, recipients, (SObject) request);
    }

    public static List<HOT_Request__c> checkWorkOrders(List<HOT_Request__c> unfilteredRequests) {
        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(unfilteredRequests);
        List<WorkOrder> workOrders = [
            SELECT Id, Status, HOT_Request__c
            FROM WorkOrder
            WHERE HOT_Request__c IN :requests.keySet()
        ];
        Map<Id, List<WorkOrder>> workOrdersByRequestId = new Map<Id, List<WorkOrder>>();
        for (WorkOrder workOrder : workOrders) {
            if (workorder.Status != 'Avlyst') {
                if (workOrdersByRequestId.get(workOrder.HOT_Request__c) == null) {
                    List<WorkOrder> workOrderList = new List<WorkOrder>{ workOrder };
                    workOrdersByRequestId.put(workOrder.HOT_Request__c, workOrderList);
                } else {
                    workOrdersByRequestId.get(workOrder.HOT_Request__c).add(workOrder);
                }
            }
        }
        for (Id requestId : requests.keySet()) {
            if (requests.get(requestId) != null && workOrdersByRequestId.get(requestId) != null) {
                if (requests.get(requestId).NumberOfWorkOrders__c == workOrdersByRequestId.get(requestId).size()) {
                    requests.remove(requestId);
                }
            }
        }
        return requests.values();
    }
}
