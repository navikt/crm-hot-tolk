@IsTest
private class HOT_PreferredResourceAvailFlowTest {
    private class TestContext {
        public Id requestId;
    }

    @IsTest
    private static void checkAvailabilityBuildsWarningsAndAvailability() {
        TestContext contextItem = createAvailabilityScenario();

        HOT_PreferredResourceAvailFlow.Request inputItem = new HOT_PreferredResourceAvailFlow.Request();
        inputItem.parentRecordId = contextItem.requestId;

        Test.startTest();
        List<HOT_PreferredResourceAvailFlow.Response> responses = HOT_PreferredResourceAvailFlow.checkAvailability(
            new List<HOT_PreferredResourceAvailFlow.Request>{ inputItem }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Expected exactly one response row.');
        System.assertEquals(
            true,
            responses[0].isPreferredResource1Unavailable,
            'Resource 1 should be marked unavailable.'
        );
        System.assertEquals(
            true,
            responses[0].isPreferredResource2Unavailable,
            'Resource 2 should be marked unavailable.'
        );
        System.assertEquals(
            true,
            responses[0].isFreelanceInterpreterAvailable,
            'At least one non-overlap should mark availability true.'
        );
        System.assertNotEquals(null, responses[0].warningDisplayText, 'Warning text should be populated for overlaps.');
        System.assert(
            responses[0].warningDisplayText.contains('Foretrukket ressurs 1 (Foretrukket 1)'),
            'Warning text should include preferred resource 1 label.'
        );
        System.assert(
            responses[0].warningDisplayText.contains('Foretrukket ressurs 2 (Foretrukket 2)'),
            'Warning text should include preferred resource 2 label.'
        );
    }

    @IsTest
    private static void checkAvailabilityHandlesMissingInput() {
        HOT_PreferredResourceAvailFlow.Request inputItem = new HOT_PreferredResourceAvailFlow.Request();

        Test.startTest();
        List<HOT_PreferredResourceAvailFlow.Response> responses = HOT_PreferredResourceAvailFlow.checkAvailability(
            new List<HOT_PreferredResourceAvailFlow.Request>{ inputItem }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Expected exactly one response row.');
        System.assertEquals(null, responses[0].warningDisplayText, 'No input id should give no warning text.');
        System.assertEquals(
            null,
            responses[0].isFreelanceInterpreterAvailable,
            'No input id should not set availability.'
        );
        System.assertEquals(
            null,
            responses[0].isPreferredResource1Unavailable,
            'No input id should not set resource 1 flag.'
        );
        System.assertEquals(
            null,
            responses[0].isPreferredResource2Unavailable,
            'No input id should not set resource 2 flag.'
        );
    }

    private static TestContext createAvailabilityScenario() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c requestRecord = HOT_TestDataFactory.createRequest('TEST', workType);
        insert requestRecord;

        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
            LIMIT 1
        ];
        String userSuffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6);
        User secondUser = HOT_TestDataFactory.createUser('PR' + userSuffix, profile);
        insert secondUser;

        ServiceResource serviceResource1 = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        serviceResource1.Name = 'SR-1';
        ServiceResource serviceResource2 = HOT_TestDataFactory.createServiceResource(secondUser.Id);
        serviceResource2.Name = 'SR-2';
        insert new List<ServiceResource>{ serviceResource1, serviceResource2 };

        HOT_Resource__c preferredResource1 = HOT_TestDataFactory.createResource(serviceResource1);
        preferredResource1.Name = 'Foretrukket 1';
        HOT_Resource__c preferredResource2 = HOT_TestDataFactory.createResource(serviceResource2);
        preferredResource2.Name = 'Foretrukket 2';
        insert new List<HOT_Resource__c>{ preferredResource1, preferredResource2 };

        requestRecord.PreferredResource1__c = preferredResource1.Id;
        requestRecord.PreferredResource2__c = preferredResource2.Id;
        update requestRecord;

        WorkOrder workOrder1 = HOT_TestDataFactory.createWorkOrder(requestRecord, workType);
        workOrder1.StartDate = Datetime.newInstance(2026, 1, 10, 10, 0, 0);
        workOrder1.EndDate = Datetime.newInstance(2026, 1, 10, 12, 0, 0);
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(requestRecord, workType);
        workOrder2.StartDate = Datetime.newInstance(2026, 1, 10, 13, 0, 0);
        workOrder2.EndDate = Datetime.newInstance(2026, 1, 10, 15, 0, 0);
        insert new List<WorkOrder>{ workOrder1, workOrder2 };

        WorkOrderLineItem woli1 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder1, workType);
        WorkOrderLineItem woli2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder2, workType);
        WorkOrderLineItem woli3 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder2, workType);
        insert new List<WorkOrderLineItem>{ woli1, woli2, woli3 };

        ServiceAppointment overlapForResource1 = HOT_TestDataFactory.createServiceAppointment(woli1);
        overlapForResource1.HOT_ServiceResource__c = serviceResource1.Id;
        overlapForResource1.Status = 'Scheduled';
        overlapForResource1.EarliestStartTime = Datetime.newInstance(2026, 1, 10, 9, 30, 0);
        overlapForResource1.DueDate = Datetime.newInstance(2026, 1, 10, 10, 30, 0);

        ServiceAppointment nonOverlapForResource1 = HOT_TestDataFactory.createServiceAppointment(woli2);
        nonOverlapForResource1.HOT_ServiceResource__c = serviceResource1.Id;
        nonOverlapForResource1.Status = 'Scheduled';
        nonOverlapForResource1.EarliestStartTime = Datetime.newInstance(2026, 1, 10, 16, 0, 0);
        nonOverlapForResource1.DueDate = Datetime.newInstance(2026, 1, 10, 17, 0, 0);

        ServiceAppointment overlapForResource2 = HOT_TestDataFactory.createServiceAppointment(woli3);
        overlapForResource2.HOT_ServiceResource__c = serviceResource2.Id;
        overlapForResource2.Status = 'Scheduled';
        overlapForResource2.EarliestStartTime = Datetime.newInstance(2026, 1, 10, 13, 30, 0);
        overlapForResource2.DueDate = Datetime.newInstance(2026, 1, 10, 14, 30, 0);

        insert new List<ServiceAppointment>{ overlapForResource1, nonOverlapForResource1, overlapForResource2 };

        TestContext contextItem = new TestContext();
        contextItem.requestId = requestRecord.Id;
        return contextItem;
    }
}
