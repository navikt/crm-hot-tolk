public without sharing class HOT_WageClaimService {
    @AuraEnabled
    public static void assign(Id wageClaimId, Id serviceAppointmentId) {
        HOT_WageClaim__c wageClaim = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c WHERE Id = :wageClaimId];
        AssignedResource assignedResource = new AssignedResource(
            ServiceAppointmentId = serviceAppointmentId,
            ServiceResourceId = wageClaim.ServiceResource__c
        );
        try {
            insert assignedResource;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
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

    public static void createWageClaims(Map<Id, Id> resourceByAppointment) {
        List<HOT_WageClaim__c> wageClaims = new List<HOT_WageClaim__c>();
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, SchedStartTime, SchedEndTime, WorkTypeId, ServiceTerritoryId, Status
                FROM ServiceAppointment
                WHERE Id IN :resourceByAppointment.keySet()
            ]
        );
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(
            [
                SELECT Id, HOT_IsFreelanceInterpreter__c, HOT_AgreementFreelance__c
                FROM ServiceResource
                WHERE Id IN :resourceByAppointment.values()
            ]
        );
        Date criticalDate = Date.today().addDays(14);
        for (ServiceAppointment serviceAppointment : serviceAppointments.values()) {
            if (
                criticalDate >= serviceAppointment.SchedStartTime.date() &&
                serviceResources.get(resourceByAppointment.get(serviceAppointment.Id)).HOT_IsFreelanceInterpreter__c ==
                true
            ) {
                HOT_WageClaim__c wageClaim = new HOT_WageClaim__c();
                wageClaim.IsAutomaticallyCreated__c = true;
                wageClaim.Type__c = 'Available on Wage';
                wageClaim.Status__c = 'Open';
                wageClaim.ServiceResource__c = resourceByAppointment.get(serviceAppointment.Id);
                wageClaim.ServiceAppointment__c = serviceAppointment.Id;
                wageClaim.StartTime__c = serviceAppointment.SchedStartTime;
                wageClaim.EndTime__c = serviceAppointment.SchedEndTime;
                wageClaim.WorkType__c = serviceAppointment.WorkTypeId;
                wageClaim.ServiceTerritory__c = serviceAppointment.ServiceTerritoryId;
                wageClaims.add(wageClaim);
            }
        }
        try {
            insert wageClaims;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @Future
    public static void updateWageClaimsFuture(Set<Id> serviceAppointmentIds) {
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, SchedStartTime, SchedEndTime, HOT_IsReleasedToFreelance__c, HOT_ServiceResource__c
                FROM ServiceAppointment
                WHERE Id IN :serviceAppointmentIds AND HOT_IsReleasedToFreelance__c = TRUE AND Status = 'Dispatched'
            ]
        );
        List<HOT_WageClaim__c> wageClaims = getWageClaimsFromServiceAppointments(serviceAppointments.values());
        Map<Id, List<HOT_WageClaim__c>> wageClaimsByServiceResourceId = getWageClaimsByServiceResourceId(wageClaims);

        List<HOT_WageClaim__c> newWageClaims = new List<HOT_WageClaim__c>();
        for (ServiceAppointment serviceAppointment : serviceAppointments.values()) {
            if (wageClaimsByServiceResourceId.get(serviceAppointment.HOT_ServiceResource__c) != null) {
                for (
                    HOT_WageClaim__c wageClaim : wageClaimsByServiceResourceId.get(
                        serviceAppointment.HOT_ServiceResource__c
                    )
                ) {
                    HOT_WageClaim__c updatedWageClaim = new HOT_WageClaim__c(Id = wageClaim.Id);
                    Datetime serviceAppointmentStartTime = serviceAppointment.SchedStartTime;
                    Datetime serviceAppointmentEndTime = serviceAppointment.SchedEndTime;
                    //Completely covered
                    if (
                        serviceAppointmentStartTime <= wageClaim.StartTime__c &&
                        serviceAppointmentEndTime >= wageClaim.EndTime__c
                    ) {
                        updatedWageClaim.Status__c = 'Covered';
                    }
                    //lower
                    if (
                        serviceAppointmentEndTime > wageClaim.StartTime__c &&
                        serviceAppointmentEndTime < wageClaim.EndTime__c
                    ) {
                        HOT_WageClaim__c newWageClaim = new HOT_WageClaim__c(
                            ParentWageClaim__c = wageClaim.Id,
                            ServiceResource__c = wageClaim.ServiceResource__c,
                            StartTime__c = serviceAppointmentEndTime,
                            EndTime__c = wageClaim.EndTime__c
                        );
                        newWageClaims.add(newWageClaim);
                        updatedWageClaim.Status__c = 'Covered';
                        updatedWageClaim.EndTime__c = serviceAppointmentEndTime;
                    }
                    //upper
                    if (
                        serviceAppointmentStartTime < wageClaim.EndTime__c &&
                        serviceAppointmentStartTime > wageClaim.StartTime__c
                    ) {
                        HOT_WageClaim__c newWageClaim = new HOT_WageClaim__c(
                            ParentWageClaim__c = wageClaim.Id,
                            ServiceResource__c = wageClaim.ServiceResource__c,
                            StartTime__c = wageClaim.StartTime__c,
                            EndTime__c = serviceAppointmentStartTime
                        );
                        newWageClaims.add(newWageClaim);
                        updatedWageClaim.Status__c = 'Covered';
                        updatedWageClaim.StartTime__c = serviceAppointmentStartTime;
                    }
                    newWageClaims.add(updatedWageClaim);
                }
            }
        }
        try {
            upsert newWageClaims;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    private static Map<Id, List<HOT_WageClaim__c>> getWageClaimsByServiceResourceId(List<HOT_WageClaim__c> wageClaims) {
        Map<Id, List<HOT_WageClaim__c>> wageClaimsByServiceResourceId = new Map<Id, List<HOT_WageClaim__c>>();
        for (HOT_WageClaim__c wageClaim : wageClaims) {
            if (wageClaimsByServiceResourceId.get(wageClaim.ServiceResource__c) == null) {
                wageClaimsByServiceResourceId.put(
                    wageClaim.ServiceResource__c,
                    new List<HOT_WageClaim__c>{ wageClaim }
                );
            } else {
                wageClaimsByServiceResourceId.get(wageClaim.ServiceResource__c).add(wageClaim);
            }
        }
        return wageClaimsByServiceResourceId;
    }

    private static List<HOT_WageClaim__c> getWageClaimsFromServiceAppointments(
        List<ServiceAppointment> serviceAppointments
    ) {
        Map<Id, Id> serviceResourceByServiceAppointment = new Map<Id, Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceResourceByServiceAppointment.put(serviceAppointment.Id, serviceAppointment.HOT_ServiceResource__c);
        }
        System.debug('serviceResourceByServiceAppointment.values(): ' + serviceResourceByServiceAppointment.values());
        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c, StartTime__c, EndTime__c
            FROM HOT_WageClaim__c
            WHERE
                ServiceResource__c IN :serviceResourceByServiceAppointment.values()
                AND Status__c = 'Open'
                AND Type__c = 'Available on Wage'
        ];
        return wageClaims;
    }
}
