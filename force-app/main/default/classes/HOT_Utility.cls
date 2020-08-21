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
    public static Account getPersonAccount() {
		User user = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()];
		return [SELECT Id, Name FROM Account WHERE Id = :User.AccountId];
	}

	@AuraEnabled(cacheable = true)
    public static Boolean checkUserHasEntitlement() {
		User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		if(user.AccountId != null){
			Person__c person = [SELECT Id, HOT_DailyLifeInterpreter__c, HOT_EducationInterpreter__c, HOT_Escort__c, HOT_HapticCommunication__c, HOT_InterpreterAtWork__c, HOT_RemoteInterpreter__c,
									   HOT_SignLanguage__c, HOT_SignLanguageWithLimitedFieldOfView__c, HOT_SignToSupportMouthReading__c, HOT_SpeechInterpreting__c, HOT_TactileSignLanguage__c, HOT_WritenInterpreting__c
								FROM Person__c WHERE CRM_Account__c = :user.AccountId LIMIT 1];

			Map<String, Object> fieldsToValue = person.getPopulatedFieldsAsMap();
			for (String fieldName : fieldsToValue.keySet()){
				if(fieldName != 'Id'){
					if(fieldsToValue.get(fieldName) == true){
						return true;
					}
				}
			}
		}
		
		return false;
	}


	@AuraEnabled(cacheable = true)
    public static Map<String, String> getOrdererDetails() {
		User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

		//Metode 1
		List<HOT_Request__c> requests = [SELECT Id, OrdererEmail__c, OrdererPhone__c, CreatedDate FROM HOT_Request__c WHERE Orderer__c = :user.AccountId ORDER BY CreatedDate ASC LIMIT 1];
		HOT_Request__c latestCreatedRequest;
		Map<String, String> ordererDetails = new Map<String,String>();
		if(requests.size()>0){
			latestCreatedRequest = requests[0];
			ordererDetails.put('OrdererEmail__c', String.valueOf(latestCreatedRequest.OrdererEmail__c));
			ordererDetails.put('OrdererPhone__c', String.valueOf(latestCreatedRequest.OrdererPhone__c));
		}
		

		return ordererDetails;
	}

	
	@AuraEnabled(cacheable = true)
    public static void setAccountFieldOnRequestFromPersonNumber(Id requestId, String personNumber) {
		Account account = [SELECT Id FROM Account WHERE INT_PersonIdent__c = :personNumber LIMIT 1];
		if(account != null){
			HOT_Request__c request = [SELECT Id, Account__C FROM HOT_Request__c WHERE Id = :requestId LIMIT 1];
			request.Account__c = account.Id;
			update request;
		}
	}
}
