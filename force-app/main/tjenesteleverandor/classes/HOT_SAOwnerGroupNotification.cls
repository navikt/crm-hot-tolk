public without sharing class HOT_SAOwnerGroupNotification {
    private static final String NOTIFICATION_TYPE = 'HOT_NotifyDispatcher';
    private static final Integer QUEUEABLE_CHUNK_SIZE = 10;
    private static final String STATUS_FAILED = 'Failed';
    private static final String STATUS_MISSING_RECIPIENT = 'MissingRecipient';
    private static final String STATUS_QUEUED = 'Queued';
    private static final String STATUS_SENT = 'Sent';
    private static final String STATUS_SKIPPED = 'Skipped';

    public class Request {
        @InvocableVariable(required=true label='Service Appointment Id')
        public Id serviceAppointmentId;

        @InvocableVariable(required=true label='Title')
        public String title;

        @InvocableVariable(required=true label='Body')
        public String body;
    }

    public class Result {
        @InvocableVariable(label='Service Appointment Id')
        public Id serviceAppointmentId;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Queued')
        public Boolean queued;

        @InvocableVariable(label='Sent')
        public Boolean sent;

        @InvocableVariable(label='Skipped')
        public Boolean skipped;

        @InvocableVariable(label='Missing Recipient')
        public Boolean missingRecipient;

        @InvocableVariable(label='Message')
        public String message;
    }

    public class WorkItem {
        public Id serviceAppointmentId;
        public String title;
        public String body;
    }

    @InvocableMethod(
        label='Notify Service Appointment Owner Group'
        description='Queues custom notifications to the formidler group derived from the ServiceAppointment owner.'
        category='HOT Tolketjeneste'
        iconName='slds:standard:service_appointment'
    )
    public static List<Result> send(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        List<WorkItem> workItems = collectWorkItems(requests, results, true);
        if (workItems.isEmpty()) {
            return results;
        }

        try {
            System.enqueueJob(new NotificationQueueable(workItems));
        } catch (Exception e) {
            logException(e);
            for (Result result : results) {
                if (result.status == STATUS_QUEUED) {
                    setStatus(result, STATUS_FAILED, 'Could not queue notification job.');
                }
            }
        }

        return results;
    }

    @TestVisible
    private static List<Result> processSynchronously(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        List<WorkItem> workItems = collectWorkItems(requests, results, false);
        if (!workItems.isEmpty()) {
            results.addAll(processWorkItems(workItems));
        }
        return results;
    }

    private static List<Result> processWorkItems(List<WorkItem> workItems) {
        List<Result> results = new List<Result>();
        if (workItems == null || workItems.isEmpty()) {
            return results;
        }

        Map<Id, WorkItem> workItemByServiceAppointmentId = new Map<Id, WorkItem>();
        for (WorkItem workItem : workItems) {
            workItemByServiceAppointmentId.put(workItem.serviceAppointmentId, workItem);
        }

        Map<Id, ServiceAppointment> serviceAppointmentsById = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, OwnerId
                FROM ServiceAppointment
                WHERE Id IN :workItemByServiceAppointmentId.keySet()
            ]
        );

        List<Id> queueIds = new List<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointmentsById.values()) {
            if (serviceAppointment.OwnerId != null) {
                queueIds.add(serviceAppointment.OwnerId);
            }
        }

        Map<Id, Id> groupIdByQueueId = HOT_NotificationHandler.getGroupIdByQueueId(queueIds);
        Id notificationTypeId;
        List<ServiceAppointment> missingRecipientServiceAppointments = new List<ServiceAppointment>();

        for (Id serviceAppointmentId : workItemByServiceAppointmentId.keySet()) {
            ServiceAppointment serviceAppointment = serviceAppointmentsById.get(serviceAppointmentId);
            if (serviceAppointment == null) {
                results.add(createResult(serviceAppointmentId, STATUS_SKIPPED, 'ServiceAppointment was not found.'));
                continue;
            }

            Id groupId = groupIdByQueueId.get(serviceAppointment.OwnerId);
            if (groupId == null) {
                missingRecipientServiceAppointments.add(serviceAppointment);
                results.add(
                    createResult(
                        serviceAppointmentId,
                        STATUS_MISSING_RECIPIENT,
                        'Could not resolve formidler group for ServiceAppointment owner.'
                    )
                );
                continue;
            }

            if (notificationTypeId == null) {
                notificationTypeId = getNotificationTypeId();
            }

            WorkItem workItem = workItemByServiceAppointmentId.get(serviceAppointmentId);
            Messaging.CustomNotification notification = HOT_NotificationHandler.prepareNotification(
                workItem.title,
                workItem.body,
                notificationTypeId,
                serviceAppointment.Id
            );
            try {
                notification.send(new Set<String>{ String.valueOf(groupId) });
                results.add(createResult(serviceAppointmentId, STATUS_SENT, 'Notification sent.'));
            } catch (Exception e) {
                logException(e);
                results.add(createResult(serviceAppointmentId, STATUS_FAILED, e.getMessage()));
            }
        }

        logMissingRecipients(missingRecipientServiceAppointments);
        return results;
    }

    private static Id getNotificationTypeId() {
        return [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = :NOTIFICATION_TYPE
            LIMIT 1
        ]
        .Id;
    }

    private static List<WorkItem> collectWorkItems(List<Request> requests, List<Result> results, Boolean queueResults) {
        List<WorkItem> workItems = new List<WorkItem>();
        Set<Id> collectedServiceAppointmentIds = new Set<Id>();

        for (Request request : requests) {
            if (request?.serviceAppointmentId == null || String.isBlank(request.title) || String.isBlank(request.body)) {
                results.add(createResult(request?.serviceAppointmentId, STATUS_SKIPPED, 'Invalid notification request.'));
                continue;
            }
            if (collectedServiceAppointmentIds.contains(request.serviceAppointmentId)) {
                results.add(createResult(request.serviceAppointmentId, STATUS_SKIPPED, 'Duplicate notification request.'));
                continue;
            }

            WorkItem workItem = new WorkItem();
            workItem.serviceAppointmentId = request.serviceAppointmentId;
            workItem.title = request.title;
            workItem.body = request.body;
            workItems.add(workItem);
            collectedServiceAppointmentIds.add(request.serviceAppointmentId);

            if (queueResults) {
                results.add(createResult(request.serviceAppointmentId, STATUS_QUEUED, 'Notification job queued.'));
            }
        }

        return workItems;
    }

    private static Result createResult(Id serviceAppointmentId, String status, String message) {
        Result result = new Result();
        result.serviceAppointmentId = serviceAppointmentId;
        result.message = message;
        setStatus(result, status, message);
        return result;
    }

    private static void setStatus(Result result, String status, String message) {
        result.status = status;
        result.message = message;
        result.queued = status == STATUS_QUEUED;
        result.sent = status == STATUS_SENT;
        result.skipped = status == STATUS_SKIPPED;
        result.missingRecipient = status == STATUS_MISSING_RECIPIENT;
    }

    private static void logException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }

    private static void logMissingRecipients(List<ServiceAppointment> serviceAppointments) {
        if (serviceAppointments == null || serviceAppointments.isEmpty()) {
            return;
        }

        List<String> serviceAppointmentIds = new List<String>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointmentIds.add(String.valueOf(serviceAppointment.Id));
        }

        LoggerUtility logger = new LoggerUtility();
        logger.warning(
            'Could not resolve formidler group for ' +
                String.valueOf(serviceAppointments.size()) +
                ' ServiceAppointment owner(s): ' +
                String.join(serviceAppointmentIds, ','),
            serviceAppointments[0],
            CRM_ApplicationDomain.Domain.HOT
        );
        logger.publishSynch();
    }

    public class NotificationQueueable implements Queueable {
        private List<WorkItem> workItems;

        public NotificationQueueable(List<WorkItem> workItems) {
            this.workItems = workItems == null ? new List<WorkItem>() : workItems;
        }

        public void execute(QueueableContext context) {
            List<WorkItem> currentChunk = new List<WorkItem>();
            List<WorkItem> remainingWorkItems = new List<WorkItem>();

            for (Integer index = 0; index < workItems.size(); index++) {
                if (index < QUEUEABLE_CHUNK_SIZE) {
                    currentChunk.add(workItems[index]);
                } else {
                    remainingWorkItems.add(workItems[index]);
                }
            }

            processWorkItems(currentChunk);

            if (!remainingWorkItems.isEmpty()) {
                System.enqueueJob(new NotificationQueueable(remainingWorkItems));
            }
        }
    }
}
