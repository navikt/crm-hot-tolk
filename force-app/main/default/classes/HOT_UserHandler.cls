public without sharing class HOT_UserHandler extends MyTriggers {
    
	public override void onAfterInsert(){
		List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
		if(profiles.size()>0){
			List<User> users = new List<User>();
			for(User user:(List<User>) records){
				if(user.ProfileId == profiles[0].Id){
					users.add(user);
				}
			}
			HOT_ServiceResourceHandler.createServiceResource(users, false, null);
		}
	}
}
