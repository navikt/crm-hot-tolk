public without sharing class HOT_WageClaimService {
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

    @Future
    public static void updateWageClaimsFuture(Set<Id> serviceAppointmentIds) {
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, SchedStartTime, SchedEndTime, HOT_IsReleasedToFreelance__c, HOT_ServiceResource__c
                FROM ServiceAppointment
                WHERE Id IN :serviceAppointmentIds AND HOT_IsReleasedToFreelance__c = TRUE
            ]
        );
        Map<Id, Id> serviceResourceByServiceAppointment = new Map<Id, Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointments.values()) {
            serviceResourceByServiceAppointment.put(serviceAppointment.Id, serviceAppointment.HOT_ServiceResource__c);
        }
        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, ServiceAppointment__c
            FROM HOT_WageClaim__c
            WHERE
                ServiceResource__c IN :serviceResourceByServiceAppointment.values()
                AND Status__c = 'Open'
                AND Type__c = 'Available on Wage'
        ];
        Map<Id, List<HOT_WageClaim__c>> wageClaimsByServiceResourceId = new Map<Id, List<HOT_WageClaim__c>>();
        for (HOT_WageClaim__c wageClaim : wageClaims) {
            System.debug('wageClaim: ' + wageClaim);
            System.debug('wageClaim.ServiceResource__c: ' + wageClaim.ServiceResource__c);
            if (wageClaimsByServiceResourceId.get(wageClaim.ServiceResource__c) == null) {
                wageClaimsByServiceResourceId.put(
                    wageClaim.ServiceResource__c,
                    new List<HOT_WageClaim__c>{ wageClaim }
                );
            } else {
                wageClaimsByServiceResourceId.get(wageClaim.ServiceResource__c).add(wageClaim);
            }
        }
        System.debug(wageClaimsByServiceResourceId.keySet());
        Map<Id, Map<String, Datetime>> wageClaimMap = new Map<Id, Map<String, Datetime>>();
        for (ServiceAppointment serviceAppointment : serviceAppointments.values()) {
            System.debug('serviceAppointment.HOT_ServiceResource__c: ' + serviceAppointment.HOT_ServiceResource__c);
            System.debug(
                'wageClaimsByServiceResourceId.get(serviceAppointment.HOT_ServiceResource__c): ' +
                wageClaimsByServiceResourceId.get(serviceAppointment.HOT_ServiceResource__c)
            );
            if (wageClaimsByServiceResourceId.get(serviceAppointment.HOT_ServiceResource__c) != null) {
                for (
                    HOT_WageClaim__c wageClaim : wageClaimsByServiceResourceId.get(
                        serviceAppointment.HOT_ServiceResource__c
                    )
                ) {
                    Map<String, Datetime> tempDateTimes = new Map<String, Datetime>();
                    tempDateTimes.put('serviceAppointmentStartTime', serviceAppointment.SchedStartTime);
                    tempDateTimes.put('serviceAppointmentEndTime', serviceAppointment.SchedEndTime);
                    wageClaimMap.put(wageClaim.Id, tempDateTimes);
                }
            }
        }
        if (!wageClaimMap.isEmpty()) {
            updateWageClaims(wageClaimMap);
        }
    }

    public static List<String> updateWageClaims(Map<Id, Map<String, Datetime>> wageClaimMap) {
        Map<Id, HOT_WageClaim__c> wageClaims = new Map<Id, HOT_WageClaim__c>(
            [
                SELECT Id, StartTime__c, EndTime__c, ServiceResource__c
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
                wageClaim.Status__c = 'Covered';
                newWageClaims.add(wageClaim);
            } else if (
                serviceAppointmentStartTime > wageClaim.StartTime__c &&
                serviceAppointmentEndTime < wageClaim.EndTime__c
            ) {
                //Split
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
                wageClaim.Status__c = 'Partly Covered';
                newWageClaims.add(wageClaim);
                newWageClaims.add(lowerWageClaim);
                newWageClaims.add(upperWageClaim);
            } else if (
                serviceAppointmentStartTime <= wageClaim.StartTime__c &&
                serviceAppointmentEndTime > wageClaim.StartTime__c
            ) {
                //lower
                HOT_WageClaim__c newWageClaim = new HOT_WageClaim__c(
                    ParentWageClaim__c = wageClaim.Id,
                    ServiceResource__c = wageClaim.ServiceResource__c,
                    StartTime__c = serviceAppointmentEndTime,
                    EndTime__c = wageClaim.EndTime__c
                );
                wageClaim.Status__c = 'Partly Covered';
                newWageClaims.add(wageClaim);
                newWageClaims.add(newWageClaim);
            } else if (
                serviceAppointmentStartTime <= wageClaim.EndTime__c &&
                serviceAppointmentEndTime > wageClaim.EndTime__c
            ) {
                //upper
                HOT_WageClaim__c newWageClaim = new HOT_WageClaim__c(
                    ParentWageClaim__c = wageClaim.Id,
                    ServiceResource__c = wageClaim.ServiceResource__c,
                    StartTime__c = wageClaim.StartTime__c,
                    EndTime__c = serviceAppointmentStartTime
                );
                wageClaim.Status__c = 'Partly Covered';
                newWageClaims.add(wageClaim);
                newWageClaims.add(newWageClaim);
            }
        }

        try {
            upsert newWageClaims;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
        return null;
    }
}
