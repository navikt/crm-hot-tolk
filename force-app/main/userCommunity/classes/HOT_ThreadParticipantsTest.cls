@isTest
private class HOT_ThreadParticipantsTest {
    @TestSetup
    private static void setup() {
        myTriggers.disable(UserPermissionSetAssignmentHandler.class);
        myTriggers.disable(UserProfileHandler.class);
        myTriggers.disable(UserRegionHandler.class);
        myTriggers.disable(UserRoleAssignmentHandler.class);
        myTriggers.disable(HOT_ThreadHandler.class);
        myTriggers.disable(HOT_RequestHandler.class);
        myTriggers.disable(HOT_ServiceResourceHandler.class);
        myTriggers.disable(HOT_AssignedResourceHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentStatusHandler.class);
        myTriggers.disable(HOT_ServiceAppointmentAccessHandler.class);

        // Opprett nødvendige setup-objekter
        UserRole testRole = new UserRole(Name = 'Test Rolle', DeveloperName = 'Test_Rolle');
        //insert testRole;
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1][0]) {
            insert testRole;
            User u = new User(Id = UserInfo.getUserId(), UserRoleId = testRole.Id);
            update u;
        }

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
        PermissionSet psg = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Frilans' LIMIT 1];

        Id personAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();

        // Opprett Person__c
        List<Person__c> persons = new List<Person__c>();
        for (Integer i = 1; i <= 2; i++) {
            persons.add(
                new Person__c(
                    Name = String.valueOf(i),
                    INT_FirstName__c = 'Person',
                    INT_LastName__c = String.valueOf(i),
                    INT_Confidential__c = 'UGRADERT'
                )
            );
        }
        insert persons;

        List<Account> accounts = [
            SELECT Id, FirstName, LastName, PersonContactId
            FROM Account
            WHERE CRM_Person__c IN :new Map<Id, Person__c>(persons).keySet()
        ];
        // Opprett Users
        List<User> usersToInsert = new List<User>();
        List<User> portalUsers = new List<User>();
        for (Account acc : accounts) {
            if (acc.PersonContactId != null) {
                String email = acc.PersonContactId + '@nav.no';
                portalUsers.add(
                    new User(
                        FirstName = acc.FirstName,
                        LastName = acc.LastName,
                        ContactId = acc.PersonContactId,
                        Alias = String.valueOf(acc.PersonContactId).substring(1, 6),
                        Username = email,
                        Email = email,
                        ProfileId = profile.Id,
                        EmailEncodingKey = 'UTF-8',
                        CommunityNickname = acc.LastName,
                        TimeZoneSidKey = 'Europe/Paris',
                        LocaleSidKey = 'no_NO',
                        LanguageLocaleKey = 'no'
                    )
                );
                if (portalUsers.size() == 1) {
                    break;
                }
            }
        }
        usersToInsert.addAll(portalUsers);

        Map<String, Profile> profileByName = new Map<String, Profile>();
        for (Profile profileRecord : [
            SELECT Id, Name, UserType
            FROM Profile
            WHERE Name IN ('HOT Tolk Formidler', 'HOT Tolk Tjenesteleverandør')
        ]) {
            profileByName.put(profileRecord.Name, profileRecord);
        }
        Profile fallbackProfile = [
            SELECT Id, Name, UserType
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ];
        Profile formidlerProfile = profileByName.get('HOT Tolk Formidler') ?? fallbackProfile;
        Profile tjenesteleverandorProfile = profileByName.get('HOT Tolk Tjenesteleverandør') ?? fallbackProfile;
        User formidlerUser = HOT_TestDataFactory.createUser('tpform', formidlerProfile);
        usersToInsert.add(formidlerUser);
        User tjenesteleverandorUser = HOT_TestDataFactory.createUser('tptjen', tjenesteleverandorProfile);
        if (
            tjenesteleverandorProfile.Name == 'HOT Tolk Tjenesteleverandør' &&
            accounts.size() > 1 &&
            accounts[1].PersonContactId != null
        ) {
            tjenesteleverandorUser.ContactId = accounts[1].PersonContactId;
        }
        usersToInsert.add(tjenesteleverandorUser);
        insert usersToInsert;

        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1][0]) {
            insert new PermissionSetAssignment(PermissionSetId = psg.Id, AssigneeId = portalUsers[0].Id);
        }

        // Opprett annen testdata
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Test', workType);
        request.Account__c = accounts[0].Id;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = accounts[0].Id;
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.Subject = 'Test';
        serviceAppointment.HOT_Request__c = request.Id;
        serviceAppointment.HOT_Account__c = accounts[0].Id;
        insert serviceAppointment;

        // Opprett ServiceResource
        User getUserToBeFreelanc = portalUsers[0];
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(getUserToBeFreelanc.Id);
        resource1.HOT_ServiceTerritory__c = serviceTerritory.Id;
        resource1.HOT_IsFreelanceInterpreter__c = true;
        resource1.Name = 'Frilans';
        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        resource2.HOT_ServiceTerritory__c = serviceTerritory.Id;
        resource2.HOT_IsFreelanceInterpreter__c = false;
        resource2.Name = 'Ansatt';
        resource2.CRM_Subdomain__c = 'Tolketjenesten';
        resource2.CRM_Domain__c = 'HOT';
        insert new List<ServiceResource>{ resource1, resource2 };

        ServiceTerritoryMember stm = HOT_TestDataFactory.createServiceTerritoryMember(resource1, serviceTerritory);
        ServiceTerritoryMember stm2 = HOT_TestDataFactory.createServiceTerritoryMember(resource2, serviceTerritory);
        insert new List<ServiceTerritoryMember>{ stm, stm2 };

        serviceAppointment.HOT_ServiceResource__c = resource1.Id;
        update serviceAppointment;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment.Id,
            resource1.Id
        );
        interestedResource.Status__c = 'Assigned';
        insert interestedResource;
    }
    @IsTest
    private static void getParticipantByRelatedRequest() {
        HOT_Request__c request = [SELECT Id, Account__r.PersonContactId FROM HOT_Request__c LIMIT 1];
        User personUser = [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId = :request.Account__r.PersonContactId
            LIMIT 1
        ];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-FORMIDLER');
        thread.CRM_Related_Object__c = request.Id;
        thread.HOT_Thread_read_by__c = personUser.Id + ';';
        insert thread;

        Test.startTest();
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            request.Id,
            new List<String>{ 'HOT_BRUKER-FORMIDLER' }
        );
        Test.stopTest();
        System.assert(
            threadMap.containsKey('HOT_BRUKER-FORMIDLER'),
            'Deltakere for trådtypen "HOT_BRUKER-FORMIDLER" mangler'
        );
        System.assert(threadMap.get('HOT_BRUKER-FORMIDLER').containsKey(thread.Id), 'Tråden mangler');

        List<HOT_ThreadParticipants.Participant> participants = threadMap.get('HOT_BRUKER-FORMIDLER').get(thread.Id);

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Person 1'), 'Mangler deltaker "Person 1"');
        System.assert(participantNames.contains('Formidler'), 'Mangler deltaker "Formidler"');
    }
    @IsTest
    private static void getParticipantByRelatedInterestedResource() {
        HOT_InterestedResource__c interestedResource = [SELECT Id FROM HOT_InterestedResource__c LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = interestedResource.Id;
        insert thread;
        Test.startTest();
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            interestedResource.Id,
            new List<String>{ 'HOT_TOLK-FORMIDLER' }
        );
        Test.stopTest();
        System.assert(
            threadMap.containsKey('HOT_TOLK-FORMIDLER'),
            'Deltakere for trådtypen "HOT_TOLK-FORMIDLER" mangler'
        );
        System.assert(threadMap.get('HOT_TOLK-FORMIDLER').containsKey(thread.Id), 'Tråden mangler');
    }
    @IsTest
    private static void getParticipantByRelatedWageClaim() {
        myTriggers.disable(HOT_ThreadHandler.class);
        ServiceAppointment serviceAppointment = [
            SELECT Id, ServiceTerritoryId, WorkTypeId, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Subject = 'Test'
            LIMIT 1
        ];

        Test.startTest();
        Datetime startT = System.now().addHours(1);
        Datetime endT = startT.addHours(1);

        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE AND Name = 'Frilans'
        ];
        // Oppretter wageclaim manuelt pga fjerning av logikk 1 feb 2026.
        HOT_WageClaim__c wageClaim = new HOT_WageClaim__c();
        wageClaim.IsAutomaticallyCreated__c = true;
        wageClaim.Type__c = 'Available on Wage';
        wageClaim.Status__c = 'Open';
        wageClaim.ServiceResource__c = serviceResource.Id;
        wageClaim.ServiceAppointment__c = serviceAppointment.Id;
        wageClaim.StartTime__c = startT;
        wageClaim.EndTime__c = endT;
        wageClaim.WorkType__c = serviceAppointment.WorkTypeId;
        wageClaim.ServiceTerritory__c = serviceAppointment.ServiceTerritoryId;
        insert wageClaim;

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-RESSURSKONTOR');
        thread.CRM_Related_Object__c = wageClaim.Id;
        insert thread;
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            wageClaim.Id,
            new List<String>{ 'HOT_TOLK-RESSURSKONTOR' }
        );
        Test.stopTest();
        System.assert(
            threadMap.containsKey('HOT_TOLK-RESSURSKONTOR'),
            'Deltakere for trådtypen "HOT_TOLK-RESSURSKONTOR" mangler'
        );
        System.assert(threadMap.get('HOT_TOLK-RESSURSKONTOR').containsKey(thread.Id), 'Tråden mangler');
    }
    @IsTest
    private static void getParticipantByRelatedWorkOrder() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-TOLK');
        thread.CRM_Related_Object__c = workOrder.Id;
        insert thread;
        Test.startTest();
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            workOrder.Id,
            new List<String>{ 'HOT_BRUKER-TOLK' }
        );
        Test.stopTest();
        System.assert(threadMap.containsKey('HOT_BRUKER-TOLK'), 'Deltakere for trådtypen "HOT_BRUKER-TOLK" mangler');
        System.assert(threadMap.get('HOT_BRUKER-TOLK').containsKey(thread.Id), 'Tråden mangler');
    }
    @IsTest
    private static void getParticipantByRelatedServiceAppointment() {
        myTriggers.disable(HOT_ThreadHandler.class);
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Subject = 'Test' LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        insert thread;
        Test.startTest();
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            serviceAppointment.Id,
            new List<String>{ 'HOT_TOLK-FORMIDLER' }
        );
        Test.stopTest();
        System.assert(
            threadMap.containsKey('HOT_TOLK-FORMIDLER'),
            'Deltakere for trådtypen "HOT_TOLK-FORMIDLER" mangler'
        );
        System.assert(threadMap.get('HOT_TOLK-FORMIDLER').containsKey(thread.Id), 'Tråden mangler');
    }
    @IsTest
    private static void getRequestThreadParticipants() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-FORMIDLER');
        thread.CRM_Related_Object__c = request.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Person 1'), 'Mangler deltaker "Person 1"');
        System.assert(participantNames.contains('Formidler'), 'Mangler deltaker "Formidler"');
    }

    @IsTest
    private static void getBestillerRequestThreadParticipants() {
        HOT_Request__c request = [SELECT Id, Account__c, Orderer__c FROM HOT_Request__c LIMIT 1];
        request.Orderer__c = request.Account__c;
        update request;

        User ordererUser = [SELECT Id FROM User WHERE AccountId = :request.Orderer__c LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BESTILLER-FORMIDLER');
        thread.CRM_Related_Object__c = request.Id;
        thread.HOT_Thread_read_by__c = ordererUser.Id + ';';
        insert thread;

        Test.startTest();
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            request.Id,
            new List<String>{ 'HOT_BESTILLER-FORMIDLER' }
        );
        Test.stopTest();

        System.assert(
            threadMap.containsKey('HOT_BESTILLER-FORMIDLER'),
            'Deltakere for trådtypen "HOT_BESTILLER-FORMIDLER" mangler'
        );
        System.assert(threadMap.get('HOT_BESTILLER-FORMIDLER').containsKey(thread.Id), 'Tråden mangler');

        List<HOT_ThreadParticipants.Participant> participants = threadMap.get('HOT_BESTILLER-FORMIDLER').get(thread.Id);
        HOT_ThreadParticipants.Participant bestillerParticipant;
        Boolean hasFormidler = false;
        for (HOT_ThreadParticipants.Participant participant : participants) {
            if (participant.role == 'Bestiller') {
                bestillerParticipant = participant;
            }
            if (participant.name == 'Formidler') {
                hasFormidler = true;
            }
        }

        System.assert(bestillerParticipant != null, 'Mangler deltaker med rolle "Bestiller"');
        System.assert(bestillerParticipant.hasRead, 'Bestiller skal være markert som lest');
        System.assert(hasFormidler, 'Mangler deltaker "Formidler"');
    }

    @IsTest
    private static void getUserSenderRoleInThreadReturnsFormidlerForFormidlerSender() {
        myTriggers.disable(HOT_ThreadHandler.class);
        User formidlerUser = [SELECT Id, Profile.Name FROM User WHERE LastName = 'tpform' LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Subject = 'Test' LIMIT 1];

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        insert thread;

        List<Thread__c> threadList = [SELECT Id, CRM_Thread_Type__c FROM Thread__c WHERE Id = :thread.Id];
        Map<Id, Id> threadToLastSender = new Map<Id, Id>{ thread.Id => formidlerUser.Id };

        Test.startTest();
        Map<Id, String> senderRoles = HOT_ThreadParticipants.getUserSenderRoleInThread(threadList, threadToLastSender);
        Test.stopTest();

        System.assert(senderRoles.containsKey(thread.Id), 'Mangler rolle for tråd');
        if (formidlerUser.Profile.Name == 'HOT Tolk Formidler') {
            System.assertEquals(
                'formidler',
                senderRoles.get(thread.Id),
                'Forventet rolle "formidler" når avsender har Formidler-profil'
            );
        } else {
            System.assertEquals(
                null,
                senderRoles.get(thread.Id),
                'Forventet null rolle når testbruker ikke har Formidler-profil'
            );
        }
    }

    @IsTest
    private static void getWorkOrderThreadParticipants() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-TOLK');
        thread.CRM_Related_Object__c = workOrder.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Person 1'), 'Mangler deltaker "Person 1"');
        System.assert(participantNames.contains('Frilans'), 'Mangler deltaker "Frilans"');
    }

    @IsTest
    private static void getWorkOrderThread2Participants() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-TOLK');
        thread.CRM_Related_Object__c = workOrder.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(!participantNames.contains('Person 1'), '"Person 1" skulle ikke vært deltaker');
        System.assert(participantNames.contains('Frilans'), 'Mangler deltaker "Frilans"');
    }

    @IsTest
    private static void getInterestedResourceThreadParticipants() {
        myTriggers.disable(HOT_ThreadHandler.class);
        HOT_InterestedResource__c interestedResource = [SELECT Id FROM HOT_InterestedResource__c LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = interestedResource.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Formidler'), 'Mangler deltaker "Formidler"');
        System.assert(participantNames.contains('Frilans'), 'Mangler deltaker "Frilans"');
    }

    @IsTest
    private static void getServiceAppointmentThreadParticipants() {
        myTriggers.disable(HOT_ThreadHandler.class);
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE Subject = 'Test'
            LIMIT 1
        ];
        if (serviceAppointment.HOT_ServiceResource__c == null) {
            ServiceResource serviceResource = [
                SELECT Id
                FROM ServiceResource
                WHERE HOT_IsFreelanceInterpreter__c = TRUE AND Name = 'Frilans'
                LIMIT 1
            ];
            serviceAppointment.HOT_ServiceResource__c = serviceResource.Id;
            update serviceAppointment;
        }
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Formidler'), 'Mangler deltaker "Formidler"');
        System.assert(participantNames.contains('Frilans'), 'Mangler deltaker "Frilans"');
    }
    @IsTest
    private static void getTjenesteleverandorFormidlerThreadParticipants() {
        myTriggers.disable(HOT_ThreadHandler.class);
        User formidler = [SELECT Id FROM User WHERE LastName = 'tpform' LIMIT 1];
        User tjenesteleverandor = [SELECT Id FROM User WHERE LastName = 'tptjen' LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Subject = 'Test' LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TJENESTELEVERANDOR-FORMIDLER');
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        thread.HOT_Thread_read_by__c = formidler.Id + ';' + tjenesteleverandor.Id + ';';

        insert thread;
        Thread__c insertedThread = [
            SELECT Id, CRM_Thread_Type__c
            FROM Thread__c
            WHERE Id = :thread.Id
        ];
        if (insertedThread.CRM_Thread_Type__c != 'HOT_TJENESTELEVERANDOR-FORMIDLER') {
            insertedThread.CRM_Thread_Type__c = 'HOT_TJENESTELEVERANDOR-FORMIDLER';
            update insertedThread;
        }

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> directParticipants = HOT_ThreadParticipants.getParticipants(
            insertedThread.Id
        );
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> participantsByServiceAppointment = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            serviceAppointment.Id,
            new List<String>{ 'HOT_TJENESTELEVERANDOR-FORMIDLER' }
        );
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> participantsByThread = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            insertedThread.Id,
            new List<String>{ 'HOT_TJENESTELEVERANDOR-FORMIDLER' }
        );
        Test.stopTest();

        assertTjenesteleverandorParticipants(directParticipants);
        assertTjenesteleverandorParticipants(
            participantsByServiceAppointment.get('HOT_TJENESTELEVERANDOR-FORMIDLER').get(insertedThread.Id)
        );
        assertTjenesteleverandorParticipants(
            participantsByThread.get('HOT_TJENESTELEVERANDOR-FORMIDLER').get(insertedThread.Id)
        );
    }
    @IsTest
    private static void getWageClaimThreadParticipants() {
        myTriggers.disable(HOT_ThreadHandler.class);
        ServiceAppointment serviceAppointment = [
            SELECT Id, ServiceTerritoryId, WorkTypeId, SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Subject = 'Test'
            LIMIT 1
        ];

        Test.startTest();
        Datetime startT = System.now().addHours(1);
        Datetime endT = startT.addHours(1);

        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsFreelanceInterpreter__c = TRUE AND Name = 'Frilans'
        ];
        // Oppretter wageclaim manuelt pga fjerning av logikk 1 feb 2026.
        HOT_WageClaim__c wageClaim = new HOT_WageClaim__c();
        wageClaim.IsAutomaticallyCreated__c = true;
        wageClaim.Type__c = 'Available on Wage';
        wageClaim.Status__c = 'Open';
        wageClaim.ServiceResource__c = serviceResource.Id;
        wageClaim.ServiceAppointment__c = serviceAppointment.Id;
        wageClaim.StartTime__c = startT;
        wageClaim.EndTime__c = endT;
        wageClaim.WorkType__c = serviceAppointment.WorkTypeId;
        wageClaim.ServiceTerritory__c = serviceAppointment.ServiceTerritoryId;
        insert wageClaim;

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-RESSURSKONTOR');
        thread.CRM_Related_Object__c = wageClaim.Id;
        insert thread;
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);

        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(
            participantNames.contains('Ressurskontor'),
            'Mangler deltaker med navn "Ressurskontor". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );

        System.assert(
            participantNames.contains('Frilans'),
            'Mangler deltaker med navn "Frilans". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );
    }
    @IsTest
    private static void getParticipantsThreadWithoutRelatedObject() {
        myTriggers.disable(HOT_ThreadHandler.class);
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.HOT_ParticipantIds__c = UserInfo.getUserId() + ',';
        thread.CRM_Related_Object__c = null;
        insert thread;
        Test.startTest();
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            thread.id,
            new List<String>{ 'HOT_TOLK-FORMIDLER' }
        );
        Test.stopTest();
        System.Assert.isTrue(
            threadMap.containsKey('HOT_TOLK-FORMIDLER'),
            'Deltakere for trådtypen "HOT_TOLK-FORMIDLER" mangler'
        );
        System.Assert.isTrue(threadMap.get('HOT_TOLK-FORMIDLER').containsKey(thread.Id), 'Tråden mangler');
        System.Assert.areEqual(
            2,
            threadMap.get('HOT_TOLK-FORMIDLER').get(thread.Id).size(),
            'Feil antall deltakere for tråden'
        );
        System.Assert.areEqual(
            UserInfo.getUserId(),
            threadMap.get('HOT_TOLK-FORMIDLER').get(thread.Id)[0].userId,
            'Feil deltaker hentet'
        );
        System.Assert.areEqual(
            'Ansatt',
            threadMap.get('HOT_TOLK-FORMIDLER').get(thread.Id)[0].name,
            'Feil deltaker hentet'
        );
        System.Assert.areEqual(
            null,
            threadMap.get('HOT_TOLK-FORMIDLER').get(thread.Id)[1].userId,
            'Feil deltaker hentet'
        );
        System.Assert.areEqual(
            'Formidler',
            threadMap.get('HOT_TOLK-FORMIDLER').get(thread.Id)[1].name,
            'Feil deltaker hentet'
        );
    }

    private static void assertTjenesteleverandorParticipants(List<HOT_ThreadParticipants.Participant> participants) {
        Set<String> participantNames = new Set<String>();
        for (HOT_ThreadParticipants.Participant participant : participants) {
            participantNames.add(participant.name);
        }

        System.Assert.areEqual(2, participants.size(), 'Tråden skal bare ha to deltakere');
        System.Assert.isTrue(participantNames.contains('Tjenesteleverandør'), 'Mangler Tjenesteleverandør');
        System.Assert.isTrue(participantNames.contains('Formidler'), 'Mangler Formidler');
        Set<String> existingProfileNames = new Set<String>();
        for (Profile profileRecord : [
            SELECT Name
            FROM Profile
            WHERE Name IN ('HOT Tolk Formidler', 'HOT Tolk Tjenesteleverandør')
        ]) {
            existingProfileNames.add(profileRecord.Name);
        }
        Boolean canAssertReadStatus =
            existingProfileNames.contains('HOT Tolk Formidler') &&
            existingProfileNames.contains('HOT Tolk Tjenesteleverandør');
        if (canAssertReadStatus) {
            for (HOT_ThreadParticipants.Participant participant : participants) {
                System.Assert.isTrue(participant.hasRead, participant.name + ' skal være markert som lest');
            }
        }
    }
}
