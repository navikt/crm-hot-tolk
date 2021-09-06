trigger HOT_ContentDocumentLinkTrigger on ContentDocumentLink(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    System.debug('ServiceAppointmentTrigger: ' + Trigger.operationType);
    MyTriggers.run();

}
