@isTest
private class HOT_MassNotificationServiceTest {
    @testSetup
    static void setup() {
    }

    @isTest
    static void getUsersByProfileTest() {
        Set<String> userIds = HOT_MassNotificationService.getUsersWithProfiles(
            new List<String>{ 'System Administrator', 'admin' }
        );
        System.assertNotEquals(0, userIds.size(), 'Could not get Users by profile');
    }
    @isTest
    static void getMassNotificationTypeIdTest() {
        Id notificationTypeId = HOT_MassNotificationService.getMassNotificationTypeId();
        System.assertNotEquals(null, notificationTypeId, 'Could not get notificationTypeId');
    }
    @isTest
    static void prepNotificationTest() {
        Messaging.CustomNotification notification = HOT_MassNotificationService.prepNotification();
        System.assertNotEquals(null, notification, 'Could not get notification');
    }
}
