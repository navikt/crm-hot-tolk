List<Person__c> persons = [SELECT Id, INT_MunicipalityNumber__c FROM Person__c];

if (persons.isEmpty()) {
    for (Person__c p : persons) {
        p.INT_MunicipalityNumber__c = '1822';
        p.INT_RegionNumber__c = '18';
    }
    update persons;
}
