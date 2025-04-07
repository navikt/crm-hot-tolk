@IsTest
private class HOT_WageClaimListControllerTest {
    @testSetup
    static void setup() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user1', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.HOT_IsFreelanceInterpreter__c = true;
        insert resource;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert woli;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject = 'TEST';
        insert sa;

        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(resource);
        wageClaim.WorkType__c = workType.Id;
        wageClaim.ServiceAppointment__c = sa.Id;
        insert wageClaim;
        HOT_WageClaim__c wageClaim2 = HOT_TestDataFactory.createWageClaim(resource);
        wageClaim2.Status__c = 'Annul';
        insert wageClaim2;
    }

    @IsTest
    static void getMyWageClaimsTest() {
        User user = [SELECT Id FROM User WHERE UserName = 'HOT.user1@nav.hot.nav.no'];

        System.runAs(user) {
            Test.startTest();
            List<HOT_WageClaim__c> wageClaims = HOT_WageClaimListController.getMyWageClaims();

            Test.stopTest();

            System.assertEquals(1, wageClaims.size(), 'Could not get my wage claims');
        }
    }

    @IsTest
    static void retractAvailabilityTest() {
        HOT_WageClaim__c wageClaim = [SELECT Id FROM HOT_WageClaim__c WHERE Status__c != 'Annul' LIMIT 1];
        String recordId = String.valueOf(wageClaim.Id);
        Test.startTest();
        HOT_WageClaimListController.retractAvailability(recordId);
        Test.stopTest();

        wageClaim = [SELECT Id, Status__c FROM HOT_WageClaim__c WHERE Id = :wageClaim.Id LIMIT 1];
        System.assertEquals('Retracted Availability', wageClaim.Status__c, 'Could not retract wage claim');
    }
    @IsTest
    static void getWageClaimThreadIdTest() {
        HOT_WageClaim__c wageClaim = [SELECT Id FROM HOT_WageClaim__c LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = wageClaim.Id;
        insert thread;

        Test.startTest();
        String threadId = HOT_WageClaimListController.getThreadId(wageClaim.Id);
        Test.stopTest();
        System.assertEquals(thread.Id, threadId, 'Could not find the wageclaim thread');
    }
}
