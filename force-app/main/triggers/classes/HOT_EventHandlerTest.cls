@IsTest
private class HOT_EventHandlerTest {
    @IsTest
    private static void testSetDefaultValues() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType, 1, null, null);
        request.MeetingStreet__c = 'Street 1';
        request.MeetingPostalCode__c = '1001';
        request.MeetingPostalCity__c = 'City';
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, AppointmentNumber, WorkType.Name, HOT_AddressFormated__c
            FROM ServiceAppointment
        ];

        String hotEventRecordTypeId = Schema.getGlobalDescribe()
            .get('Event')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('HOT_Events')
            .getRecordTypeId();

        Test.startTest();
        Event event = new Event(
            StartDateTime = DateTime.now(),
            DurationInMinutes = 60,
            WhatId = serviceAppointment.Id,
            RecordTypeId = hotEventRecordTypeId
        );
        insert event;
        event = [SELECT Subject, Location FROM Event];
        System.assertEquals(
            serviceAppointment.AppointmentNumber +
            ': ' +
            serviceAppointment.WorkType.Name,
            event.Subject
        );
        System.assertEquals(serviceAppointment.HOT_AddressFormated__c, event.Location);

        event.Subject = 'TEST';
        event = [SELECT Subject FROM Event];
        update event;

        System.assertEquals(
            serviceAppointment.AppointmentNumber +
            ': ' +
            serviceAppointment.WorkType.Name,
            event.Subject
        );
        Test.stopTest();
    }

    @IsTest
    private static void testChangeOfAddress() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType, 1, null, null);
        request.MeetingStreet__c = 'Street 1';
        request.MeetingPostalCode__c = '1001';
        request.MeetingPostalCity__c = 'City';
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, AppointmentNumber, WorkType.Name, HOT_AddressFormated__c
            FROM ServiceAppointment
        ];

        String hotEventRecordTypeId = Schema.getGlobalDescribe()
            .get('Event')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('HOT_Events')
            .getRecordTypeId();

        Event event = new Event(
            StartDateTime = DateTime.now(),
            DurationInMinutes = 60,
            WhatId = serviceAppointment.Id,
            RecordTypeId = hotEventRecordTypeId
        );
        insert event;

        Test.startTest();
        serviceAppointment.Street = 'Street 2';
        update serviceAppointment;
        Test.stopTest();

        event = [SELECT Location FROM Event];
        serviceAppointment = [SELECT HOT_AddressFormated__c FROM ServiceAppointment];
        System.assertEquals(serviceAppointment.HOT_AddressFormated__c, event.Location);
    }
}
