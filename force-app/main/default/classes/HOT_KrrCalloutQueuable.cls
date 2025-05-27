public without sharing class HOT_KrrCalloutQueuable implements Queueable, Database.AllowsCallouts {
    private List<HOT_Request__c> requests;
    private class KRRException extends Exception {
    }

    public HOT_KrrCalloutQueuable(List<HOT_Request__c> requests) {
        this.requests = [
            SELECT Id, Person__c, Person__r.Name, Person__r.HOT_KrrIntegrationErrorCounter__c
            FROM HOT_Request__c
            WHERE Id IN :requests
        ];
    }

    public void execute(QueueableContext context) {
        Map<String, Id> personIdByPersonalNumber = new Map<String, Id>();
        Map<Id, Person__c> personByPersonId = new Map<Id, Person__c>();
        CRM_DatabaseOperations cdo = new CRM_DatabaseOperations();
        cdo.setDomain(CRM_ApplicationDomain.Domain.HOT);
        for (HOT_Request__c request : requests) {
            personIdByPersonalNumber.put(String.valueOf(request.Person__r.Name), request.Person__c);
            personByPersonId.put(request.Person__c, request.Person__r);
        }

        try {
            if (personIdByPersonalNumber.size() == 0) {
                throw new KRRException('(HOT) personIdByPersonalNumber was empty.');
            }
            Map<String, KRRCalloutService.Person> krrResponseByPersonalNumber = new Map<String, KRRCalloutService.Person>();
            List<String> personNumbers = new List<String>(personIdByPersonalNumber.keySet());
            KrrCalloutService krrService = new KrrCalloutService();
            KrrCalloutService.KrrResponse personResponse = krrService.getPersons(personNumbers, true);

            // Line #34 might be irrelevant after we switced to getPersons.
            // KrrCalloutService.doPersonOppslag() fails in 25% of cases. We are rerunning the Callout, to see if there are some irregularities with the integration
            if (personResponse == null || personResponse.personer == null) {
                throw new KRRException('(HOT) KrrCalloutService.getPersons return null.');
            }
      
            Map<String, KrrCalloutService.Person> krrResponseByPersonalNumber = response.personer;

            List<Person__c> personsToUpdate = new List<Person__c>();
            for (String personalNumber : personIdByPersonalNumber.keySet()) {
                KrrCalloutService.Person p = krrResponseByPersonalNumber.get(personalNumber);
                if (p != null) {
                    Person__c person = new Person__c();
                    person.Id = personIdByPersonalNumber.get(personalNumber);
                    person.INT_LastUpdatedFromKRR__c = System.now();
                    person.INT_KrrIntegrationStatus__c = 'Completed';
                    person.HOT_KrrIntegrationErrorCounter__c = 0;
    
                    if (p.epostadresse != null)
                        person.INT_KrrEmail__c = p.epostadresse;
                    if (p.mobiltelefonnummer != null)
                        person.INT_KrrMobilePhone__c = p.mobiltelefonnummer;
    
                    personsToUpdate.add(person);
                }
            }
            cdo.updateRecords(personsToUpdate);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, requests[0], CRM_ApplicationDomain.Domain.HOT);
            logger.publish();
    
            List<Person__c> personsToUpdate = new List<Person__c>();
            for (Id personId : personIdByPersonalNumber.values()) {
                Person__c person = new Person__c();
                person.Id = personId;
                person.INT_LastUpdatedFromKRR__c = System.now();
                person.INT_KrrIntegrationStatus__c = 'Failed';
                Decimal errorCounter = personByPersonId.get(personId).HOT_KrrIntegrationErrorCounter__c;
                person.HOT_KrrIntegrationErrorCounter__c = errorCounter != null ? errorCounter + 1 : 1;
                personsToUpdate.add(person);
            }
            cdo.updateRecords(personsToUpdate);
        }
}
