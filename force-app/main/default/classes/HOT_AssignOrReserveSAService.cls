public without sharing class HOT_AssignOrReserveSAService {
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
        label='Assign or Reserve Service Appointment'
        description='Creates the first assigned resource on a service appointment and sets it to Scheduled or Dispatched.'
        category='HOT Tolketjeneste'
        iconName='slds:standard:service_appointment'
    )
    public static List<Result> assignOrReserve(List<Input> reqs) {
        HOT_AssignOrReserveSAService service = new HOT_AssignOrReserveSAService(reqs);
        return service.process();
    }

    private List<Input> reqs;
    private List<Result> results;
    private Set<Id> serviceAppointmentIds;
    private Set<Id> serviceResourceIds;
    private Map<Id, ServiceAppointment> serviceAppointmentsById;
    private Map<Id, ServiceResource> serviceResourcesById;
    private Map<Id, List<AssignedResource>> assignedResourcesByServiceAppointmentId;

    public HOT_AssignOrReserveSAService(List<Input> reqs) {
        this.reqs = reqs;
        this.results = new List<Result>();
        this.serviceAppointmentIds = new Set<Id>();
        this.serviceResourceIds = new Set<Id>();
        this.assignedResourcesByServiceAppointmentId = new Map<Id, List<AssignedResource>>();
    }

    public List<Result> process() {
        initializeResults();

        if (this.reqs == null || this.reqs.isEmpty()) {
            return this.results;
        }

        collectIds();
        loadData();
        processRequests();

        return this.results;
    }

    private void initializeResults() {
        if (this.reqs == null) {
            return;
        }

        for (Input req : this.reqs) {
            this.results.add(new Result(req));
        }
    }

    private void collectIds() {
        for (Input req : this.reqs) {
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
    }

    private void loadData() {
        this.serviceAppointmentsById = this.serviceAppointmentIds.isEmpty()
            ? new Map<Id, ServiceAppointment>()
            : new Map<Id, ServiceAppointment>(
                  [
                      SELECT Id, Status, HOT_ServiceResource__c, HOT_AssignedResourceId__c
                      FROM ServiceAppointment
                      WHERE Id IN :this.serviceAppointmentIds
                  ]
              );

        this.serviceResourcesById = this.serviceResourceIds.isEmpty()
            ? new Map<Id, ServiceResource>()
            : new Map<Id, ServiceResource>(
                  [SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN :this.serviceResourceIds]
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

    private void processRequests() {
        for (Integer i = 0; i < this.reqs.size(); i++) {
            processRequest(this.reqs[i], this.results[i]);
        }
    }

    private void processRequest(Input req, Result result) {
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

            validateServiceAppointment(serviceAppointment, getAssignedResources(req.serviceAppointmentId));

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

            result.success = true;
            result.message = req.targetStatus == 'Dispatched'
                ? 'Tolken ble tildelt oppdraget.'
                : 'Tolken ble reservert til oppdraget.';
        } catch (Exception ex) {
            result.message = ex.getMessage();
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
        if (serviceAppointment.Status != 'None') {
            throw new FlowHandledException(
                'Denne handlingen kan bare brukes når oppdraget har status None. Nåværende status er ' +
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

    private List<AssignedResource> getAssignedResources(Id serviceAppointmentId) {
        return this.assignedResourcesByServiceAppointmentId.containsKey(serviceAppointmentId)
            ? this.assignedResourcesByServiceAppointmentId.get(serviceAppointmentId)
            : new List<AssignedResource>();
    }

    private class FlowHandledException extends Exception {
    }
}
