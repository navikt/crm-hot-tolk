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

    public static ServiceResourceSkill setResourceSkill(ServiceResource serviceResource, Skill selectedSkill) {
        ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill();
        serviceResourceSkill.ServiceResourceId = serviceResource.Id;
        serviceResourceSkill.SkillId = selectedSkill.Id;
        serviceResourceSkill.EffectiveStartDate = Date.today();
        return serviceResourceSkill;
    }

    @AuraEnabled
    public static void createServiceResourceSkill(ServiceResource serviceResource, List<Skill> selectedSkills) {
        List<ServiceResourceSkill> newServiceResourceSkills = new List<ServiceResourceSkill>();
        List<ServiceResourceSkill> serviceResourceSkillList = getServiceResourceSkill();

        List<String> checkIDs = new List<String>();
        Integer i = 0;
        for (Skill selectedSkill : selectedSkills) {
            Integer j = 0;
            System.debug('selected skill' + i);
            i++;
            if (serviceResourceSkillList.isEmpty()) {
                newServiceResourceSkills.add(setResourceSkill(serviceResource, selectedSkill));
                serviceResourceSkillList.add(setResourceSkill(serviceResource, selectedSkill));
                checkIDs.add(selectedSkill.Id);
                System.debug(serviceResourceSkillList);
            }

            for (serviceResourceSkill x : serviceResourceSkillList) {
                System.debug('serviceResourceskill' + j);
                j++;
                if (!checkIDs.contains(x.SkillId)) {
                    checkIDs.add(x.SkillId);
                }

                if (x.SkillId != selectedSkill.Id && !checkIDs.contains(selectedSkill.Id)) {
                    if (!checkIDs.contains(selectedSkill.Id)) {
                        checkIDs.add(selectedSkill.Id);
                    }
                    System.debug('etter add: ' + checkIDs);
                    newServiceResourceSkills.add(setResourceSkill(serviceResource, selectedSkill));
                    // }  if (x.SkillId == selectedSkill.Id && x.EffectiveEndDate != null) {
                    //    x.EffectiveEndDate = Date.today();
                    //  }

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

            //refreshApex(this.getServiceResourceSkill());
        }
    }
}

// System.debug('x: ' + x.SkillId);
// System.debug('selected skill: ' + selectedSkill.Id);
// System.debug('før add: ' + checkIDs);

