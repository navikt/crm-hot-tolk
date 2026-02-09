public without sharing class HOT_WageClaimService {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
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
            handleException(e);
            throw e;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getServiceAppointments(String wageClaimId) {
        HOT_WageClaim__c wageClaim = [
            SELECT Id, StartTime__c, EndTime__c, WorkType__c, ServiceResource__c
            FROM HOT_WageClaim__c
            WHERE Id = :wageClaimId
            LIMIT 1
        ];
        List<ServiceResourceSkill> serviceResourceSkills = [
            SELECT Id, SkillId
            FROM ServiceResourceSkill
            WHERE ServiceResourceId = :wageClaim.ServiceResource__c
        ];
        List<Id> skillIds = new List<Id>();
        for (ServiceResourceSkill serviceResourceSkill : serviceResourceSkills) {
            skillIds.add(serviceResourceSkill.SkillId);
        }
        List<WorkType> allWorkTypes = [SELECT Id, (SELECT Id, SkillId FROM WorkType.SkillRequirements) FROM WorkType];
        List<Id> workTypeIds = new List<Id>();

        for (WorkType workType : allWorkTypes) {
            Integer n = 0;
            for (SkillRequirement sreq : workType.SkillRequirements) {
                if (skillIds.contains(sreq.SkillId)) {
                    n++;
                }
            }
            if (n == workType.SkillRequirements.size()) {
                workTypeIds.add(workType.Id);
            }
        }

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
                WorkTypeId IN :workTypeIds
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
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT
                    Id,
                    SchedStartTime,
                    SchedEndTime,
                    WorkTypeId,
                    ServiceTerritoryId,
                    Status,
                    HOT_Request__r.ServiceResourceWithAgreement1__c,
                    HOT_Request__r.ServiceResourceWithAgreement2__c,
                    HOT_Request__r.ServiceResourceWithAgreement3__c
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
        List<HOT_WageClaim__c> wageClaims = createWageClaimsFromServiceAppointments(
            serviceAppointments,
            resourceByAppointment,
            serviceResources
        );
        try {
            insert wageClaims;
        } catch (Exception e) {
            handleException(e);
        }
    }

    public static List<HOT_WageClaim__c> createWageClaimsFromServiceAppointments(
        Map<Id, ServiceAppointment> serviceAppointments,
        Map<Id, Id> resourceByAppointment,
        Map<Id, ServiceResource> serviceResources
    ) {
        List<HOT_WageClaim__c> wageClaims = new List<HOT_WageClaim__c>();

        Datetime nowDt = System.now();
        Datetime criticalDt = nowDt.addHours(48);

        for (ServiceAppointment sa : serviceAppointments.values()) {
            Id resourceId = resourceByAppointment.get(sa.Id);
            ServiceResource sr = serviceResources.get(resourceId);

            if (
                sr != null &&
                sa.SchedStartTime != null &&
                sa.SchedStartTime > nowDt &&
                sa.SchedStartTime <= criticalDt &&
                sr.HOT_IsFreelanceInterpreter__c &&
                !isAgreement(sr, sa)
            ) {
                HOT_WageClaim__c wageClaim = new HOT_WageClaim__c();
                wageClaim.IsAutomaticallyCreated__c = true;
                wageClaim.Type__c = 'Claim on Wage';
                wageClaim.Status__c = null;
                wageClaim.ServiceResource__c = resourceId;
                wageClaim.ServiceAppointment__c = sa.Id;
                wageClaim.StartTime__c = sa.SchedStartTime;
                wageClaim.EndTime__c = sa.SchedEndTime;
                wageClaim.WorkType__c = sa.WorkTypeId;
                wageClaim.ServiceTerritory__c = sa.ServiceTerritoryId;

                wageClaims.add(wageClaim);
            }
        }

        return wageClaims;
    }

    private static Boolean isAgreement(ServiceResource serviceResource, ServiceAppointment serviceAppointment) {
        return serviceResource.HOT_AgreementFreelance__c == true &&
            (serviceResource.Id == serviceAppointment.HOT_Request__r.ServiceResourceWithAgreement1__c ||
            serviceResource.Id == serviceAppointment.HOT_Request__r.ServiceResourceWithAgreement2__c ||
            serviceResource.Id == serviceAppointment.HOT_Request__r.ServiceResourceWithAgreement3__c);
    }

    @Future
    public static void updateWageClaimsFuture(Set<Id> serviceAppointmentIds) {
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, SchedStartTime, SchedEndTime, HOT_IsReleasedToFreelance__c, HOT_ServiceResource__c
                FROM ServiceAppointment
                WHERE Id IN :serviceAppointmentIds
            ]
        );
        List<HOT_WageClaim__c> wageClaims = getWageClaimsFromServiceAppointments(serviceAppointments.values());
        updateWageClaims(serviceAppointments, wageClaims, true);
    }
    public static void updateWageClaims(
        Map<Id, ServiceAppointment> serviceAppointments,
        List<HOT_WageClaim__c> wageClaims,
        Boolean isUpsert
    ) {
        Map<Id, List<HOT_WageClaim__c>> wageClaimsByServiceResourceId = getWageClaimsByServiceResourceId(wageClaims);

        List<HOT_WageClaim__c> newWageClaims = new List<HOT_WageClaim__c>();
        Map<Id, HOT_WageClaim__c> updatedWageClaims = new Map<Id, HOT_WageClaim__c>();

        for (ServiceAppointment serviceAppointment : serviceAppointments.values()) {
            if (wageClaimsByServiceResourceId.get(serviceAppointment.HOT_ServiceResource__c) != null) {
                for (
                    HOT_WageClaim__c wageClaim : wageClaimsByServiceResourceId.get(
                        serviceAppointment.HOT_ServiceResource__c
                    )
                ) {
                    Boolean isWageClaimChanged = false;
                    HOT_WageClaim__c updatedWageClaim = wageClaim;
                    if (updatedWageClaim?.Status__c == 'Covered') {
                        continue;
                    }

                    Datetime serviceAppointmentStartTime = serviceAppointment.SchedStartTime;
                    Datetime serviceAppointmentEndTime = serviceAppointment.SchedEndTime;
                    //Completely covered
                    if (
                        serviceAppointmentStartTime <= updatedWageClaim.StartTime__c &&
                        serviceAppointmentEndTime >= updatedWageClaim.EndTime__c
                    ) {
                        updatedWageClaim.Status__c = 'Covered';
                        isWageClaimChanged = true;
                    }
                    if (
                        serviceAppointmentEndTime > updatedWageClaim.StartTime__c &&
                        serviceAppointmentEndTime < updatedWageClaim.EndTime__c
                    ) {
                        //lower
                        HOT_WageClaim__c newWageClaim = createWageClaim(
                            updatedWageClaim,
                            serviceAppointmentEndTime,
                            updatedWageClaim.EndTime__c,
                            isUpsert
                        );
                        newWageClaims.add(newWageClaim);
                        updatedWageClaim.Status__c = 'Covered';
                        updatedWageClaim.EndTime__c = serviceAppointmentEndTime;
                        isWageClaimChanged = true;
                    }
                    if (
                        serviceAppointmentStartTime < updatedWageClaim.EndTime__c &&
                        serviceAppointmentStartTime > updatedWageClaim.StartTime__c
                    ) {
                        //upper
                        HOT_WageClaim__c newWageClaim = createWageClaim(
                            updatedWageClaim,
                            updatedWageClaim.StartTime__c,
                            serviceAppointmentStartTime,
                            isUpsert
                        );
                        newWageClaims.add(newWageClaim);
                        updatedWageClaim.Status__c = 'Covered';
                        updatedWageClaim.StartTime__c = serviceAppointmentStartTime;
                        isWageClaimChanged = true;
                    }

                    if (isWageClaimChanged) {
                        updatedWageClaims.put(updatedWageClaim.Id, updatedWageClaim);
                    }
                }
            }
        }
        List<HOT_WageClaim__c> wageClaimsToUpsert = new List<HOT_WageClaim__c>();
        wageClaimsToUpsert.addAll(newWageClaims);
        if (isUpsert) {
            wageClaimsToUpsert.addAll(updatedWageClaims.values());
        }
        try {
            upsert wageClaimsToUpsert;
        } catch (Exception e) {
            handleException(e);
        }
        if (newWageClaims.size() > 0) {
            updateWageClaims(serviceAppointments, newWageClaims, isUpsert);
        }
    }

    private static HOT_WageClaim__c createWageClaim(
        HOT_WageClaim__c parentWageClaim,
        Datetime startTime,
        Datetime endTime,
        Boolean isUpsert
    ) {
        HOT_WageClaim__c newWageClaim = new HOT_WageClaim__c(
            Status__c = 'Open',
            ParentWageClaim__c = isUpsert ? parentWageClaim.Id : null,
            ServiceResource__c = parentWageClaim.ServiceResource__c,
            ServiceAppointment__c = parentWageClaim.ServiceAppointment__c,
            WorkType__c = parentWageClaim.WorkType__c,
            IsAutomaticallyCreated__c = true,
            StartTime__c = startTime,
            EndTime__c = endTime
        );
        return newWageClaim;
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
        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c, StartTime__c, EndTime__c, WorkType__c, Status__c
            FROM HOT_WageClaim__c
            WHERE
                ServiceResource__c IN :serviceResourceByServiceAppointment.values()
                AND Status__c = 'Open'
                AND Type__c = 'Available on Wage'
        ];
        return wageClaims;
    }
}
