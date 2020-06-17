trigger ServiceResourceTrigger on ServiceResource (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    System.debug('ServiceResourceTrigger: ' + Trigger.operationType);
    MyTriggers.run();
    
}