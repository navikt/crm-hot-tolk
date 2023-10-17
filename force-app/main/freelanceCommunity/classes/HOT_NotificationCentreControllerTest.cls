@isTest
private class HOT_NotificationCentreControllerTest {
    @isTest
    public static void getMyNotifications() {
        List<HOT_Notification__c> notifications = HOT_NotificationCentreController.getMyNotifications();

        System.assertEquals(0, notifications.size(), 'Got wrong notifications');
    }
    @isTest
    public static void createNotification() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.HOT_Account__c = personAccount.Id;
        notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
        notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
        notification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
        notification.HOT_RelatedObjectType__c = 'threadInterpreter';

        notificationList.add(notification);

        HOT_NotificationCentreController.createNotification(notificationList);

        List<HOT_Notification__c> notifications = [SELECT Id FROM HOT_Notification__c];
        System.assertEquals(1, notifications.size(), 'Could not insert notifications');
    }
    @isTest
    public static void getNotificationType() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;
        List<HOT_Notification__c> notificationList = new List<HOT_Notification__c>();
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.HOT_Account__c = personAccount.Id;
        notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
        notification.HOT_Subject__c = 'Ny melding fra Tolketjenesten';
        notification.HOT_NotificationText__c = 'Du har fått en melding fra Tolketjenesten.';
        notification.HOT_RelatedObjectType__c = 'threadInterpreter';

        notificationList.add(notification);

        HOT_NotificationCentreController.createNotification(notificationList);

        HOT_Notification__c notifications = HOT_NotificationCentreController.getNotificationType(notification.Id);
        System.assertEquals(
            'threadInterpreter',
            notifications.HOT_RelatedObjectType__c,
            'Could not get notificationtype'
        );
    }
}
