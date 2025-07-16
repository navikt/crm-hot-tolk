@IsTest
public with sharing class HOT_FullmaktControllerTest {
    @TestSetup
    static void makeData() {
        Person__c p1 = (Person__c) HOT_ST_TestDataFactory.createRecord(
            new Person__c(
                Name = '01234567890',
                INT_FirstName__c = 'Fullmaktsgiver',
                INT_LastName__c = 'McFullmaktsen',
                INT_Confidential__c = 'UGRADERT'
            ),
            true
        );
        Account a1 = (Account) HOT_ST_TestDataFactory.createRecord(new Account(Name = 'Fake person'), true);
        Common_Code__c cCode = (Common_Code__c) HOT_ST_TestDataFactory.createRecord(
            new Common_Code__c(Name = 'Test ccode', CRM_Code_Set__c = 'Tema', CRM_Code__c = 'ARP'),
            true
        );
    }

    @IsTest
    static void getFullmaktsgiverHistorikkTest() {
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '01234567890'];
        Case c = (Case) HOT_ST_TestDataFactory.createRecord(
            new Case(AccountId = p.CRM_Account__c, STO_Category__c = 'Arbeid', Status = 'New'),
            true
        );
        ApiMock.setTestMock(FullmaktService.services.GET_FULLMAKTSGIVER_HISTORIKK.name(), 200, 'OK');

        Test.startTest();
        List<HOT_FullmaktController.FullmaktsgiverHistorikk> historikk = HOT_FullmaktController.getHistorikk(
            c.Id,
            'Case'
        );
        Test.stopTest();

        Assert.isNotNull(historikk);
        Assert.areNotEqual(0, historikk.size());
    }

    @IsTest
    static void getFullmaktsgiverHistorikkNoPersonIdentTest() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Fake Person'];
        Test.startTest();
        List<HOT_FullmaktController.FullmaktsgiverHistorikk> historikk = HOT_FullmaktController.getHistorikk(
            a.Id,
            'Account'
        );
        Test.stopTest();

        Assert.isNull(historikk);
    }

    @IsTest
    static void getFullmaktsgiverTest() {
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '01234567890'];
        Case c = (Case) HOT_ST_TestDataFactory.createRecord(
            new Case(AccountId = p.CRM_Account__c, STO_Category__c = 'Arbeid', Status = 'New'),
            true
        );
        ApiMock.setTestMock(FullmaktService.services.GET_FULLMAKTSGIVER.name(), 200, 'OK');

        Test.startTest();
        List<HOT_FullmaktController.Fullmaktsgiver> fullmaktsGiver = HOT_FullmaktController.getFullmaktsgiver(
            c.Id,
            'Case'
        );
        Test.stopTest();

        Assert.isNotNull(fullmaktsGiver);
        Assert.areNotEqual(0, fullmaktsGiver.size());
        Assert.isNotNull(fullmaktsGiver[0].formattedOmraadeListByThemeGroup);
        Assert.areNotEqual(0, fullmaktsGiver[0].formattedOmraadeListByThemeGroup.size());
    }

    @IsTest
    static void getFullmaktsgiverNoPersonIdentTest() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Fake Person'];

        Test.startTest();
        List<HOT_FullmaktController.Fullmaktsgiver> fullmaktsGiver = HOT_FullmaktController.getFullmaktsgiver(
            a.Id,
            'Account'
        );
        Test.stopTest();

        Assert.isNull(fullmaktsGiver);
    }

    @IsTest
    static void testGetFullmaktsgiverHistorikkErrorHandling() {
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '01234567890'];
        Case c = (Case) HOT_ST_TestDataFactory.createRecord(
            new Case(AccountId = p.CRM_Account__c, STO_Category__c = 'Arbeid', Status = 'New'),
            true
        );
        ApiMock.setTestMock(FullmaktService.services.GET_FULLMAKTSGIVER_HISTORIKK.name(), 500, 'Error');

        Boolean exceptionOccured = false;
        Test.startTest();
        try {
            List<HOT_FullmaktController.FullmaktsgiverHistorikk> historikk = HOT_FullmaktController.getHistorikk(
                c.Id,
                'Case'
            );
            exceptionOccured = false;
        } catch (Exception e) {
            exceptionOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionOccured);
    }

    @IsTest
    static void testGetFullmaktsgiverErrorHandling() {
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '01234567890'];
        Case c = (Case) HOT_ST_TestDataFactory.createRecord(
            new Case(AccountId = p.CRM_Account__c, STO_Category__c = 'Arbeid', Status = 'New'),
            true
        );
        ApiMock.setTestMock(FullmaktService.services.GET_FULLMAKTSGIVER.name(), 500, 'Error');

        Boolean exceptionOccured = false;
        Test.startTest();
        try {
            List<HOT_FullmaktController.Fullmaktsgiver> fullmaktsGiver = HOT_FullmaktController.getFullmaktsgiver(
                c.Id,
                'Case'
            );
            exceptionOccured = false;
        } catch (Exception e) {
            exceptionOccured = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionOccured);
    }

    @IsTest
    static void testGetFullmaktsgiverHistorikkDataNullInput() {
        Test.startTest();
        List<HOT_FullmaktController.FullmaktsgiverHistorikk> historikk = HOT_FullmaktController.processHistorikkData(
            null
        );
        Test.stopTest();

        Assert.isNull(historikk);
    }

    @IsTest
    static void testGetFullmaktsgiverDataNullInput() {
        Test.startTest();
        List<HOT_FullmaktController.Fullmaktsgiver> fullmaktsGiver = HOT_FullmaktController.processFullmaktsgiverData(
            null
        );
        Test.stopTest();

        Assert.isNull(fullmaktsGiver);
    }

    @IsTest
    static void testCheckAccessAndGetPersonIdentWithCase() {
        Person__c p = [SELECT Id, CRM_Account__c FROM Person__c WHERE Name = '01234567890'];
        Case c = (Case) HOT_ST_TestDataFactory.createRecord(
            new Case(AccountId = p.CRM_Account__c, STO_Category__c = 'Arbeid', Status = 'New'),
            true
        );

        Test.startTest();
        String personIdent = HOT_FullmaktController.fetchPersonIdent(c.Id, 'Case');
        Test.stopTest();

        Assert.isNotNull(personIdent);
    }

    @IsTest
    static void testCheckAccessAndGetPersonIdentWithAccount() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Fake Person'];

        Test.startTest();
        String personIdent = HOT_FullmaktController.fetchPersonIdent(a.Id, 'Account');
        Test.stopTest();

        Assert.isNull(personIdent);
    }

    @IsTest
    static void testCheckAccessAndGetPersonIdentWithPerson() {
        Person__c p = [SELECT Id, Name FROM Person__c WHERE Name = '01234567890'];

        Test.startTest();
        String personIdent = HOT_FullmaktController.fetchPersonIdent(p.Id, 'Person__c');
        Test.stopTest();

        Assert.areEqual('01234567890', personIdent);
    }

    @IsTest
    static void testLogErrorForCoverage() {
        Test.startTest();
        HOT_FullmaktController.logError('test err message');
        Test.stopTest();
    }
}
