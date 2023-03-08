@isTest
public with sharing class HOT_UpdateChildRecordsServiceTest {
    @IsTest
    static void updateChildRecordsServiceFlowTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Old Subject', workType);
        request.InterpretationPostalCode__c = '0000';
        request.MeetingPostalCode__c = '0000';
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        HOT_UpdateChildRecordsService input = new HOT_UpdateChildRecordsService();

        request = [
            SELECT
                Id,
                Account__c,
                InterpretationStreet__c,
                InterpretationPostalCode__c,
                InterpretationPostalCity__c,
                MeetingStreet__c,
                MeetingPostalCode__c,
                MeetingPostalCity__c,
                Subject__c,
                UserPersonNumber__c,
                UserName__c,
                Description__c,
                IsScreenInterpreter__c,
                Dispatcher__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];

        request.InterpretationStreet__c = 'New interpretationStreet';
        request.InterpretationPostalCode__c = '1111';
        request.InterpretationPostalCity__c = 'New interpretationPostalCity';
        request.MeetingStreet__c = 'New meetingStreet';
        request.MeetingPostalCode__c = '1111';
        request.MeetingPostalCity__c = 'New meetingPostalCity';
        request.Subject__c = 'New subject';
        request.Description__c = 'New description';
        request.IsScreenInterpreter__c = true;

        input.request = request;

        input.isAccountChoice = false;
        input.isAddressChoice = true;
        input.isSubjectChoice = true;
        input.isDescriptionChoice = true;
        input.isScreenInterpreterChoice = true;
        input.isDispatcherChoice = true;

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
                Dispatcher__c
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
                    HOT_IsScreenInterpreterNew__c,
                    HOT_DispatcherNew__c
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
        System.assertEquals(request.Dispatcher__c, serviceAppointments.values()[0].HOT_DispatcherNew__c, 'Could not update Dispatcher on Request');
    }
}
