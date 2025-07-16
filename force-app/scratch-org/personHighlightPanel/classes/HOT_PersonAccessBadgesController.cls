public without sharing class HOT_PersonAccessBadgesController {
    /**
     * @description Get an apex type holding all the data we need for showing badges.
     */
    @AuraEnabled(cacheable=true)
    public static List<AccessBadge> getPersonAccessBadges(String field, String parentObject, String parentRecordId) {
        Id personId = getPersonId(field, parentObject, parentRecordId);

        if (String.isBlank(personId)) {
            return new List<AccessBadge>();
        }

        Person__c person = getPerson(personId);
        return createAccessBadgeList(person);
    }

    private static List<AccessBadge> createAccessBadgeList(Person__c person) {
        List<AccessBadge> accessBadgeList = new List<AccessBadge>();
        // Add INT_IsNavEmployee__c
        if (person.INT_IsNavEmployee__c) {
            accessBadgeList.add(new AccessBadge('isNavEmployee', 'Skjermet person (Nav Ansatt)'));
        }

        // Add INT_Confidential__c
        // prettier-ignore
        if (true == person.INT_Confidential__c.equalsIgnoreCase('FORTROLIG')) {
            accessBadgeList.add(new AccessBadge('isConfidential', 'Skjermet adresse - fortrolig'));
        } else if (true == person.INT_Confidential__c.equalsIgnoreCase('STRENGT_FORTROLIG')) {
            accessBadgeList.add(new AccessBadge('isConfidential', 'Skjermet adresse - strengt fortrolig'));
        } else if (
            true == person.INT_Confidential__c.equalsIgnoreCase('STRENGT_FORTROLIG_UTLAND')
        ) {
            accessBadgeList.add(new AccessBadge('isConfidential', 'Skjermet adresse - strengt fortrolig'));
        }
        return accessBadgeList;
    }

    /**
     * @description Dynamically find the person ID
     * *Example
     * - field = 'Account.CRM_Person__c';
     * - objString = 'Case';
     * - recordId = '5001X000007xMSuQAM';
     * - relation = 'Id';
     */
    private static Id getPersonId(String field, String parentObject, String parentRecordId) {
        Id personId = null;
        String queryString = 'SELECT ' + field + ' FROM ' + parentObject + ' WHERE Id = :parentRecordId LIMIT 1';
        List<SObject> objList = Database.query(String.escapeSingleQuotes(queryString));

        if (false == objList.isEmpty()) {
            personId = (Id) getFieldValue(objList[0], field);
        }

        return personId;
    }

    /**
     * @description recursive method for collecting the value of a field on a sObject
     */
    private static Object getFieldValue(SObject obj, String fieldName) {
        if (obj == null) {
            return null;
        }
        List<String> fieldNameList = fieldName.split('\\.');

        if (1 < fieldNameList.size()) {
            return getFieldValue(obj.getSObject(fieldNameList.remove(0)), String.join(fieldNameList, '.'));
        }

        return obj.get(fieldNameList[0]);
    }

    private static Person__c getPerson(Id personId) {
        List<Person__c> personList = [
            SELECT Id, INT_Confidential__c, INT_IsNavEmployee__c
            FROM Person__c
            WHERE Id = :personId
        ];

        return personList.isEmpty() ? null : personList[0];
    }

    public class AccessBadge {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String label;

        public AccessBadge(String name, String label) {
            this.name = name;
            this.label = label;
        }
    }
}