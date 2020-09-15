public without sharing class HOT_RequestHandler extends MyTriggers {

	public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap){
			List<HOT_Request__c> ownerChangedRequests = new List<HOT_Request__c>();
		for (HOT_Request__c request : (List<HOT_Request__c>) records) {
			// Filter for owner change
            if (request.OwnerId != triggerOldMap.get(request.Id).get('OwnerId')) {
                ownerChangedRequests.add(request);
			}
		}
		if(ownerChangedRequests.size() > 0){
			setServiceTerritory(ownerChangedRequests);
		}
	}

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
		List<HOT_Request__c> avlystRequests = new List<HOT_Request__c>();
		List<HOT_Request__c> annullertRequests = new List<HOT_Request__c>();
		Set<Id> personIdsToUpdate = new Set<Id>();
		List<HOT_Request__c> requestsToGetContactInformationFor = new List<HOT_Request__c>();
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
			// Filter for relevant records to initiate callout to Kontakt og Reservasjonsregisteret (KRR)
			if (request.Person__c != null && request.Person__c != triggerOldMap.get(request.Id).get('Person__c')) {
                personIdsToUpdate.add(request.Person__c);
                requestsToGetContactInformationFor.add(request);
			}
			/*
			//Filter for relevant records to delete attached files (from finished requests)
			if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') &&
				 (request.Status__c == 'Avlyst' || request.Status__c == 'Avslått' || 
				 request.Status__c == 'Dekket' || request.Status__c == 'Udekket')) {
					finishedRequests.add(request);
			}*/
        }
        if (avlystRequests.size() > 0) {
            updateChildRecords(avlystRequests, 'Canceled');
		}
		if (annullertRequests.size() > 0) {
            updateChildRecords(annullertRequests, 'Annul');
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
        List<WorkOrder> workOrders = [SELECT Status FROM WorkOrder WHERE HOT_Request__c IN :changedRequests];
        List<WorkOrderLineItem> workOrderLineItems = [SELECT Status FROM WorkOrderLineItem WHERE WorkOrderId IN :workOrders];
        List<ServiceAppointment> serviceAppointments = [SELECT Status FROM ServiceAppointment WHERE ParentRecordId IN :workOrderLineItems];

        // We only need to update Service Appointment, since the status is updated from SA -> WOLI -> WO in other tigger logic
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.Status = newStatus;
        }
        if (serviceAppointments.size() > 0) {
            update serviceAppointments;
        }
	}
	
	public static void setServiceTerritory(List<HOT_Request__c> requests){
		Map<String, String> serviceTerritoryByQueue = new Map<String, String>{
			'queue_4719' => 'Tromso',
			'queue_4718' => 'Nordland'
		};
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
			request.ServiceTerritory__c = serviceTerritoryIdByQueueId.get(request.OwnerId);
		}
	}
}