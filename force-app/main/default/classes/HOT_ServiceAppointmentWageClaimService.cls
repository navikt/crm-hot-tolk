public without sharing class HOT_ServiceAppointmentWageClaimService {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getServiceAppointments(String wageClaimId) {
        HOT_WageClaim__c wageClaim = [
            SELECT Id, StartTime__c, EndTime__c, WorkType__c
            FROM HOT_WageClaim__c
            WHERE Id = :wageClaimId
            LIMIT 1
        ];
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, SchedStartTime, SchedEndTime, HOT_WorkTypeName__c, Status
            FROM ServiceAppointment
            WHERE
                WorkTypeId = :wageClaim.WorkType__c
                AND ((SchedStartTime >= :wageClaim.StartTime__c
                AND SchedStartTime < :wageClaim.EndTime__c)
                OR (SchedEndTime >= :wageClaim.StartTime__c
                AND SchedEndTime < :wageClaim.EndTime__c)
                OR (SchedStartTime <= :wageClaim.StartTime__c
                AND SchedEndTime >= :wageClaim.EndTime__c))
        ];

        return serviceAppointments;
    }

    @InvocableVariable
    public Id wageClaimId;
    @InvocableVariable
    public Datetime serviceAppointmentStartTime;
    @InvocableVariable
    public Datetime serviceAppointmentEndTime;
    @InvocableMethod
    public static List<String> updateWageClaimsInvocable(List<HOT_ServiceAppointmentWageClaimService> inputVariables) {
        HOT_ServiceAppointmentWageClaimService input = inputVariables[0];

        return updateWageClaims(input.wageClaimId, input.serviceAppointmentStartTime, input.serviceAppointmentEndTime);
    }

    public static List<String> updateWageClaims(
        Id wageClaimId,
        Datetime serviceAppointmentStartTime,
        Datetime serviceAppointmentEndTime
    ) {
        HOT_WageClaim__c wageClaim = [
            SELECT Id, StartTime__c, EndTime__c, ServiceResource__c, IsParent__c
            FROM HOT_WageClaim__c
            WHERE Id = :wageClaimId
            LIMIT 1
        ];
        List<HOT_WageClaim__c> newWageClaims = new List<HOT_WageClaim__c>();

        //Completely covered
        if (
            serviceAppointmentStartTime <= wageClaim.StartTime__c &&
            serviceAppointmentEndTime >= wageClaim.EndTime__c
        ) {
            wageClaim.IsParent__c = true;
        }
        //Split
        if (serviceAppointmentStartTime > wageClaim.StartTime__c && serviceAppointmentEndTime < wageClaim.EndTime__c) {
            HOT_WageClaim__c lowerWageClaim = new HOT_WageClaim__c(
                ParentWageClaim__c = wageClaim.Id,
                ServiceResource__c = wageClaim.ServiceResource__c,
                StartTime__c = wageClaim.StartTime__c,
                EndTime__c = serviceAppointmentStartTime
            );
            HOT_WageClaim__c upperWageClaim = new HOT_WageClaim__c(
                ParentWageClaim__c = wageClaim.Id,
                ServiceResource__c = wageClaim.ServiceResource__c,
                StartTime__c = serviceAppointmentEndTime,
                EndTime__c = wageClaim.EndTime__c
            );
            newWageClaims.add(lowerWageClaim);
            newWageClaims.add(upperWageClaim);
        }
        //lower
        if (
            serviceAppointmentStartTime <= wageClaim.StartTime__c &&
            serviceAppointmentEndTime > wageClaim.StartTime__c
        ) {
            HOT_WageClaim__c newWageClaim = new HOT_WageClaim__c(
                ParentWageClaim__c = wageClaim.Id,
                ServiceResource__c = wageClaim.ServiceResource__c,
                StartTime__c = serviceAppointmentEndTime,
                EndTime__c = wageClaim.EndTime__c
            );
            newWageClaims.add(newWageClaim);
        }
        //upper
        if (serviceAppointmentStartTime <= wageClaim.EndTime__c && serviceAppointmentEndTime > wageClaim.EndTime__c) {
            HOT_WageClaim__c newWageClaim = new HOT_WageClaim__c(
                ParentWageClaim__c = wageClaim.Id,
                ServiceResource__c = wageClaim.ServiceResource__c,
                StartTime__c = wageClaim.StartTime__c,
                EndTime__c = serviceAppointmentStartTime
            );
            newWageClaims.add(newWageClaim);
        }

        try {
            insert newWageClaims;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
        return null;
    }
}
