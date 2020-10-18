public without sharing class HOT_RequestHandler extends MyTriggers {

	public override void onBeforeInsert(){
		setServiceTerritory((List<HOT_Request__c>) records);
	}

	public override void onAfterInsert(){
		List<HOT_Request__c> requestsToGetContactInformationFor = new List<HOT_Request__c>();
		Set<Id> personIdsToUpdate = new Set<Id>();
		for (HOT_Request__c request : (List<HOT_Request__c>) records) {
			// Filter for relevant records to initiate callout to Kontakt og Reservasjonsregisteret (KRR)
			if (request.Person__c != null) {
				personIdsToUpdate.add(request.Person__c);
				requestsToGetContactInformationFor.add(request);
			}
		}

		if (requestsToGetContactInformationFor.size() > 0) {
            // Set related Person__c records "KRR Integration Status" field to 'Queued'
            List<Person__c> personsToUpdate = new List<Person__c>();
			for (Id personId : personIdsToUpdate) {
                personsToUpdate.add(new Person__c(Id = personId, INT_KrrIntegrationStatus__c = 'Queued'));
            }
            update personsToUpdate;

            // Call out to KRR through Queuable Apex
            KRRCalloutQueuable krr = new KRRCalloutQueuable(requestsToGetContactInformationFor);
            System.enqueueJob(krr);
		}
	}

	public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap){
		List<HOT_Request__c> ownerChangedRequests = new List<HOT_Request__c>();
		List<HOT_Request__c> avlystRequests = new List<HOT_Request__c>();
		for (HOT_Request__c request : (List<HOT_Request__c>) records) {
			// Filter for owner change
            if (request.OwnerId != triggerOldMap.get(request.Id).get('OwnerId')) {
                ownerChangedRequests.add(request);
			}
			// Filter for Avlyst requests
            if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Avlyst') {
                avlystRequests.add(request);
			}
		}
		if(ownerChangedRequests.size() > 0){
			setServiceTerritory(ownerChangedRequests);
		}
		if (avlystRequests.size() > 0) {
            setCancelDate(avlystRequests);
		}
	}

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
		List<HOT_Request__c> avlystRequests = new List<HOT_Request__c>();
		List<HOT_Request__c> annullertRequests = new List<HOT_Request__c>();
        List<HOT_Request__c> finishedRequests = new List<HOT_Request__c>();

        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
			// Filter for Avlyst requests
            if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Avlyst') {
                avlystRequests.add(request);
			}
			// Filter for Annullert requests
            if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Annullert') {
                annullertRequests.add(request);
			}
        }
        if (avlystRequests.size() > 0) {
            updateChildRecords(avlystRequests, 'Canceled');
		}
		if (annullertRequests.size() > 0) {
            updateChildRecords(annullertRequests, 'Annul');
		}

		if (finishedRequests.size() > 0) {
			for (HOT_Request__c request : finishedRequests) {
				List<ContentDocumentLink> files = [Select Id, ContentDocumentId From ContentDocumentLink where LinkedEntityId=:request.Id];
				List<Id> documentIds = new List<Id>();
				for(ContentDocumentLink f :files){
					documentIds.add(f.ContentDocumentId);
				}
				List<ContentDocument> relatedFiles = [Select id, Title From ContentDocument where Id in: documentIds];
				delete relatedFiles;
			}
		}

    }

    private static void updateChildRecords(List<HOT_Request__c> changedRequests, String newStatus) {
        List<WorkOrder> workOrders = [SELECT Status FROM WorkOrder WHERE HOT_Request__c IN :changedRequests AND Status != :newStatus];
        List<WorkOrderLineItem> workOrderLineItems = [SELECT Status FROM WorkOrderLineItem WHERE WorkOrderId IN :workOrders AND Status != :newStatus];
        List<ServiceAppointment> serviceAppointments = [SELECT Status FROM ServiceAppointment WHERE ParentRecordId IN :workOrderLineItems AND Status != :newStatus];

		for (WorkOrder workOrder : workOrders) {
            workOrder.Status = newStatus;
        }
        if (workOrders.size() > 0) {
            update workOrders;
        }
		for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            workOrderLineItem.Status = newStatus;
        }
        if (workOrderLineItems.size() > 0) {
            update workOrderLineItems;
		}
		for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.Status = newStatus;
        }
        if (serviceAppointments.size() > 0) {
            update serviceAppointments;
		}
	}
	
	public static void setServiceTerritory(List<HOT_Request__c> requests){
		List<HOT_ServiceTerritoryByQueue__mdt> serviceTerritoryByQueueList = [SELECT Queue__c, ServiceTerritory__c FROM HOT_ServiceTerritoryByQueue__mdt];
		Map<String, String> serviceTerritoryByQueue = new Map<String, String>();
		for(HOT_ServiceTerritoryByQueue__mdt STbyQ:serviceTerritoryByQueueList){
			serviceTerritoryByQueue.put(STbyQ.Queue__c, STbyQ.ServiceTerritory__c);
		}
		List<Group> queues = [SELECT Id, Name, DeveloperName FROM Group WHERE Type='Queue' AND DeveloperName IN :serviceTerritoryByQueue.keySet()];
		List<ServiceTerritory> serviceTerritories = [SELECT Id, Name, HOT_DeveloperName__c FROM ServiceTerritory WHERE HOT_DeveloperName__c IN :serviceTerritoryByQueue.values()];
		Map<Id, Id> serviceTerritoryIdByQueueId = new Map<Id, Id>();
		for(Group queue:queues){
			for(ServiceTerritory serviceTerritory:serviceTerritories){
				if(serviceTerritoryByQueue.get(queue.DeveloperName) == serviceTerritory.HOT_DeveloperName__c){
					serviceTerritoryIdByQueueId.put(queue.Id, serviceTerritory.Id);
				}
			}
		}
		for(HOT_Request__c request:requests){
			if(serviceTerritoryIdByQueueId.get(request.OwnerId) != null){
				request.ServiceTerritory__c = serviceTerritoryIdByQueueId.get(request.OwnerId);
			}
		}
	}

	public static void setCancelDate(List<HOT_Request__c> requests){
		for(HOT_Request__c request:requests){
			request.CanceledDate__c = Date.today();
		}
	}
}
