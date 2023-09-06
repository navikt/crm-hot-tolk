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
    }
          public void updateInterestedResourceStatus(List<SObject> records) {
    Set<Id> serviceAppointmentIds = new Set<Id>();

     for (HOT_InterestedResource__c interestedResource : (List<HOT_InterestedResource__c>) records) {
        serviceAppointmentIds.add(interestedResource.ServiceAppointment__c);
     }
        List<HOT_InterestedResource__c> existingInterestedResources = [
        SELECT Id, ServiceAppointment__c
        FROM HOT_InterestedResource__c
        WHERE ServiceAppointment__c IN :serviceAppointmentIds
        AND Status__c = 'Assigned'
    ];
    Map<Id,Id> irMap = new Map<Id,Id>();
    for (HOT_InterestedResource__c existingInterestedResource : existingInterestedResources) {
        irMap.put(existingInterestedResource.ServiceAppointment__c,existingInterestedResource.Id);
    }
    List<HOT_InterestedResource__c> recordsToUpdate = new List<HOT_InterestedResource__c>();
    for (HOT_InterestedResource__c interestedResource : (List<HOT_InterestedResource__c>) records) {
        if (irMap.containsKey(interestedResource.ServiceAppointment__c)) {
            HOT_InterestedResource__c irToUpdate=new HOT_InterestedResource__c(Id=interestedResource.Id, Status__c='Not Assigned');
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
            if(interestedResource.Status__c=='Wanted'){
                wantedInterestedResourceIds.add(interestedResource.Id);
                System.debug('Status er wanted');
            }
        }  
        if(wantedInterestedResourceIds.size()>0){
            System.debug('Listen større enn');
            HOT_InterestedResourceNotification.newWantedServiceResource(
                    wantedInterestedResourceIds
                );
        }
     }
}
