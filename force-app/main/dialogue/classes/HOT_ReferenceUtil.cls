global class CRM_ReferenceUtil {
    /**
     * @description: Generates a reference for an sObject on the form <ID_Prefix>_<15HEX_CHARS>
     * @author Stian Ruud Schikora | 10-04-2021
     * @param sObj
     * @return String
     **/
    global static String generateReference(SObject sObj) {
        Blob randomizer = Crypto.GenerateAESKey(128);
        String hexRef = EncodingUtil.ConvertTohex(randomizer);
        String objPrefix = sObj.getSObjectType().getDescribe().getKeyPrefix();

        return objPrefix + hexRef.substring(0, 15);
    }

    /**
     * @description: Return the object API name based on the three first chars of the id (ID prefix)
     * @author Stian Ruud Schikora | 10-04-2021
     * @param idPrefix
     * @return String
     **/
    global static String getObjectNameFromIdPrefix(String idPrefix) {
        String objectName;
        if (String.isBlank(idPrefix))
            return objectName;

        //Get schema information
        Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();

        for (Schema.SObjectType stype : globalDesc.values()) {
            Schema.DescribeSObjectResult objDescribe = stype.getDescribe();
            String prefix = objDescribe != null ? objDescribe.getKeyPrefix() : null;

            if (String.isNotBlank(prefix) && prefix.equals(idPrefix)) {
                objectName = objDescribe.getName();
                break;
            }
        }

        return objectName;
    }
}
