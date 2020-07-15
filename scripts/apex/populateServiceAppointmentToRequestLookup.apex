List<ServiceAppointment> serviceAppointments = [SELECT Id, ParentRecordId, HOT_Request__c FROM ServiceAppointment WHERE HOT_Request__c = null];
Map<Id, ServiceAppointment> IdtoSA = new Map<Id, ServiceAppointment>();
for(ServiceAppointment sa:serviceAppointments){
    IdtoSA.put(sa.Id, sa);
}

Map<Id, Id> SAtoWOLI = new Map<Id, Id>();
for(ServiceAppointment sa:serviceAppointments){
    SAtoWOLI.put(sa.Id, sa.ParentRecordId);
}
List<WorkOrderLineItem> workOrderLineItems = [SELECT Id, WorkOrderId FROM WorkOrderLineItem WHERE Id IN :SAtoWOLI.values()];
Map<Id, Id> WOLItoWO = new Map<Id, Id>();
for(WorkOrderLineItem woli:workOrderLineItems){
    WOLItoWO.put(woli.Id, woli.WorkOrderId);
}
List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c FROM WorkOrder WHERE Id IN :WOLItoWO.values()];
Map<Id, Id> WOtoRequest = new Map<Id, Id>();
for(WorkOrder wo:workOrders){
    WOtoRequest.put(wo.Id, wo.HOT_Request__c);
}
List<HOT_Request__c> requests = [SELECT Id, AssignmentType__c, IsAcute__c, Status__c        
                                 FROM HOT_Request__c WHERE Id IN :WOtoRequest.values()];

Map<Id, HOT_Request__c> requestMap = new Map<Id, HOT_Request__c>();
for(HOT_Request__c req:requests){
    requestMap.put(req.Id, req);
}

Map<Id, HOT_Request__c> SAIdtoRequest = new Map<Id, HOT_Request__c>();
for(Id saId:SAtoWOLI.keySet()){
    SAIdtoRequest.put(saId, requestMap.get(WOtoRequest.get(WOLItoWO.get(SAtoWOLI.get(saId)))));
}

for(Id saId:SAIdtoRequest.keySet()){
    IdtoSA.get(saId).HOT_Request__c = SAIdtoRequest.get(saId).Id;
}
update IdtoSA.values();