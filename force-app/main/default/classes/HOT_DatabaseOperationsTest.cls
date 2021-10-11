@isTest
public with sharing class HOT_DatabaseOperationsTest {
    @TestSetup
    @isTest
    public static void testInsertRecord() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Adding comment', workType);
        String name = 'Willy Wonka';
        request. = name;

        Test.startTest();
        HOT_DatabaseOperations.insertRecords(request);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Name FROM HOT_Request__c WHERE Name = :name];

        assert(requestResult != null, 'Expected to find a request');
    }

    @isTest
    public static void testInsertRecords() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Adding comment', workType);
        String name = 'Willy Wonka';
        request.Name = name;

        List<SObject> sObjects = new List<SObject>{ request };

        Test.startTest();
        HOT_DatabaseOperations.insertRecords(sObjects);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Name FROM HOT_Request__c WHERE Name = :name];

        assert(requestResult != null, 'Expected to find a request');
    }

    @isTest
    public static void testUpdateRecord() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Adding comment', workType);
        String name = 'Willy Wonka';
        request.Name = name;
        insert request;

        request = [SELECT Id, Name FROM HOT_Request__c WHERE Name = :name];

        String name2 = 'Wenche Wonka';
        request.Name = name2;

        Test.startTest();
        HOT_DatabaseOperations.updateRecords(request);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Name FROM HOT_Request__c WHERE Name = :name2];

        assert(requestResult != null, 'Expected to find a request');
    }

    @isTest
    public static void testUpdateRecords() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Adding comment', workType);
        String name = 'Willy Wonka';
        request.Name = name;
        insert request;

        request = [SELECT Name FROM HOT_Request__c WHERE Name = :name];

        String name2 = 'Wenche Wonka';
        request.Name = name2;

        List<SObject> sObjects = new List<SObject>{ request };

        Test.startTest();
        HOT_DatabaseOperations.updateRecords(sObjects);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Name FROM HOT_Request__c WHERE Name = :name2];

        assert(requestResult != null, 'Expected to find a request');
    }

    @isTest
    public static void testUpsertRecord() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Adding comment', workType);
        String name = 'Willy Wonka';
        request.Name = name;
        insert request;

        request = [SELECT Id, Name FROM HOT_Request__c WHERE Name = :name];
        String name2 = 'Wenche Wonka';
        request.Name = name2;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Adding comment', workType);
        request2.Name = name;

        Test.startTest();
        HOT_DatabaseOperations.upsertRecords(request);
        HOT_DatabaseOperations.upsertRecords(request2);
        Test.stopTest();

        List<HOT_Request__c> requestResults = [SELECT Name FROM HOT_Request__c];

        assert(requestResults.size() == 2, 'Expected to find two request');
    }

    @isTest
    public static void testUpsertRecords() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Adding comment', workType);
        String name = 'Willy Wonka';
        request.Name = name;
        insert request;

        request = [SELECT Id, Name FROM HOT_Request__c WHERE Name = :name];
        String name2 = 'Wenche Wonka';
        request.Name = name2;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Adding comment', workType);
        request2.Name = name;

        List<HOT_Request__c> requests = new List<HOT_Request__c>{ request, request2 };

        Test.startTest();
        HOT_DatabaseOperations.upsertRecords(requests);
        Test.stopTest();

        List<HOT_Request__c> requestResults = [SELECT Name FROM HOT_Request__c];

        assert(requestResults.size() == 2, 'Expected to find two request');
    }

    @isTest
    public static void deleteRecord() {
    }

    @isTest
    public static void deleteRecords() {
    }

    @isTest
    public static void undeleteRecord() {
    }

    @AisTest
    public static void undeleteRecords() {
    }
}
