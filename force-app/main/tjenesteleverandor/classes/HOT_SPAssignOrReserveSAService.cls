public without sharing class HOT_SPAssignOrReserveSAService {
    private static final Set<String> SUPPORTED_SOURCE_STATUSES = new Set<String>{ 'None', 'Released to Freelance' };
    private static final Set<String> SUPPORTED_TARGET_STATUSES = new Set<String>{ 'Scheduled', 'Dispatched' };

    public class Input {
        @InvocableVariable(required=true label='Service Appointment Id')
        public Id serviceAppointmentId;

        @InvocableVariable(required=true label='Service Resource Id')
        public Id serviceResourceId;

        @InvocableVariable(required=true label='Target Status')
        public String targetStatus;
    }

    public class Result {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Service Appointment Id')
        public Id serviceAppointmentId;

        public Result(Input req) {
            this.success = false;
            this.message = 'Ingen handling ble utført.';
            this.serviceAppointmentId = req != null ? req.serviceAppointmentId : null;
        }
    }

    @InvocableMethod(
        label='Assign or Reserve Service Provider Appointment'
        description='Assigns or reserves an active freelance interpreter after the service provider has accepted the appointment.'
        category='HOT Tolketjeneste'
        iconName='slds:standard:service_appointment'
    )
    public static List<Result> assignOrReserve(List<Input> reqs) {
        return new HOT_SPAssignOrReserveSAService(reqs).process();
    }

    private List<Input> reqs;
    private List<Result> results;
    private Set<Id> serviceAppointmentIds;
    private Set<Id> serviceResourceIds;
    private Map<Id, ServiceAppointment> serviceAppointmentsById;
    private Map<Id, ServiceResource> serviceResourcesById;
    private Map<Id, List<AssignedResource>> assignedResourcesByServiceAppointmentId;

    public HOT_SPAssignOrReserveSAService(List<Input> reqs) {
        this.reqs = reqs;
        this.results = new List<Result>();
        this.serviceAppointmentIds = new Set<Id>();
        this.serviceResourceIds = new Set<Id>();
        this.assignedResourcesByServiceAppointmentId = new Map<Id, List<AssignedResource>>();
    }

    public List<Result> process() {
        if (this.reqs == null || this.reqs.isEmpty()) {
            return this.results;
        }

        for (Input req : this.reqs) {
            this.results.add(new Result(req));
            if (req == null) {
                continue;
            }
            if (req.serviceAppointmentId != null) {
                this.serviceAppointmentIds.add(req.serviceAppointmentId);
            }
            if (req.serviceResourceId != null) {
                this.serviceResourceIds.add(req.serviceResourceId);
            }
        }
        loadData();
        for (Integer i = 0; i < this.reqs.size(); i++) {
            processRequest(this.reqs[i], this.results[i]);
        }
        return this.results;
    }

    private void loadData() {
        this.serviceAppointmentsById = this.serviceAppointmentIds.isEmpty()
            ? new Map<Id, ServiceAppointment>()
            : new Map<Id, ServiceAppointment>(
                  [
                      SELECT
                          Id,
                          Status,
                          HOT_ServiceResource__c,
                          HOT_AssignedResourceId__c,
                          HOT_TjenesteleverandorStatus__c
                      FROM ServiceAppointment
                      WHERE Id IN :this.serviceAppointmentIds
                      FOR UPDATE
                  ]
              );
        this.serviceResourcesById = this.serviceResourceIds.isEmpty()
            ? new Map<Id, ServiceResource>()
            : new Map<Id, ServiceResource>(
                  [
                      SELECT Id, RelatedRecordId, IsActive, HOT_IsFreelanceInterpreter__c
                      FROM ServiceResource
                      WHERE Id IN :this.serviceResourceIds
                  ]
              );
        if (this.serviceAppointmentIds.isEmpty()) {
            return;
        }
        for (AssignedResource assignedResource : [
            SELECT Id, ServiceAppointmentId, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :this.serviceAppointmentIds
        ]) {
            if (!this.assignedResourcesByServiceAppointmentId.containsKey(assignedResource.ServiceAppointmentId)) {
                this.assignedResourcesByServiceAppointmentId.put(
                    assignedResource.ServiceAppointmentId,
                    new List<AssignedResource>()
                );
            }
            this.assignedResourcesByServiceAppointmentId.get(assignedResource.ServiceAppointmentId)
                .add(assignedResource);
        }
    }

    private void processRequest(Input req, Result result) {
        Savepoint assignmentSavepoint;
        try {
            validateRequest(req);
            ServiceAppointment serviceAppointment = this.serviceAppointmentsById.get(req.serviceAppointmentId);
            if (serviceAppointment == null) {
                throw new FlowHandledException('Oppdraget ble ikke funnet.');
            }
            ServiceResource serviceResource = this.serviceResourcesById.get(req.serviceResourceId);
            if (serviceResource == null) {
                throw new FlowHandledException('Valgt tolk ble ikke funnet.');
            }
            List<AssignedResource> existingAssignedResources = this.assignedResourcesByServiceAppointmentId.get(
                req.serviceAppointmentId
            );
            Boolean dispatchingReservation =
                serviceAppointment.Status == 'Scheduled' &&
                req.targetStatus == 'Dispatched';
            if (dispatchingReservation) {
                if (
                    existingAssignedResources == null ||
                    existingAssignedResources.size() != 1 ||
                    existingAssignedResources[0].ServiceResourceId != req.serviceResourceId
                ) {
                    throw new FlowHandledException(
                        'Den reserverte tolken finnes ikke eller er endret. Last inn oppdraget på nytt.'
                    );
                }
            } else {
                validateServiceAppointment(serviceAppointment, existingAssignedResources);
            }
            if (serviceAppointment.HOT_TjenesteleverandorStatus__c != 'Accepted') {
                throw new FlowHandledException('Oppdraget må være akseptert av tjenesteleverandør.');
            }
            if (!serviceResource.HOT_IsFreelanceInterpreter__c || !serviceResource.IsActive) {
                throw new FlowHandledException('Du må velge en aktiv tolk.');
            }
            assignmentSavepoint = Database.setSavepoint();
            if (dispatchingReservation) {
                update new ServiceAppointment(Id = serviceAppointment.Id, Status = req.targetStatus);
            } else {
                AssignedResource assignedResource = new AssignedResource(
                    ServiceAppointmentId = req.serviceAppointmentId,
                    ServiceResourceId = req.serviceResourceId
                );
                insert assignedResource;
                update new ServiceAppointment(
                    Id = serviceAppointment.Id,
                    Status = req.targetStatus,
                    HOT_ServiceResource__c = serviceResource.Id,
                    HOT_AssignedResourceId__c = serviceResource.RelatedRecordId
                );
            }
            serviceAppointment.Status = req.targetStatus;
            result.success = true;
            result.message = req.targetStatus == 'Dispatched'
                ? 'Tolken ble tildelt oppdraget.'
                : 'Tolken ble reservert til oppdraget.';
        } catch (Exception ex) {
            if (assignmentSavepoint != null) {
                Database.rollback(assignmentSavepoint);
            }
            result.message = ex.getMessage();
        } finally {
            if (assignmentSavepoint != null) {
                Database.releaseSavepoint(assignmentSavepoint);
            }
        }
    }

    private static void validateRequest(Input req) {
        if (req == null) {
            throw new FlowHandledException('Ingen input ble sendt til handlingen.');
        }
        if (req.serviceAppointmentId == null) {
            throw new FlowHandledException('Oppdrag mangler.');
        }
        if (req.serviceResourceId == null) {
            throw new FlowHandledException('Du må velge en tolk.');
        }
        if (!SUPPORTED_TARGET_STATUSES.contains(req.targetStatus)) {
            throw new FlowHandledException('Ugyldig målstatus.');
        }
    }

    private static void validateServiceAppointment(
        ServiceAppointment serviceAppointment,
        List<AssignedResource> existingAssignedResources
    ) {
        if (!SUPPORTED_SOURCE_STATUSES.contains(serviceAppointment.Status)) {
            throw new FlowHandledException(
                'Denne handlingen kan bare brukes når oppdraget har status Åpen eller Frigitt til tolker. Nåværende status er ' +
                    serviceAppointment.Status +
                    '.'
            );
        }
        if (
            serviceAppointment.HOT_ServiceResource__c != null ||
            serviceAppointment.HOT_AssignedResourceId__c != null ||
            (existingAssignedResources != null && !existingAssignedResources.isEmpty())
        ) {
            throw new FlowHandledException(
                'Dette oppdraget har allerede en valgt tolk. Endring av eksisterende reservering eller tildeling må gjøres i standardprosessen.'
            );
        }
    }

    private class FlowHandledException extends Exception {
    }
}
