trigger HOT_RequestTrigger on HOT_Request__c(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    System.debug('RequestTrigger: ' + Trigger.operationType);
    MyTriggers.run();

}
