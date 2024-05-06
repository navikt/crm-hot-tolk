public without sharing class HOT_InterestedResourceHandler extends MyTriggers {
    public override void onAfterInsert() {
        updateInterestedResourceNamesOnServiceAppointments(records, null, false);
        updateInterestedResourceStatus(records);
        notifyOnWantedSR(records);
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        updateInterestedResourceNamesOnServiceAppointments(records, triggerOldMap, true);
    }

    public void updateInterestedResourceNamesOnServiceAppointments(
        List<SObject> records,
        Map<Id, sObject> triggerOldMap,
        Boolean isUpdate
    ) {
        // All IRs from trigger
        List<HOT_InterestedResource__c> interestedResources = new List<HOT_InterestedResource__c>();
        for (HOT_InterestedResource__c interestedResource : (List<HOT_InterestedResource__c>) records) {
            if (isUpdate && triggerOldMap.get(interestedResource.Id).get('Status__c') == interestedResource.Status__c) {
                continue; // No changes to Status__c - continue
            }
            if (!isUpdate && interestedResource.Status__c != 'Interested') {
                continue;
            }
            interestedResources.add(interestedResource);
        }
        if (interestedResources.size() == 0) {
            return;
        }

        // Find Service Appointment IDs to update based on trigger IR's SA ID
        List<Id> serviceAppointmentsIDs = new List<Id>();
        for (HOT_InterestedResource__c interestedResource : interestedResources) {
            if (!serviceAppointmentsIDs.contains(interestedResource.ServiceAppointment__c)) {
                serviceAppointmentsIDs.add(interestedResource.ServiceAppointment__c);
            }
        }

        // List of all Service Appointment records to update
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_InterestedResourceNames__c
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentsIDs
        ];

        // Find all IRs in org based on related SAs in trigger IRs
        List<HOT_InterestedResource__c> allInterestedResources = [
            SELECT Id, ServiceAppointment__c, ServiceResource__r.Name
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c IN :serviceAppointmentsIDs AND Status__c = 'Interested'
        ];

        // Update service appointments with names from matching IR's Service Resource
        List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_InterestedResourceNames__c = ''; // Clear field before remaking
            for (HOT_InterestedResource__c interestedResource : allInterestedResources) {
                if (interestedResource.ServiceAppointment__c == ServiceAppointment.Id) {
                    serviceAppointment.HOT_InterestedResourceNames__c += serviceAppointment.HOT_InterestedResourceNames__c ==
                        ''
                        ? interestedResource.ServiceResource__r.Name
                        : ', ' + interestedResource.ServiceResource__r.Name;
                }
            }
            if (serviceAppointment.HOT_InterestedResourceNames__c.length() >= 255) {
                serviceAppointment.HOT_InterestedResourceNames__c =
                    serviceAppointment.HOT_InterestedResourceNames__c.substring(0, 252) + '...';
            }
            serviceAppointmentsToUpdate.add(serviceAppointment);
        }
        update serviceAppointmentsToUpdate;

        Set<Id> potentialSAWithThreadsIds = new Set<Id>();
           for (HOT_InterestedResource__c interestedResource : interestedResources) {
             if (triggerOldMap.get(interestedResource.Id).get('Status__c') == 'Assigned' && interestedResource.Status__c != triggerOldMap.get(interestedResource.Id).get('Status__c')) {
                potentialSAWithThreadsIds.add(interestedResource.ServiceAppointment__c);
             }
        }

        // List of all Service Appointment records to update
        List<ServiceAppointment> potentialSAWithThreadsIdsList = [
            SELECT Id, HOT_InterestedResourceNames__c
            FROM ServiceAppointment
            WHERE Id IN :potentialSAWithThreadsIds
        ];
        //transfer all threads to Ir when status er alt annet enn assigned.

        
        for (ServiceAppointment sa : serviceAppointments) {
            potentialSAWithThreadsIds.add(sa.Id);
        }
        List<Thread__c> exisitingThreadsToBeTransferred = [
            SELECT Id, HOT_IsEmployeeThread__c, CRM_Account__c, CRM_Related_Object__c, HOT_ServiceAppointment__c
            FROM Thread__c
            WHERE CRM_Related_Object__c IN :potentialSAWithThreadsIds AND CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
        ];

        //Finn ir hvor accountid og serviceappointment id er samme
        Set<Id> accountIds = new Set<Id>();
        for (Thread__c thread : exisitingThreadsToBeTransferred) {
            accountIds.add(thread.CRM_Account__c);
        }
        List<HOT_InterestedResource__c> irList = [
            SELECT Id, ServiceAppointment__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__r.AccountId IN :accountIds AND ServiceAppointment__c IN :potentialSAWithThreadsIds
        ];
        //LOOP om threads sin related record er samme serviceappointmentId. Så sett ir sin id som related object
        Map<Id, List<Id>> saIdToIrIdListMap = new Map<Id, List<Id>>();
        for (HOT_InterestedResource__c ir : irList) {
            if (!saIdToIrIdListMap.containsKey(ir.ServiceAppointment__c)) {
                saIdToIrIdListMap.put(ir.ServiceAppointment__c, new List<Id>{ ir.Id });
            } else {
                saIdToIrIdListMap.get(ir.ServiceAppointment__c).add(ir.Id);
            }
        }

        if (exisitingThreadsToBeTransferred.size() != 0) {
            for (Thread__c thread : exisitingThreadsToBeTransferred) {
                if (
                    saIdToIrIdListMap.containsKey(thread.HOT_ServiceAppointment__c) &&
                    thread.HOT_IsEmployeeThread__c == false
                ) {
                    thread.CRM_Related_Object__c = saIdToIrIdListMap.get(thread.HOT_ServiceAppointment__c)[0];
                    thread.HOT_InterestedResource__c = saIdToIrIdListMap.get(thread.HOT_ServiceAppointment__c)[0];
                }
            }
            update exisitingThreadsToBeTransferred;
        }

        //
    }
    public void updateInterestedResourceStatus(List<SObject> records) {
        Set<Id> serviceAppointmentIds = new Set<Id>();

        for (HOT_InterestedResource__c interestedResource : (List<HOT_InterestedResource__c>) records) {
            serviceAppointmentIds.add(interestedResource.ServiceAppointment__c);
        }
        List<HOT_InterestedResource__c> existingInterestedResources = [
            SELECT Id, ServiceAppointment__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c IN :serviceAppointmentIds AND Status__c = 'Assigned'
        ];
        Map<Id, Id> irMap = new Map<Id, Id>();
        for (HOT_InterestedResource__c existingInterestedResource : existingInterestedResources) {
            irMap.put(existingInterestedResource.ServiceAppointment__c, existingInterestedResource.Id);
        }
        List<HOT_InterestedResource__c> recordsToUpdate = new List<HOT_InterestedResource__c>();
        for (HOT_InterestedResource__c interestedResource : (List<HOT_InterestedResource__c>) records) {
            if (irMap.containsKey(interestedResource.ServiceAppointment__c)) {
                HOT_InterestedResource__c irToUpdate = new HOT_InterestedResource__c(
                    Id = interestedResource.Id,
                    Status__c = 'Not Assigned'
                );
                recordsToUpdate.add(irToUpdate);
            }
        }
        if (recordsToUpdate.size() > 0) {
            update recordsToUpdate;
        }
    }
    public void notifyOnWantedSR(List<SObject> records) {
        List<Id> wantedInterestedResourceIds = new List<Id>();
        for (HOT_InterestedResource__c interestedResource : (List<HOT_InterestedResource__c>) records) {
            if (interestedResource.Status__c == 'Wanted') {
                wantedInterestedResourceIds.add(interestedResource.Id);
            }
        }

        if (wantedInterestedResourceIds.size() > 0) {
            HOT_InterestedResourceNotification.newWantedServiceResource(wantedInterestedResourceIds);
        }
    }
}
