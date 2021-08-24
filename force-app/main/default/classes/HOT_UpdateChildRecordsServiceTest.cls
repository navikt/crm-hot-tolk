@isTest
public with sharing class HOT_UpdateChildRecordsServiceTest {
    @IsTest
    static void methodName() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Old Subject', workType);
        request.InterpretationPostalCode__c = '0000';
        request.MeetingPostalCode__c = '0000';
        request.AssignmentType__c = 'Work';
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        HOT_UpdateChildRecordsService input = new HOT_UpdateChildRecordsService();

        input.requestId = request.Id;
        input.interpretationStreet = 'New interpretationStreet';
        input.interpretationPostalCode = '1111';
        input.interpretationPostalCity = 'New interpretationPostalCity';
        input.meetingStreet = 'New meetingStreet';
        input.meetingPostalCode = '1111';
        input.meetingPostalCity = 'New meetingPostalCity';
        input.subject = 'New subject';
        input.description = 'New description';
        input.isScreenInterpreter = true;
        input.assignmentType = 'Private';

        Test.startTest();
        HOT_UpdateChildRecordsService.updateChildRecordsFromRequest(new List<HOT_UpdateChildRecordsService>{ input });
        Test.stopTest();

        request = [
            SELECT
                Id,
                InterpretationStreet__c,
                InterpretationPostalCode__c,
                InterpretationPostalCity__c,
                MeetingStreet__c,
                MeetingPostalCode__c,
                MeetingPostalCity__c,
                Subject__c,
                Description__c,
                IsScreenInterpreter__c,
                AssignmentType__c,
                PreferredResource1__c,
                PreferredResource2__c,
                PreferredResource3__c,
                InterpretationMethod__c,
                InterpretationMethodSecondary__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(
            [
                SELECT
                    Id,
                    HOT_InterpretationStreet__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_InterpretationPostalCity__c,
                    Street,
                    PostalCode,
                    City,
                    Subject,
                    Description
                FROM WorkOrder
                WHERE HOT_Request__c = :request.Id
            ]
        );
        Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem>(
            [
                SELECT
                    Id,
                    HOT_InterpretationPostalStreet__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_InterpretationPostalCity__c,
                    Street,
                    PostalCode,
                    City,
                    Subject,
                    Description
                FROM WorkOrderLineItem
                WHERE WorkOrderId IN :workOrders.keySet()
            ]
        );
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT
                    Id,
                    HOT_InterpretationStreet__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_InterpretationPostalCity__c,
                    Street,
                    PostalCode,
                    City,
                    Subject,
                    Description,
                    HOT_IsScreenInterpreterNew__c
                FROM ServiceAppointment
                WHERE HOT_Request__c = :request.Id
            ]
        );

        System.assertEquals('New subject', request.Subject__c, 'Could not update Subject on Request');
        System.assertEquals('New subject', workOrders.values()[0].Subject, 'Could not update Subject on WorkOrder');
        System.assertEquals(
            'New subject',
            workOrderLineItems.values()[0].Subject,
            'Could not update Subject on WorkOrderLineItem'
        );
        System.assertEquals(
            'New subject',
            serviceAppointments.values()[0].Subject,
            'Could not update Subject on ServiceAppointment'
        );
    }
}
