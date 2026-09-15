List<String> testLabels = new List<String>{
    'AKSEPTANSETEST - ENKEL',
    'AKSEPTANSETEST - BULK 1',
    'AKSEPTANSETEST - BULK 2',
    'AKSEPTANSETEST - BULK 3',
    'AKSEPTANSETEST - BULK 4'
};
Datetime currentTime = System.now();

List<SObject> seedAppointments = Database.query(
    'SELECT ParentRecordId, HOT_WorkOrderLineItem__c, ServiceTerritoryId, ' +
        'Duration, DurationType, HOT_Request__c ' +
        'FROM ServiceAppointment ' +
        'WHERE HOT_WorkOrderLineItem__c != NULL ' +
        'AND HOT_Request__c != NULL ' +
        'ORDER BY CreatedDate ASC LIMIT 1'
);
SObject seedAppointment = seedAppointments[0];

Map<String, SObject> activeAppointmentByLabel = new Map<String, SObject>();
for (SObject appointment : Database.query(
    'SELECT Id, HOT_FreelanceSubject__c FROM ServiceAppointment ' +
        'WHERE HOT_FreelanceSubject__c IN :testLabels ' +
        'AND Status = \'Released to Freelance\' ' +
        'AND HOT_IsReleasedToFreelance__c = TRUE ' +
        'AND HOT_TjenesteleverandorStatus__c = \'Transferred\' ' +
        'AND HOT_TjenesteleverandorDeadline__c > :currentTime'
)) {
    activeAppointmentByLabel.put((String) appointment.get('HOT_FreelanceSubject__c'), appointment);
}

Schema.SObjectType appointmentType = Schema.getGlobalDescribe().get('ServiceAppointment');
Datetime firstStart = currentTime.addDays(14);
List<SObject> appointmentsToInsert = new List<SObject>();
for (Integer index = 0; index < testLabels.size(); index++) {
    String testLabel = testLabels[index];
    if (activeAppointmentByLabel.containsKey(testLabel)) {
        continue;
    }

    Datetime appointmentStart = firstStart.addDays(index);
    SObject appointment = appointmentType.newSObject();
    appointment.put('ParentRecordId', seedAppointment.get('ParentRecordId'));
    appointment.put('HOT_WorkOrderLineItem__c', seedAppointment.get('HOT_WorkOrderLineItem__c'));
    appointment.put('ServiceTerritoryId', seedAppointment.get('ServiceTerritoryId'));
    appointment.put('Duration', seedAppointment.get('Duration'));
    appointment.put('DurationType', seedAppointment.get('DurationType'));
    appointment.put('HOT_Request__c', seedAppointment.get('HOT_Request__c'));
    appointment.put('Status', 'None');
    appointment.put('EarliestStartTime', appointmentStart);
    appointment.put('DueDate', appointmentStart.addHours(1));
    appointment.put('Subject', testLabel);
    appointment.put('HOT_FreelanceSubject__c', testLabel);
    appointmentsToInsert.add(appointment);
}

if (!appointmentsToInsert.isEmpty()) {
    insert appointmentsToInsert;

    for (SObject appointment : appointmentsToInsert) {
        appointment.put('Status', 'Released to Freelance');
        appointment.put('HOT_IsReleasedToFreelance__c', true);
        appointment.put('HOT_ReleasedBy__c', 'Akseptansetest');
        appointment.put('HOT_ReleaseDate__c', Date.today());
    }
    update appointmentsToInsert;
}

List<SObject> activeAppointments = Database.query(
    'SELECT Id, AppointmentNumber, Status, HOT_FreelanceSubject__c, ' +
        'HOT_IsReleasedToFreelance__c, HOT_TjenesteleverandorStatus__c, ' +
        'HOT_TjenesteleverandorTransferDate__c, HOT_TjenesteleverandorDeadline__c, ' +
        'EarliestStartTime, DueDate FROM ServiceAppointment ' +
        'WHERE HOT_FreelanceSubject__c IN :testLabels ' +
        'AND Status = \'Released to Freelance\' ' +
        'AND HOT_IsReleasedToFreelance__c = TRUE ' +
        'ORDER BY EarliestStartTime'
);

Datetime acceptanceDeadline = currentTime.addDays(10);
for (SObject appointment : activeAppointments) {
    if ((String) appointment.get('HOT_TjenesteleverandorStatus__c') != 'Transferred') {
        appointment.put('HOT_TjenesteleverandorStatus__c', 'Transferred');
        appointment.put('HOT_TjenesteleverandorTransferDate__c', currentTime);
    }
    appointment.put('HOT_TjenesteleverandorDeadline__c', acceptanceDeadline);
}
update activeAppointments;

List<SObject> supplierGroups = Database.query(
    'SELECT Id FROM Group WHERE Name = \'HOT Tolk Tjenesteleverandør\' AND Type = \'Regular\' LIMIT 1'
);
Id supplierGroupId = (Id) supplierGroups[0].get('Id');

Set<Id> appointmentIds = new Set<Id>();
for (SObject appointment : activeAppointments) {
    appointmentIds.add((Id) appointment.get('Id'));
}

Set<Id> alreadySharedAppointmentIds = new Set<Id>();
for (SObject appointmentShare : Database.query(
    'SELECT ParentId FROM ServiceAppointmentShare ' +
        'WHERE ParentId IN :appointmentIds AND UserOrGroupId = :supplierGroupId'
)) {
    alreadySharedAppointmentIds.add((Id) appointmentShare.get('ParentId'));
}

Schema.SObjectType appointmentShareType = Schema.getGlobalDescribe().get('ServiceAppointmentShare');
List<SObject> sharesToInsert = new List<SObject>();
for (Id appointmentId : appointmentIds) {
    if (!alreadySharedAppointmentIds.contains(appointmentId)) {
        SObject appointmentShare = appointmentShareType.newSObject();
        appointmentShare.put('ParentId', appointmentId);
        appointmentShare.put('UserOrGroupId', supplierGroupId);
        appointmentShare.put('AccessLevel', 'Read');
        appointmentShare.put('RowCause', 'Manual');
        sharesToInsert.add(appointmentShare);
    }
}
if (!sharesToInsert.isEmpty()) {
    insert sharesToInsert;
}

System.debug(
    LoggingLevel.ERROR,
    'Created or reused acceptance test appointments: ' +
        Database.query(
            'SELECT Id, AppointmentNumber, HOT_FreelanceSubject__c, EarliestStartTime, ' +
                'HOT_TjenesteleverandorDeadline__c FROM ServiceAppointment ' +
                'WHERE Id IN :appointmentIds ORDER BY EarliestStartTime'
        )
);
