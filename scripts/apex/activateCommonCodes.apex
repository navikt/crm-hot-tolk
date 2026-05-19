List<Common_Code__c> commonCode = [
    SELECT Id, CRM_Active__c
    FROM Common_Code__c
    WHERE CRM_Code_Set__c = 'Kommune' OR CRM_Code_Set__c = 'Fylke'
];

if (!commonCode.isEmpty()) {
    for (Common_Code__c cc : commonCode) {
        cc.CRM_Active__c = true;
    }
    update commonCode;
}
