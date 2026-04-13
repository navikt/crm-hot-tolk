@IsTest
private class HOT_ServiceResourceAccessHandlerTest {
    @TestSetup
    static void setup() {
        Profile profileAdmin = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
            LIMIT 1
        ];

        User user1 = HOT_TestDataFactory.createUser('SRUser1', profileAdmin);
        User user2 = HOT_TestDataFactory.createUser('SRUser2', profileAdmin);
        insert new List<User>{ user1, user2 };
    }

    @IsTest
    static void testAfterInsertGrantsEditAccessToRelatedUser() {
        List<User> users = [SELECT Id FROM User WHERE LastName IN ('SRUser1', 'SRUser2')];
        User ownerUser = users[0];
        User relatedUser = users[1];

        ServiceResource sr = HOT_TestDataFactory.createServiceResource(relatedUser.Id);
        sr.OwnerId = ownerUser.Id;
        sr.RelatedRecordId = relatedUser.Id;
        sr.IsActive = true;

        OperatingHours operatingHour = HOT_TestDataFactory.createOperatingHours();
        insert operatingHour;

        ServiceTerritory serTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHour);
        insert serTerritory;

        System.Test.startTest();
        insert sr;
        insert HOT_TestDataFactory.createServiceTerritoryMember(sr, serTerritory);
        System.Test.stopTest();

        List<ServiceResourceShare> shares = [
            SELECT ParentId, UserOrGroupId, AccessLevel, RowCause
            FROM ServiceResourceShare
            WHERE ParentId = :sr.Id AND RowCause = 'Manual'
        ];
        System.assert(shares.size() > 0, 'Expected manual share records to be created');

        Boolean hasEditToRelated = false;
        for (ServiceResourceShare share : shares) {
            if (share.UserOrGroupId == relatedUser.Id && share.AccessLevel == 'Edit') {
                hasEditToRelated = true;
            }
        }
        System.assertEquals(true, hasEditToRelated, 'Expected Edit share to RelatedRecordId user');
    }
}
