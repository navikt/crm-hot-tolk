public without sharing class HOT_UserHandler extends MyTriggers {
    
	public override void onAfterInsert(){
		List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
		if(profiles.size()>0){
			List<User> users = new List<User>();
			List<Id> userIds = new List<Id>();
			for(User user:(List<User>) records){
				if(user.ProfileId == profiles[0].Id){
					userIds.add(user.Id);
				}
			}
			HOT_ServiceResourceHandler.createServiceResourceFuture(userIds);
		}
	}
}
