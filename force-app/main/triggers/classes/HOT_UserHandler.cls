public without sharing class HOT_UserHandler extends MyTriggers {
    //Om en bruker som er Ansatt Tolk opprettes, skal en Tjenesteressurs opprettes, og kobles til denne brukeren.
    public override void onAfterInsert() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Ansatt'];

        if (profiles.size() > 0) {
            List<Id> userIds = new List<Id>();
            for (User user : (List<User>) records) {
                if (user.ProfileId == profiles[0].Id) {
                    userIds.add(user.Id);
                }
            }
            if (userIds.size() > 0) {
                HOT_ServiceResourceHandler.createServiceResourceFuture(userIds);
            }
        }
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        Map<Id, User> oldUserMap = (Map<Id, User>)Trigger.oldMap;
        Map<Id, User> newUserMap = (Map<Id, User>)Trigger.newMap;
    
        List<Profile> formidlerProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Tolk Formidler'];
        List<Profile> ansattProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
    
        Set<Id> usersWithChangedProfile = new Set<Id>();
        
        if(!formidlerProfile.isEmpty() && !ansattProfile.isEmpty()){
            for (Id userId : oldUserMap.keySet()) {
                User oldUser = oldUserMap.get(userId);
                User newUser = newUserMap.get(userId);
    
                if (oldUser.ProfileId == formidlerProfile[0].Id && newUser.ProfileId == ansattProfile[0].Id) {
                    usersWithChangedProfile.add(userId);
                }
            }
        }
    
        if (!usersWithChangedProfile.isEmpty()) {
            HOT_ServiceResourceHandler.createServiceResourceFuture(new List<Id>(usersWithChangedProfile));
        }
    }

}