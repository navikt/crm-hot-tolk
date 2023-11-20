@IsTest
private class HOT_ThreadSharingServiceTest {
    @TestSetup
    static void makeData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;
    }

    @IsTest
    private static void testGrantAccess() {
        Map<Id, Set<Id>> interpreterByThread = new Map<Id, Set<Id>>();
        Set<Id> participants = new Set<Id>();
        User user = [SELECT Id FROM User LIMIT 1];

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.HOT_Participants__c = user.Id;
        insert thread;

        participants.add(user.Id);
        interpreterByThread.put(thread.Id, participants);

        Test.startTest();
        HOT_ThreadSharingService.grantAccess(interpreterByThread);
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Thread__Share
                WHERE UserOrGroupId = :user.Id AND ParentId = :thread.Id AND RowCause = 'Manual'
            ]
        );
    }
}
