@isTest
public without sharing class HOT_RemoveAccessForHiddenSABatchTest {
    @IsTest
    public static void testRemoveAccessForHiddenServiceAppointments_NoOtherVisibleSAs() {
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        Account acc = HOT_TestDataFactory.createAccount(true);
        insert acc;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('TestRequest1', wt);
        insert req;

        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        wo.AccountId = acc.Id;
        insert wo;

        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;

        ServiceAppointment saHidden = HOT_TestDataFactory.createServiceAppointment(woli);
        saHidden.HOT_Request__c = req.Id;

        Date d = Date.today().addDays(1);
        DateTime start1 = DateTime.newInstance(d, Time.newInstance(9, 0, 0, 0));
        saHidden.EarliestStartTime = start1;
        saHidden.DueDate = start1.addHours(1);
        saHidden.ArrivalWindowStartTime = start1;
        saHidden.ArrivalWindowEndTime = start1.addHours(1);
        insert saHidden;

        ServiceResource sr1 = [SELECT Id, RelatedRecordId FROM ServiceResource ORDER BY CreatedDate ASC LIMIT 1];
        AssignedResource arHidden = new AssignedResource(
            ServiceAppointmentId = saHidden.Id,
            ServiceResourceId = sr1.Id
        );
        insert arHidden;

        Map<Id, Id> apptByAssign = new Map<Id, Id>{ arHidden.Id => saHidden.Id };
        Map<Id, Id> resByAssign = new Map<Id, Id>{ arHidden.Id => sr1.Id };
        HOT_ServiceAppointmentsSharingService.grantAccess(apptByAssign, resByAssign);

        // check before hide: one SA share, one WO share, one Account share
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saHidden.Id AND RowCause = 'Manual']
        );
        System.assertEquals(1, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :wo.Id AND RowCause = 'Manual']);
        System.assertEquals(1, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);

        saHidden.HOT_DelPol_IsHideRecord__c = true;
        update saHidden;

        Test.startTest();
        HOT_RemoveAccessForHiddenSABatch instance = new HOT_RemoveAccessForHiddenSABatch();
        database.executebatch(instance);
        Test.stopTest();

        // All Manual shares removed
        System.assertEquals(
            0,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saHidden.Id AND RowCause = 'Manual']
        );
        System.assertEquals(0, [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :wo.Id AND RowCause = 'Manual']);
        System.assertEquals(0, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);
    }

    // SAME Service Resource: Account share should stay
    @IsTest
    public static void testRemoveAccessForHiddenServiceAppointments_HasOtherVisibleSharedSAs() {
        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        Account acc = HOT_TestDataFactory.createAccount(true);
        insert acc;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('TestRequest', wt);
        insert req;

        WorkOrder woHidden = HOT_TestDataFactory.createWorkOrder(req, wt);
        woHidden.AccountId = acc.Id;
        insert woHidden;
        WorkOrderLineItem woliHidden = HOT_TestDataFactory.createWorkOrderLineItem(woHidden, wt);
        insert woliHidden;
        ServiceAppointment saHidden = HOT_TestDataFactory.createServiceAppointment(woliHidden);
        saHidden.HOT_Request__c = req.Id;

        WorkOrder woVisible = HOT_TestDataFactory.createWorkOrder(req, wt);
        woVisible.AccountId = acc.Id;
        insert woVisible;
        WorkOrderLineItem woliVisible = HOT_TestDataFactory.createWorkOrderLineItem(woVisible, wt);
        insert woliVisible;
        ServiceAppointment saVisible = HOT_TestDataFactory.createServiceAppointment(woliVisible);
        saVisible.HOT_Request__c = req.Id;
        saVisible.HOT_DelPol_IsHideRecord__c = false;
        saVisible.HOT_DelPol_ProcessedHidden__c = false;

        Date d = Date.today().addDays(1);
        DateTime t0900 = DateTime.newInstance(d, Time.newInstance(9, 0, 0, 0));
        saHidden.EarliestStartTime = t0900;
        saHidden.DueDate = t0900.addHours(1);
        saHidden.ArrivalWindowStartTime = t0900;
        saHidden.ArrivalWindowEndTime = t0900.addHours(1);

        saVisible.EarliestStartTime = t0900.addHours(1);
        saVisible.DueDate = t0900.addHours(2);
        saVisible.ArrivalWindowStartTime = t0900.addHours(1);
        saVisible.ArrivalWindowEndTime = t0900.addHours(2);

        insert new List<ServiceAppointment>{ saHidden, saVisible };

        ServiceResource sr = [SELECT Id, RelatedRecordId FROM ServiceResource ORDER BY CreatedDate ASC LIMIT 1];
        AssignedResource arHidden = new AssignedResource(ServiceAppointmentId = saHidden.Id, ServiceResourceId = sr.Id);
        AssignedResource arVisible = new AssignedResource(
            ServiceAppointmentId = saVisible.Id,
            ServiceResourceId = sr.Id
        );
        insert new List<AssignedResource>{ arHidden, arVisible };

        Map<Id, Id> apptByAssign = new Map<Id, Id>{ arHidden.Id => saHidden.Id, arVisible.Id => saVisible.Id };
        Map<Id, Id> resByAssign = new Map<Id, Id>{ arHidden.Id => sr.Id, arVisible.Id => sr.Id };
        HOT_ServiceAppointmentsSharingService.grantAccess(apptByAssign, resByAssign);

        // Before hide: 1 SA share per SA, 1 WO share per WO, and 1 Account share (per user)
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saHidden.Id AND RowCause = 'Manual']
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saVisible.Id AND RowCause = 'Manual']
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woHidden.Id AND RowCause = 'Manual']
        );

        System.assertEquals(
            1,
            [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woVisible.Id AND RowCause = 'Manual']
        );
        System.assertEquals(1, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);

        saHidden.HOT_DelPol_IsHideRecord__c = true;
        update saHidden;

        Test.startTest();
        HOT_RemoveAccessForHiddenSABatch instance = new HOT_RemoveAccessForHiddenSABatch();
        database.executebatch(instance);
        Test.stopTest();

        // Hidden SA share removed
        System.assertEquals(
            0,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saHidden.Id AND RowCause = 'Manual']
        );

        // Visible SA share remains for the same interpreter
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saVisible.Id AND RowCause = 'Manual']
        );

        // WO shares: hidden SA WO share removed, visible SA WO share remains
        System.assertEquals(
            0,
            [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woHidden.Id AND RowCause = 'Manual']
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woVisible.Id AND RowCause = 'Manual']
        );

        // Account share is KEPT because another visible SA exists (same interpreter)
        System.assertEquals(1, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);
    }

    // DIFFERENT Service Resources: hidden user's AccountShare should be deleted, other user's should remain
    @IsTest
    public static void testRemoveAccessForHiddenServiceAppointments_HasOtherVisibleSAs_DifferentServiceResource() {
        Profile profile = [SELECT Id FROM Profile LIMIT 1];
        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;
        ServiceResource sr2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        insert sr2;

        ServiceResource sr1 = [SELECT Id, RelatedRecordId FROM ServiceResource ORDER BY CreatedDate ASC LIMIT 1];

        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        Account acc = HOT_TestDataFactory.createAccount(true);
        insert acc;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('DifferentSR', wt);
        insert req;

        WorkOrder woHidden = HOT_TestDataFactory.createWorkOrder(req, wt);
        woHidden.AccountId = acc.Id;
        insert woHidden;
        WorkOrderLineItem woliHidden = HOT_TestDataFactory.createWorkOrderLineItem(woHidden, wt);
        insert woliHidden;
        ServiceAppointment saHidden = HOT_TestDataFactory.createServiceAppointment(woliHidden);
        saHidden.HOT_Request__c = req.Id;

        WorkOrder woVisible = HOT_TestDataFactory.createWorkOrder(req, wt);
        woVisible.AccountId = acc.Id;
        insert woVisible;
        WorkOrderLineItem woliVisible = HOT_TestDataFactory.createWorkOrderLineItem(woVisible, wt);
        insert woliVisible;
        ServiceAppointment saVisible = HOT_TestDataFactory.createServiceAppointment(woliVisible);
        saVisible.HOT_Request__c = req.Id;
        saVisible.HOT_DelPol_IsHideRecord__c = false;
        saVisible.HOT_DelPol_ProcessedHidden__c = false;

        Date d = Date.today().addDays(2);
        DateTime t0900 = DateTime.newInstance(d, Time.newInstance(9, 0, 0, 0));
        saHidden.EarliestStartTime = t0900;
        saHidden.DueDate = t0900.addHours(1);
        saHidden.ArrivalWindowStartTime = t0900;
        saHidden.ArrivalWindowEndTime = t0900.addHours(1);

        saVisible.EarliestStartTime = t0900.addHours(1);
        saVisible.DueDate = t0900.addHours(2);
        saVisible.ArrivalWindowStartTime = t0900.addHours(1);
        saVisible.ArrivalWindowEndTime = t0900.addHours(2);

        insert new List<ServiceAppointment>{ saHidden, saVisible };

        AssignedResource arHidden = new AssignedResource(
            ServiceAppointmentId = saHidden.Id,
            ServiceResourceId = sr1.Id
        );
        AssignedResource arVisible = new AssignedResource(
            ServiceAppointmentId = saVisible.Id,
            ServiceResourceId = sr2.Id
        );
        insert new List<AssignedResource>{ arHidden, arVisible };

        HOT_ServiceAppointmentsSharingService.grantAccess(
            new Map<Id, Id>{ arHidden.Id => saHidden.Id, arVisible.Id => saVisible.Id },
            new Map<Id, Id>{ arHidden.Id => sr1.Id, arVisible.Id => sr2.Id }
        );

        // Pre-assert: 2 Account shares (one per SR)
        System.assertEquals(2, [SELECT COUNT() FROM AccountShare WHERE AccountId = :acc.Id AND RowCause = 'Manual']);

        // Hide the SA for sr1
        saHidden.HOT_DelPol_IsHideRecord__c = true;
        update saHidden;

        Test.startTest();
        HOT_RemoveAccessForHiddenSABatch instance = new HOT_RemoveAccessForHiddenSABatch();
        database.executebatch(instance);
        Test.stopTest();

        // SA shares
        System.assertEquals(
            0,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saHidden.Id AND RowCause = 'Manual']
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE ParentId = :saVisible.Id AND RowCause = 'Manual']
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woHidden.Id AND RowCause = 'Manual']
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM WorkOrderShare WHERE ParentId = :woVisible.Id AND RowCause = 'Manual']
        );

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
