public with sharing class HOT_ServiceAppointmentReportController implements Database.Batchable<SObject> {
    public String getQuery() {
        return null;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    ParentRecordId,
                    HOT_IsEmployedInterpreter__c,
                    HOT_IsReleasedToFreelance__c,
                    WorkType.Name,
                    ServiceTerritory.Name,
                    EarliestStartTime,
                    DueDate,
                    SchedStartTime,
                    SchedEndTime,
                    ActualStartTime,
                    ActualEndTime,
                    HOT_HapticCommunication__c,
                    CreatedDate,
                    Status,
                    Duration,
                    Owner.Name,
                    ActualDuration,
                    DurationType,
                    AppointmentNumber,
                    HOT_IsSerieoppdrag__c,
                    HOT_CancelComment__c,
                    HOT_IsAcute__c,
                    HOT_IsScreenInterpreter__c,
                    HOT_ReleaseDate__c,
                    HOT_FreelanceSubject__c,
                    HOT_DeadlineDate__c,
                    HOT_Request__c,
                    Subject
                FROM ServiceAppointment
                WHERE LastModifiedDate >= :this.periodStart AND LastModifiedDate <= :this.periodEnd
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> scope) {
        upsertReportingData(scope);
    }

    private Datetime periodStart;
    private Datetime periodEnd;
    public HOT_ServiceAppointmentReportController(Datetime periodStart, Datetime periodEnd) {
        this.periodStart = periodStart;
        this.periodEnd = periodEnd;
    }

    public HOT_ServiceAppointmentReportController() {
        this.periodStart = Datetime.now().addDays(-1);
        this.periodEnd = Datetime.now();
    }

    public void finish(Database.BatchableContext bc) {
    }

    public static void upsertReportingData(List<ServiceAppointment> serviceAppointments) {
        List<ReportingData__c> reportingData = [
            SELECT Id, HOT_ServiceAppointment__c
            FROM ReportingData__c
            WHERE HOT_ServiceAppointment__c IN :serviceAppointments
        ];
        Map<Id, ReportingData__c> SAIdtoRepData = new Map<Id, ReportingData__c>();
        for (ReportingData__c repData : reportingData) {
            SAIdtoRepData.put(repData.HOT_ServiceAppointment__c, repData);
        }

        for (ServiceAppointment sa : serviceAppointments) {
            if (SAIdtoRepData.containsKey(sa.Id)) {
                SAIdtoRepData.put(sa.Id, setFieldValues(SAIdtoRepData.get(sa.Id), sa));
            } else {
                ReportingData__c repData = new ReportingData__c();
                SAIdtoRepData.put(sa.Id, setFieldValues(repData, sa));
            }
        }
        upsert SAIdtoRepData.values();
    }

    public static ReportingData__c setFieldValues(ReportingData__c repData, ServiceAppointment serviceAppointment) {
        repData.CRM_Category__c = 'Service Appointment';
        repData.CRM_Region__c = serviceAppointment.ServiceTerritory.Name;

        repData.HOT_ServiceAppointment__c = serviceAppointment.Id;
        repData.HOT_CreatedDate__c = serviceAppointment.CreatedDate;

        repData.HOT_RecordName__c = serviceAppointment.AppointmentNumber;
        repData.HOT_Request__c = serviceAppointment.HOT_Request__c;
        repData.HOT_Subject__c = serviceAppointment.Subject;
        repData.HOT_WorkType__c = serviceAppointment.WorkType.Name;
        repData.HOT_IsHapticCommunication__c = serviceAppointment.HOT_HapticCommunication__c;
        repData.HOT_IsSerieoppdrag__c = serviceAppointment.HOT_IsSerieoppdrag__c;

        repData.HOT_Owner__c = serviceAppointment.Owner.Name;
        repData.HOT_ServiceTerritory__c = serviceAppointment.ServiceTerritory.Name;
        repData.HOT_Status2__c = serviceAppointment.Status;
        repData.HOT_CancelComment__c = serviceAppointment.HOT_CancelComment__c;
        repData.HOT_IsAcute__c = serviceAppointment.HOT_IsAcute__c;
        repData.HOT_IsScreenInterpreter__c = serviceAppointment.HOT_IsScreenInterpreter__c;

        repData.HOT_EarliestStartTime__c = serviceAppointment.EarliestStartTime;
        repData.HOT_DueDate__c = serviceAppointment.DueDate;

        repData.HOT_SchedStartTime__c = serviceAppointment.SchedStartTime;
        repData.HOT_SchedEndTime__c = serviceAppointment.SchedEndTime;
        repData.HOT_Duration__c = serviceAppointment.Duration;
        repData.HOT_DurationType__c = serviceAppointment.DurationType;

        repData.HOT_ActualStartTime__c = serviceAppointment.ActualStartTime;
        repData.HOT_ActualEndTime__c = serviceAppointment.ActualEndTime;
        repData.HOT_ActualDuration__c = serviceAppointment.ActualDuration;

        repData.HOT_IsEmployedInterpreter__c = serviceAppointment.HOT_IsEmployedInterpreter__c;
        repData.HOT_IsFreelanceInterpreter__c = serviceAppointment.HOT_IsReleasedToFreelance__c;
        repData.HOT_FreelanceSubject__c = serviceAppointment.HOT_FreelanceSubject__c;
        repData.HOT_ReleaseDate__c = serviceAppointment.HOT_ReleaseDate__c;
        repData.HOT_DeadlineDate__c = serviceAppointment.HOT_DeadlineDate__c;

        return repData;
    }
}
