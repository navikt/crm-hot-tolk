public without sharing class HOT_KrrCalloutQueuable implements Queueable, Database.AllowsCallouts {
    private List<HOT_Request__c> requests;

    public HOT_KrrCalloutQueuable(List<HOT_Request__c> requests) {
        this.requests = [SELECT Id, Person__c, Person__r.Name FROM HOT_Request__c WHERE Id IN :requests];
    }

    public void execute(QueueableContext context) {
        Map<String, Id> personIdByPersonalNumber = new Map<String, Id>();
        for (HOT_Request__c request : requests) {
            personIdByPersonalNumber.put(String.valueOf(request.Person__r.Name), request.Person__c);
        }

        try {
            Map<String, KRRCalloutService.Personer> krrResponseByPersonalNumber = new Map<String, KRRCalloutService.Personer>();
            for (
                KRRCalloutService.Personer person : KrrCalloutService.doPersonOppslag(
                    new List<String>(personIdByPersonalNumber.keySet())
                )
            ) {
                krrResponseByPersonalNumber.put(person.personidentifikator, person);
            }
            List<Person__c> personsToUpdate = new List<Person__c>();
            for (String personalNumber : personIdByPersonalNumber.keySet()) {
                if (krrResponseByPersonalNumber.containsKey(personalNumber)) {
                    // Initialize related Person record and set audit fields
                    Person__c person = new Person__c();
                    person.Id = personIdByPersonalNumber.get(personalNumber);
                    person.INT_LastUpdatedFromKRR__c = System.now();
                    person.INT_KrrIntegrationStatus__c = 'Completed';

                    // Map contact information fields if they were returned by krr
                    if (krrResponseByPersonalNumber.get(personalNumber).kontaktinformasjon != null) {
                        if (krrResponseByPersonalNumber.get(personalNumber).kontaktinformasjon.epostadresse != null) {
                            person.INT_KrrEmail__c = krrResponseByPersonalNumber.get(personalNumber)
                                .kontaktinformasjon.epostadresse;
                        }
                        if (
                            krrResponseByPersonalNumber.get(personalNumber).kontaktinformasjon.mobiltelefonnummer !=
                            null
                        ) {
                            person.INT_KrrMobilePhone__c = krrResponseByPersonalNumber.get(personalNumber)
                                .kontaktinformasjon.mobiltelefonnummer;
                        }
                    }
                    personsToUpdate.add(person);
                }
            }
            update personsToUpdate;
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            List<Person__c> personsToUpdate = new List<Person__c>();
            for (Id personId : personIdByPersonalNumber.values()) {
                Person__c person = new Person__c();
                person.Id = personId;
                person.INT_LastUpdatedFromKRR__c = System.now();
                person.INT_KrrIntegrationStatus__c = 'Failed';
                personsToUpdate.add(person);
            }
            update personsToUpdate;
        }
    }
}
