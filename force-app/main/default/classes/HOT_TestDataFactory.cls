@IsTest
public class HOT_TestDataFactory {
    public static HOT_Request__c createRequest(String subject, WorkType workType) {
        return createRequest(subject, workType, 1, null, null);
    }

    public static HOT_Request__c createRequest(
        String subject,
        WorkType workType,
        Integer numberOfInter,
        WorkType workTypeSecondary,
        Integer numberOfInterSecondary
    ) {
        HOT_Request__c request = new HOT_Request__c();
        request.Subject__c = subject;
        request.Status__c = 'Åpen';
        request.InterpretationMethod__c = workType.Id;
        request.NumberOfInterpreters__c = numberOfInter;
        if (workTypeSecondary != null) {
            request.InterpretationMethodSecondary__c = workTypeSecondary.Id;
            request.NumberOfInterpretersSecondary__c = numberOfInterSecondary;
        }
        request.StartTime__c = Datetime.now().addHours(1);
        request.EndTime__c = request.StartTime__c.addHours(2);
        request.AssignmentType__c = 'Work';
        request.Source__c = null;

        return request;
    }

    public static WorkOrder createWorkOrder(HOT_Request__c request, WorkType workType) {
        WorkOrder workOrder = new WorkOrder();
        workOrder.HOT_Request__c = request.Id;
        workOrder.Status = 'New';
        workOrder.HOT_NumberOfInterpreters__c = 1;
        workOrder.StartDate = Datetime.now().addHours(1);
        workOrder.EndDate = workOrder.StartDate.addHours(2);
        workOrder.WorkTypeId = workType.Id;

        return workOrder;
    }

    public static WorkOrderLineItem createWorkOrderLineItem(WorkOrder workOrder, WorkType workType) {
        WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem();
        workOrderLineItem.WorkOrderId = workOrder.Id;
        workOrderLineItem.Status = 'New';
        workOrderLineItem.HOT_NumberOfInterpreters__c = 1;
        workOrderLineItem.StartDate = Datetime.now().addHours(1);
        workOrderLineItem.EndDate = workOrderLineItem.StartDate.addHours(2);
        workOrderLineItem.WorkTypeId = workType.Id;

        return workOrderLineItem;
    }

    public static ServiceAppointment createServiceAppointment(WorkOrderLineItem workOrderLineItem) {
        ServiceAppointment serviceAppointment = new ServiceAppointment();
        serviceAppointment.ParentRecordId = workOrderLineItem.Id;
        serviceAppointment.HOT_WorkOrderLineItem__c = workOrderLineItem.Id;
        serviceAppointment.Status = 'None';
        serviceAppointment.EarliestStartTime = Datetime.now().addHours(1);
        serviceAppointment.DueDate = serviceAppointment.EarliestStartTime.addHours(2);

        return serviceAppointment;
    }

    public static WorkType createWorkType() {
        return createWorkType('workTypeName');
    }

    public static WorkType createWorkType(String workTypeName) {
        WorkType workType = new WorkType();
        workType.Name = workTypeName;
        workType.EstimatedDuration = 1;

        return workType;
    }

    public static ServiceResource createServiceResource(Id userId) {
        ServiceResource serviceResource = new ServiceResource();
        serviceResource.Name = 'Service Resource Name';
        serviceResource.RelatedRecordId = userId;
        serviceResource.IsActive = true;
        serviceResource.ResourceType = 'T';
        serviceResource.HOT_MobilePhoneOverride__c = '12345678';
        serviceResource.HOT_NotificationChannel__c = 'Push-varsel i appen';
        return serviceResource;
    }

    public static OperatingHours createOperatingHours() {
        OperatingHours operatingHours = new OperatingHours();
        operatingHours.Name = 'Operating Hours Name';
        return operatingHours;
    }

    public static ServiceTerritory createServiceTerritory(OperatingHours operatingHour) {
        ServiceTerritory serviceTerritory = new ServiceTerritory();
        serviceTerritory.OperatingHoursId = operatingHour.Id;
        serviceTerritory.IsActive = true;
        serviceTerritory.Name = 'Service Territory Name';
        serviceTerritory.HOT_DeveloperName__c = 'Service_Territory_Name';
        return serviceTerritory;
    }
    public static ServiceTerritoryMember createServiceTerritoryMember(
        ServiceResource serviceResource,
        ServiceTerritory serviceTerritory
    ) {
        ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember();
        serviceTerritoryMember.ServiceResourceId = serviceResource.Id;
        serviceTerritoryMember.ServiceTerritoryId = serviceTerritory.Id;
        serviceTerritoryMember.EffectiveStartDate = Datetime.now().addHours(-1);
        return serviceTerritoryMember;
    }

    public static Skill createSkill(WorkType workType) {
        Skill skill = new Skill();
        skill.MasterLabel = workType.Name;
        return skill;
    }

    public static ServiceResourceSkill createServiceResourceSkill(ServiceResource serviceResource, Skill skill) {
        ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
        serviceResourceSkill.ServiceResourceId = serviceResource.Id;
        serviceResourceSkill.SkillId = skill.Id;
        serviceResourceSkill.EffectiveStartDate = Date.today();
        return serviceResourceSkill;
    }

    public static ServiceResourceSkill createServiceResourceSkill(ServiceResource serviceResource, WorkType workType) {
        ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
        serviceResourceSkill.ServiceResourceId = serviceResource.Id;
        serviceResourceSkill.SkillId = workType.Id;
        serviceResourceSkill.EffectiveStartDate = Date.today();
        return serviceResourceSkill;
    }

    public static Account createAccount(boolean isPersonAccount) {
        if (isPersonAccount) {
            String personAccountRecordTypeId = Schema.getGlobalDescribe()
                .get('Account')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('PersonAccount')
                .getRecordTypeId();
            Account account = new Account(
                RecordTypeId = personAccountRecordTypeId,
                FirstName = 'Test',
                LastName = 'User',
                PersonEmail = 'HOT_testaccount@nav.hot.no'
            );
            return account;
        } else {
            String businessAccountRecordTypeId = Schema.getGlobalDescribe()
                .get('Account')
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('Employer')
                .getRecordTypeId();
            return new Account(RecordTypeId = businessAccountRecordTypeId, Name = 'Test AS');
        }
    }

    public static Person__c createPerson() {
        return createPerson('12015678901');
    }
    public static Person__c createPerson(String ident) {
        Person__c person = new Person__c();
        person.INT_Confidential__c = 'UGRADERT';
        person.Name = ident;
        person.INT_LastName__c = 'Last';
        person.INT_FirstName__c = 'First';

        return person;
    }

    public static User createUser(Profile profile, Account account) {
        User user = createUser('User', profile);
        user.ContactId = account.PersonContactId;
        return user;
    }

    public static User createUser(String lastName, Profile profile) {
        User user = new User(
            Username = 'HOT.' + lastName + '@nav.hot.no',
            LastName = lastName,
            Email = 'HOT_testuser@nav.hot.no',
            Alias = lastName,
            CommunityNickname = lastName,
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'no_NO',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'no',
            ProfileId = profile.id
        );

        return user;
    }

    public static User changeUserProfile(User user, Profile profile) {
        user.ProfileId = profile.id;
        return user;
    }

    public static User createUserWithAllNames(String firstname, String middleName, String lastName, Profile profile) {
        User user = new User(
            Username = 'HOT.' + firstName + middleName + lastName + '@nav.hot.no',
            FirstName = firstName,
            MiddleName = middleName,
            LastName = lastName,
            Email = 'HOT_testuser@nav.hot.no',
            Alias = lastName,
            CommunityNickname = lastName,
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'no_NO',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'no',
            ProfileId = profile.id
        );

        return user;
    }

    public static AssignedResource createAssignedResource(Id serviceAppointmentId, Id serviceResourceId) {
        AssignedResource assignedResource = new AssignedResource(
            ServiceAppointmentId = serviceAppointmentId,
            ServiceResourceId = serviceResourceId
        );

        return assignedResource;
    }

    public static HOT_InterestedResource__c createInterestedResource(Id serviceAppointmentId, Id serviceResourceId) {
        HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c(
            ServiceAppointment__c = serviceAppointmentId,
            ServiceResource__c = serviceResourceId
        );

        return interestedResource;
    }

    public static Event createEvent(RecordType eventRecordType, Integer offset) {
        Event event = new Event();
        event.RecordTypeId = eventRecordType.Id;
        event.Subject = 'Subject';
        event.ShowAs = 'Busy';
        event.StartDateTime = Datetime.now().addHours(offset);
        event.EndDateTime = Datetime.now().addHours(1 + offset);

        return event;
    }

    public static HOT_Resource__c createResource(ServiceResource serviceResource) {
        HOT_Resource__c resource = new HOT_Resource__c();
        resource.Service_Resource__c = serviceResource.Id;
        resource.Name = serviceResource.Name;
        return resource;
    }
    public static HOT_ResourceMember__c createResourceMember(
        ServiceResource serviceResource,
        HOT_Resource__c resource
    ) {
        HOT_ResourceMember__c resourceMember = new HOT_ResourceMember__c();
        resourceMember.Service_Resource__c = serviceResource.Id;
        resourceMember.Resource__c = resource.Id;
        return resourceMember;
    }

    public static HOT_WageClaim__c createWageClaim(ServiceResource serviceResource) {
        HOT_WageClaim__c wageClaim = new HOT_WageClaim__c();
        wageClaim.ServiceResource__c = serviceResource.Id;
        wageClaim.StartTime__c = Datetime.now().addHours(1);
        wageClaim.EndTime__c = Datetime.now().addHours(2);
        return wageClaim;
    }

    public static ContentVersion createContentVersion() {
        return createContentVersion('a picture', 'Pic.jpg', 'Test Content');
    }
    public static ContentVersion createContentVersion(String title, String filename, String versionDataString) {
        ContentVersion contentVersion = new ContentVersion(
            Title = title,
            PathOnClient = filename,
            VersionData = Blob.valueOf(versionDataString),
            IsMajorVersion = true
        );
        return contentVersion;
    }
    public static ContentDocumentLink createContentDocumentLink(Id linkedEntityId, Id contentDocumentId) {
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.LinkedEntityId = linkedEntityId;
        contentDocumentLink.ContentDocumentId = contentDocumentId;
        contentDocumentLink.shareType = 'V';
        contentDocumentLink.visibility = 'AllUsers';
        return contentDocumentLink;
    }
    public static Shift createShift(Id serviceResourceId) {
        Shift shift = new Shift();
        shift.ServiceResourceId = serviceResourceId;
        shift.StartTime = Datetime.now().addDays(1);
        shift.EndTime = Datetime.now().addDays(1).addHours(1);
        return shift;
    }
    public static SMS__c createSms() {
        SMS__c sms = new SMS__c();
        sms.Domain__c = 'HOT';
        return sms;
    }
    public static Thread__c createThread() {
        return createThread('HOT_BRUKER-FORMIDLER');
    }
    public static Thread__c createThread(String threadType) {
        Thread__c thread = new Thread__c();
        thread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        thread.CRM_Thread_Type__c = threadType;
        return thread;
    }
    public static final Id PERSON_ACCOUNT_RECORDTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('PersonAccount')
        .getRecordTypeId();
    private static List<User> users;
    private static List<Account> personAccounts;

    public static List<User> getEmployerCommunityUser(Set<Id> personAccountsIds, String profileName, Boolean doInsert) {
        List<Account> personAccounts = [
            SELECT Id, FirstName, LastName, PersonContactId
            FROM Account
            WHERE Id IN :personAccountsIds
        ];
        Profile communityProfile = [
            SELECT Name
            FROM Profile
            //WHERE Name = :profileName OR Name = 'Trial Customer Portal User'
            WHERE Name = 'Customer Community Plus User'
            LIMIT 1
        ];

        List<User> users = new List<User>();
        for (Account pa : personAccounts) {
            String email = pa.PersonContactId + '@nav.apextest';
            User u = new User();
            u.FirstName = pa.FirstName;
            u.LastName = pa.LastName;
            u.ContactId = pa.PersonContactId;
            u.Alias = String.valueOf(pa.PersonContactId).substring(1, 6);
            u.Username = email;
            u.Email = email;
            u.ProfileId = communityProfile.Id;
            u.EmailEncodingKey = 'UTF-8';
            u.CommunityNickname = pa.LastName;
            u.TimeZoneSidKey = 'Europe/Paris';
            u.LocaleSidKey = 'no_NO';
            u.LanguageLocaleKey = 'no';
            users.add(u);
        }
        if (doInsert)
            insert users;
        return users;
    }

    public static List<Account> getPersonAccounts(Integer numberOfAccounts) {
        if (personAccounts != null)
            return personAccounts;
        personAccounts = new List<Account>();
        List<Person__c> persons = getPersons(numberOfAccounts);

        //return person accounts if created by trigger
        personAccounts = [
            SELECT FirstName, LastName, INT_PersonIdent__c, CRM_Person__c
            FROM Account
            WHERE RecordTypeId = :PERSON_ACCOUNT_RECORDTYPEID
        ];
        if (personAccounts.size() > 0) {
            return personAccounts;
        }
        for (Integer i = 1; i <= numberOfAccounts; i++) {
            personAccounts.add(
                new Account(
                    FirstName = 'Person',
                    LastName = String.valueOf(i),
                    INT_PersonIdent__c = String.valueOf(i),
                    CRM_Person__c = persons[i - 1].Id,
                    RecordTypeId = PERSON_ACCOUNT_RECORDTYPEID
                )
            );
        }
        insert personAccounts;
        personAccounts = [
            SELECT FirstName, LastName, INT_PersonIdent__c, CRM_Person__c
            FROM Account
            WHERE RecordTypeId = :PERSON_ACCOUNT_RECORDTYPEID
        ];
        return personAccounts;
    }

    private static List<Person__c> getPersons(Integer numberOfPersons) {
        List<Person__c> persons = new List<Person__c>();
        for (Integer i = 1; i <= numberOfPersons; i++) {
            persons.add(
                new Person__c(
                    Name = String.valueOf(i),
                    INT_LastName__c = String.valueOf(i),
                    INT_Confidential__c = 'UGRADERT'
                )
            );
        }
        insert persons;
        return persons;
    }

    public static List<User> getUsers(Integer numberOfUsers, String profileName, Boolean assignRole, Boolean doInsert) {
        if (users != null)
            return users;
        users = new List<User>();
        Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = :profileName LIMIT 1];

        for (Integer i = 1; i <= numberOfUsers; i++) {
            String firstName = 'User';
            String lastName = String.valueOf(i);
            String email = firstName + lastName + '@nav.apextest';
            User user = new User(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Username = email,
                Alias = lastName,
                LanguageLocaleKey = 'no',
                LocaleSidKey = 'no_NO',
                TimeZoneSidKey = 'Europe/Paris',
                EmailEncodingKey = 'UTF-8',
                ProfileId = profile.Id
            );
            if (assignRole) {
                UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Default'];
                user.UserRoleId = role.Id;
            }
            users.add(user);
        }
        if (doInsert)
            insert users;
        return users;
    }
}
