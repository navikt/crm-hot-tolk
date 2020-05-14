User user = [SELECT Id FROM User WHERE Email = 'fakeemail@nav.no.scratchorg'];
Skill skill = [SELECT Id FROM Skill WHERE DeveloperName = 'Tegnspraktolk'];

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