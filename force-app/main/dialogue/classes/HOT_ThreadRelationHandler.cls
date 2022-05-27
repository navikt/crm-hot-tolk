public without sharing class CRM_ThreadRelationHandler extends MyTriggers {
    public override void onBeforeInsert() {
        for (Thread__c thread : (List<Thread__c>) Records) {
            if (String.isNotBlank(thread.CRM_Related_Object__c)) {
                thread.CRM_Related_Object_Type__c = getObjectType(thread.CRM_Related_Object__c);
            }
        }
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        for (Thread__c thread : (List<Thread__c>) Records) {
            if (String.isNotBlank(thread.CRM_Related_Object__c)) {
                thread.CRM_Related_Object_Type__c = getObjectType(thread.CRM_Related_Object__c);
            }
        }
    }

    /**
     * @description: Returns the Object API Name based on a input ID. If ID is not a valid
     * SF Id or anything fails, the method returns null
     * @author Stian Ruud Schikora | 01-25-2022
     * @param objIdString
     * @return String
     **/
    public String getObjectType(String objIdString) {
        String objType;
        try {
            Id objId = (Id) objIdString;
            objType = objId?.getSobjectType()?.getDescribe()?.getName();
        } catch (Exception ex) {
            //Error during Id casting
        }
        return objType;
    }
}
