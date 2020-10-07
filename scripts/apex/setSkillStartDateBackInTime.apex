String serviceTerritoryDeveloperName = 'Tromso';

Datetime startDate = Datetime.valueOf('2018-01-01 00:00:00');

List<ServiceResourceSkill> serviceResourceSkills = [SELECT Id, EffectiveStartDate FROM ServiceResourceSkill WHERE ServiceResource.HOT_ServiceTerritory__r.HOT_DeveloperName__c = :serviceTerritoryDeveloperName];
for(ServiceResourceSkill srs:serviceResourceSkills){
	srs.EffectiveStartDate = startDate;
}
update serviceResourceSkills;