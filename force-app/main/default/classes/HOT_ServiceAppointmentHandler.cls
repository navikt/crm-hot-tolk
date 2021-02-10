public without sharing class HOT_ServiceAppointmentHandler extends MyTriggers {
	
	public override void onBeforeInsert() {
		setDefaultFields((List<ServiceAppointment>) records);
		setOwner((List<ServiceAppointment>) records);
		setFieldsByPreferredResource((List<ServiceAppointment>) records);
	}

	public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
		
		List<ServiceAppointment> recievedNewInterpreter = new List<ServiceAppointment>();
		List<ServiceAppointment> updatedServiceAppointments = new List<ServiceAppointment>();
		List<ServiceAppointment> serviceAppointmentsWithDeletedPreferredResources = new List<ServiceAppointment>();
		List<ServiceAppointment> serviceAppointmentsWithChangedStatusOrResource = new List<ServiceAppointment>();
		List<ServiceAppointment> allServiceAppointments = new List<ServiceAppointment>();
		
		for(ServiceAppointment serviceAppointment : (List<ServiceAppointment>) records) {
			if(serviceAppointment.get('HOT_ServiceResource__c') != null &&
			serviceAppointment.get('HOT_ServiceResource__c') != triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')) {
					recievedNewInterpreter.add(serviceAppointment);
			}
			if(triggerOldMap.get(serviceAppointment.Id).get('HOT_PreferredResource__c') != ServiceAppointment.HOT_PreferredResource__c && serviceAppointment.HOT_PreferredResource__c != null){
				updatedServiceAppointments.add(serviceAppointment);
			} 
			if(triggerOldMap.get(serviceAppointment.Id).get('HOT_PreferredResource__c') != ServiceAppointment.HOT_PreferredResource__c && serviceAppointment.HOT_PreferredResource__c == null){
				serviceAppointmentsWithDeletedPreferredResources.add(serviceAppointment);
			} 
			if(serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') || serviceAppointment.HOT_ServiceResource__c != triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')) {
				serviceAppointmentsWithChangedStatusOrResource.add(serviceAppointment);
			}
			allServiceAppointments.add(serviceAppointment);
		}
		if(!updatedServiceAppointments.isEmpty()) {
			updatedServiceAppointments = setFieldsByPreferredResource(updatedServiceAppointments);
		}
		if(!serviceAppointmentsWithDeletedPreferredResources.isEmpty()) {
			serviceAppointmentsWithDeletedPreferredResources = setFieldsIfPreferredResourceDeleted(serviceAppointmentsWithDeletedPreferredResources);
		}
		if(recievedNewInterpreter.size() > 0) {
			updateCancelledByInterpreter(recievedNewInterpreter);
		}
		if(serviceAppointmentsWithChangedStatusOrResource.size()>0) {
			createHistoricallyAssignedResources(serviceAppointmentsWithChangedStatusOrResource, triggerOldMap);
		}
		notifyUsers(allServiceAppointments, triggerOldMap);
	}

	public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
		List<ServiceAppointment> serviceAppointmentsToRemoveAssignedResource = new List<ServiceAppointment>();
		List<ServiceAppointment> updatedServiceAppointments = new List<ServiceAppointment>();
		
		for(ServiceAppointment serviceAppointment : (List<ServiceAppointment>) records) {
			if((serviceAppointment.Status == 'Canceled' || serviceAppointment.Status == 'Annul') && serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status')) {
				serviceAppointmentsToRemoveAssignedResource.add(serviceAppointment);
				if(serviceAppointment.Status == 'Annul'){
					updatedServiceAppointments.add(serviceAppointment);
				}
			}
		}

		if(serviceAppointmentsToRemoveAssignedResource.size() > 0) {
			removeAssignedResource(serviceAppointmentsToRemoveAssignedResource);
		}
		if(updatedServiceAppointments.size() > 0) {
			updateWorkOrderLineItems(updatedServiceAppointments);
		}
	}
	
	public override void onAfterInsert() {
		updateWorkOrderLineItems((List<ServiceAppointment>) records);
	}
	public override void onAfterDelete() {
		updateWorkOrderLineItems((List<ServiceAppointment>) records);
	}
	public override void onAfterUndelete() {
		updateWorkOrderLineItems((List<ServiceAppointment>) records);
	}

	public static void updateWorkOrderLineItems(List<ServiceAppointment> serviceAppointments){
		Set<Id> workOrderLineItemIds = new Set<Id>();
		List<Id> deletedServiceAppointments = new List<Id>();
		for(ServiceAppointment serviceAppointment:serviceAppointments){
			workOrderLineItemIds.add(serviceAppointment.ParentRecordId);
			if(serviceAppointment.IsDeleted){
				deletedServiceAppointments.add(serviceAppointment.Id);
			}
		}
		List<WorkOrderLineItem> workOrderLineItems = [SELECT Id, HOT_NumberOfServiceAppointments__c, 
										(SELECT Id, Status FROM WorkOrderLineItem.HOT_ServiceAppointments__r
										WHERE Id NOT IN :deletedServiceAppointments AND Status != 'Annul') 
										FROM WorkOrderLineItem WHERE Id IN :workOrderLineItemIds];
		for(WorkOrderLineItem workOrderLineItem:workOrderLineItems){
			if(workOrderLineItem.HOT_NumberOfServiceAppointments__c != workOrderLineItem.HOT_ServiceAppointments__r.size()){
				workOrderLineItem.HOT_NumberOfServiceAppointments__c = workOrderLineItem.HOT_ServiceAppointments__r.size();
			}
		}
		update workOrderLineItems;
	}
	
	private static void removeAssignedResource(List<ServiceAppointment> serviceAppointments) {
		List<AssignedResource> arList = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId IN :serviceAppointments];
		delete arList;
	}

	private static void updateCancelledByInterpreter(List<ServiceAppointment> recievedNewInterpreter) {
		for(ServiceAppointment serviceAppointment : recievedNewInterpreter) {
			serviceAppointment.HOT_CanceledByInterpreter__c = false;		
		}
	}

	private static void setDefaultFields(List<ServiceAppointment> serviceAppointments) {
		List<Id> workOrderLineItemIds = new List<Id>();														
		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			workOrderLineItemIds.add(serviceAppointment.ParentRecordId);
		}
		Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem>([SELECT Id, WorkOrder.HOT_Request__c, WorkOrder.OwnerId, Subject, Description, StartDate, EndDate,
																Street, City, PostalCode, HOT_InterpretationPostalCity__c, HOT_InterpretationPostalCode__c, HOT_InterpretationPostalStreet__c
																FROM WorkOrderLineItem WHERE Id IN :workOrderLineItemIds]);

		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			serviceAppointment.Status = 'None';
			if(serviceAppointment.ParentRecordId != null){
				if(serviceAppointment.HOT_Request__c == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrder.HOT_Request__c != null){
					serviceAppointment.HOT_Request__c = workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrder.HOT_Request__c;
				}
				if(serviceAppointment.Subject == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).Subject != null){
					serviceAppointment.Subject = workOrderLineItems.get(serviceAppointment.ParentRecordId).Subject;
				}
				if(serviceAppointment.Description == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).Description != null){
					serviceAppointment.Description = workOrderLineItems.get(serviceAppointment.ParentRecordId).Description;
				}
				if(serviceAppointment.HOT_InterpretationPostalCity__c == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).HOT_InterpretationPostalCity__c != null){
					serviceAppointment.HOT_InterpretationPostalCity__c = workOrderLineItems.get(serviceAppointment.ParentRecordId).HOT_InterpretationPostalCity__c;
				}
				if(serviceAppointment.HOT_InterpretationPostalCode__c == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).HOT_InterpretationPostalCode__c != null){
					serviceAppointment.HOT_InterpretationPostalCode__c = workOrderLineItems.get(serviceAppointment.ParentRecordId).HOT_InterpretationPostalCode__c;
				}
				if(serviceAppointment.HOT_InterpretationStreet__c == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).HOT_InterpretationPostalStreet__c != null){
					serviceAppointment.HOT_InterpretationStreet__c = workOrderLineItems.get(serviceAppointment.ParentRecordId).HOT_InterpretationPostalStreet__c;
				}
				if(serviceAppointment.City == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).City != null){
					serviceAppointment.City = workOrderLineItems.get(serviceAppointment.ParentRecordId).City;
				}
				if(serviceAppointment.PostalCode == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).PostalCode != null){
					serviceAppointment.PostalCode = workOrderLineItems.get(serviceAppointment.ParentRecordId).PostalCode;
				}
				if(serviceAppointment.Street == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).Street != null){
					serviceAppointment.Street = workOrderLineItems.get(serviceAppointment.ParentRecordId).Street;
				}
				if(serviceAppointment.EarliestStartTime == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).StartDate != null){
					serviceAppointment.EarliestStartTime = workOrderLineItems.get(serviceAppointment.ParentRecordId).StartDate;
				}
				if(serviceAppointment.DueDate == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).EndDate != null){
					serviceAppointment.DueDate = workOrderLineItems.get(serviceAppointment.ParentRecordId).EndDate;
				}
				if(serviceAppointment.SchedStartTime == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).StartDate != null){
					serviceAppointment.SchedStartTime = workOrderLineItems.get(serviceAppointment.ParentRecordId).StartDate;
				}
				if(serviceAppointment.SchedEndTime == null && workOrderLineItems.get(serviceAppointment.ParentRecordId).EndDate != null){
					serviceAppointment.SchedEndTime = workOrderLineItems.get(serviceAppointment.ParentRecordId).EndDate;
				}
				if(serviceAppointment.HOT_WorkOrderLineItem__c == null && serviceAppointment.ParentRecordId != null){
					serviceAppointment.HOT_WorkOrderLineItem__c = serviceAppointment.ParentRecordId;
				}
			}
		}
	}

	private static void setOwner(List<ServiceAppointment> serviceAppointments) {
		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			if(serviceAppointment.HOT_Request__c != null) {
				serviceAppointment.OwnerId = serviceAppointment.HOT_RequestOwnerId__c;
			}
		}
	}

	private static void createHistoricallyAssignedResources(List<ServiceAppointment> serviceAppointments, Map<Id,sObject> triggerOldMap) {
		
		List<HOT_HistoricallyAssignedResource__c> newHistoricallyAssignedResources = new List<HOT_HistoricallyAssignedResource__c>();
		
		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			
			ServiceAppointment oldServiceAppointment = (ServiceAppointment)triggerOldMap.get(serviceAppointment.Id);
			
			// First check if we sould create a Historically Assigned Resource for this change
			if(serviceAppointment.HOT_DoNotCreateHAR__c) {
				serviceAppointment.HOT_DoNotCreateHAR__c = false;

			} else {
				// Added resource
				if(serviceAppointment.HOT_ServiceResource__c != null && oldServiceAppointment.HOT_ServiceResource__c == null) {
					HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResource.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResource.Status__c = getTranslatedStatus(serviceAppointment.Status);
					newHistoricallyAssignedResources.add(historicallyAssignedResource);
				}
				// Same resource, but status has changed
				if(serviceAppointment.HOT_ServiceResource__c != null && serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c && serviceAppointment.Status != 'None' && serviceAppointment.Status != null) {
					HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResource.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResource.Status__c = getTranslatedStatus(serviceAppointment.Status);
					newHistoricallyAssignedResources.add(historicallyAssignedResource);
				}
				// Changed resource
				if(serviceAppointment.HOT_ServiceResource__c != null && oldServiceAppointment.HOT_ServiceResource__c != null && serviceAppointment.HOT_ServiceResource__c != oldServiceAppointment.HOT_ServiceResource__c) {
					HOT_HistoricallyAssignedResource__c historicallyAssignedResourceOld = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResourceOld.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResourceOld.ServiceResource__c = oldServiceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResourceOld.Status__c = 'Tolk tatt av oppdraget';
					newHistoricallyAssignedResources.add(historicallyAssignedResourceOld);

					HOT_HistoricallyAssignedResource__c historicallyAssignedResourceNew = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResourceNew.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResourceNew.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResourceNew.Status__c = getTranslatedStatus(serviceAppointment.Status);
					newHistoricallyAssignedResources.add(historicallyAssignedResourceNew);
				}
				// Removed resource
				if(serviceAppointment.HOT_ServiceResource__c == null && oldServiceAppointment.HOT_ServiceResource__c != null) {
					HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResource.ServiceResource__c = oldServiceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResource.Status__c = 'Tolk tatt av oppdraget';
					newHistoricallyAssignedResources.add(historicallyAssignedResource);
				}
				// Only status change, no resource connected to service appointment
				if(serviceAppointment.HOT_ServiceResource__c == null && serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c) {
					// Do noting
				}					
			}
		}
		insert newHistoricallyAssignedResources;
	}

	@TestVisible 
	private static String getTranslatedStatus (String status) {
		if(status == 'Annul') return 'Annullert';
		if(status == 'Canceled') return 'Avlyst av bruker';
		if(status == 'Cannot Complete') return 'Udekket';
		if(status == 'Completed') return 'Dekket';
		if(status == 'Dispatched') return 'Tildelt';
		if(status == 'In Progress') return 'Pågår';
		if(status == 'None') return 'Åpen';
		if(status == 'Released to Freelance') return 'Frigitt til frilanstolker';
		if(status == 'Scheduled') return 'Reservert';

		return '';
	}

	public static List<ServiceAppointment> setFieldsByPreferredResource(List<ServiceAppointment> serviceAppointments) {
		List<Id> PreferredResourceId = new List<Id>();
		List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
		for(ServiceAppointment serviceAppointment : serviceAppointments){
			if(serviceAppointment.HOT_PreferredServiceResourceId__c != null){
				PreferredResourceId.add(serviceAppointment.HOT_PreferredServiceResourceId__c);
				serviceAppointmentsToUpdate.add(serviceAppointment);
			}
		}
		Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>([SELECT Id, HOT_ServiceTerritory__c, HOT_IsFreelanceInterpreter__c, HOT_IsEmployedInterpreter__c FROM ServiceResource WHERE Id IN :PreferredResourceId]);
		for(ServiceAppointment serviceAppointment : serviceAppointmentsToUpdate){
			if(serviceAppointment.ServiceTerritoryId != serviceResources.get(serviceAppointment.HOT_PreferredServiceResourceId__c).HOT_ServiceTerritory__c){
				serviceAppointment.ServiceTerritoryId = serviceResources.get(serviceAppointment.HOT_PreferredServiceResourceId__c).HOT_ServiceTerritory__c;
			}

			if(serviceAppointment.HOT_IsReleasedToFreelance__c != serviceResources.get(serviceAppointment.HOT_PreferredServiceResourceId__c).HOT_IsFreelanceInterpreter__c){
				serviceAppointment.HOT_IsReleasedToFreelance__c = serviceResources.get(serviceAppointment.HOT_PreferredServiceResourceId__c).HOT_IsFreelanceInterpreter__c;
				serviceAppointment.HOT_IsEmployedInterpreter__c = serviceResources.get(serviceAppointment.HOT_PreferredServiceResourceId__c).HOT_IsEmployedInterpreter__c;
			}
		}
		return serviceAppointmentsToUpdate;
	}

	public static List<ServiceAppointment> setFieldsIfPreferredResourceDeleted(List<ServiceAppointment> serviceAppointments) {
		List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
		List<Id> requestIds = new List<Id>();
		for (ServiceAppointment serviceAppointment : serviceAppointments){
			requestIds.add(serviceAppointment.HOT_Request__c);
		}

		List<HOT_Request__c> requests = [SELECT Id, ServiceTerritory__c FROM HOT_Request__c WHERE Id IN :requestIds];
		Map<Id,HOT_Request__c> requestMap = new Map<Id,HOT_Request__c>(requests);

		for(ServiceAppointment serviceAppointment : serviceAppointments){
				serviceAppointment.ServiceTerritoryId = requestMap.get(serviceAppointment.HOT_Request__c)?.ServiceTerritory__c;
				serviceAppointment.HOT_IsReleasedToFreelance__c = false;
				serviceAppointment.HOT_IsEmployedInterpreter__c = true;
				serviceAppointmentsToUpdate.add(serviceAppointment);
		}
		return serviceAppointmentsToUpdate;
	}

	public static void notifyUsers(List<ServiceAppointment> serviceAppointments, Map<Id,sObject> triggerOldMap) {

		CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='HOT_Service_Appointment_Changed'];
		
		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			
			ServiceAppointment oldServiceAppointment = (ServiceAppointment)triggerOldMap.get(serviceAppointment.Id);
			
			// Varsel ved avlyst av bruker
			if(serviceAppointment.Status == 'Canceled' && oldServiceAppointment.Status != 'Canceled' && serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c && oldServiceAppointment.Status != 'Scheduled') {
			
				Messaging.CustomNotification notification = new Messaging.CustomNotification();
				notification.setTitle(serviceAppointment.AppointmentNumber + ' - ' + serviceAppointment.EarliestStartTime?.format('d.M.yyyy') + ' - ' + ' Avlyst');
				notification.setBody('Oppdraget ' + serviceAppointment.AppointmentNumber + ' som skulle vært gjennomført ' + serviceAppointment.EarliestStartTime?.format('d.M.yyyy') + ' er avlyst.');
				notification.setNotificationTypeId(notificationType.Id);
				notification.setTargetId(serviceAppointment.Id);
				
				Set<String> recipients = new Set<String>();
				recipients.add(oldServiceAppointment.HOT_AssignedResourceId__c);
				try {
					notification.send(recipients);
				}
				catch (Exception e) {
					System.debug('Problem sending notification: ' + e.getMessage());
				}
			}

			// Varsel ved endring av tidspunkt
			if((serviceAppointment.SchedStartTime != oldServiceAppointment.SchedStartTime || serviceAppointment.SchedEndTime != oldServiceAppointment.SchedEndTime) && serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c && serviceAppointment.Status != 'Scheduled' && serviceAppointment.SchedStartTime != null) {
			
				Messaging.CustomNotification notification = new Messaging.CustomNotification();
				notification.setTitle(serviceAppointment.AppointmentNumber + ' - ' + serviceAppointment.SchedStartTime?.format('d.M.yyyy') + ' - ' + ' Endret tidspunkt');
				notification.setBody('Oppdraget ' + serviceAppointment.AppointmentNumber + ' den ' + serviceAppointment.SchedStartTime?.format('d.M.yyyy') + ' har fått nytt tidspunkt.');
				notification.setNotificationTypeId(notificationType.Id);
				notification.setTargetId(serviceAppointment.Id);
				
				Set<String> recipients = new Set<String>();
				recipients.add(oldServiceAppointment.HOT_AssignedResourceId__c);
				try {
					notification.send(recipients);
				}
				catch (Exception e) {
					System.debug('Problem sending notification: ' + e.getMessage());
				}
			}

			// Varsel ved endring av adresse
			if(serviceAppointment.HOT_AddressFormated__c != oldServiceAppointment.HOT_AddressFormated__c && serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c && serviceAppointment.Status != 'Scheduled') {
			
				Messaging.CustomNotification notification = new Messaging.CustomNotification();
				notification.setTitle(serviceAppointment.AppointmentNumber + ' - ' + serviceAppointment.EarliestStartTime?.format('d.M.yyyy') + ' - ' + ' Endret adresse');
				notification.setBody('Oppdraget ' + serviceAppointment.AppointmentNumber + ' den ' + serviceAppointment.EarliestStartTime?.format('d.M.yyyy') + ' har fått ny adresse.');
				notification.setNotificationTypeId(notificationType.Id);
				notification.setTargetId(serviceAppointment.Id);
				
				Set<String> recipients = new Set<String>();
				recipients.add(oldServiceAppointment.HOT_AssignedResourceId__c);
				try {
					notification.send(recipients);
				}
				catch (Exception e) {
					System.debug('Problem sending notification: ' + e.getMessage());
				}
			}

			// Varsel ved fjerning av tolk
			if(serviceAppointment.HOT_ServiceResource__c != oldServiceAppointment.HOT_ServiceResource__c && serviceAppointment.Status != 'Scheduled') {
			
				Messaging.CustomNotification notification = new Messaging.CustomNotification();
				notification.setTitle(serviceAppointment.AppointmentNumber + ' - ' + serviceAppointment.EarliestStartTime?.format('d.M.yyyy') + ' - ' + ' Tatt av oppdraget');
				notification.setBody('Du er tatt av oppdraget ' + serviceAppointment.AppointmentNumber + ' den ' + serviceAppointment.EarliestStartTime?.format('d.M.yyyy'));
				notification.setNotificationTypeId(notificationType.Id);
				notification.setTargetId(serviceAppointment.Id);
				
				Set<String> recipients = new Set<String>();
				recipients.add(oldServiceAppointment.HOT_AssignedResourceId__c);
				try {
					notification.send(recipients);
				}
				catch (Exception e) {
					System.debug('Problem sending notification: ' + e.getMessage());
				}
			}
		}
    }
}
