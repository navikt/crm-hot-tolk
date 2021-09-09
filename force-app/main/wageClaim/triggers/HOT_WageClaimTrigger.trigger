trigger HOT_WageClaimTrigger on HOT_WageClaim__c(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    System.debug('WageClaimTrigger: ' + Trigger.operationType);
    MyTriggers.run();

}
