public without sharing class HOT_UserContactInformationController {

	@AuraEnabled
    public static Person__c getPersonPhoneEmail() {
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
		System.debug(currentUser);
		Person__c person = [SELECT Id, INT_Email__c, INT_MobilePhone__c FROM Person__c WHERE Id = :currentUser.Account.CRM_Person__c];
		System.debug(person);
		return person;
	}
	
	@AuraEnabled
    public static Person__c getPerson() {
		User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
		System.debug(currentUser);
		Person__c person = [SELECT Id, HOT_WorkplaceInterpreter__c, HOT_DailyLifeInterpreter__c,	HOT_EducationInterpreter__c,
		HOT_InterpreterAtWork__c, HOT_RemoteInterpreter__c, HOT_SignLanguage__c, HOT_WritenInterpreting__c, 
		HOT_SignToSupportMouthReading__c, HOT_SpeechInterpreting__c, HOT_TactileSignLanguage__c, HOT_SignLanguageWithLimitedFieldOfView__c,
		HOT_HapticCommunication__c, HOT_Escort__c, HOT_DegreeOfHearingAndVisualImpairment__c, HOT_Reservations__c, INT_SecurityMeasures__c, 
		HOT_SIPAddress__c, HOT_LanguageAndCommunicationMethods__c
		FROM Person__c WHERE Id = :currentUser.Account.CRM_Person__c];
		System.debug(person);
        return person;
    }
}
