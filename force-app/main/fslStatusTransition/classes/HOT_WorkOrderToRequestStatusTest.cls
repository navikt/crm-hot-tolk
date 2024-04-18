@IsTest
public class HOT_WorkOrderToRequestStatusTest {
    @IsTest
    private static void test_all_new() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Åpen', request.Status__c, 'Status on the request did not update to correct value');
    }

    @IsTest
    private static void test_all_Scheduled() {
        //Fails with old logic
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Scheduled';
        workOrder2.Status = 'Scheduled';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Godkjent', request.Status__c, 'Status on the request did not update to correct value');
    }

    @IsTest
    private static void test_all_Dispatched() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Dispatched';
        workOrder2.Status = 'Dispatched';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Tildelt', request.Status__c, 'Status on the request did not update to correct value');
    }

    @IsTest
    private static void test_all_Completed() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Completed';
        workOrder2.Status = 'Completed';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Dekket', request.Status__c, 'Status on the request did not update to correct value');
    }
    @IsTest
    private static void test_all_Canceled() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Canceled';
        workOrder2.Status = 'Canceled';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Avlyst', request.Status__c, 'Status on the request did not update to correct value');
    }
    @IsTest
    private static void test_all_CannotComplete() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Cannot Complete';
        workOrder2.Status = 'Cannot Complete';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Udekket', request.Status__c, 'Status on the request did not update to correct value');
    }
    @IsTest
    private static void test_all_PartiallyComplete() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Partially Complete';
        workOrder2.Status = 'Partially Complete';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(
            'Delvis dekket',
            request.Status__c,
            'Status on the request did not update to correct value'
        );
    }
    @IsTest
    private static void test_1Open_1Complete() {
        //Fails with old logic
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder2.Status = 'Completed';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Godkjent', request.Status__c, 'Status on the request did not update to correct value');
    }
    @IsTest
    private static void test_1Open_1Canceled() {
        //Fails with old logic
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder2.Status = 'Canceled';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Godkjent', request.Status__c, 'Status on the request did not update to correct value');
    }
    @IsTest
    private static void test_1Scheduled_1Complete() {
        //Fails with old logic
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Scheduled';
        workOrder2.Status = 'Completed';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Godkjent', request.Status__c, 'Status on the request did not update to correct value');
    }
    @IsTest
    private static void test_1Dispatched_1Complete() {
        //Fails with old logic
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Dispatched';
        workOrder2.Status = 'Completed';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Tildelt', request.Status__c, 'Status on the request did not update to correct value');
    }
    @IsTest
    private static void test_1Canceled_1Complete() {
        //Fails with old logic
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Canceled';
        workOrder2.Status = 'Completed';
        update new List<WorkOrder>{ workOrder1, workOrder2 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals('Dekket', request.Status__c, 'Status on the request did not update to correct value');
    }

    @IsTest
    private static void test_1Complete_1CannotComplete_1PartiallyComplete() {
        //Fails with old logic
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        WorkOrder workOrder3 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder3;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Completed';
        workOrder2.Status = 'Cannot Complete';
        workOrder3.Status = 'Partially Complete';
        update new List<WorkOrder>{ workOrder1, workOrder2, workOrder3 };

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(
            'Delvis dekket',
            request.Status__c,
            'Status on the request did not update to correct value'
        );
    }
    @IsTest
    private static void test_1Complete_1CannotComplete() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Completed';
        workOrder2.Status = 'Cannot Complete';
        update workOrder1;
        update workOrder2;

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(
            'Delvis dekket',
            request.Status__c,
            'Status on the request did not update to correct value'
        );
    }

    @IsTest
    private static void test_1Complete_1CannotComplete_1Canceled() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder1;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder2;
        WorkOrder workOrder3 = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder3;
        request.Status__c = 'Godkjent';
        update request;
        workOrder1.Status = 'Completed';
        workOrder2.Status = 'Cannot Complete';
        workOrder3.Status = 'Canceled';
        update workOrder1;
        update workOrder2;
        update workOrder3;

        request = [SELECT Status__c FROM HOT_Request__c WHERE Id = :request.Id];

        System.assertEquals(
            'Delvis dekket',
            request.Status__c,
            'Status on the request did not update to correct value'
        );
    }
}
