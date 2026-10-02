public without sharing class HOT_SAOwnerGroupNotificationService {
    private static final String NOTIFICATION_TYPE = 'HOT_NotifyDispatcher';

    private NotificationSender notificationSender;

    public HOT_SAOwnerGroupNotificationService() {
        this(new NotificationSender());
    }

    @TestVisible
    private HOT_SAOwnerGroupNotificationService(NotificationSender notificationSender) {
        this.notificationSender = notificationSender;
    }

    public List<HOT_SAOwnerGroupNotification.Result> process(List<HOT_SAOwnerGroupNotification.WorkItem> workItems) {
        List<HOT_SAOwnerGroupNotification.Result> results = new List<HOT_SAOwnerGroupNotification.Result>();
        if (workItems == null || workItems.isEmpty()) {
            return results;
        }

        Map<Id, HOT_SAOwnerGroupNotification.WorkItem> workItemByServiceAppointmentId = new Map<Id, HOT_SAOwnerGroupNotification.WorkItem>();
        for (HOT_SAOwnerGroupNotification.WorkItem workItem : workItems) {
            workItemByServiceAppointmentId.put(workItem.serviceAppointmentId, workItem);
        }

        Map<Id, ServiceAppointment> serviceAppointmentsById = new Map<Id, ServiceAppointment>(
            [SELECT Id, OwnerId FROM ServiceAppointment WHERE Id IN :workItemByServiceAppointmentId.keySet()]
        );

        Map<Id, Id> groupIdByQueueId = HOT_NotificationHandler.getGroupIdByQueueId(
            collectOwnerIds(serviceAppointmentsById.values())
        );
        Id notificationTypeId = getNotificationTypeId();
        List<ServiceAppointment> missingRecipients = new List<ServiceAppointment>();
        List<ServiceAppointment> failedNotifications = new List<ServiceAppointment>();
        List<String> failureMessages = new List<String>();

        for (HOT_SAOwnerGroupNotification.WorkItem workItem : workItems) {
            ServiceAppointment serviceAppointment = serviceAppointmentsById.get(workItem.serviceAppointmentId);
            if (serviceAppointment == null) {
                results.add(
                    HOT_SAOwnerGroupNotification.createResult(
                        workItem.serviceAppointmentId,
                        HOT_SAOwnerGroupNotification.STATUS_SKIPPED,
                        'ServiceAppointment was not found.'
                    )
                );
                continue;
            }

            Id groupId = groupIdByQueueId.get(serviceAppointment.OwnerId);
            if (groupId == null) {
                missingRecipients.add(serviceAppointment);
                results.add(
                    HOT_SAOwnerGroupNotification.createResult(
                        serviceAppointment.Id,
                        HOT_SAOwnerGroupNotification.STATUS_MISSING_RECIPIENT,
                        'Could not resolve formidler group for ServiceAppointment owner.'
                    )
                );
                continue;
            }

            if (notificationTypeId == null) {
                failedNotifications.add(serviceAppointment);
                results.add(
                    HOT_SAOwnerGroupNotification.createResult(
                        serviceAppointment.Id,
                        HOT_SAOwnerGroupNotification.STATUS_FAILED,
                        'Custom notification type was not found.'
                    )
                );
                continue;
            }

            try {
                notificationSender.send(
                    HOT_NotificationHandler.prepareNotification(
                        workItem.title,
                        workItem.body,
                        notificationTypeId,
                        serviceAppointment.Id
                    ),
                    new Set<String>{ String.valueOf(groupId) }
                );
                results.add(
                    HOT_SAOwnerGroupNotification.createResult(
                        serviceAppointment.Id,
                        HOT_SAOwnerGroupNotification.STATUS_SENT,
                        'Notification sent.'
                    )
                );
            } catch (Exception exceptionThrown) {
                failedNotifications.add(serviceAppointment);
                failureMessages.add(exceptionThrown.getTypeName() + ': ' + exceptionThrown.getMessage());
                results.add(
                    HOT_SAOwnerGroupNotification.createResult(
                        serviceAppointment.Id,
                        HOT_SAOwnerGroupNotification.STATUS_FAILED,
                        exceptionThrown.getMessage()
                    )
                );
            }
        }

        logProcessingIssues(missingRecipients, failedNotifications, failureMessages);
        return results;
    }

    private static List<Id> collectOwnerIds(List<ServiceAppointment> serviceAppointments) {
        Set<Id> ownerIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (serviceAppointment.OwnerId != null) {
                ownerIds.add(serviceAppointment.OwnerId);
            }
        }
        return new List<Id>(ownerIds);
    }

    private static Id getNotificationTypeId() {
        List<CustomNotificationType> notificationTypes = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = :NOTIFICATION_TYPE
            LIMIT 1
        ];
        return notificationTypes.isEmpty() ? null : notificationTypes[0].Id;
    }

    private static void logProcessingIssues(
        List<ServiceAppointment> missingRecipients,
        List<ServiceAppointment> failedNotifications,
        List<String> failureMessages
    ) {
        List<String> messages = new List<String>();
        List<ServiceAppointment> affectedRecords = new List<ServiceAppointment>();

        if (!missingRecipients.isEmpty()) {
            messages.add('Missing formidler group for ServiceAppointments: ' + joinRecordIds(missingRecipients));
            affectedRecords.addAll(missingRecipients);
        }
        if (!failedNotifications.isEmpty()) {
            String failureDetails = failureMessages.isEmpty()
                ? 'Notification type is missing.'
                : String.join(failureMessages, ' | ');
            messages.add(
                'Failed notifications for ServiceAppointments: ' +
                joinRecordIds(failedNotifications) +
                '. Details: ' +
                failureDetails
            );
            affectedRecords.addAll(failedNotifications);
        }
        if (messages.isEmpty()) {
            return;
        }

        // One log entry per chunk keeps mass updates from producing synchronous logging DML per record.
        LoggerUtility logger = new LoggerUtility();
        logger.warning(String.join(messages, ' | '), affectedRecords[0], CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }

    private static String joinRecordIds(List<ServiceAppointment> serviceAppointments) {
        List<String> ids = new List<String>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ids.add(String.valueOf(serviceAppointment.Id));
        }
        return String.join(ids, ',');
    }

    public virtual class NotificationSender {
        public virtual void send(Messaging.CustomNotification notification, Set<String> recipients) {
            notification.send(recipients);
        }
    }
}
