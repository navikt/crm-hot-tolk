trigger WorkOrderLineItemTrigger on WorkOrderLineItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

	MyTriggers.run();
	
}