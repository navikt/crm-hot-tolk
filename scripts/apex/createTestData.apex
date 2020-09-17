User user = [SELECT Id, UserRoleId, Name FROM User WHERE Alias = 'UUser' LIMIT 1];
List<Skill> skills = [SELECT Id FROM Skill WHERE DeveloperName = 'Tegnspraktolk' LIMIT 1];

HOT_TestDatabase testDatabase = new HOT_TestDatabase();
Integer n = 3;
List<Person__c> persons = testDatabase.getPersons(2, '54');
List<Person__c> persons = testDatabase.getPersons(2, '18');
insert persons;
System.debug(persons);

List<Account> personAccounts = [SELECT Id, Name, INT_PersonIdent__c FROM Account];

List<Account> companies = testDatabase.getCompanies(1);
insert companies;

List<WorkType> workTypes = testDatabase.getWorkTypes(2);
insert workTypes;
System.debug(workTypes);
List<SkillRequirement> skillRequirements = testDatabase.getSkillRequirements(workTypes, skills);
insert skillRequirements;
System.debug(skillRequirements);

List<OperatingHours> operatingHours = testDatabase.getOperatingHours();
insert operatingHours;
System.debug(operatingHours);
List<ServiceTerritory> serviceTerritories = testDatabase.getServiceTerritories(operatingHours[0], 3);
insert serviceTerritories;
System.debug(serviceTerritories);

List<ServiceResource> serviceResources = testDatabase.getServiceResources(new List<User>{user});
insert serviceResources;
System.debug(serviceResources);
List<ServiceResourceSkill> serviceResourceSkills = testDatabase.getServiceResourceSkills(serviceResources, skills);
insert serviceResourceSkills;
System.debug(serviceResourceSkills);
List<ServiceTerritoryMember> serviceTerritoryMembers = testDatabase.getServiceTerritoryMembers(serviceResources, serviceTerritories[0]);
insert serviceTerritoryMembers;
System.debug(serviceTerritoryMembers);


List<WorkType> requestWorkTypes = new List<WorkType>();
for(Integer i=0; i<personAccounts.size(); i++){
	requestWorkTypes.add(workTypes[math.mod(i, workTypes.size())]);
}
List<HOT_Request__c> meRequests = testDatabase.getMeRequests(personAccounts, requestWorkTypes);
insert meRequests;
System.debug(meRequests);

List<Account> orderers = new List<Account>();
for(Integer i=0; i<personAccounts.size(); i++){
	orderers.add(personAccounts[0]);
}
personAccounts.remove(0);
orderers.remove(0);
requestWorkTypes.remove(0);
List<HOT_Request__c> userRequests = testDatabase.getUserRequests(personAccounts, orderers, requestWorkTypes);
insert userRequests;
System.debug(userRequests);

meRequests[0].Status__c = 'Godkjent';
update meRequests[0];