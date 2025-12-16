public class HOT_TestData {
    //Data
    List<String> idents = new List<String>{
        '01010100000',
        '02020200000',
        '03030300000',
        '04040400000',
        '05050500000',
        '06060600000',
        '07070700000'
    };
    List<List<String>> names = new List<List<String>>{
        new List<String>{ 'JarJar', '', 'Binks' },
        new List<String>{ 'Darth', '', 'Vader' },
        new List<String>{ 'Luke', '', 'Skywalker' },
        new List<String>{ 'Princess', '', 'Leah' },
        new List<String>{ 'Lord', '', 'Sidius' },
        new List<String>{ 'Han', '', 'Solo' },
        new List<String>{ '', '', 'Yoda' }
    };
    List<String> companies = new List<String>{ 'Jedi Order', 'The Empire', 'The Rebels' };
    List<String> org_numbers = new List<String>{ '987654321', '123456789', '808080808' };

    List<String> workTypeNames = new List<String>{
        'TS - Tegnspråk',
        'BTV - Bildetolkvakt',
        'TT - Taktilt tegnspråk',
        'TBS - Tegnspråk i begrenset synsfelt'
    };
    List<String> ServiceTerritoryNames = new List<String>{
        'Tromso',
        'Nordland',
        'Naboo',
        'Dagobah System',
        'Rogaland'
    };

    //Get-methods
    public List<Person__c> getPersons(Integer j, Integer n, String regionNumber) {
        List<Person__c> persons = new List<Person__c>();
        for (Integer i = j; i < n + j && i < this.idents.size(); i++) {
            Person__c person = new Person__c();
            person.Name = this.idents[i];
            person.HOT_DailyLifeInterpreter__c = true;
            person.HOT_DegreeOfHearingAndVisualImpairment__c = 'Hearing impaired or deaf';
            person.INT_RegionNumber__c = regionNumber;
            person.INT_FirstName__c = this.names[i][0];
            person.INT_MiddleName__c = this.names[i][1];
            person.INT_LastName__c = this.names[i][2];
            person.INT_Confidential__c = 'UGRADERT';
            persons.add(person);
        }
        return persons;
    }

    public List<Account> getCompanies(Integer n) {
        Id employerRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Employer' LIMIT 1].Id;
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < n && i < this.companies.size(); i++) {
            Account account = new Account();
            account.RecordTypeId = employerRecordTypeId;
            account.Name = this.companies[i];
            account.INT_OrganizationNumber__c = this.org_numbers[i];
            accounts.add(account);
        }
        return accounts;
    }

    public List<WorkType> getWorkTypes(Integer n) {
        List<WorkType> workTypes = new List<WorkType>();
        for (Integer i = 0; i < n && i < this.workTypeNames.size(); i++) {
            WorkType workType = new WorkType();
            workType.Name = this.workTypeNames[i];
            workType.HOT_DeveloperName__c = this.workTypeNames[i].split(' - ')[0];
            workType.DurationType = 'Hours';
            workType.EstimatedDuration = 1;
            workTypes.add(workType);
        }
        return workTypes;
    }

    public List<SkillRequirement> getSkillRequirements(List<WorkType> workTypes, List<Skill> skills) {
        List<SkillRequirement> skillRequirements = new List<SkillRequirement>();
        for (WorkType workType : workTypes) {
            for (Skill skill : skills) {
                SkillRequirement skillRequirement = new SkillRequirement();
                skillRequirement.RelatedRecordId = workType.Id;
                skillRequirement.SkillId = skill.Id;
                skillRequirements.add(skillRequirement);
            }
        }
        return skillRequirements;
    }

    public List<OperatingHours> getOperatingHours() {
        List<OperatingHours> operatingHours = new List<OperatingHours>{ new OperatingHours(Name = 'Always') };
        return operatingHours;
    }

    public List<ServiceTerritory> getServiceTerritories(OperatingHours operatingHours, Integer n) {
        List<ServiceTerritory> ServiceTerritories = new List<ServiceTerritory>();
        for (Integer i = 0; i < n && i < this.ServiceTerritoryNames.size(); i++) {
            ServiceTerritory serviceTerritory = new ServiceTerritory();
            serviceTerritory.Name = this.ServiceTerritoryNames[i];
            serviceTerritory.HOT_DeveloperName__c = this.ServiceTerritoryNames[i];
            serviceTerritory.OperatingHoursId = operatingHours.Id;
            serviceTerritory.IsActive = true;
            serviceTerritories.add(serviceTerritory);
        }
        return serviceTerritories;
    }

    public List<HOT_Request__c> getMeRequests(List<Account> accounts, List<WorkType> workTypes) {
        List<HOT_Request__c> requests = new List<HOT_Request__c>();
        for (Integer i = 0; i < accounts.size(); i++) {
            HOT_Request__c request = new HOT_Request__c(
                Subject__c = 'Forespørsel ' + String.valueOf(i),
                Account__c = accounts[i].Id,
                InterpretationMethod__c = workTypes[i].Id,
                InterpretationAddress__Street__s = 'Veien ' + String.valueOf(i),
                InterpretationAddress__PostalCode__s = String.valueOf(i) + '00' + String.valueOf(i),
                InterpretationAddress__City__s = 'Oslo',
                MeetingAddress__Street__s = 'Veien ' + String.valueOf(i),
                MeetingAddress__PostalCode__s = String.valueOf(i) + '00' + String.valueOf(i),
                MeetingAddress__City__s = 'Oslo',
                NumberOfInterpreters__c = 2,
                StartTime__c = DateTime.now().addDays(i).addHours(1),
                EndTime__c = DateTime.now().addDays(i).addHours(2),
                Status__c = 'Åpen',
                AssignmentType__c = 'Private',
                Type__c = 'Me',
                Source__c = 'Dispatcher',
                Orderer__c = accounts[i].Id
            );
            requests.add(request);
        }
        return requests;
    }

    public List<HOT_Request__c> getUserRequests(
        List<Account> accounts,
        List<Account> orderers,
        List<WorkType> workTypes
    ) {
        List<HOT_Request__c> requests = new List<HOT_Request__c>();
        for (Integer i = 0; i < accounts.size(); i++) {
            HOT_Request__c request = new HOT_Request__c(
                Subject__c = 'Forespørsel på vegne av ' + accounts[i].Name,
                InterpretationMethod__c = workTypes[i].Id,
                InterpretationAddress__Street__s = 'Gata ' + String.valueOf(i),
                InterpretationAddress__PostalCode__s = String.valueOf(i) + '11' + String.valueOf(i),
                InterpretationAddress__City__s = 'Lillestrøm',
                MeetingAddress__Street__s = 'Gata ' + String.valueOf(i),
                MeetingAddress__PostalCode__s = String.valueOf(i) + '11' + String.valueOf(i),
                MeetingAddress__City__s = 'Lillestrøm',
                NumberOfInterpreters__c = 2,
                StartTime__c = DateTime.now().addDays(i).addHours(1),
                EndTime__c = DateTime.now().addDays(i).addHours(2),
                Status__c = 'Åpen',
                AssignmentType__c = 'Private',
                Type__c = 'User',
                Source__c = 'Community',
                Orderer__c = orderers[i].Id,
                Account__c = accounts[i].Id,
                UserName__c = accounts[i].Name,
                UserPersonNumber__c = accounts[i].INT_PersonIdent__c
            );
            requests.add(request);
        }
        return requests;
    }

    public List<HOT_Request__c> getCompanyRequests(
        List<Account> accounts,
        List<Account> orderers,
        Account company,
        List<WorkType> workTypes
    ) {
        List<HOT_Request__c> requests = new List<HOT_Request__c>();
        for (Integer i = 0; i < accounts.size(); i++) {
            HOT_Request__c request = new HOT_Request__c(
                Subject__c = 'Forespørsel på vegne av ' + accounts[i].Name,
                InterpretationMethod__c = workTypes[i].Id,
                InterpretationAddress__Street__s = 'Gata ' + String.valueOf(i),
                InterpretationAddress__PostalCode__s = String.valueOf(i) + '11' + String.valueOf(i),
                InterpretationAddress__City__s = 'Lillestrøm',
                MeetingAddress__Street__s = 'Gata ' + String.valueOf(i),
                MeetingAddress__PostalCode__s = String.valueOf(i) + '11' + String.valueOf(i),
                MeetingAddress__City__s = 'Lillestrøm',
                NumberOfInterpreters__c = 2,
                StartTime__c = DateTime.now().addDays(i).addHours(1),
                EndTime__c = DateTime.now().addDays(i).addHours(2),
                Status__c = 'Åpen',
                AssignmentType__c = 'Private',
                Type__c = 'Company',
                Source__c = 'Community',
                Orderer__c = orderers[i].Id,
                Company__c = company.Id,
                UserName__c = accounts[i].Name,
                Account__c = accounts[i].Id,
                UserPersonNumber__c = accounts[i].INT_PersonIdent__c
            );
            requests.add(request);
        }
        return requests;
    }

    public List<ServiceResource> getServiceResources(List<User> users) {
        List<ServiceResource> serviceResources = new List<ServiceResource>();
        for (User user : users) {
            ServiceResource serviceResource = new ServiceResource();
            serviceResource.Name = user.Name;
            serviceResource.IsActive = true;
            serviceResource.RelatedRecordId = user.Id;
            serviceResource.HOT_IsFreelanceInterpreter__c = true;
            serviceResources.add(serviceResource);
        }
        return serviceResources;
    }

    public List<ServiceResourceSkill> getServiceResourceSkills(
        List<ServiceResource> serviceResources,
        List<Skill> skills
    ) {
        List<ServiceResourceSkill> serviceResourceSkills = new List<ServiceResourceSkill>();
        for (ServiceResource serviceResource : serviceResources) {
            for (Skill skill : skills) {
                ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
                serviceResourceSkill.ServiceResourceId = serviceResource.Id;
                serviceResourceSkill.EffectiveStartDate = Date.today().addDays(-1);
                serviceResourceSkill.SkillId = skill.Id;
                serviceResourceSkills.add(serviceResourceSkill);
            }
        }
        return serviceResourceSkills;
    }

    public List<ServiceTerritoryMember> getServiceTerritoryMembers(
        List<ServiceResource> serviceResources,
        ServiceTerritory serviceTerritory
    ) {
        List<ServiceTerritoryMember> serviceTerritoryMembers = new List<ServiceTerritoryMember>();
        for (ServiceResource serviceResource : serviceResources) {
            ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember();
            serviceTerritoryMember.EffectiveStartDate = Date.today().addDays(-1);
            serviceTerritoryMember.ServiceResourceId = serviceResource.Id;
            serviceTerritoryMember.ServiceTerritoryId = serviceTerritory.Id;
            serviceTerritoryMembers.add(serviceTerritoryMember);
        }
        return serviceTerritoryMembers;
    }
}
