@IsTest
private class HOT_AnnouncementControllerTest {
    @TestSetup
    private static void setup() {
        List<Common_Code__c> regions = new List<Common_Code__c>{
            new Common_Code__c(Name = 'Oslo', CRM_Code__c = '03', CRM_Code_Set__c = 'Fylke', CRM_Active__c = true)
        };
        insert regions;

        Account frilansAccount = HOT_TestDataFactory.createAccount(true);
        insert frilansAccount;

        frilansAccount = [SELECT Id, PersonContactId FROM Account WHERE Id = :frilansAccount.Id LIMIT 1];

        Person__c frilansPerson = new Person__c(
            Name = 'Frilans1',
            INT_FirstName__c = 'Frilans',
            INT_LastName__c = 'Person',
            CRM_Account__c = frilansAccount.Id,
            CRM_Region__c = regions[0].Id,
            INT_MunicipalityNumber__c = '0345'
        );
        insert frilansPerson;

        update frilansPerson;

        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'NAV Samhandler' LIMIT 1];

        String timestamp = String.valueOf(System.currentTimeMillis());
        User frilansUser = new User(
            Username = 'frilans' + timestamp + '@test.com',
            LastName = 'Person',
            Email = 'frilans' + timestamp + '@test.com',
            Alias = 'frlans',
            CommunityNickname = 'Frilans',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'no_NO',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'no',
            ProfileId = communityProfile.Id,
            ContactId = frilansAccount.PersonContactId
        );
        insert frilansUser;

        List<HOT_Announcement__c> announcements = new List<HOT_Announcement__c>{
            new HOT_Announcement__c(
                Title__c = 'For frilans',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Bare frilanstolk',
                Type__c = 'News',
                RegionAudience__c = 'Oslo'
            ),
            new HOT_Announcement__c(
                Title__c = 'For alle',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Alle',
                Type__c = 'News',
                RegionAudience__c = 'Oslo'
            ),
            new HOT_Announcement__c(
                Title__c = 'Feil region',
                IsPublished__c = true,
                TargetSite__c = 'Tolkebestilling',
                Audience__c = 'Alle',
                Type__c = 'News',
                RegionAudience__c = 'Akershus'
            )
        };
        insert announcements;
    }

    @IsTest
    static void testFrilansSeAnnouncements() {
        User frilansUser = [SELECT Id FROM User WHERE CommunityNickname = 'Frilans' LIMIT 1];

        Test.startTest();
        System.runAs(frilansUser) {
            List<HOT_Announcement__c> result = HOT_AnnouncementController.getAnnouncements();
            System.assertEquals(2, result.size(), 'Frilans bør se 2 annonser for Oslo-regionen');
            Set<String> titles = new Set<String>();
            for (HOT_Announcement__c a : result)
                titles.add(a.Title__c);
            System.assert(titles.contains('For frilans'));
            System.assert(titles.contains('For alle'));
        }
        Test.stopTest();
    }
}
