User user = [SELECT Id FROM User WHERE Email = 'fakeemail@nav.no.scratchorg' LIMIT 1];
Skill skill = [SELECT Id FROM Skill WHERE DeveloperName = 'Tegnspraktolk'];
ServiceTerritory serviceTerritory = [SELECT Id FROM ServiceTerritory WHERE HOT_DeveloperName__c = 'Tromso'];
WorkType workType = [SELECT Id FROM WorkType WHERE Name = 'Tegnspråktolk'];
HOT_Request__c request = [SELECT Id, Status__c FROM HOT_Request__c WHERE Subject__c = 'Forespørsel 1'];
OperatingHours operatingHours = [SELECT Id FROM OperatingHours WHERE Name = 'Always'];

ServiceResource serviceResource = new ServiceResource();
serviceResource.Name = 'Boba Fett';
serviceResource.IsActive = true;
serviceResource.RelatedRecordId = user.Id;
insert serviceResource;

ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
serviceResourceSkill.ServiceResourceId = serviceResource.Id;
serviceResourceSkill.EffectiveStartDate = Date.today().addDays(-1);
serviceResourceSkill.SkillId = skill.Id;
insert serviceResourceSkill;
SkillRequirement skillRequirement = new SkillRequirement();
skillRequirement.RelatedRecordId = workType.Id;
skillRequirement.SkillId = skill.Id;
insert skillRequirement;

ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember();
serviceTerritoryMember.EffectiveStartDate = Date.today().addDays(-1);
serviceTerritoryMember.ServiceResourceId = serviceResource.Id;
serviceTerritoryMember.ServiceTerritoryId = serviceTerritory.Id;
insert serviceTerritoryMember;

request.Status__c = 'Godkjent';
update request;