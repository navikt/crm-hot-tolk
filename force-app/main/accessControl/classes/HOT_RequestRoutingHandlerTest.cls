@IsTest
private class HOT_RequestRoutingHandlerTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('HMS Troms og Finmark', 'group_4719');
        TestDataFactory.getQueue('HMS Troms og Finmark', 'queue_4719', 'HOT_Request__c');
        TestDataFactory.getPublicGroup('NAV Tolketjeneste Oslo', 'group_4703');
        TestDataFactory.getQueue('NAV Tolketjeneste Oslo', 'queue_4703', 'HOT_Request__c');
        User user = [SELECT Id, Department FROM User WHERE Id = :UserInfo.getUserId()];
        user.Department = '4719';
        update user;
    }

    @IsTest
    private static void testRequstRegion54OnUser() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_MunicipalityNumber__c = '5501';
        insert person;
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = accountId;
        insert request;

        Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4719' LIMIT 1].Id;
        System.assertEquals(queueId, [SELECT OwnerId FROM HOT_Request__c WHERE Id = :request.Id].OwnerId);
    }

    @IsTest
    private static void testRequestRoutingWhenAccountDifferFromOrdererRegion() {
        Person__c personTromso = HOT_TestDataFactory.createPerson();
        personTromso.INT_FirstName__c = 'Tromso';
        personTromso.INT_LastName__c = 'User';
        personTromso.INT_MunicipalityNumber__c = '5501';
        insert personTromso;
        Account accountTromso = [SELECT Id FROM Account WHERE FirstName = :personTromso.INT_FirstName__c LIMIT 1];

        Person__c personOslo = HOT_TestDataFactory.createPerson();
        personOslo.INT_FirstName__c = 'Oslo';
        personOslo.INT_LastName__c = 'User';
        personOslo.INT_MunicipalityNumber__c = '0301';
        insert personOslo;
        Account accountOslo = [SELECT Id FROM Account WHERE FirstName = :personOslo.INT_FirstName__c LIMIT 1];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = accountOslo.Id;
        request.Orderer__c = accountTromso.Id;
        Test.startTest();
        insert request;
        Test.stopTest();

        Id queueOrdererId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4719' LIMIT 1].Id;
        Id queueAccountId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4703' LIMIT 1].Id;
        Id orderedOnBehalfRequestOwnersId = [SELECT OwnerId FROM HOT_Request__c WHERE Id = :request.Id].OwnerId;
        System.assertNotEquals(queueOrdererId, orderedOnBehalfRequestOwnersId);
        System.assertEquals(queueAccountId, orderedOnBehalfRequestOwnersId);
    }

    @IsTest
    private static void testRequstRegion54OnOrderer() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.INT_MunicipalityNumber__c = '5501';
        insert person;
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c orderedRequest = HOT_TestDataFactory.createRequest('Orderer TEST', workType);
        orderedRequest.Orderer__c = accountId;
        insert orderedRequest;

        Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4719' LIMIT 1].Id;
        System.assertEquals(queueId, [SELECT OwnerId FROM HOT_Request__c WHERE Id = :orderedRequest.Id].OwnerId);
    }

    @IsTest
    private static void testRequstRegion54OnCompany() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        Account company = HOT_TestDataFactory.createAccount(false);
        company.INT_MunicipalityNumber__c = '5501';
        insert company;

        HOT_Request__c companyRequest = HOT_TestDataFactory.createRequest('Company TEST', workType);
        companyRequest.Company__c = company.Id;
        insert companyRequest;

        Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4719' LIMIT 1].Id;
        System.assertEquals(queueId, [SELECT OwnerId FROM HOT_Request__c WHERE Id = :companyRequest.Id].OwnerId);
    }

    @IsTest
    private static void testRequstDefaultRouting() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('defaultRouting TEST', workType);
        insert request;

        Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'HOT_Tolk_Admin' LIMIT 1].Id;
        System.assertEquals(queueId, [SELECT OwnerId FROM HOT_Request__c WHERE Id = :request.Id].OwnerId);
    }

    @IsTest
    private static void testRequstCreatorRouting_adminQueue() {
        Test.startTest();
        WorkType workType = HOT_TestDataFactory.createWorkType('Bildetolk');
        workType.HOT_DeveloperName__c = 'BTV';
        insert workType;
        Test.stopTest();

        HOT_Request__c request = HOT_TestDataFactory.createRequest('bildetolk TEST', workType);
        request.Type__c = 'ImageInterpreter';
        insert request;

        Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4719' LIMIT 1].Id;
        System.assertEquals(queueId, [SELECT OwnerId FROM HOT_Request__c WHERE Id = :request.Id].OwnerId);
    }

    @IsTest
    private static void testRequestAccountFields() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;
        Account businessAccount = HOT_TestDataFactory.createAccount(false);
        businessAccount.INT_OrganizationNumber__c = '987654321';
        insert businessAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c personRequest = HOT_TestDataFactory.createRequest('Person Test', workType);
        personRequest.UserPersonNumber__c = '12015678999';
        HOT_Request__c businessRequest = HOT_TestDataFactory.createRequest('Business Test', workType);
        businessRequest.OrganizationNumber__c = '987654321';

        Test.startTest();
        insert personRequest;
        insert businessRequest;
        Test.stopTest();

        personRequest = [SELECT Id, Account__c FROM HOT_Request__c WHERE Subject__c = 'Person Test'];
        businessRequest = [SELECT Id, Company__c FROM HOT_Request__c WHERE Subject__c = 'Person Test'];

        //TODO: Oppdatere asserts til å sjekke id på bruker eller virksomhet, men må da kunne kjøre testen som en Community-bruker, noe som vi ikke har fått til enda
        System.assertEquals(null, personRequest.Account__c, 'Could not set Account__c field');
        System.assertEquals(null, businessRequest.Company__c, 'Could not set Company__c field');
    }

    @IsTest
    private static void testRequestWithUserPhone() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = 'test';
        person.INT_KrrMobilePhone__c = '12345678';
        insert person;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c personRequest = HOT_TestDataFactory.createRequest('Person Test', workType);
        personRequest.UserPhone__c = '12345678';

        Test.startTest();
        insert personRequest;
        Test.stopTest();

        personRequest = [SELECT Id, Account__c FROM HOT_Request__c WHERE Subject__c = 'Person Test'];

        System.assertEquals(null, personRequest.Account__c, 'Could not set Account__c field');
    }
}
