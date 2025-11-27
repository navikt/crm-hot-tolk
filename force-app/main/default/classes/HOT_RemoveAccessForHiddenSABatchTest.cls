@isTest
public without sharing class HOT_RemoveAccessForHiddenSABatchTest {
    @TestSetup
    static void makeData() {
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        User u = HOT_TestDataFactory.createUser('user', p);
        insert u;

        ServiceResource sr = HOT_TestDataFactory.createServiceResource(u.Id);
        insert sr;

        WorkType wt = HOT_TestDataFactory.createWorkType();
        OperatingHours oh = HOT_TestDataFactory.createOperatingHours();
        insert oh;
        ServiceTerritory st = HOT_TestDataFactory.createServiceTerritory(oh);
        insert new List<SObject>{ wt, st };
    }

    @IsTest
    static void testRemoveAccessForHiddenServiceAppointments_NoOtherVisibleSAs() {
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        Account acc = HOT_TestDataFactory.createAccount(true);
        HOT_Request__c req = HOT_TestDataFactory.createRequest('r1', wt);
        insert new List<SObject>{ acc, req };

        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        wo.AccountId = acc.Id;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert new List<SObject>{ wo, woli };

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.HOT_Request__c = req.Id;

        DateTime t = DateTime.now().addDays(1);
        sa.EarliestStartTime = t;
        sa.DueDate = t.addHours(1);
        sa.ArrivalWindowStartTime = t;
        sa.ArrivalWindowEndTime = t.addHours(1);
        insert sa;

        ServiceResource sr = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1];
        AssignedResource ar = new AssignedResource(ServiceAppointmentId = sa.Id, ServiceResourceId = sr.Id);
        insert ar;

        HOT_ServiceAppointmentsSharingService.grantAccess(
            new Map<Id, Id>{ ar.Id => sa.Id },
            new Map<Id, Id>{ ar.Id => sr.Id }
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :sa.Id AND RowCause = 'Manual']
        );
        System.assertEquals(1, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :wo.Id AND RowCause = 'Manual']);
        System.assertEquals(1, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);

        sa.HOT_DelPol_IsHideRecord__c = true;
        update sa;

        Test.startTest();
        Database.executeBatch(new HOT_RemoveAccessForHiddenSABatch());
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :sa.Id AND RowCause = 'Manual']
        );
        System.assertEquals(0, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :wo.Id AND RowCause = 'Manual']);
        System.assertEquals(0, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);
    }

    @IsTest
    static void testRemoveAccessForHiddenServiceAppointments_HasOtherVisibleSharedSAs() {
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        Account acc = HOT_TestDataFactory.createAccount(true);
        HOT_Request__c req = HOT_TestDataFactory.createRequest('r2', wt);
        insert new List<SObject>{ acc, req };

        WorkOrder woH = HOT_TestDataFactory.createWorkOrder(req, wt);
        WorkOrder woV = HOT_TestDataFactory.createWorkOrder(req, wt);
        woH.AccountId = acc.Id;
        woV.AccountId = acc.Id;

        WorkOrderLineItem woliH = HOT_TestDataFactory.createWorkOrderLineItem(woH, wt);
        WorkOrderLineItem woliV = HOT_TestDataFactory.createWorkOrderLineItem(woV, wt);

        insert new List<SObject>{ woH, woV, woliH, woliV };

        ServiceAppointment saH = HOT_TestDataFactory.createServiceAppointment(woliH);
        ServiceAppointment saV = HOT_TestDataFactory.createServiceAppointment(woliV);
        saH.HOT_Request__c = req.Id;
        saV.HOT_Request__c = req.Id;

        DateTime base = DateTime.now().addDays(1);
        saH.EarliestStartTime = base;
        saH.DueDate = base.addHours(1);
        saH.ArrivalWindowStartTime = base;
        saH.ArrivalWindowEndTime = base.addHours(1);

        saV.EarliestStartTime = base.addHours(1);
        saV.DueDate = base.addHours(2);
        saV.ArrivalWindowStartTime = base.addHours(1);
        saV.ArrivalWindowEndTime = base.addHours(2);

        insert new List<ServiceAppointment>{ saH, saV };

        ServiceResource sr = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1];
        AssignedResource arH = new AssignedResource(ServiceAppointmentId = saH.Id, ServiceResourceId = sr.Id);
        AssignedResource arV = new AssignedResource(ServiceAppointmentId = saV.Id, ServiceResourceId = sr.Id);
        insert new List<AssignedResource>{ arH, arV };

        HOT_ServiceAppointmentsSharingService.grantAccess(
            new Map<Id, Id>{ arH.Id => saH.Id, arV.Id => saV.Id },
            new Map<Id, Id>{ arH.Id => sr.Id, arV.Id => sr.Id }
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saH.Id AND RowCause = 'Manual']
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saV.Id AND RowCause = 'Manual']
        );
        System.assertEquals(1, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woH.Id AND RowCause = 'Manual']);
        System.assertEquals(1, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woV.Id AND RowCause = 'Manual']);
        System.assertEquals(1, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);

        saH.HOT_DelPol_IsHideRecord__c = true;
        update saH;

        Test.startTest();
        Database.executeBatch(new HOT_RemoveAccessForHiddenSABatch());
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saH.Id AND RowCause = 'Manual']
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saV.Id AND RowCause = 'Manual']
        );
        System.assertEquals(0, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woH.Id AND RowCause = 'Manual']);
        System.assertEquals(1, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woV.Id AND RowCause = 'Manual']);
        System.assertEquals(1, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);
    }

    @IsTest
    static void testRemoveAccessForHiddenServiceAppointments_HasOtherVisibleSAs_DifferentServiceResource() {
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        User u2 = HOT_TestDataFactory.createUser('u2', p);
        insert u2;

        ServiceResource sr2 = HOT_TestDataFactory.createServiceResource(u2.Id);
        insert sr2;

        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        Account acc = HOT_TestDataFactory.createAccount(true);
        HOT_Request__c req = HOT_TestDataFactory.createRequest('r3', wt);
        insert new List<SObject>{ acc, req };

        ServiceResource sr1 = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        Test.startTest();
        WorkOrder woH = HOT_TestDataFactory.createWorkOrder(req, wt);
        WorkOrder woV = HOT_TestDataFactory.createWorkOrder(req, wt);
        woH.AccountId = acc.Id;
        woV.AccountId = acc.Id;
        insert woH;
        insert woV;

        WorkOrderLineItem woliH = HOT_TestDataFactory.createWorkOrderLineItem(woH, wt);
        WorkOrderLineItem woliV = HOT_TestDataFactory.createWorkOrderLineItem(woV, wt);
        insert woliH;
        insert woliV;

        //HOT_DatabaseOperations.insertRecords(new List<SObject>{ woH, woV, woliH, woliV });

        ServiceAppointment saH = HOT_TestDataFactory.createServiceAppointment(woliH);
        ServiceAppointment saV = HOT_TestDataFactory.createServiceAppointment(woliV);
        saH.HOT_Request__c = req.Id;
        saV.HOT_Request__c = req.Id;

        DateTime t = DateTime.now().addDays(2);
        saH.EarliestStartTime = t;
        saH.DueDate = t.addHours(1);
        saH.ArrivalWindowStartTime = t;
        saH.ArrivalWindowEndTime = t.addHours(1);
        saH.HOT_IsEmployedInterpreter__c = true;

        saV.EarliestStartTime = t.addHours(1);
        saV.DueDate = t.addHours(2);
        saV.ArrivalWindowStartTime = t.addHours(1);
        saV.ArrivalWindowEndTime = t.addHours(2);
        saV.HOT_IsEmployedInterpreter__c = true;
        insert new List<ServiceAppointment>{ saH, saV };
        //HOT_DatabaseOperations.insertRecords(new List<SObject>{ saH, saV });

        ServiceTerritoryMember stm1 = HOT_TestDataFactory.createServiceTerritoryMember(sr1, st);
        ServiceTerritoryMember stm2 = HOT_TestDataFactory.createServiceTerritoryMember(sr2, st);
        insert new List<ServiceTerritoryMember>{ stm1, stm2 };

        AssignedResource arH = new AssignedResource(ServiceAppointmentId = saH.Id, ServiceResourceId = sr1.Id);
        AssignedResource arV = new AssignedResource(ServiceAppointmentId = saV.Id, ServiceResourceId = sr2.Id);
        insert new List<AssignedResource>{ arH, arV };

        HOT_ServiceAppointmentsSharingService.grantAccess(
            new Map<Id, Id>{ arH.Id => saH.Id, arV.Id => saV.Id },
            new Map<Id, Id>{ arH.Id => sr1.Id, arV.Id => sr2.Id }
        );

        System.assertEquals(2, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);

        saH.HOT_DelPol_IsHideRecord__c = true;
        update saH;

        Database.executeBatch(new HOT_RemoveAccessForHiddenSABatch());
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saH.Id AND RowCause = 'Manual']
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saV.Id AND RowCause = 'Manual']
        );
        System.assertEquals(0, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woH.Id AND RowCause = 'Manual']);
        System.assertEquals(1, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woV.Id AND RowCause = 'Manual']);
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM AccountShare
                WHERE AccountId = :acc.Id AND RowCause = 'Manual' AND UserOrGroupId = :sr1.RelatedRecordId
            ]
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM AccountShare
                WHERE AccountId = :acc.Id AND RowCause = 'Manual' AND UserOrGroupId = :sr2.RelatedRecordId
            ]
        );
        System.assertEquals(1, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);
    }
}
