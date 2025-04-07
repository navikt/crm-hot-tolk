@isTest
private class HOT_EventControllerTest {
    @IsTest
    public static void testResourceServiceAppointmentChanged() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment sa = [
            SELECT Id, Status, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c
            FROM ServiceAppointment
            LIMIT 1
        ];

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User user = HOT_TestDataFactory.createUser('User', profile);
        insert user;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert serviceResource;
        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert ar;

        Test.startTest();
        sa = [
            SELECT Id, Status, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c
            FROM ServiceAppointment
            WHERE Id = :sa.Id
            LIMIT 1
        ];
        sa.Status = 'Dispatched';
        update sa;
        Test.stopTest();

        System.Assert.areEqual(1, [SELECT COUNT() FROM Event WHERE WhatId = :sa.Id], 'Could not create event');
    }
}
