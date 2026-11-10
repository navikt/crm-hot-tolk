@IsTest
private class HOT_SAMessageControllerTest {
    @TestSetup
    static void makeData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permissions = new PermissionSet(Name = 'HOT_SAMessageTest', Label = 'SA Message Test');
            insert permissions;
            insert new ObjectPermissions(
                ParentId = permissions.Id,
                SObjectType = 'HOT_ServiceAppointmentMessage__c',
                PermissionsRead = true
            );
            insert new List<FieldPermissions>{
                new FieldPermissions(
                    ParentId = permissions.Id,
                    SObjectType = 'HOT_ServiceAppointmentMessage__c',
                    Field = 'HOT_ServiceAppointmentMessage__c.Message__c',
                    PermissionsRead = true
                ),
                new FieldPermissions(
                    ParentId = permissions.Id,
                    SObjectType = 'HOT_ServiceAppointmentMessage__c',
                    Field = 'HOT_ServiceAppointmentMessage__c.Request__c',
                    PermissionsRead = true
                )
            };
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissions.Id);
        }
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Meldingstest', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        HOT_Request__c otherRequest = HOT_TestDataFactory.createRequest('Annen bestilling', workType);
        insert otherRequest;

        List<HOT_ServiceAppointmentMessage__c> messages = new List<HOT_ServiceAppointmentMessage__c>{
            new HOT_ServiceAppointmentMessage__c(Request__c = request.Id, Message__c = 'Eldre melding'),
            new HOT_ServiceAppointmentMessage__c(Request__c = request.Id, Message__c = 'Nyeste melding'),
            new HOT_ServiceAppointmentMessage__c(Request__c = otherRequest.Id, Message__c = 'Annen bestilling'),
            new HOT_ServiceAppointmentMessage__c(Message__c = 'Uten bestilling')
        };
        insert messages;
        Test.setCreatedDate(messages[0].Id, Datetime.newInstanceGmt(2020, 1, 1, 10, 0, 0));
        Test.setCreatedDate(messages[1].Id, Datetime.newInstanceGmt(2020, 1, 2, 10, 0, 0));
    }

    @IsTest
    static void returnsOnlyRelatedMessagesNewestFirst() {
        ServiceAppointment appointment = [SELECT Id FROM ServiceAppointment WHERE HOT_Request__c != NULL LIMIT 1];

        Test.startTest();
        List<HOT_ServiceAppointmentMessage__c> messages = getMessagesAsUser(appointment.Id);
        Test.stopTest();

        Assert.areEqual(2, messages.size());
        Assert.areEqual('Nyeste melding', messages[0].Message__c);
        Assert.areEqual('Eldre melding', messages[1].Message__c);
        Assert.isTrue(messages[0].CreatedDate > messages[1].CreatedDate);
    }

    @IsTest
    static void returnsEmptyWhenRequestHasNoMessages() {
        ServiceAppointment appointment = [SELECT Id, HOT_Request__c FROM ServiceAppointment LIMIT 1];
        delete [SELECT Id FROM HOT_ServiceAppointmentMessage__c WHERE Request__c = :appointment.HOT_Request__c];

        Assert.areEqual(0, getMessagesAsUser(appointment.Id).size());
    }

    @IsTest
    static void returnsEmptyWhenAppointmentHasNoRequest() {
        ServiceAppointment appointment = [SELECT Id, HOT_Request__c FROM ServiceAppointment LIMIT 1];
        appointment.HOT_Request__c = null;
        update appointment;

        Assert.areEqual(0, getMessagesAsUser(appointment.Id).size());
    }

    @IsTest
    static void returnsRequestAndWorkOrderMessages() {
        ServiceAppointment appointment = [
            SELECT Id, HOT_Request__c, HOT_WorkOrderID__c
            FROM ServiceAppointment
            WHERE HOT_Request__c != NULL
            LIMIT 1
        ];
        Assert.isNotNull(appointment.HOT_WorkOrderID__c);
        HOT_Request__c otherRequest = [SELECT Id FROM HOT_Request__c WHERE Id != :appointment.HOT_Request__c LIMIT 1];
        WorkOrder unrelatedWorkOrder = HOT_TestDataFactory.createWorkOrder(
            otherRequest,
            [SELECT Id FROM WorkType LIMIT 1]
        );
        insert unrelatedWorkOrder;
        List<HOT_ServiceAppointmentMessage__c> messages = new List<HOT_ServiceAppointmentMessage__c>{
            new HOT_ServiceAppointmentMessage__c(
                WorkOrder__c = appointment.HOT_WorkOrderID__c,
                Message__c = 'Arbeidsordremelding'
            ),
            new HOT_ServiceAppointmentMessage__c(
                WorkOrder__c = unrelatedWorkOrder.Id,
                Message__c = 'Annen arbeidsordre'
            )
        };
        insert messages;
        Test.setCreatedDate(messages[0].Id, Datetime.newInstanceGmt(2020, 1, 3, 10, 0, 0));

        Test.startTest();
        List<HOT_ServiceAppointmentMessage__c> results = getMessagesAsUser(appointment.Id);
        Test.stopTest();

        Assert.areEqual(3, results.size());
        Assert.areEqual('Arbeidsordremelding', results[0].Message__c);
        Assert.areEqual('Nyeste melding', results[1].Message__c);
        Assert.areEqual('Eldre melding', results[2].Message__c);
    }

    @IsTest
    static void returnsWorkOrderMessagesWhenRequestIsMissing() {
        ServiceAppointment appointment = [
            SELECT Id, HOT_Request__c, HOT_WorkOrderID__c
            FROM ServiceAppointment
            LIMIT 1
        ];
        Assert.isNotNull(appointment.HOT_WorkOrderID__c);
        HOT_ServiceAppointmentMessage__c message = new HOT_ServiceAppointmentMessage__c(
            WorkOrder__c = appointment.HOT_WorkOrderID__c,
            Message__c = 'Arbeidsordremelding'
        );
        insert message;
        appointment.HOT_Request__c = null;
        update appointment;

        List<HOT_ServiceAppointmentMessage__c> results = getMessagesAsUser(appointment.Id);
        Assert.areEqual(1, results.size());
        Assert.areEqual(message.Id, results[0].Id);
    }

    @IsTest
    static void returnsRequestMessagesWhenWorkOrderIsMissing() {
        ServiceAppointment appointment = [SELECT Id, HOT_WorkOrderLineItem__c FROM ServiceAppointment LIMIT 1];
        appointment.HOT_WorkOrderLineItem__c = null;
        update appointment;

        List<HOT_ServiceAppointmentMessage__c> results = getMessagesAsUser(appointment.Id);
        Assert.areEqual(2, results.size());
        Assert.areEqual('Nyeste melding', results[0].Message__c);
        Assert.areEqual('Eldre melding', results[1].Message__c);
    }

    @IsTest
    static void returnsEmptyWhenBothLinksAreMissing() {
        ServiceAppointment appointment = [
            SELECT Id, HOT_Request__c, HOT_WorkOrderLineItem__c
            FROM ServiceAppointment
            LIMIT 1
        ];
        appointment.HOT_Request__c = null;
        appointment.HOT_WorkOrderLineItem__c = null;
        update appointment;

        Assert.areEqual(0, getMessagesAsUser(appointment.Id).size());
    }

    @IsTest
    static void rejectsInvalidRecordId() {
        try {
            HOT_ServiceAppointmentMessageController.getMessages(null);
            Assert.fail('En manglende oppdrags-ID skal gi feil.');
        } catch (AuraHandledException error) {
            Assert.isNotNull(error);
        }
        Id requestId = [SELECT Id FROM HOT_Request__c LIMIT 1].Id;
        try {
            HOT_ServiceAppointmentMessageController.getMessages(requestId);
            Assert.fail('En bestillings-ID skal ikke godtas som oppdrags-ID.');
        } catch (AuraHandledException error) {
            Assert.isNotNull(error);
        }
    }

    @IsTest
    static void rejectsMissingAppointment() {
        ServiceAppointment appointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        delete appointment;
        try {
            HOT_ServiceAppointmentMessageController.getMessages(appointment.Id);
            Assert.fail('Et slettet oppdrag skal gi feil.');
        } catch (AuraHandledException error) {
            Assert.isNotNull(error);
        }
    }

    private static List<HOT_ServiceAppointmentMessage__c> getMessagesAsUser(Id recordId) {
        List<HOT_ServiceAppointmentMessage__c> messages;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            messages = HOT_ServiceAppointmentMessageController.getMessages(recordId);
        }
        return messages;
    }
}
