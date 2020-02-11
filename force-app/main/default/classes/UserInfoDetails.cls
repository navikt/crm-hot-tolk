public class UserInfoDetails {
	@AuraEnabled(cacheable = true)
	public static User getUserDetails( String recId ) {
		return [SELECT Id, Account.Name, Account.PersonEmail, AccountId, Account.PersonMobilePhone FROM User WHERE Id = : recId];
	}


	@AuraEnabled(cacheable = true)
	public static Person__c getPersonDetails( String userId  ) {
		User user = [SELECT Id, AccountId FROM User WHERE Id = : userId];

		return [SELECT INT_Ident__c, Name, INT_Phone__c, INT_Email__c FROM Person__c WHERE CRM_Account__c = : user.AccountId];
	}
}