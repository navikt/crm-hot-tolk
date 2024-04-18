@IsTest
private class HOT_TestDataTest {
    @IsTest
    static void testMethod1() {
        User user = [SELECT Id, UserRoleId, Name FROM User WHERE Alias = 'UUser' LIMIT 1];
        List<Skill> skills = [SELECT Id FROM Skill WHERE DeveloperName = 'Tegnspraktolk' LIMIT 1];

        HOT_TestData testData = new HOT_TestData();
        Integer n = 3;
        List<Person__c> persons = testData.getPersons(0, 4, '54');
        insert persons;

        List<Account> personAccounts = [SELECT Id, Name, INT_PersonIdent__c FROM Account];

        List<Account> companies = testData.getCompanies(1);
        insert companies;

        List<WorkType> workTypes = testData.getWorkTypes(2);
        insert workTypes;
        List<SkillRequirement> skillRequirements = testData.getSkillRequirements(workTypes, skills);
        insert skillRequirements;

        List<OperatingHours> operatingHours = testData.getOperatingHours();
        insert operatingHours;
        List<ServiceTerritory> serviceTerritories = testData.getServiceTerritories(operatingHours[0], 3);
        insert serviceTerritories;

        List<ServiceResource> serviceResources = testData.getServiceResources(new List<User>{ user });
        insert serviceResources;
        List<ServiceResourceSkill> serviceResourceSkills = testData.getServiceResourceSkills(serviceResources, skills);
        insert serviceResourceSkills;
        List<ServiceTerritoryMember> serviceTerritoryMembers = testData.getServiceTerritoryMembers(
            serviceResources,
            serviceTerritories[0]
        );
        insert serviceTerritoryMembers;

        List<WorkType> requestWorkTypes = new List<WorkType>();
        for (Integer i = 0; i < personAccounts.size(); i++) {
            requestWorkTypes.add(workTypes[math.mod(i, workTypes.size())]);
        }
        List<HOT_Request__c> meRequests = testData.getMeRequests(personAccounts, requestWorkTypes);
        insert meRequests;

        List<Account> orderers = new List<Account>();
        for (Integer i = 0; i < personAccounts.size(); i++) {
            orderers.add(personAccounts[0]);
        }
        personAccounts.remove(0);
        orderers.remove(0);
        requestWorkTypes.remove(0);
        List<HOT_Request__c> userRequests = testData.getUserRequests(personAccounts, orderers, requestWorkTypes);
        insert userRequests;
        List<HOT_Request__c> companyRequests = testData.getCompanyRequests(
            personAccounts,
            orderers,
            companies[0],
            requestWorkTypes
        );
        insert companyRequests;

        System.assertEquals(true, userRequests.size() != null, 'Was not able to create test data');
    }
}
