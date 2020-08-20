public without sharing class HOT_Utility {
	
	@AuraEnabled(cacheable = true)
    public static ServiceResource getServiceResource() {
		ServiceResource serviceResource = [SELECT Id, Name, ResourceType, IsActive, RelatedRecordId,
		(SELECT Id, ServiceTerritoryId FROM ServiceResource.ServiceTerritories)
		FROM ServiceResource WHERE RelatedRecordId =: UserInfo.getUserId()];
		return serviceResource;
	}
	
	@AuraEnabled(cacheable = true)
    public static Boolean checkAssignedPermissionSet(String permissionSetName) {
		List<PermissionSetAssignment> permsets = [SELECT Id, Assignee.Name FROM PermissionSetAssignment 
		WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name =: permissionSetName];
		//Or hotTolkFrilansGroup IN :PermissionSetGroup];
		return permsets.size()>0;
	}
	
	@AuraEnabled(cacheable = true)
    public static Boolean checkAssignedPermissionSetGroup(String permissionSetGroupName) {
		List<PermissionSetAssignment> permsets = [SELECT Id, Assignee.Name FROM PermissionSetAssignment 
		WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSetGroup.DeveloperName =: permissionSetGroupName];
		return permsets.size()>0;
	}


	@AuraEnabled(cacheable = true)
	public static Map<Id, List<String>> getAssignedResources(List<Id> requestIds){
		
		List<ServiceAppointment> serviceAppointments = [SELECT Id, HOT_ServiceResource__r.Name, HOT_Request__c FROM ServiceAppointment WHERE HOT_Request__r.Id IN :requestIds AND HOT_ServiceResource__c != null];
		Map<Id, List<String>> requestIdToServiceResource= new Map<Id, List<String>>();
		for(Id id:requestIds){
			List<String> serviceResources = new List<String>();
			for(ServiceAppointment sa:serviceAppointments){
				if(sa.HOT_Request__c == id){
					serviceResources.add((String) sa.HOT_ServiceResource__r.Name);
				}
			}
			requestIdToServiceResource.put(id, serviceResources);
		}
		return requestIdToServiceResource;
	}

	@AuraEnabled(cacheable = true)
    public static Id getPersonAccountId() {
		return [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()].AccountId;
	}

	@AuraEnabled(cacheable = true)
    public static Boolean checkUserHasEntitlement() {
		User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
		Person__c person = [SELECT Id, HOT_DailyLifeInterpreter__c, HOT_EducationInterpreter__c, HOT_Escort__c, HOT_HapticCommunication__c, HOT_InterpreterAtWork__c, HOT_RemoteInterpreter__c,
								   HOT_SignLanguage__c, HOT_SignLanguageWithLimitedFieldOfView__c, HOT_SignToSupportMouthReading__c, HOT_SpeechInterpreting__c, HOT_TactileSignLanguage__c, HOT_WritenInterpreting__c
							FROM Person__c];// WHERE CRM_Account__c = :user.AccountId];
		System.debug([SELECT Id FROM Person__c]);
		Map<String, Object> fieldsToValue = person.getPopulatedFieldsAsMap();

		for (String fieldName : fieldsToValue.keySet()){
			if(fieldName != 'Id'){
				if(fieldsToValue.get(fieldName) == true){
					return true;
				}
			}
		}
		return false;
	}

}
