public without sharing class HOT_UserInformationController {
    @AuraEnabled(cacheable=true)
    public static Person__c getPersonPhoneEmail() {
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
        Person__c person = [
            SELECT Id, INT_KrrEmail__c, INT_KrrMobilePhone__c
            FROM Person__c
            WHERE Id = :currentUser.Account.CRM_Person__c
        ];
        return person;
    }

    @AuraEnabled(cacheable=true)
    public static Person__c getPerson() {
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
        Person__c person = [
            SELECT
                Id,
                HOT_WorkplaceInterpreter__c,
                HOT_DailyLifeInterpreter__c,
                HOT_EducationInterpreter__c,
                HOT_InterpreterAtWork__c,
                HOT_RemoteInterpreter__c,
                HOT_SignLanguage__c,
                HOT_WritenInterpreting__c,
                HOT_SignToSupportMouthReading__c,
                HOT_SpeechInterpreting__c,
                HOT_TactileSignLanguage__c,
                HOT_SignLanguageWithLimitedFieldOfView__c,
                HOT_HapticCommunication__c,
                HOT_Escort__c,
                HOT_DegreeOfHearingAndVisualImpairment__c,
                INT_SecurityMeasures__c,
                HOT_SIPAddress__c,
                HOT_NotificationChannel__c
            FROM Person__c
            WHERE Id = :currentUser.Account.CRM_Person__c
        ];
        return person;
    }
    @AuraEnabled
    public static List < Map < String, String >> getNotificationPickListValues(String chosen) {
        List < Map < String, String >> options = new List < Map < String, String >> ();
        
        Schema.DescribeFieldResult fieldResult = Person__c.HOT_NotificationChannel__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry f : ple){
            if(chosen!=f.getLabel()){
                Map < String, String > values = new Map < String, String > {
                    'label' => f.getLabel(),
                    'value' => f.getValue()
                };
                options.add(values);
            }
		}     
        return options;
    }
    @AuraEnabled
    public static boolean changeUserNotificationSetting(String personId, String newNotificationValue) {
        Person__c person = [
            SELECT
                Id,
                HOT_NotificationChannel__c
                FROM Person__c
                WHERE Id = :personId
        ];
         if(person!=null){
             person.HOT_NotificationChannel__c=newNotificationValue;
             update person;
         }
        return true;
    }
}
