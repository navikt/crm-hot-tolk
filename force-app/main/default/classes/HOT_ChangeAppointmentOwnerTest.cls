@IsTest
private class HOT_ChangeAppointmentOwnerTest {
    @TestSetup
    static void setup() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Group formidlerGroup = [
                SELECT Id
                FROM Group
                WHERE DeveloperName = 'HOT_group_47000_formidler' AND Type = 'Regular'
            ];
            insert new GroupMember(GroupId = formidlerGroup.Id, UserOrGroupId = UserInfo.getUserId());
        }
        OperatingHours hours = HOT_TestDataFactory.createOperatingHours();
        insert hours;
        ServiceTerritory territory = HOT_TestDataFactory.createServiceTerritory(hours);
        insert territory;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Owner change', workType);
        request.NumberOfInterpreters__c = 3;
        request.ServiceTerritory__c = territory.Id;
        insert request;
        request.Status__c = 'Godkjent';
        update request;
    }

    @IsTest
    static void checksAccessWithoutSelection() {
        HOT_ChangeAppointmentOwner.Input input = new HOT_ChangeAppointmentOwner.Input();
        input.checkAccessOnly = true;
        Test.startTest();
        List<HOT_ChangeAppointmentOwner.Result> results = HOT_ChangeAppointmentOwner.changeOwner(
            new List<HOT_ChangeAppointmentOwner.Input>{ input, input }
        );
        Test.stopTest();
        System.assertEquals(2, results.size());
        System.assertEquals(true, results[0].hasAccess);
        System.assertEquals(true, results[1].hasAccess);
    }

    @IsTest
    static void acceptsNestedMembership() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Group formidlerGroup = [
                SELECT Id
                FROM Group
                WHERE DeveloperName = 'HOT_group_47000_formidler' AND Type = 'Regular'
            ];
            delete [
                SELECT Id
                FROM GroupMember
                WHERE GroupId = :formidlerGroup.Id AND UserOrGroupId = :UserInfo.getUserId()
            ];
            Group child = new Group(Name = 'Owner access child', DeveloperName = 'OwnerAccessChild', Type = 'Regular');
            Group middle = new Group(
                Name = 'Owner access middle',
                DeveloperName = 'OwnerAccessMiddle',
                Type = 'Regular'
            );
            insert new List<Group>{ child, middle };
            insert new List<GroupMember>{
                new GroupMember(GroupId = child.Id, UserOrGroupId = UserInfo.getUserId()),
                new GroupMember(GroupId = middle.Id, UserOrGroupId = child.Id),
                new GroupMember(GroupId = formidlerGroup.Id, UserOrGroupId = middle.Id)
            };
        }
        HOT_ChangeAppointmentOwner.Input input = new HOT_ChangeAppointmentOwner.Input();
        input.checkAccessOnly = true;
        Test.startTest();
        System.assertEquals(
            true,
            HOT_ChangeAppointmentOwner.changeOwner(new List<HOT_ChangeAppointmentOwner.Input>{ input })[0].hasAccess
        );
        Test.stopTest();
    }

    @IsTest
    static void rejectsNonMemberBeforeSelection() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            delete [SELECT Id FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId()];
        }
        HOT_ChangeAppointmentOwner.Input input = new HOT_ChangeAppointmentOwner.Input();
        input.checkAccessOnly = true;
        Test.startTest();
        System.assertEquals(
            false,
            HOT_ChangeAppointmentOwner.changeOwner(new List<HOT_ChangeAppointmentOwner.Input>{ input })[0].hasAccess
        );
        input.checkAccessOnly = false;
        try {
            HOT_ChangeAppointmentOwner.changeOwner(new List<HOT_ChangeAppointmentOwner.Input>{ input });
            System.assert(false, 'Nonmembers must not change owners');
        } catch (Exception error) {
            System.assertEquals('Dette er kun en formidler funksjon!', error.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void changesOnlySelectedAppointmentOwners() {
        List<ServiceAppointment> beforeAppointments = [
            SELECT Id, OwnerId, ServiceTerritoryId
            FROM ServiceAppointment
            ORDER BY Id
        ];
        System.assert(beforeAppointments.size() >= 3, 'Test requires an unselected sibling');
        List<HOT_Request__c> beforeRequests = [SELECT Id, OwnerId, ServiceTerritory__c FROM HOT_Request__c ORDER BY Id];
        List<WorkOrder> beforeOrders = [SELECT Id, OwnerId, ServiceTerritoryId FROM WorkOrder ORDER BY Id];
        List<WorkOrderLineItem> beforeLines = [SELECT Id, ServiceTerritoryId FROM WorkOrderLineItem ORDER BY Id];
        Set<Id> selectedIds = new Set<Id>{ beforeAppointments[0].Id, beforeAppointments[1].Id };
        HOT_ChangeAppointmentOwner.Input input = new HOT_ChangeAppointmentOwner.Input();
        input.ownerQueueName = 'nav tolketjeneste oslo';
        input.serviceAppointmentIds = new List<Id>{
            beforeAppointments[0].Id,
            beforeAppointments[0].Id,
            beforeAppointments[1].Id
        };

        Test.startTest();
        HOT_ChangeAppointmentOwner.changeOwner(new List<HOT_ChangeAppointmentOwner.Input>{ input });
        Test.stopTest();

        Id ownerId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'queue_4703'].Id;
        Map<Id, ServiceAppointment> afterAppointments = new Map<Id, ServiceAppointment>(
            [SELECT Id, OwnerId, ServiceTerritoryId FROM ServiceAppointment]
        );
        for (ServiceAppointment beforeAppointment : beforeAppointments) {
            ServiceAppointment afterAppointment = afterAppointments.get(beforeAppointment.Id);
            System.assertEquals(
                selectedIds.contains(beforeAppointment.Id) ? ownerId : beforeAppointment.OwnerId,
                afterAppointment.OwnerId
            );
            System.assertEquals(beforeAppointment.ServiceTerritoryId, afterAppointment.ServiceTerritoryId);
        }
        System.assertEquals(beforeRequests, [SELECT Id, OwnerId, ServiceTerritory__c FROM HOT_Request__c ORDER BY Id]);
        System.assertEquals(beforeOrders, [SELECT Id, OwnerId, ServiceTerritoryId FROM WorkOrder ORDER BY Id]);
        System.assertEquals(beforeLines, [SELECT Id, ServiceTerritoryId FROM WorkOrderLineItem ORDER BY Id]);
    }

    @IsTest
    static void changesOwnerWithoutRequest() {
        ServiceAppointment appointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        appointment.HOT_Request__c = null;
        update appointment;
        System.assertEquals(
            null,
            [SELECT HOT_Request__c FROM ServiceAppointment WHERE Id = :appointment.Id].HOT_Request__c
        );
        HOT_ChangeAppointmentOwner.Input input = new HOT_ChangeAppointmentOwner.Input();
        input.serviceAppointmentIds = new List<Id>{ appointment.Id };
        input.ownerQueueName = 'NAV Akuttvakt Tolk';

        Test.startTest();
        HOT_ChangeAppointmentOwner.changeOwner(new List<HOT_ChangeAppointmentOwner.Input>{ input });
        Test.stopTest();

        System.assertEquals(
            [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'HOT_Tolk_Akuttvakt'].Id,
            [SELECT OwnerId FROM ServiceAppointment WHERE Id = :appointment.Id].OwnerId
        );
    }

    @IsTest
    static void rejectsEmptySelection() {
        HOT_ChangeAppointmentOwner.Input input = new HOT_ChangeAppointmentOwner.Input();
        input.serviceAppointmentIds = new List<Id>();
        input.ownerQueueName = 'NAV Akuttvakt Tolk';
        Test.startTest();
        try {
            HOT_ChangeAppointmentOwner.changeOwner(new List<HOT_ChangeAppointmentOwner.Input>{ input });
            System.assert(false, 'Empty selection must fail');
        } catch (Exception error) {
            System.assert(error.getMessage().contains('Marker minst ett oppdrag'));
        }
        Test.stopTest();
    }

    @IsTest
    static void invalidQueueDoesNotChangeOwner() {
        ServiceAppointment appointment = [SELECT Id, OwnerId FROM ServiceAppointment LIMIT 1];
        HOT_ChangeAppointmentOwner.Input input = new HOT_ChangeAppointmentOwner.Input();
        input.serviceAppointmentIds = new List<Id>{ appointment.Id };
        input.ownerQueueName = 'Nonexistent owner queue';
        Test.startTest();
        try {
            HOT_ChangeAppointmentOwner.changeOwner(new List<HOT_ChangeAppointmentOwner.Input>{ input });
            System.assert(false, 'Invalid queue must fail');
        } catch (Exception error) {
            System.assert(error.getMessage().contains('Fant ikke eierk'));
        }
        Test.stopTest();
        System.assertEquals(
            appointment.OwnerId,
            [SELECT OwnerId FROM ServiceAppointment WHERE Id = :appointment.Id].OwnerId
        );
    }
}
