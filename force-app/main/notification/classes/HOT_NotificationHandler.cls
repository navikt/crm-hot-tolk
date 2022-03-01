public without sharing class HOT_NotificationHandler {
    public static void sendNotification(
        Messaging.CustomNotification notification,
        Set<String> recipients,
        SObject record
    ) {
        LoggerUtility logger = new LoggerUtility();

        if (recipients != null && recipients.size() > 0) {
            try {
                notification.send(recipients);
            } catch (Exception e) {
                logger.exception(e, record, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }
        }
    }
    public static Messaging.CustomNotification prepareNotification(
        String title,
        String body,
        Id notificationTypeId,
        Id targetId
    ) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId(targetId);

        return notification;
    }
}
