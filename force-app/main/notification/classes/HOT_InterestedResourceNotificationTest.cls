@isTest
private class HOT_InterestedResourceNotificationTest {
    @testSetup
    static void setup() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        insert serviceResource;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_InterestedResourceHandler', workType);
        request.NumberOfInterpreters__c = 3;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c(
            ServiceResource__c = serviceResource.Id,
            Status__c = 'Interested',
            ServiceAppointment__c = serviceAppointment.Id
        );
        insert interestedResource;
    }

    @isTest
    static void CustomNotificationTypeTest() {
        String devName = [SELECT DeveloperName FROM CustomNotificationType LIMIT 1].DeveloperName;

        Test.startTest();
        HOT_InterestedResourceNotification.getCustomNotificationType(devName);
        Test.stopTest();
    }

    @isTest
    static void InterestedUserIdTest() {
        list<id> ids = new List<id>{ [SELECT id FROM HOT_InterestedResource__c LIMIT 1].id };

        Test.startTest();
        HOT_InterestedResourceNotification.newWantedServiceResource(ids);
        Test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT HOT_NotificationChannel__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :ids[0]
        ];
        System.assertEquals(1, notifications.size());
        System.assertEquals('Push-varsel i appen', notifications[0].HOT_NotificationChannel__c);
    }

    @isTest
    static void employeeReceivesPushWithoutChannel() {
        assertEmployeeReceivesPush(null);
    }

    @isTest
    static void employeeReceivesPushInsteadOfSms() {
        assertEmployeeReceivesPush('SMS');
    }

    private static void assertEmployeeReceivesPush(String channel) {
        HOT_InterestedResource__c interestedResource = [
            SELECT Id, ServiceResource__c, ServiceAppointment__r.AppointmentNumber
            FROM HOT_InterestedResource__c
            LIMIT 1
        ];
        update new ServiceResource(
            Id = interestedResource.ServiceResource__c,
            HOT_IsEmployedInterpreter__c = true,
            HOT_IsFreelanceInterpreter__c = false,
            HOT_NotificationChannel__c = channel
        );
        Integer smsCount = [SELECT COUNT() FROM SMS__c];

        Test.startTest();
        HOT_InterestedResourceNotification.newWantedServiceResource(new List<Id>{ interestedResource.Id });
        Test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT HOT_ServiceResource__c, HOT_NotificationChannel__c, HOT_Subject__c, HOT_RelatedObjectType__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :interestedResource.Id
        ];
        System.assertEquals(1, notifications.size(), 'The employee must receive a notification record');
        System.assertEquals(interestedResource.ServiceResource__c, notifications[0].HOT_ServiceResource__c);
        System.assertEquals('Push-varsel i appen', notifications[0].HOT_NotificationChannel__c);
        System.assertEquals('wanted', notifications[0].HOT_RelatedObjectType__c);
        System.assertEquals(
            'Du er ønsket til et oppdrag. ' + interestedResource.ServiceAppointment__r.AppointmentNumber,
            notifications[0].HOT_Subject__c
        );
        System.assertEquals(smsCount, [SELECT COUNT() FROM SMS__c], 'Employees must never receive SMS');
    }

    @isTest
    static void freelanceWithoutPushKeepsSmsNotification() {
        HOT_InterestedResource__c interestedResource = [
            SELECT Id, ServiceResource__c
            FROM HOT_InterestedResource__c
            LIMIT 1
        ];
        update new ServiceResource(
            Id = interestedResource.ServiceResource__c,
            HOT_IsEmployedInterpreter__c = false,
            HOT_NotificationChannel__c = 'SMS'
        );

        Test.startTest();
        HOT_InterestedResourceNotification.newWantedServiceResource(new List<Id>{ interestedResource.Id });
        Test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT HOT_NotificationChannel__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :interestedResource.Id
        ];
        System.assertEquals(1, notifications.size());
        System.assertEquals('SMS', notifications[0].HOT_NotificationChannel__c);
    }

    @isTest
    static void emptyWantedListDoesNothing() {
        Test.startTest();
        HOT_InterestedResourceNotification.newWantedServiceResource(new List<Id>());
        System.assertEquals(0, Limits.getDmlStatements());
        Test.stopTest();
    }

    @isTest
    static void wantedNotificationTypesMatchRecipient() {
        Map<String, CustomNotificationType> notificationTypes = new Map<String, CustomNotificationType>();
        for (CustomNotificationType notificationType : [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName IN ('HOT_NotifyUser', 'HOT_NotifyInterpreter')
        ]) {
            notificationTypes.put(notificationType.DeveloperName, notificationType);
        }

        System.assertEquals(
            'HOT_NotifyInterpreter',
            HOT_InterestedResourceNotification.getWantedNotificationType(notificationTypes, true).DeveloperName
        );
        System.assertEquals(
            'HOT_NotifyUser',
            HOT_InterestedResourceNotification.getWantedNotificationType(notificationTypes, false).DeveloperName
        );
    }

    @isTest
    static void freelancePushTargetsWantedList() {
        Map<String, Object> pageReference = (Map<String, Object>) JSON.deserializeUntyped(
            HOT_UserNotificationService.getTargetPageRefWanted()
        );
        Map<String, Object> attributes = (Map<String, Object>) pageReference.get('attributes');
        Map<String, Object> state = (Map<String, Object>) pageReference.get('state');

        System.assertEquals('comm__namedPage', pageReference.get('type'));
        System.assertEquals('Mine_Oppdrag__c', attributes.get('name'));
        System.assertEquals('wanted', state.get('list'));
    }
}
