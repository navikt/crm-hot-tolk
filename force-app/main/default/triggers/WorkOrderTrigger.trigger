trigger WorkOrderTrigger on WorkOrder(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    System.debug('WorkOrderTrigger: ' + Trigger.operationType);
    if (!FeatureManagement.checkPermission('RunWithoutTrigger')) {
        MyTriggers.run();
    }

}
