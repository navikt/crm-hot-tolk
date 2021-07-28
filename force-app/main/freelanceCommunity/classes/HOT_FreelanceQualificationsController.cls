public without sharing class HOT_FreelanceQualificationsController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource myServiceResource() {
        Id userId = UserInfo.getUserId();
        ServiceResource myFreelanceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :userId];
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
    @AuraEnabled
    public static void createServiceResourceSkill(ServiceResource serviceResource, List<Skill> selectedSkills) {
        List<ServiceResourceSkill> newServiceResourceSkills = new List<ServiceResourceSkill>();
        List<ServiceResourceSkill> serviceResourceSkillList = getServiceResourceSkill();

        List<String> checkIDs = new List<String>();
        for (Skill selectedSkill : selectedSkills) {
            for (serviceResourceSkill x : serviceResourceSkillList) {
                if (!checkIDs.contains(x.SkillId)) {
                    checkIDs.add(x.SkillId);
                }
                //finnes ikke fra før - Opprett nytt serviceReSkill og add til tempSkillList
                if (
                    x.SkillId != selectedSkill.Id &&
                    (!checkIDs.contains(x.SkillId) || !checkIDs.contains(selectedSkill.Id))
                ) {
                    System.debug('x: ' + x.SkillId);
                    System.debug('selected skill: ' + selectedSkill.Id);
                    ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
                    serviceResourceSkill.ServiceResourceId = serviceResource.Id;
                    serviceResourceSkill.SkillId = selectedSkill.Id;
                    serviceResourceSkill.EffectiveStartDate = Date.today();
                    System.debug('før add: ' + checkIDs);
                    if (!checkIDs.contains(x.SkillId)) {
                        checkIDs.add(x.SkillId);
                    }
                    if (!checkIDs.contains(selectedSkill.Id)) {
                        checkIDs.add(selectedSkill.Id);
                    }
                    System.debug('etter add: ' + checkIDs);
                    newServiceResourceSkills.add(serviceResourceSkill);
                } // if (x.EffectiveEndDate != null) {
                //   x.EffectiveEndDate =
                // }

                //newServiceResourceSkills.add(serviceResourceSkill);
            }

            // for (Skill selectedSkill : selectedSkills) {
            //     System.debug(x + 'x');
            //     System.debug(selectedSkill);
            //     if (x.SkillId == selectedSkill.Id) {
            //         System.debug(x + 'removed');
            //         selectedSkills.remove(x);

            //         System.debug(selectedSkills);
            //     }

            //System.debug(newServiceResourceSkills + ' lengde: ' + newServiceResourceSkills.size());
        }

        try {
            upsert newServiceResourceSkills;
            System.debug('upsert completed');
        } catch (Exception e) {
            throw e;
        }

        // refreshapex
    }
}
