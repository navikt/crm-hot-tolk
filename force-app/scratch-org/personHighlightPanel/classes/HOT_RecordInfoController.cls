public with sharing class HOT_RecordInfoController {
    /**
     * @description
     * @param parentId [Id of the object to query to relation from]
     * @param relationshipField [API name of lookup field]
     * @param objectApiName [API name of parent]
     * @return sObject
     **/
    @AuraEnabled(cacheable=true)
    public static sObject getRelatedRecord(String parentId, String relationshipField, String objectApiName) {
        return getReverseRelatedRecord(parentId, relationshipField, objectApiName, 'Id', null)[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getReverseRelatedRecord(
        String parentId,
        string queryFields,
        string objectApiName,
        string relationshipField
    ) {
        return getReverseRelatedRecord(parentId, queryFields, objectApiName, relationshipField, null);
    }
    private static List<SObject> getReverseRelatedRecord(
        String parentId,
        string queryFields,
        string objectApiName,
        string relationshipField,
        string ordering
    ) {
        String query =
            'SELECT ' +
            queryFields +
            ' FROM ' +
            objectApiName +
            ' WHERE ' +
            relationshipField +
            '=\'' +
            parentId +
            '\'';
        if (ordering != null) {
            query += ' ORDER BY ' + ordering;
        } else {
            query += ' ORDER BY Id';
        }
        return Database.query(query);
    }
}
