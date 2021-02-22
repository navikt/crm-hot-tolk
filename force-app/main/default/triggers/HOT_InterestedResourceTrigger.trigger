trigger HOT_InterestedResourceTrigger on HOT_InterestedResource__c(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    System.debug('InterestedResourceTrigger: ' + Trigger.operationType);
    MyTriggers.run();
}
