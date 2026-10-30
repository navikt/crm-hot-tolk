public without sharing class HOT_InterestedResourceNotification {
    public static void newWantedServiceResource(List<Id> wantedIrIds) {
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT
                Id,
                ServiceResource__c,
                ServiceResource__r.RelatedRecordId,
                ServiceResource__r.HOT_IsEmployedInterpreter__c,
                ServiceResource__r.HOT_NotificationChannel__c,
                ServiceAppointment__c,
                ServiceAppointment__r.AppointmentNumber
            FROM HOT_InterestedResource__c
            WHERE Id IN :wantedIrIds
        ];

        if (interestedResources.isEmpty()) {
            return;
        }

        List<HOT_Notification__c> notifications = new List<HOT_Notification__c>();
        Set<Id> smsInterestedResourceIds = new Set<Id>();
        Map<String, CustomNotificationType> notificationTypes = new Map<String, CustomNotificationType>();
        for (CustomNotificationType notificationType : [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName IN ('HOT_NotifyUser', 'HOT_NotifyInterpreter')
        ]) {
            notificationTypes.put(notificationType.DeveloperName, notificationType);
        }

        for (HOT_InterestedResource__c interestedResource : interestedResources) {
            ServiceResource resource = interestedResource.ServiceResource__r;
            Boolean isEmployee = resource.HOT_IsEmployedInterpreter__c == true;
            Id recipientId = resource.RelatedRecordId;
            Boolean usesPush =
                isEmployee ||
                (resource.HOT_NotificationChannel__c != null && resource.HOT_NotificationChannel__c.contains('Push'));

            if (!isEmployee && (!usesPush || recipientId == null)) {
                smsInterestedResourceIds.add(interestedResource.Id);
                continue;
            }

            sendPushNotification(getWantedNotificationType(notificationTypes, isEmployee), interestedResource);
            notifications.add(createNotificationForList(interestedResource));
        }

        if (!smsInterestedResourceIds.isEmpty()) {
            HOT_ReminderSMSService.sendSMSOnNewWantedSR(smsInterestedResourceIds);
        }

        try {
            HOT_NotificationCentreController.createNotification(notifications);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
        }
    }

    @TestVisible
    private static CustomNotificationType getWantedNotificationType(
        Map<String, CustomNotificationType> notificationTypes,
        Boolean isEmployee
    ) {
        String developerName = isEmployee ? 'HOT_NotifyInterpreter' : 'HOT_NotifyUser';
        CustomNotificationType notificationType = notificationTypes.get(developerName);
        if (notificationType == null) {
            throw new WantedNotificationException('Missing CustomNotificationType ' + developerName);
        }
        return notificationType;
    }

    private static void sendPushNotification(
        CustomNotificationType notificationType,
        HOT_InterestedResource__c interestedResource
    ) {
        ServiceResource resource = interestedResource.ServiceResource__r;
        if (resource.RelatedRecordId == null) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(
                new WantedNotificationException(
                    'Missing user for wanted ServiceResource ' + interestedResource.ServiceResource__c
                ),
                CRM_ApplicationDomain.Domain.HOT
            );
            logger.publish();
            return;
        }

        HOT_UserNotificationService.newWantedSRNotification(
            notificationType,
            new Set<String>{ String.valueOf(resource.RelatedRecordId) },
            interestedResource.ServiceAppointment__r.AppointmentNumber,
            resource.HOT_IsEmployedInterpreter__c == true ? interestedResource.ServiceAppointment__c : null
        );
    }

    private static HOT_Notification__c createNotificationForList(HOT_InterestedResource__c interestedResource) {
        return new HOT_Notification__c(
            HOT_ServiceResource__c = interestedResource.ServiceResource__c,
            HOT_NotificationChannel__c = 'Push-varsel i appen',
            HOT_Subject__c = 'Du er ønsket til et oppdrag. ' +
                interestedResource.ServiceAppointment__r.AppointmentNumber,
            HOT_NotificationText__c = 'Du kan melde interesse for oppdraget eller avslå.',
            HOT_RelatedObject__c = interestedResource.Id,
            HOT_RelatedObjectType__c = 'wanted'
        );
    }

    private class WantedNotificationException extends Exception {
    }

    public static CustomNotificationType getCustomNotificationType(String devName) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = :devName
        ];
        return notificationType;
    }
}
