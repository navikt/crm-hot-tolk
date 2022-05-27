@isTest
public class HOT_ReferenceUtil_Test {
    @isTest
    static void testReferenceGeneration() {
        String ref = HOT_ReferenceUtil.generateReference(new Account());

        System.assert(ref.contains(Account.getSObjectType().getDescribe().getKeyPrefix()));
    }

    @isTest
    static void testGetObjectName() {
        String ref = HOT_ReferenceUtil.generateReference(new Account());

        System.assertEquals('Account', HOT_ReferenceUtil.getObjectNameFromIdPrefix(ref.substring(0, 3)));
    }
}
