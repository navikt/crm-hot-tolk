@IsTest
private class HOT_NotificationCentreControllerTest {
    @IsTest
    public static void getMyNotifications() {
        List<HOT_Notification__c> notifications = HOT_NotificationCentreController.getMyNotifications();

        System.assertEquals(0, notifications.size(), 'Got wrong notifications');
    }
    @IsTest
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
    @IsTest
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
    @IsTest
    public static void getPageRef() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        String result = HOT_NotificationCentreController.getTargetPage(workOrder.Id);
        System.assertEquals('mine-bestillinger', result, 'Could not get correct page');
    }
    @IsTest
    public static void getPageRefOtherOrderer() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        request.Orderer__c = currentUser.accountId;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        System.runAs(currentUser) {
            String result = HOT_NotificationCentreController.getTargetPage(workOrder.Id);
            System.assertEquals('mine-bestillinger-andre', result, 'Could not get correct page');
        }
    }
}
