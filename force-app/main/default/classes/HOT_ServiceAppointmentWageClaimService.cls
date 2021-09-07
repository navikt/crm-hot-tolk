public without sharing class HOT_ServiceAppointmentWageClaimService {
    @AuraEnabled
    public static void assign(Id wageClaimId, Id serviceAppointmentId) {
        HOT_WageClaim__c wageClaim = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c WHERE Id = :wageClaimId];
        AssignedResource assignedResource = new AssignedResource(
            ServiceAppointmentId = serviceAppointmentId,
            ServiceResourceId = wageClaim.ServiceResource__c
        );
        insert assignedResource;
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getServiceAppointments(String wageClaimId) {
        HOT_WageClaim__c wageClaim = [
            SELECT Id, StartTime__c, EndTime__c, WorkType__c
            FROM HOT_WageClaim__c
            WHERE Id = :wageClaimId
            LIMIT 1
        ];
        List<ServiceAppointment> serviceAppointments = [
            SELECT
                Id,
                AppointmentNumber,
                SchedStartTime,
                SchedEndTime,
                HOT_WorkTypeName__c,
                HOT_ServiceTerritoryName__c,
                HOT_InterpretationType__c,
                Status
            FROM ServiceAppointment
            WHERE
                WorkTypeId = :wageClaim.WorkType__c
                AND (Status = 'None'
                OR Status = 'Released to Freelance')
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
        return updateWageClaims(inputVariables);
    }

    public static List<String> updateWageClaims(List<HOT_ServiceAppointmentWageClaimService> inputVariables) {
        Map<Id, Map<String, Datetime>> wageClaimMap = new Map<Id, Map<String, Datetime>>();
        for (HOT_ServiceAppointmentWageClaimService input : inputVariables) {
            Map<String, Datetime> tempDateTimes = new Map<String, Datetime>();
            tempDateTimes.put('serviceAppointmentStartTime', input.serviceAppointmentStartTime);
            tempDateTimes.put('serviceAppointmentStartTime', input.serviceAppointmentEndTime);
            wageClaimMap.put(input.wageClaimId, tempDateTimes);
        }
        Map<Id, HOT_WageClaim__c> wageClaims = new Map<Id, HOT_WageClaim__c>(
            [
                SELECT Id, StartTime__c, EndTime__c, ServiceResource__c, IsParent__c
                FROM HOT_WageClaim__c
                WHERE Id IN :wageClaimMap.keySet()
                LIMIT 1
            ]
        );
        List<HOT_WageClaim__c> newWageClaims = new List<HOT_WageClaim__c>();

        for (Id wageClaimId : wageClaims.keySet()) {
            Datetime serviceAppointmentStartTime = wageClaimMap.get(wageClaimId).get('serviceAppointmentStartTime');
            Datetime serviceAppointmentEndTime = wageClaimMap.get(wageClaimId).get('serviceAppointmentEndTime');
            HOT_WageClaim__c wageClaim = wageClaims.get(wageClaimId);
            //Completely covered
            if (
                serviceAppointmentStartTime <= wageClaim.StartTime__c &&
                serviceAppointmentEndTime >= wageClaim.EndTime__c
            ) {
                wageClaim.IsParent__c = true;
            }
            //Split
            if (
                serviceAppointmentStartTime > wageClaim.StartTime__c &&
                serviceAppointmentEndTime < wageClaim.EndTime__c
            ) {
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
            if (
                serviceAppointmentStartTime <= wageClaim.EndTime__c &&
                serviceAppointmentEndTime > wageClaim.EndTime__c
            ) {
                HOT_WageClaim__c newWageClaim = new HOT_WageClaim__c(
                    ParentWageClaim__c = wageClaim.Id,
                    ServiceResource__c = wageClaim.ServiceResource__c,
                    StartTime__c = wageClaim.StartTime__c,
                    EndTime__c = serviceAppointmentStartTime
                );
                newWageClaims.add(newWageClaim);
            }
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
