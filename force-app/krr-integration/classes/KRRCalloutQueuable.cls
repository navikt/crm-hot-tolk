public with sharing class KRRCalloutQueuable implements Queueable, Database.AllowsCallouts {

    private List<HOT_Request__c> requests;

    public KRRCalloutQueuable(List<HOT_Request__c> requests) {
        this.requests = requests;
    }

    public void execute(QueueableContext context) {
        Map<String, Id> personIdByPersonalNumber = new Map<String, Id>();
        for (HOT_Request__c request : requests) {
            personIdByPersonalNumber.put(String.valueOf(request.PersonalNumber__c), request.Person__c);
        }


        try {
            Map<String, KRRCalloutService.Personer> krrResponseByPersonalNumber = new Map<String, KRRCalloutService.Personer>();
            for (KRRCalloutService.Personer person : KRRCalloutService.doPersonOppslag(new List<String>(personIdByPersonalNumber.keySet()))) {
                krrResponseByPersonalNumber.put(person.personidentifikator, person);
            }
            List<Person__c> personsToUpdate = new List<Person__c>();
            for (String personalNumber : personIdByPersonalNumber.keySet()) {
                if (krrResponseByPersonalNumber.containsKey(personalNumber)) {
                    // Initialize related Person record and set audit fields
                    Person__c person = new Person__c();
                    person.Id = personIdByPersonalNumber.get(personalNumber);
                    person.INT_LastUpdatedFromKRR__c = System.now();
                    person.INT_KRRIntegrationStatus__c = 'Completed';

                    // Map contact information fields if they were returned by krr
                    if (krrResponseByPersonalNumber.get(personalNumber).kontaktinformasjon != null) {
                        if (krrResponseByPersonalNumber.get(personalNumber).kontaktinformasjon.epostadresse != null) {
                            person.INT_Email__c = krrResponseByPersonalNumber.get(personalNumber).kontaktinformasjon.epostadresse;
                        }
                        if (krrResponseByPersonalNumber.get(personalNumber).kontaktinformasjon.mobiltelefonnummer != null) {
                            person.INT_MobilePhone__c = krrResponseByPersonalNumber.get(personalNumber).kontaktinformasjon.mobiltelefonnummer;
                        }
                    }
                    personsToUpdate.add(person);
                }
            }
            update personsToUpdate;
        } catch (Exception e) {
            System.debug('Catching!');
            List<Person__c> personsToUpdate = new List<Person__c>();
            for (Id personId : personIdByPersonalNumber.values()) {
                Person__c person = new Person__c();
                person.Id = personId;
                person.INT_LastUpdatedFromKRR__c = System.now();
                person.INT_KRRIntegrationStatus__c = 'Failed';
                personsToUpdate.add(person);
            }
            update personsToUpdate;
        }
    }

}