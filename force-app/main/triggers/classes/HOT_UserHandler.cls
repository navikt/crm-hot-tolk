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
        List<Profile> ansattProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
        Set<Id> usersToUpdate = new Set<Id>();
        
        if(!ansattProfile.isEmpty()){
            for (User user : (List<User>) records) {
                User oldUser = (User)triggerOldMap.get(user.Id);
    
                if ((oldUser.ProfileId != ansattProfile[0].Id && user.ProfileId == ansattProfile[0].Id) ||
                    (oldUser.IsActive == false && user.IsActive == true && user.ProfileId == ansattProfile[0].Id)) {
                    usersToUpdate.add(user.Id);
                }
            }
        }
    
        if (!usersToUpdate.isEmpty()) {
            HOT_ServiceResourceHandler.updateServiceResourceFuture(new List<Id>(usersToUpdate));
        }
    }

}