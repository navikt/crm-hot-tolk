trigger AssignedResourceTrigger on AssignedResource(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    if (!FeatureManagement.checkPermission('RunWithoutTrigger')) {
        MyTriggers.run();
    }
}
