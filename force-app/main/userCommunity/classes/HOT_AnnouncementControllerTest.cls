@IsTest
private class HOT_AnnouncementControllerTest {
    @TestSetup
    static void setup() {
        myTriggers.disable(PersonAccessHandler.class);
        createAnnouncementsAndCommonCodes();

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'test@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';

        insert person;

        person.INT_MunicipalityNumber__c = '5501';
        person.INT_RegionNumber__c = '55';

        update person;
    }

    private static void createAnnouncementsAndCommonCodes() {
        RecordType rt = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'TolkEkstern' AND SObjectType = 'HOT_Announcement__c'
            LIMIT 1
        ];

        insert new List<HOT_Announcement__c>{
            new HOT_Announcement__c(
                Title__c = 'For frilanstolk',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Bare frilanstolk',
                Type__c = 'News',
                RegionAudience__c = 'Nordland',
                RecordTypeId = rt.Id
            ),
            new HOT_Announcement__c(
                Title__c = 'For alle',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Alle',
                Type__c = 'News',
                RegionAudience__c = 'Troms',
                RecordTypeId = rt.Id
            ),
            new HOT_Announcement__c(
                Title__c = 'Feil region',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Alle',
                Type__c = 'News',
                RegionAudience__c = 'Akershus',
                RecordTypeId = rt.Id
            ),
            new HOT_Announcement__c(
                Title__c = 'Bare bruker',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Bare tolkebruker',
                Type__c = 'News',
                RegionAudience__c = 'Troms',
                RecordTypeId = rt.Id
            ),
            new HOT_Announcement__c(
                Title__c = 'Inaktiv',
                IsPublished__c = false,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Alle',
                Type__c = 'News',
                RegionAudience__c = 'Troms',
                RecordTypeId = rt.Id
            )
        };

        insert new List<Common_Code__c>{
            new Common_Code__c(Name = 'Troms', CRM_Code_Set__c = 'Fylke', CRM_Code__c = '55', CRM_Active__c = true),
            new Common_Code__c(Name = 'Tromsø', CRM_Code_Set__c = 'Kommune', CRM_Code__c = '5501', CRM_Active__c = true)
        };
    }

    private static User createCommunityUser(String suffix) {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User admin = HOT_TestDataFactory.createUser('admusr', adminProfile);
        admin.Alias = 'admusr';
        insert admin;

        Account account = [SELECT Id, PersonContactId FROM Account WHERE LastName = 'Bruker' LIMIT 1];

        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];

        User communityUser;

        System.runAs(admin) {
            communityUser = HOT_TestDataFactory.createUser(communityProfile, account);

            communityUser.Alias = suffix.left(8);
            communityUser.Username = suffix + '@nav.hot.no';
            communityUser.CommunityNickname = suffix;

            insert communityUser;

            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Bruker_v2' LIMIT 1];

            insert new PermissionSetAssignment(AssigneeId = communityUser.Id, PermissionSetId = ps.Id);
        }

        return communityUser;
    }

    @IsTest
    static void testGetAnnouncements_All() {
        User u = createCommunityUser('u1');

        Test.startTest();

        System.runAs(u) {
            List<HOT_Announcement__c> result = HOT_AnnouncementController.getAnnouncements();

            System.assertEquals(2, result.size());
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetAnnouncementWrapper() {
        User u = createCommunityUser('u2');

        Test.startTest();

        System.runAs(u) {
            HOT_AnnouncementController.AnnouncementWrapper wrapper = HOT_AnnouncementController.getAnnouncementWrapper();

            System.assertNotEquals(null, wrapper);
            System.assertEquals(2, wrapper.newsAnnouncements.size());
            System.assertEquals(2, wrapper.unreadAnnouncementIds.size());
        }

        Test.stopTest();
    }

    @IsTest
    static void markAnnouncementsAsReadTest() {
        User u = createCommunityUser('u3');

        Test.startTest();

        System.runAs(u) {
            List<HOT_Announcement__c> announcements = HOT_AnnouncementController.getAnnouncements();

            System.assertEquals(2, announcements.size());

            HOT_AnnouncementController.markAnnouncementsAsRead();

            List<HOT_ReadReceipt__c> receipts = [SELECT Id FROM HOT_ReadReceipt__c WHERE User__c = :u.Id];

            System.assertEquals(2, receipts.size());
        }

        Test.stopTest();
    }
}
