@IsTest
public with sharing class HOT_DatabaseOperationsTest {
    @IsTest
    public static void testInsertRecord() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Insert single', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;

        Test.startTest();
        HOT_DatabaseOperations.insertRecords(request);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Subject__c FROM HOT_Request__c WHERE Subject__c = :subject];

        System.assert(requestResult != null, 'Expected to find a request');
    }

    @IsTest
    public static void testInsertRecords() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Insert List', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;

        List<HOT_Request__c> requests = new List<HOT_Request__c>{ request };

        Test.startTest();
        HOT_DatabaseOperations.insertRecords(requests);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Subject__c FROM HOT_Request__c WHERE Subject__c = :subject];

        System.assert(requestResult != null, 'Expected to find a request');
    }

    @IsTest
    public static void testUpdateRecord() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Update single', workType);
        String subject = 'Willy Wonkas';
        request.Subject__c = subject;
        insert request;

        request = [SELECT Id, Subject__c FROM HOT_Request__c WHERE Subject__c = :subject];

        String subject2 = 'Wenche Wonkas';
        request.Subject__c = subject2;

        Test.startTest();
        HOT_DatabaseOperations.updateRecords(request);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Subject__c FROM HOT_Request__c WHERE Subject__c = :subject2];

        System.assert(requestResult != null, 'Expected to find a request');
    }

    @IsTest
    public static void testUpdateRecords() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Update List', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;
        insert request;

        request = [SELECT Subject__c FROM HOT_Request__c WHERE Subject__c = :subject];

        String subject2 = 'Wenche Wonka';
        request.Subject__c = subject2;

        List<HOT_Request__c> requests = new List<HOT_Request__c>{ request };

        Test.startTest();
        HOT_DatabaseOperations.updateRecords(requests);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Subject__c FROM HOT_Request__c WHERE Subject__c = :subject2];

        System.assert(requestResult != null, 'Expected to find a request');
    }

    @IsTest
    public static void testUpsertRecord() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Upsert Record', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;
        insert request;

        request = [SELECT Subject__c FROM HOT_Request__c WHERE Subject__c = :subject];
        String subject2 = 'Wenche Wonka';
        request.Subject__c = subject2;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Upsert another record', workType);
        request2.Subject__c = subject;

        Test.startTest();
        HOT_DatabaseOperations.upsertRecords(request);
        HOT_DatabaseOperations.upsertRecords(request2);
        Test.stopTest();

        List<HOT_Request__c> requestResults = [SELECT Subject__c FROM HOT_Request__c];

        List<String> subjects = new List<String>();

        for (HOT_Request__c req : requestResults) {
            subjects.add(req.Subject__c);
        }

        System.assert(requestResults.size() == 2, 'Expected to find two request');
        System.assert(
            subjects.contains(subject) && subjects.contains(subject2),
            'Expected to find both requests with correct subject'
        );
    }

    @IsTest
    public static void testUpsertRecords() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Upsert list', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;
        insert request;

        request = [SELECT Subject__c FROM HOT_Request__c WHERE Subject__c = :subject];
        String subject2 = 'Wenche Wonka';
        request.Subject__c = subject2;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Upsert second list item', workType);
        request2.Subject__c = subject;

        List<HOT_Request__c> requests = new List<HOT_Request__c>{ request, request2 };

        Test.startTest();
        HOT_DatabaseOperations.upsertRecords(requests);
        Test.stopTest();

        List<HOT_Request__c> requestResults = [SELECT Subject__c FROM HOT_Request__c];

        List<String> subjects = new List<String>();

        for (HOT_Request__c req : requestResults) {
            subjects.add(req.Subject__c);
        }

        System.assert(requestResults.size() == 2, 'Expected to find two request');
        System.assert(
            subjects.contains(subject) && subjects.contains(subject2),
            'Expected to find both requests with correct subject'
        );
    }

    @IsTest
    public static void deleteRecord() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Delete record', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;

        insert request;
        Test.startTest();
        HOT_DatabaseOperations.deleteRecords(request);
        request = [SELECT Id, IsDeleted FROM HOT_Request__c ALL ROWS];
        System.assert(request.IsDeleted, 'Expected to find no requests');
        Test.stopTest();
    }

    @IsTest
    public static void deleteRecordFail() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Delete record fail', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;

        insert request;
        delete request;

        Test.startTest();
        HOT_DatabaseOperations.deleteRecords(request);
        Test.stopTest();

        List<Application_Log__c> logs = [SELECT Id FROM Application_Log__c];

        System.assert(logs.size() > 0, 'Expected to find no records and an error since no records exists.');
    }

    @IsTest
    public static void deleteRecords() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Delete list', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;

        insert request;

        List<HOT_Request__c> requests = new List<HOT_Request__c>{ request };

        Test.startTest();
        HOT_DatabaseOperations.deleteRecords(requests);
        request = [SELECT Id, IsDeleted FROM HOT_Request__c ALL ROWS];
        System.assert(request.IsDeleted, 'Expected to find no requests');
        Test.stopTest();
    }

    @IsTest
    public static void undeleteRecord() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Undelete record', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;

        insert request;
        delete request;

        Test.startTest();
        HOT_DatabaseOperations.undeleteRecords(request);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Subject__c FROM HOT_Request__c WHERE Subject__c = :subject];

        System.assert(requestResult != null, 'Expected to find a request');
        System.assert(requestResult.Subject__c == subject, 'Expected to find a request with correct subject.');
    }

    @IsTest
    public static void undeleteRecords() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Undelete list', workType);
        String subject = 'Willy Wonka';
        request.Subject__c = subject;

        List<SObject> sObjects = new List<SObject>{ request };

        insert request;
        delete request;

        Test.startTest();
        HOT_DatabaseOperations.undeleteRecords(sObjects);
        Test.stopTest();

        HOT_Request__c requestResult = [SELECT Subject__c FROM HOT_Request__c WHERE Subject__c = :subject];

        System.assert(requestResult != null, 'Expected to find a request');
        System.assert(requestResult.Subject__c == subject, 'Expected to find a request with correct subject.');
    }
}
