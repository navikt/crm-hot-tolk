@IsTest(IsParallel=true)
public class HOT_RequestNotificationTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('testForespørsel', workType);
        insert request;

        request.Status__c = 'Godkjent';
        update request;
    }

    @IsTest
    private static void canceledByUserTest() {
        Id notificationTypeId = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_NotifyUser'
            LIMIT 1
        ]
        .Id;

        HOT_Request__c request = [
            SELECT Id, StartTime__c, EndTime__c, IsSerieoppdrag__c, SeriesEndDate__c, SeriesStartDate__c, Name
            FROM HOT_Request__c
            LIMIT 1
        ];

        Set<String> recipients = new Set<String>{ UserInfo.getUserId() };

        Test.startTest();
        HOT_RequestNotification.canceledByUser(notificationTypeId, request, recipients);
        Test.stopTest();
    }
}
