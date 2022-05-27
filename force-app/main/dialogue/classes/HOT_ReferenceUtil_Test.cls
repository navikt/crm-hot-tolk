@isTest
public class CRM_ReferenceUtil_Test {
    @isTest
    static void testReferenceGeneration() {
        String ref = CRM_ReferenceUtil.generateReference(new Account());

        System.assert(ref.contains(Account.getSObjectType().getDescribe().getKeyPrefix()));
    }

    @isTest
    static void testGetObjectName() {
        String ref = CRM_ReferenceUtil.generateReference(new Account());

        System.assertEquals('Account', CRM_ReferenceUtil.getObjectNameFromIdPrefix(ref.substring(0, 3)));
    }
}
