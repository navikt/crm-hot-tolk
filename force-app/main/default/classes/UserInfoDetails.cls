public class UserInfoDetails {
	@AuraEnabled(cacheable = true)
	public static User getUserDetails( String recId ) {
		return [SELECT Id, Account.Name, Account.PersonEmail, AccountId, Account.PersonMobilePhone FROM User WHERE Id = : recId];
	}
}