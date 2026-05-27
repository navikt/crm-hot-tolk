@IsTest
private class HOT_AnnouncementControllerTest {
    @TestSetup
    static void setup() {
        // Announcements

        List<Common_Code__c> commonCodes = new List<Common_Code__c>();

        Common_Code__c fylke1 = new Common_Code__c(
            Name = 'Nordland',
            CRM_Code_Set__c = 'Fylke',
            CRM_Code__c = '18',
            CRM_Active__c = true
        );
        commonCodes.add(fylke1);

        Common_Code__c kommune = new Common_Code__c(
            Name = 'Herøy',
            CRM_Code_Set__c = 'Kommune',
            CRM_Code__c = '1822',
            CRM_Active__c = true
        );
        commonCodes.add(kommune);
        insert commonCodes;
        RecordType recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'TolkEkstern' AND SObjectType = 'HOT_Announcement__c'
            LIMIT 1
        ];
        Id recordTypeId = recordType.Id;
        List<HOT_Announcement__c> announcements = new List<HOT_Announcement__c>{
            new HOT_Announcement__c(
                Title__c = 'For frilanstolk',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Bare frilanstolk',
                Type__c = 'News',
                RegionAudience__c = 'Nordland',
                RecordTypeId = recordTypeId
            ),
            new HOT_Announcement__c(
                Title__c = 'For alle',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Alle',
                Type__c = 'News',
                RegionAudience__c = 'Nordland',
                RecordTypeId = recordTypeId
            ),
            new HOT_Announcement__c(
                Title__c = 'Feil region',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Alle',
                Type__c = 'News',
                RegionAudience__c = 'Akershus',
                RecordTypeId = recordTypeId
            ),
            new HOT_Announcement__c(
                Title__c = 'Bare bruker',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Bare tolkebruker',
                Type__c = 'News',
                RegionAudience__c = 'Nordland',
                RecordTypeId = recordTypeId
            ),
            // Ikke aktiv
            new HOT_Announcement__c(
                Title__c = 'Inaktiv',
                IsPublished__c = false,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Alle',
                Type__c = 'News',
                RegionAudience__c = 'Nordland',
                RecordTypeId = recordTypeId
            )
        };

        insert announcements;
    }

    @IsTest
    static void testGetAnnouncements_All() {
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        admin.UserRoleId = role.Id;
        insert admin;
        List<Group> grp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'group_4718'];
        if (grp.size() == 0) {
            Group formidlerGroup = new Group(DeveloperName = 'group_4718', Name = 'NAV HMS Nordland');
            insert formidlerGroup;
        }

        Test.startTest();
        User adminNew = [SELECT Id FROM User WHERE Name = 'admin' LIMIT 1];
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        person.INT_MunicipalityNumber__c = '1822';
        person.INT_RegionNumber__c = '18';
        update person;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
            FROM Account
            WHERE LastName = :'Bruker'
        ];
        account.OwnerId = adminNew.Id;
        update account;

        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;
        Test.stopTest();

        System.runAs(user) {
            List<HOT_Announcement__c> result = HOT_AnnouncementController.getAnnouncements();
            System.assertEquals(2, result.size(), 'Brukeren skal kun se 2 announcements');
        }

    }
    @IsTest
    static void testGetAnnouncementWrapper() {
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        admin.UserRoleId = role.Id;
        insert admin;
        List<Group> grp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'group_4718'];
        if (grp.size() == 0) {
            Group formidlerGroup = new Group(DeveloperName = 'group_4718', Name = 'NAV HMS Nordland');
            insert formidlerGroup;
        }
        User adminNew = [SELECT Id FROM User WHERE Name = 'admin' LIMIT 1];
        Test.startTest();
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        person.INT_MunicipalityNumber__c = '1822';
        person.INT_RegionNumber__c = '18';
        update person;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
            FROM Account
            WHERE LastName = :'Bruker'
        ];
        account.OwnerId = adminNew.Id;
        update account;

        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;
        Test.stopTest();

        System.runAs(user) {
            HOT_AnnouncementController.AnnouncementWrapper wrapper = HOT_AnnouncementController.getAnnouncementWrapper();

            System.assert(wrapper != null);
            System.assertEquals(2, wrapper.newsAnnouncements.size());

            // Ingen receipts enda
            System.assertEquals(2, wrapper.unreadAnnouncementIds.size());
        }
    }
    @IsTest
    static void markAnnouncementsAsReadTest() {
        Profile adminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
        User admin = HOT_TestDataFactory.createUser('admin', adminProfile);
        admin.UserRoleId = role.Id;
        insert admin;
        List<Group> grp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'group_4718'];
        if (grp.size() == 0) {
            Group formidlerGroup = new Group(DeveloperName = 'group_4718', Name = 'NAV HMS Nordland');
            insert formidlerGroup;
        }
        User adminNew = [SELECT Id FROM User WHERE Name = 'admin' LIMIT 1];
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];

        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_KrrEmail__c = 'getPersonTest@nav.no';
        person.HOT_WorkplaceInterpreter__c = true;
        person.INT_Confidential__c = 'Ugradert';
        person.INT_FirstName__c = 'Tolk';
        person.INT_LastName__c = 'Bruker';
        insert person;

        person.INT_MunicipalityNumber__c = '1822';
        person.INT_RegionNumber__c = '18';
        update person;

        Account account = [
            SELECT Id, OwnerId, PersonContactId, FirstName, LastName, PersonEmail, CRM_Person__c
            FROM Account
            WHERE LastName = :'Bruker'
        ];
        account.OwnerId = adminNew.Id;
        update account;

        User user = HOT_TestDataFactory.createUser(communityProfile, account);
        user.Alias = 'userTest';
        user.Username = 'HOT_testuser1@nav.hot.no';
        user.CommunityNickname = 'userTest';
        insert user;
        Test.startTest();
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Bruker_v2' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permSet.Id);
        insert psa;
        Test.stopTest();
        System.runAs(user) {
            List<HOT_Announcement__c> announcements = HOT_AnnouncementController.getAnnouncements();
            System.assertEquals(2, announcements.size());

            HOT_AnnouncementController.markAnnouncementsAsRead();

            List<HOT_ReadReceipt__c> receipts = [
                SELECT Id, Announcement__c
                FROM HOT_ReadReceipt__c
                WHERE User__c = :user.Id
            ];

            System.debug(receipts);

            System.assertEquals(2, receipts.size());
        }
    }
}
