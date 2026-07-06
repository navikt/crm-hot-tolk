public without sharing class HOT_SAOwnerGroupNotification {
    private static final String NOTIFICATION_TYPE = 'HOT_NotifyDispatcher';

    public class Request {
        @InvocableVariable(required=true label='Service Appointment Id')
        public Id serviceAppointmentId;

        @InvocableVariable(required=true label='Title')
        public String title;

        @InvocableVariable(required=true label='Body')
        public String body;
    }

    @InvocableMethod(
        label='Notify Service Appointment Owner Group'
        description='Sends a custom notification to the formidler group derived from the ServiceAppointment owner.'
        category='HOT Tolketjeneste'
        iconName='slds:standard:service_appointment'
    )
    public static void send(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        Map<Id, Request> requestByServiceAppointmentId = collectRequests(requests);
        if (requestByServiceAppointmentId.isEmpty()) {
            return;
        }

        Map<Id, ServiceAppointment> serviceAppointmentsById = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, OwnerId
                FROM ServiceAppointment
                WHERE Id IN :requestByServiceAppointmentId.keySet()
            ]
        );

        List<Id> queueIds = new List<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointmentsById.values()) {
            if (serviceAppointment.OwnerId != null) {
                queueIds.add(serviceAppointment.OwnerId);
            }
        }

        Map<Id, Id> groupIdByQueueId = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);
        Id notificationTypeId = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = :NOTIFICATION_TYPE
            LIMIT 1
        ]
        .Id;

        for (Id serviceAppointmentId : requestByServiceAppointmentId.keySet()) {
            ServiceAppointment serviceAppointment = serviceAppointmentsById.get(serviceAppointmentId);
            if (serviceAppointment == null) {
                continue;
            }

            Id groupId = groupIdByQueueId.get(serviceAppointment.OwnerId);
            if (groupId == null) {
                logMissingRecipient(serviceAppointment);
                continue;
            }

            Request request = requestByServiceAppointmentId.get(serviceAppointmentId);
            Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
                request.title,
                request.body,
                notificationTypeId,
                serviceAppointment.Id
            );
            HOT_NotificationHandler.sendNotification(
                notification,
                new Set<String>{ String.valueOf(groupId) },
                serviceAppointment
            );
        }
    }

    private static Map<Id, Request> collectRequests(List<Request> requests) {
        Map<Id, Request> requestByServiceAppointmentId = new Map<Id, Request>();
        for (Request request : requests) {
            if (request?.serviceAppointmentId == null || String.isBlank(request.title) || String.isBlank(request.body)) {
                continue;
            }
            requestByServiceAppointmentId.put(request.serviceAppointmentId, request);
        }
        return requestByServiceAppointmentId;
    }

    private static void logMissingRecipient(ServiceAppointment serviceAppointment) {
        LoggerUtility logger = new LoggerUtility();
        logger.warning(
            'Could not resolve formidler group for ServiceAppointment owner.',
            serviceAppointment,
            CRM_ApplicationDomain.Domain.HOT
        );
        logger.publishSynch();
    }
}
