@isTest
public with sharing class HOT_UpdateChildRecordsServiceTest {
    @IsTest
    static void updateChildRecordsServiceFlowTest() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Old Subject', workType);
        request.InterpretationPostalCode__c = '0000';
        request.MeetingPostalCode__c = '0000';
        request.Account__c = personAccount.Id;
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
                HOT_PersonContactId__c,
                IsScreenInterpreter__c,
                Dispatcher__c,
                InterpretationMethod__c
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
        request.Account__c = personAccount.Id;
        request.InterpretationMethod__c = workType.Id;

        input.request = request;

        input.isAccountChoice = true;
        input.isAddressChoice = true;
        input.isSubjectChoice = true;
        input.isDescriptionChoice = true;
        input.isScreenInterpreterChoice = true;
        input.isDispatcherChoice = true;
        input.isInterpreterMethodChoice = true;

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
        System.assertEquals(
            request.Dispatcher__c,
            serviceAppointments.values()[0].HOT_DispatcherNew__c,
            'Could not update Dispatcher on Request'
        );
    }
}
