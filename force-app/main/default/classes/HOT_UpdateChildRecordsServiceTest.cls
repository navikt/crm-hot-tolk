@IsTest(IsParallel=true)
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
        request.Account__c = personAccount.Id;
        request.InterpretationAddress__PostalCode__s = '0166';
        request.MeetingAddress__PostalCode__s = '0166';
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        request = [
            SELECT
                Id,
                Account__c,
                UserPersonNumber__c,
                UserName__c,
                HOT_PersonContactId__c,
                InterpretationAddress__Street__s,
                InterpretationAddress__PostalCode__s,
                InterpretationAddress__City__s,
                InterpretationAddress__CountryCode__s,
                MeetingAddress__Street__s,
                MeetingAddress__PostalCode__s,
                MeetingAddress__City__s,
                MeetingAddress__CountryCode__s,
                Subject__c,
                Description__c,
                IsScreenInterpreter__c,
                Dispatcher__c,
                InterpretationMethod__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];

        request.InterpretationAddress__Street__s = 'Storgata 1';
        request.InterpretationAddress__PostalCode__s = '0166';
        request.InterpretationAddress__City__s = 'Oslo';
        request.InterpretationAddress__CountryCode__s = 'NO';
        request.MeetingAddress__Street__s = 'Karl Johans gate 1';
        request.MeetingAddress__PostalCode__s = '0166';
        request.MeetingAddress__City__s = 'Oslo';
        request.Subject__c = 'New subject';
        request.Description__c = 'New description';
        request.IsScreenInterpreter__c = true;
        request.InterpretationMethod__c = workType.Id;

        HOT_UpdateChildRecordsService input = new HOT_UpdateChildRecordsService();
        input.request = request;
        input.isAccountChoice = true;
        input.isAddressChoice = true;
        input.isSubjectChoice = true;
        input.isDescriptionChoice = true;
        input.isScreenInterpreterChoice = true;
        input.isDispatcherChoice = true;
        input.isInterpreterMethodChoice = true;

        Test.startTest();
        HOT_UpdateChildRecordsService.updateChildRecords(new List<HOT_UpdateChildRecordsService>{ input });
        Test.stopTest();

        request = [
            SELECT
                Subject__c,
                InterpretationAddress__Street__s,
                InterpretationAddress__PostalCode__s,
                InterpretationAddress__City__s,
                InterpretationAddress__CountryCode__s,
                MeetingAddress__Street__s,
                MeetingAddress__PostalCode__s,
                MeetingAddress__City__s,
                MeetingAddress__CountryCode__s
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];

        WorkOrder wo = [
            SELECT
                Subject,
                HOT_InterpretationAddress__Street__s,
                HOT_InterpretationAddress__PostalCode__s,
                HOT_InterpretationAddress__City__s,
                Street,
                PostalCode,
                City
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];

        WorkOrderLineItem woli = [
            SELECT
                Subject,
                HOT_InterpretationAddress__Street__s,
                HOT_InterpretationAddress__PostalCode__s,
                HOT_InterpretationAddress__City__s,
                Street,
                PostalCode,
                City
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :wo.Id
            LIMIT 1
        ];

        ServiceAppointment sa = [
            SELECT
                Subject,
                HOT_InterpretationAddress__Street__s,
                HOT_InterpretationAddress__PostalCode__s,
                HOT_InterpretationAddress__City__s,
                Street,
                PostalCode,
                City
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];

        System.assertEquals('New subject', request.Subject__c);
        System.assertEquals('Storgata 1', request.InterpretationAddress__Street__s);
        System.assertEquals('0166', request.InterpretationAddress__PostalCode__s);
        System.assertEquals('Oslo', request.InterpretationAddress__City__s);
        System.assertEquals('Karl Johans gate 1', request.MeetingAddress__Street__s);
        System.assertEquals('0166', request.MeetingAddress__PostalCode__s);
        System.assertEquals('Oslo', request.MeetingAddress__City__s);

        System.assertEquals('New subject', wo.Subject);
        System.assertEquals('Storgata 1', wo.HOT_InterpretationAddress__Street__s);
        System.assertEquals('0166', wo.HOT_InterpretationAddress__PostalCode__s);
        System.assertEquals('Oslo', wo.HOT_InterpretationAddress__City__s);
        System.assertEquals('Karl Johans gate 1', wo.Street);
        System.assertEquals('0166', wo.PostalCode);
        System.assertEquals('Oslo', wo.City);

        System.assertEquals('New subject', woli.Subject);
        System.assertEquals('Storgata 1', woli.HOT_InterpretationAddress__Street__s);
        System.assertEquals('0166', woli.HOT_InterpretationAddress__PostalCode__s);
        System.assertEquals('Oslo', woli.HOT_InterpretationAddress__City__s);
        System.assertEquals('Karl Johans gate 1', woli.Street);
        System.assertEquals('0166', woli.PostalCode);
        System.assertEquals('Oslo', woli.City);

        System.assertEquals('New subject', sa.Subject);
        System.assertEquals('Storgata 1', sa.HOT_InterpretationAddress__Street__s);
        System.assertEquals('0166', sa.HOT_InterpretationAddress__PostalCode__s);
        System.assertEquals('Oslo', sa.HOT_InterpretationAddress__City__s);
        System.assertEquals('Karl Johans gate 1', sa.Street);
        System.assertEquals('0166', sa.PostalCode);
        System.assertEquals('Oslo', sa.City);
    }

    @IsTest
    static void updateChildRecordsServiceFlowWorkOrderTest() {
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
        request.Account__c = personAccount.Id;
        request.InterpretationAddress__PostalCode__s = '0166';
        request.MeetingAddress__PostalCode__s = '0166';
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        request = [
            SELECT
                Id,
                Account__c,
                UserPersonNumber__c,
                UserName__c,
                HOT_PersonContactId__c,
                InterpretationAddress__Street__s,
                InterpretationAddress__PostalCode__s,
                InterpretationAddress__City__s,
                InterpretationAddress__CountryCode__s,
                MeetingAddress__Street__s,
                MeetingAddress__PostalCode__s,
                MeetingAddress__City__s,
                MeetingAddress__CountryCode__s,
                Subject__c,
                Description__c,
                IsScreenInterpreter__c,
                Dispatcher__c,
                InterpretationMethod__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];

        WorkOrder wo = [
            SELECT
                Id,
                Subject,
                HOT_InterpretationAddress__Street__s,
                HOT_InterpretationAddress__PostalCode__s,
                HOT_InterpretationAddress__City__s,
                Street,
                PostalCode,
                City
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];

        request.InterpretationAddress__Street__s = 'Storgata 1';
        request.InterpretationAddress__PostalCode__s = '0166';
        request.InterpretationAddress__City__s = 'Oslo';
        request.MeetingAddress__Street__s = 'Karl Johans gate 1';
        request.MeetingAddress__PostalCode__s = '0166';
        request.MeetingAddress__City__s = 'Oslo';
        request.Subject__c = 'New subject';
        request.Description__c = 'New description';
        request.IsScreenInterpreter__c = true;
        request.InterpretationMethod__c = workType.Id;

        HOT_UpdateChildRecordsService input = new HOT_UpdateChildRecordsService();
        input.request = request;
        input.workOrder = wo;
        input.isAccountChoice = true;
        input.isAddressChoice = true;
        input.isSubjectChoice = true;
        input.isDescriptionChoice = true;
        input.isScreenInterpreterChoice = true;
        input.isDispatcherChoice = true;
        input.isInterpreterMethodChoice = true;

        Test.startTest();
        HOT_UpdateChildRecordsService.updateChildRecords(new List<HOT_UpdateChildRecordsService>{ input });
        Test.stopTest();

        wo = [
            SELECT
                Subject,
                HOT_InterpretationAddress__Street__s,
                HOT_InterpretationAddress__PostalCode__s,
                HOT_InterpretationAddress__City__s,
                Street,
                PostalCode,
                City
            FROM WorkOrder
            WHERE Id = :wo.Id
        ];

        WorkOrderLineItem woli = [
            SELECT
                Subject,
                HOT_InterpretationAddress__Street__s,
                HOT_InterpretationAddress__PostalCode__s,
                HOT_InterpretationAddress__City__s,
                Street,
                PostalCode,
                City
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :wo.Id
            LIMIT 1
        ];

        ServiceAppointment sa = [
            SELECT
                Subject,
                HOT_InterpretationAddress__Street__s,
                HOT_InterpretationAddress__PostalCode__s,
                HOT_InterpretationAddress__City__s,
                Street,
                PostalCode,
                City
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];

        System.assertEquals('New subject', wo.Subject);
        System.assertEquals('Storgata 1', wo.HOT_InterpretationAddress__Street__s);
        System.assertEquals('0166', wo.HOT_InterpretationAddress__PostalCode__s);
        System.assertEquals('Oslo', wo.HOT_InterpretationAddress__City__s);
        System.assertEquals('Karl Johans gate 1', wo.Street);
        System.assertEquals('0166', wo.PostalCode);
        System.assertEquals('Oslo', wo.City);

        System.assertEquals('New subject', woli.Subject);
        System.assertEquals('Storgata 1', woli.HOT_InterpretationAddress__Street__s);
        System.assertEquals('0166', woli.HOT_InterpretationAddress__PostalCode__s);
        System.assertEquals('Oslo', woli.HOT_InterpretationAddress__City__s);
        System.assertEquals('Karl Johans gate 1', woli.Street);
        System.assertEquals('0166', woli.PostalCode);
        System.assertEquals('Oslo', woli.City);

        System.assertEquals('New subject', sa.Subject);
        System.assertEquals('Storgata 1', sa.HOT_InterpretationAddress__Street__s);
        System.assertEquals('0166', sa.HOT_InterpretationAddress__PostalCode__s);
        System.assertEquals('Oslo', sa.HOT_InterpretationAddress__City__s);
        System.assertEquals('Karl Johans gate 1', sa.Street);
        System.assertEquals('0166', sa.PostalCode);
        System.assertEquals('Oslo', sa.City);
    }
}
