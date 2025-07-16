public without sharing class HOT_AccessErrorController {
    @AuraEnabled
    public static String checkAccess(String field, String parentObject, String parentRecordId) {
        Id personId = getPersonId(field, parentObject, parentRecordId);
        if (personId == null) {
            // This would only happen if case does not have related person for phone
            return null;
        }
        Person__c person = getPerson(personId);
        Boolean hasAccess = hasAccess(personId);

        if (accountNameSetToNotAvailable(person) && !hasAccess) {
            return 'Du mangler tilgang til å se informasjon knyttet til denne brukeren';
        }

        return null;
    }

    private static Person__c getPerson(Id personId) {
        List<Person__c> personList = [SELECT Id, CRM_Account__r.Name FROM Person__c WHERE Id = :personId];

        return personList.isEmpty() ? null : personList[0];
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

        if (!objList.isEmpty()) {
            personId = (Id) getFieldValue(objList[0], field);
        }

        return personId;
    }

    /**
     * @description recursive method for collecting the value of a field on a sObject
     */
    private static Object getFieldValue(SObject obj, String fieldName) {
        List<String> fieldNameList = fieldName.split('\\.');

        if (fieldNameList.size() > 1) {
            SObject nestedObj = obj.getSObject(fieldNameList.remove(0));
            if (nestedObj == null) {
                return null;
            }
            return getFieldValue(nestedObj, String.join(fieldNameList, '.'));
        }

        return obj.get(fieldNameList[0]);
    }
    @AuraEnabled
    public static Boolean hasAccess(Id recordId) {
        List<UserRecordAccess> result = [
            SELECT RecordID, HasReadAccess
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId() AND RecordID = :recordId
        ];

        return result.isEmpty() ? false : result[0].HasReadAccess;
    }

    private static Boolean accountNameSetToNotAvailable(Person__c person) {
        return person?.CRM_Account__r?.Name.equalsIgnoreCase('skjermet');
    }
}
