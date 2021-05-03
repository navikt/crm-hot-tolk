trigger WorkOrderLineItemTrigger on WorkOrderLineItem(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    System.debug('WorkOrderLineItemTrigger: ' + Trigger.operationType);
    if (!FeatureManagement.checkPermission('RunWithoutTrigger')) {
        MyTriggers.run();
    }

}
