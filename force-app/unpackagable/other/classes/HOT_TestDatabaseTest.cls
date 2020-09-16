@isTest
private class HOT_TestDatabaseTest{

	@isTest static void testMethod1() {
		User user = [SELECT Id, UserRoleId, Name FROM User WHERE Alias = 'UUser' LIMIT 1];
		List<Skill> skills = [SELECT Id FROM Skill WHERE DeveloperName = 'Tegnspraktolk' LIMIT 1];

		HOT_TestDatabase testDatabase = new HOT_TestDatabase();
		Integer n = 3;
		List<Person__c> persons = testDatabase.getPersons(4);
		insert persons;

		persons = [SELECT Id, Name, CRM_Account__c FROM Person__c];

		List<Account> personAccounts = testDatabase.getPersonAccounts(persons);
		insert personAccounts;
		persons = testDatabase.getUpdatedPersons(persons, personAccounts);
		update persons;
		List<Account> companies = testDatabase.getCompanies(1);
		insert companies;

		List<WorkType> workTypes = testDatabase.getWorkTypes(2);
		insert workTypes;
		List<SkillRequirement> skillRequirements = testDatabase.getSkillRequirements(workTypes, skills);
		insert skillRequirements;

		List<OperatingHours> operatingHours = testDatabase.getOperatingHours();
		insert operatingHours;
		List<ServiceTerritory> serviceTerritories = testDatabase.getServiceTerritories(operatingHours[0], 3);
		insert serviceTerritories;

		List<ServiceResource> serviceResources = testDatabase.getServiceResources(new List<User>{user});
		insert serviceResources;
		List<ServiceResourceSkill> serviceResourceSkills = testDatabase.getServiceResourceSkills(serviceResources, skills);
		insert serviceResourceSkills;
		List<ServiceTerritoryMember> serviceTerritoryMembers = testDatabase.getServiceTerritoryMembers(serviceResources, serviceTerritories[0]);
		insert serviceTerritoryMembers;


		List<WorkType> requestWorkTypes = new List<WorkType>();
		for(Integer i=0; i<personAccounts.size(); i++){
			requestWorkTypes.add(workTypes[math.mod(i, workTypes.size())]);
		}
		List<HOT_Request__c> meRequests = testDatabase.getMeRequests(personAccounts, requestWorkTypes);
		insert meRequests;

		List<Account> orderers = new List<Account>();
		for(Integer i=0; i<personAccounts.size(); i++){
			orderers.add(personAccounts[0]);
		}
		personAccounts.remove(0);
		orderers.remove(0);
		requestWorkTypes.remove(0);
		List<HOT_Request__c> userRequests = testDatabase.getUserRequests(personAccounts, orderers, requestWorkTypes);
		insert userRequests;

		System.assertEquals(true, userRequests.size() != null, 'Was not able to create test data');
	}

}