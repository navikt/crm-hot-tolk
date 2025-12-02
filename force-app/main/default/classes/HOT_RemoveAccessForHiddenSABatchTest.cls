@isTest
private class HOT_RemoveAccessForHiddenSABatchTest {
    @TestSetup
    static void makeData() {
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        User u = HOT_TestDataFactory.createUser('user', p);
        insert u;

        ServiceResource sr = HOT_TestDataFactory.createServiceResource(u.Id);
        insert sr;

        WorkType wt = HOT_TestDataFactory.createWorkType();
        insert wt;
        OperatingHours oh = HOT_TestDataFactory.createOperatingHours();
        insert oh;
        ServiceTerritory st = HOT_TestDataFactory.createServiceTerritory(oh);
        insert st;
        ServiceTerritoryMember stm = HOT_TestDataFactory.createServiceTerritoryMember(sr, st);
        insert stm;
    }

    @IsTest
    private static void testRemoveAccessForHiddenServiceAppointments() {
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        Account acc = HOT_TestDataFactory.createAccount(true);
        insert acc;
        HOT_Request__c req = HOT_TestDataFactory.createRequest('r1', wt);
        insert req;

        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        wo.AccountId = acc.Id;
        insert wo;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.HOT_Request__c = req.Id;
        sa.HOT_DelPol_IsHideRecord__c = true;
        insert sa;

        ServiceResource sr = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1];
        Id shareUserId = sr.RelatedRecordId;
        AssignedResource ar = new AssignedResource(ServiceAppointmentId = sa.Id, ServiceResourceId = sr.Id);
        insert ar;

        ServiceAppointmentShare saShare = new ServiceAppointmentShare(
            ParentId = sa.Id,
            UserOrGroupId = shareUserId,
            RowCause = 'Manual',
            AccessLevel = 'Edit'
        );

        WorkOrderShare woShare = new WorkOrderShare(
            ParentId = wo.Id,
            UserOrGroupId = shareUserId,
            RowCause = 'Manual',
            AccessLevel = 'Edit'
        );

        AccountShare accShare = new AccountShare(
            AccountId = acc.Id,
            UserOrGroupId = shareUserId,
            RowCause = 'Manual',
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'None',
            CaseAccessLevel = 'None'
        );

        insert new List<SObject>{ saShare, woShare, accShare };

        Set<Id> saShareIds = new Set<Id>{ saShare.Id };
        Set<Id> woShareIds = new Set<Id>{ woShare.Id };
        Set<Id> accShareIds = new Set<Id>{ accShare.Id };

        // Sanity: they exist before running the batch
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE Id IN :saShareIds],
            'Pre-condition: our SA share should exist'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM WorkOrderShare WHERE Id IN :woShareIds],
            'Pre-condition: our WO share should exist'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM AccountShare WHERE Id IN :accShareIds],
            'Pre-condition: our Account share should exist'
        );

        HOT_RemoveAccessForHiddenSABatch batch = new HOT_RemoveAccessForHiddenSABatch();

        Test.startTest();
        batch.execute((Database.BatchableContext) null, new List<ServiceAppointment>{ sa });
        Test.stopTest();

        sa = [
            SELECT Id, HOT_DelPol_ProcessedHidden__c
            FROM ServiceAppointment
            WHERE Id = :sa.Id
        ];

        System.assertEquals(
            true,
            sa.HOT_DelPol_ProcessedHidden__c,
            'Hidden SA should be marked as processed by the batch'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM ServiceAppointmentShare WHERE Id IN :saShareIds],
            'Our manual ServiceAppointment shares for hidden SA should be removed'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM WorkOrderShare WHERE Id IN :woShareIds],
            'Our manual WorkOrder shares for hidden SAs WorkOrder should be removed'
        );
        System.assertEquals(
            0,
            [SELECT COUNT() FROM AccountShare WHERE Id IN :accShareIds],
            'Our manual Account shares for hidden SAs Account should be removed'
        );
    }
}
