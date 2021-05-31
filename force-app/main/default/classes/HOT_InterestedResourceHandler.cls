public with sharing class HOT_InterestedResourceHandler extends MyTriggers {
    public override void onAfterInsert() {
        updateInterestedResourceNamesOnServiceAppointments(records, null, false);
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        updateInterestedResourceNamesOnServiceAppointments(records, triggerOldMap, true);
    }
    
    public void updateInterestedResourceNamesOnServiceAppointments(List<SObject> records, Map<Id, sObject> triggerOldMap, Boolean isUpdate) {
        // All IRs from trigger
        List<HOT_InterestedResource__c> interestedResources = new List<HOT_InterestedResource__c>();
        for (HOT_InterestedResource__c interestedResource : (List<HOT_InterestedResource__c>) records) {
            if (isUpdate && triggerOldMap.get(interestedResource.Id).get('Status__c') == interestedResource.Status__c)
                continue; // No changes to Status__c - continue
            
            if (!isUpdate && interestedResource.Status__c != 'Interested') 
                continue;

            interestedResources.add(interestedResource);
        }

        // Find Service Appointment IDs to update based on trigger IR's SA ID
        List<Id> serviceAppointmentsIDs = new List<Id>();
        for (HOT_InterestedResource__c interestedResource : interestedResources) {
            if (!serviceAppointmentsIDs.contains(interestedResource.ServiceAppointment__c))
                serviceAppointmentsIDs.add(interestedResource.ServiceAppointment__c);
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
            System.debug('serviceAppointment:' + serviceAppointment);
            for (HOT_InterestedResource__c interestedResource : allInterestedResources) {
                System.debug('interestedResource: ' + interestedResource);
                if (interestedResource.ServiceAppointment__c == ServiceAppointment.Id) {
                    if (serviceAppointment.HOT_InterestedResourceNames__c == '') {
                        serviceAppointment.HOT_InterestedResourceNames__c = interestedResource.ServiceResource__r.Name;
                    } else {
                        serviceAppointment.HOT_InterestedResourceNames__c += ', '+interestedResource.ServiceResource__r.Name;
                    }                        
                }
            }   
            if (serviceAppointment.HOT_InterestedResourceNames__c.length() >= 255) {
                serviceAppointment.HOT_InterestedResourceNames__c = serviceAppointment.HOT_InterestedResourceNames__c.substring(0, 252)+'...';                
            }
            serviceAppointmentsToUpdate.add(serviceAppointment);
        }
        update serviceAppointmentsToUpdate;
    }


    /*public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        // Creates map to be used in query of InterestedResources
        Map<Id, Id> interestedResourceIdByServiceAppointmentId = new Map<Id, Id>();
        for (HOT_InterestedResource__c interestedResource : (List<HOT_InterestedResource__c>) records) {
            if (interestedResource.Id == triggerOldMap.get(interestedResource.Id).get('Id') && interestedResource.Status__c == 'Interested') {
                    interestedResourceIdByServiceAppointmentId.put(
                        interestedResource.ServiceAppointment__c,
                        interestedResource.ServiceResource__c);
            }
        }

        // Fetches possible matches with Interested Resources
        List<HOT_InterestedResource__c> allInterestedResources = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE
                ServiceAppointment__c IN :interestedResourceIdByServiceAppointmentId.keySet()
                AND ServiceResource__c IN :interestedResourceIdByServiceAppointmentId.values()
        ];

        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_InterestedResourceNames__c
            FROM ServiceAppointment
            WHERE Id IN :interestedResourceIdByServiceAppointmentId.keySet()
        ];
        
        List<ServiceResource> serviceResources = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE Id IN :interestedResourceIdByServiceAppointmentId.values()
        ];
       
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            for (ServiceResource serviceResource : serviceResources) {
                if (serviceResource.Id == serviceAppointment.HOT_ServiceResource__c)
            }
        }        
    }*/
}
