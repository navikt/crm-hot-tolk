@IsTest
private class HOT_TLNotificationControllerTest {
    @IsTest
    static void getMyNotificationsReturnsOnlyCurrentUserNotificationsOrderedAsc() {
        HOT_Notification__c firstForCurrentUser = new HOT_Notification__c(
            Tjenesteleverandor__c = UserInfo.getUserId(),
            HOT_Subject__c = 'Tittel',
            HOT_NotificationText__c = 'Tekst',
            HOT_RelatedObject__c = UserInfo.getUserId(),
            HOT_IsRead__c = false
        );
        HOT_Notification__c secondForCurrentUser = new HOT_Notification__c(
            Tjenesteleverandor__c = UserInfo.getUserId(),
            HOT_Subject__c = 'Tittel',
            HOT_NotificationText__c = 'Tekst',
            HOT_RelatedObject__c = UserInfo.getUserId(),
            HOT_IsRead__c = true
        );

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User otherUser = HOT_TestDataFactory.createUser('tlnfoth', profile);
        insert otherUser;

        HOT_Notification__c forOtherUser = new HOT_Notification__c(
            Tjenesteleverandor__c = otherUser.Id,
            HOT_Subject__c = 'Tittel',
            HOT_NotificationText__c = 'Tekst',
            HOT_RelatedObject__c = UserInfo.getUserId(),
            HOT_IsRead__c = false
        );

        insert new List<HOT_Notification__c>{ secondForCurrentUser, forOtherUser, firstForCurrentUser };

        List<HOT_Notification__c> notifications = HOT_TLNotificationController.getMyNotifications();

        System.assertEquals(2, notifications.size(), 'Should return only notifications for current user');
    }

    @IsTest
    static void markAllNotificationsAsReadUpdatesOnlyUnreadForCurrentUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User otherUser = HOT_TestDataFactory.createUser('tlnfmrk', profile);
        insert otherUser;

        HOT_Notification__c unreadCurrentUser = new HOT_Notification__c(
            Tjenesteleverandor__c = UserInfo.getUserId(),
            HOT_Subject__c = 'Tittel',
            HOT_NotificationText__c = 'Tekst',
            HOT_RelatedObject__c = UserInfo.getUserId(),
            HOT_IsRead__c = false
        );
        HOT_Notification__c alreadyReadCurrentUser = new HOT_Notification__c(
            Tjenesteleverandor__c = UserInfo.getUserId(),
            HOT_Subject__c = 'Tittel',
            HOT_NotificationText__c = 'Tekst',
            HOT_RelatedObject__c = UserInfo.getUserId(),
            HOT_IsRead__c = true
        );
        HOT_Notification__c unreadOtherUser = new HOT_Notification__c(
            Tjenesteleverandor__c = otherUser.Id,
            HOT_Subject__c = 'Tittel',
            HOT_NotificationText__c = 'Tekst',
            HOT_RelatedObject__c = UserInfo.getUserId(),
            HOT_IsRead__c = false
        );

        insert new List<HOT_Notification__c>{ unreadCurrentUser, alreadyReadCurrentUser, unreadOtherUser };

        Test.startTest();
        HOT_TLNotificationController.markAllNotificationsAsRead();
        Test.stopTest();

        Map<Id, HOT_Notification__c> notificationsById = new Map<Id, HOT_Notification__c>(
            [
                SELECT Id, HOT_IsRead__c, Tjenesteleverandor__c
                FROM HOT_Notification__c
                WHERE Id IN :new Set<Id>{ unreadCurrentUser.Id, alreadyReadCurrentUser.Id, unreadOtherUser.Id }
            ]
        );

        System.assertEquals(
            true,
            notificationsById.get(unreadCurrentUser.Id).HOT_IsRead__c,
            'Unread current user notification should be marked as read'
        );
        System.assertEquals(
            true,
            notificationsById.get(alreadyReadCurrentUser.Id).HOT_IsRead__c,
            'Already read notification should stay read'
        );
        System.assertEquals(
            false,
            notificationsById.get(unreadOtherUser.Id).HOT_IsRead__c,
            'Other user notification should not be changed'
        );
    }

    @IsTest
    static void markAllNotificationsAsReadWhenNoUnreadDoesNothing() {
        HOT_Notification__c readCurrentUser = new HOT_Notification__c(
            Tjenesteleverandor__c = UserInfo.getUserId(),
            HOT_Subject__c = 'Tittel',
            HOT_NotificationText__c = 'Tekst',
            HOT_RelatedObject__c = UserInfo.getUserId(),
            HOT_IsRead__c = true
        );
        insert readCurrentUser;

        Test.startTest();
        HOT_TLNotificationController.markAllNotificationsAsRead();
        Test.stopTest();

        HOT_Notification__c result = [
            SELECT Id, HOT_IsRead__c
            FROM HOT_Notification__c
            WHERE Id = :readCurrentUser.Id
        ];
        System.assertEquals(true, result.HOT_IsRead__c, 'Read notification should remain read');
    }

    @IsTest
    static void tjenesteleverandorNotificationSendNotificationInsertsExpectedValues() {
        HOT_TjenesteleverandorNotification notification = new HOT_TjenesteleverandorNotification(
            'Du har fått ny melding',
            'Tolk har tatt seg av oppdraget',
            UserInfo.getUserId(),
            'serviceAppointment',
            UserInfo.getUserId()
        );

        Test.startTest();
        notification.sendNotification();
        Test.stopTest();

        HOT_Notification__c insertedNotification = [
            SELECT Tjenesteleverandor__c, HOT_Subject__c, HOT_NotificationText__c, HOT_RelatedObject__c
            FROM HOT_Notification__c
            WHERE HOT_Subject__c = 'Du har fått ny melding'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            UserInfo.getUserId(),
            insertedNotification.Tjenesteleverandor__c,
            'Recipient should be copied to notification'
        );
        System.assertEquals(
            'Du har fått ny melding',
            insertedNotification.HOT_Subject__c,
            'Subject should be copied to notification'
        );
        System.assertEquals(
            'Tolk har tatt seg av oppdraget',
            insertedNotification.HOT_NotificationText__c,
            'Text should be copied to notification'
        );
        System.assertEquals(
            UserInfo.getUserId(),
            insertedNotification.HOT_RelatedObject__c,
            'Related record id should be copied to notification'
        );
    }
}
