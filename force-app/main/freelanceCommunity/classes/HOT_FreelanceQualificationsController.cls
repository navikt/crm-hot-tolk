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
    public static List<String> checkIdList() {
        List<String> checkIDs = new List<String>();
        for (ServiceResourceSkill x : getServiceResourceSkill()) {
            checkIDs.add(x.SkillId);
        }
        return checkIDs;
    }

    @AuraEnabled
    public static void createServiceResourceSkill(ServiceResource serviceResource, List<Skill> selectedSkills) {
        List<ServiceResourceSkill> newServiceResourceSkills = new List<ServiceResourceSkill>();

        List<String> checkIDs = checkIdList();
        System.debug('checkID: ' + checkIDs);
        System.debug('selectedSkills: ' + selectedSkills);
        if (selectedSkills.isEmpty()) {
            for (serviceResourceSkill x1 : getServiceResourceSkill()) {
                x1.EffectiveEndDate = Date.today();
            }
            System.debug('selectedskills should be empty' + selectedSkills);
        }

        for (Skill selectedSkill : selectedSkills) {
            System.debug(checkIDs);
            if (checkIDs.isEmpty()) {
                newServiceResourceSkills.add(setResourceSkill(serviceResource, selectedSkill));
                checkIDs.add(selectedSkill.Id);

                System.debug('no previous skills: ' + checkIDs);
            }

            for (serviceResourceSkill x : getServiceResourceSkill()) {
                if (!checkIDs.contains(x.SkillId)) {
                    checkIDs.add(x.SkillId);
                }
                System.debug('inside for for...');
                System.debug('selected skill: ' + selectedSkill);
                System.debug('x: ' + x);
                System.debug('checkID:' + checkIDs);
                if (x.SkillId != selectedSkill.Id && !checkIDs.contains(selectedSkill.Id)) {
                    checkIDs.add(selectedSkill.Id);

                    System.debug('etter add: ' + checkIDs);
                    newServiceResourceSkills.add(setResourceSkill(serviceResource, selectedSkill));
                }
                if (x.SkillId == selectedSkill.Id && x.EffectiveEndDate <= Date.today() && x.EffectiveEndDate != null) {
                    System.debug('x = selectedSkill');
                    //if () {
                    System.debug('End Date != null');
                    x.EffectiveEnddate = null;
                    newServiceResourceSkills.add(x);
                    //}
                } else {
                    System.debug('End Date == null');
                    System.debug(x.EffectiveEndDate);
                    x.EffectiveEndDate = Date.today();
                    System.debug(x.EffectiveEndDate);
                    newServiceResourceSkills.add(x);
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
