@isTest
private class HOT_InterestedResourceHandlerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
    }

    @isTest
    static void createAndRetractInterestedResource() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment];
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource];
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );

        Test.startTest();
        insert interestedResource;
        Test.stopTest();

        WorkOrderLineItem workOrderLineItem = [SELECT Id, HOT_NumberOfInterestedResources__c FROM WorkOrderLineItem];
        System.debug(workOrderLineItem);
        System.assertEquals(
            1,
            workOrderLineItem.HOT_NumberOfInterestedResources__c,
            'Could not update HOT_NumberOfInterestedResources__c on WOLI'
        );

        interestedResource.Status__c = 'Retracted Interest';
        update interestedResource;

        workOrderLineItem = [SELECT Id, HOT_NumberOfInterestedResources__c FROM WorkOrderLineItem];
        System.debug(workOrderLineItem);
        System.assertEquals(
            0,
            workOrderLineItem.HOT_NumberOfInterestedResources__c,
            'Could not update HOT_NumberOfInterestedResources__c on WOLI'
        );
    }
}
