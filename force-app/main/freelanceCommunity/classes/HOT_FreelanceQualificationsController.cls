public without sharing class HOT_FreelanceQualificationsController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource myServiceResource() {
        Id userId = UserInfo.getUserId();
        ServiceResource myFreelanceResource = [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
        ];
        return myFreelanceResource;
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceResourceSkill> getServiceResourceSkill() {
        Id userId = UserInfo.getUserId();
        ServiceResource freelanceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId];

        List<ServiceResourceSkill> freelanceServiceResourceSkill = [
            SELECT EffectiveStartDate, SkillId, EffectiveEndDate, ServiceResourceId, Id
            FROM ServiceResourceSkill
            WHERE ServiceResourceId = :freelanceResource.Id
            WITH SECURITY_ENFORCED
        ];
        return freelanceServiceResourceSkill;
    }

    public static ServiceResourceSkill setResourceSkill(ServiceResource serviceResource, Skill selectedSkill) {
        ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
        serviceResourceSkill.ServiceResourceId = serviceResource.Id;
        serviceResourceSkill.SkillId = selectedSkill.Id;
        serviceResourceSkill.EffectiveStartDate = Date.today();
        return serviceResourceSkill;
    }

    //TODO bytt ut checkIDs med serviceresourceskilllist, vi tror det er det som gir oss en bug.

    @AuraEnabled
    public static void createServiceResourceSkill(ServiceResource serviceResource, List<Skill> selectedSkills) {
        List<ServiceResourceSkill> newServiceResourceSkills = new List<ServiceResourceSkill>();
        List<ServiceResourceSkill> serviceResourceSkillList = getServiceResourceSkill();

        List<String> checkIDs = new List<String>();

        for (Skill selectedSkill : selectedSkills) {
            if (serviceResourceSkillList.isEmpty()) {
                newServiceResourceSkills.add(setResourceSkill(serviceResource, selectedSkill));
                serviceResourceSkillList.add(setResourceSkill(serviceResource, selectedSkill));
                checkIDs.add(selectedSkill.Id);
                System.debug(serviceResourceSkillList);
            }

            for (serviceResourceSkill x : serviceResourceSkillList) {
                if (!checkIDs.contains(x.SkillId)) {
                    checkIDs.add(x.SkillId);
                }

                if (x.SkillId != selectedSkill.Id && !checkIDs.contains(selectedSkill.Id)) {
                    checkIDs.add(selectedSkill.Id);
                    System.debug('etter add: ' + checkIDs);
                    newServiceResourceSkills.add(setResourceSkill(serviceResource, selectedSkill));
                }
                if (x.SkillId == selectedSkill.Id) {
                    if (x.EffectiveEndDate <= Date.today() && x.EffectiveEndDate != null) {
                        x.EffectiveEnddate = null;
                        newServiceResourceSkills.add(x);
                    }
                } else {
                    x.EffectiveEndDate = Date.today();
                }
            }
        }

        try {
            upsert newServiceResourceSkills;
            System.debug('upsert completed');
        } catch (Exception e) {
            throw e;
        }

        //TODO  vi må refreshe apex. refreshApex(this.getServiceResourceSkill());
    }
}
