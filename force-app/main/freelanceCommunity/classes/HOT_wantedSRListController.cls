public without sharing class HOT_wantedSRListController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getWantedServiceAppointments() {
        Id userId = UserInfo.getUserId();
        List<ServiceResource> serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :userId];

        //Getting wanted ServiceAppointments
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, ServiceAppointment__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c IN :serviceResource AND Status__c = 'Wanted'
        ];

        Set<Id> saIds = new Set<Id>();
        for (HOT_InterestedResource__c ir : interestedResources) {
            saIds.add(ir.ServiceAppointment__c);
        }

        List<ServiceAppointment> serviceAppointments = [
            SELECT
                Id,
                HOT_ServiceAppointmentNumber__c,
                ServiceTerritoryId,
                EarliestStartTime,
                DueDate,
                HOT_DeadlineDate__c,
                HOT_FreelanceSubject__c,
                HOT_AddressFormated__c,
                HOT_IsSerieoppdrag__c,
                Address,
                HOT_InterpretationStreet__c,
                HOT_InterpretationPostalCode__c,
                HOT_WorkTypeName__c,
                HOT_NumberOfInterestedResources__c,
                WorkType.Id,
                HOT_RequestNumber__c,
                HOT_ReleasedBy__c,
                ServiceTerritory.Name,
                ServiceTerritory.HOT_DeveloperName__c,
                HOT_ServiceTerritoryDeveloperName__c,
                HOT_ServiceTerritoryName__c,
                HOT_ReleaseDate__c,
                City,
                Street,
                PostalCode,
                HOT_AssignmentType__c,
                HOT_AssignmentCategory__c,
                HOT_Information__c,
                HOT_IsScreenInterpreterNew__c,
                HOT_Request__r.IsFellesOppdrag__c,
                HOT_Request__r.OwnerName__c,
                HOT_Request__r.IsOtherEconomicProvicer__c
            FROM ServiceAppointment
            WHERE
                HOT_IsReleasedToFreelance__c = TRUE
                AND Status = 'Released To Freelance'
                AND HOT_DeadlineDate__c >= :DATE.TODAY()
                AND Id IN :saIds
                AND ServiceTerritoryId != NULL
            ORDER BY EarliestStartTime ASC
        ];
        return checkForOverlap(serviceAppointments);
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> checkForOverlap(List<ServiceAppointment> serviceAppointments) {
        Id userId = UserInfo.getUserId();
        ServiceResource serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :userId];

        List<HOT_InterestedResource__c> assignedInterestedResources = [
            SELECT
                ServiceResource__c,
                ServiceAppointment__c,
                ServiceAppointmentStartTime__c,
                ServiceAppointmentEndTime__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c = :serviceResource.Id AND Status__c = 'Assigned'
        ];

        Map<Id, List<DateTime>> existingAppointments = new Map<Id, List<DateTime>>();
        for (HOT_InterestedResource__c assignedResource : assignedInterestedResources) {
            Id serviceAppointmentId = assignedResource.ServiceAppointment__c;

            if (!existingAppointments.containsKey(serviceAppointmentId)) {
                existingAppointments.put(serviceAppointmentId, new List<DateTime>());
            }

            existingAppointments.get(serviceAppointmentId).add(assignedResource.ServiceAppointmentStartTime__c);
            existingAppointments.get(serviceAppointmentId).add(assignedResource.ServiceAppointmentEndTime__c);
        }

        List<ServiceAppointment> nonOverlappingAppointments = new List<ServiceAppointment>();
        for (ServiceAppointment potentialAppointment : serviceAppointments) {
            Boolean overlaps = false;
            DateTime potentialServiceAppointmentStart = potentialAppointment.EarliestStartTime;
            DateTime potentialServiceAppointmentEnd = potentialAppointment.DueDate;

            for (Id serviceAppointmentId : existingAppointments.keySet()) {
                List<DateTime> appointmentTimes = existingAppointments.get(serviceAppointmentId);
                DateTime startTime = appointmentTimes[0];
                DateTime endTime = appointmentTimes[1];
                if (potentialServiceAppointmentStart < endTime && potentialServiceAppointmentEnd > startTime) {
                    overlaps = true;
                    break;
                }
            }
            if (!overlaps) {
                nonOverlappingAppointments.add(potentialAppointment);
            }
        }

        return nonOverlappingAppointments;
    }

    @AuraEnabled
    public static void updateInterestedResource(Id saId, Id srId) {
        HOT_InterestedResource__c interestedResource = [
            SELECT Id, ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c = :srId AND Status__c = 'Wanted' AND ServiceAppointment__c = :saId
            LIMIT 1
        ];

        if (interestedResource != null) {
            interestedResource.Status__c = 'Interested';

            update interestedResource;

            List<ServiceAppointment> sa = [
                SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId, Status
                FROM ServiceAppointment
                WHERE
                    HOT_WorkOrderLineItem__r.WorkOrderId = :interestedResource.ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId
                    AND Status = 'Released to Freelance'
            ];

            //Check if there is IR on SA with same WO
            if (sa.size() > 1) {
                Set<Id> saIds = new Set<Id>();
                for (ServiceAppointment serviceAppointmentId : sa) {
                    saIds.add(serviceAppointmentId.Id);
                }
                //Finding existing IR on SA
                List<HOT_InterestedResource__c> existingIr = [
                    SELECT Id, Status__c, ServiceAppointment__c, ServiceResource__c
                    FROM HOT_InterestedResource__c
                    WHERE ServiceAppointment__c IN :saIds AND ServiceResource__c = :srId
                ];

                List<HOT_InterestedResource__c> newIR = new List<HOT_InterestedResource__c>();

                for (ServiceAppointment serviceAppointment : sa) {
                    for (HOT_InterestedResource__c ir : existingIr) {
                        if (ir.ServiceAppointment__c == serviceAppointment.Id) {
                            ir.Status__c = 'Interested';
                        } else {
                            HOT_InterestedResource__c newInterestedResource = new HOT_InterestedResource__c(
                                ServiceAppointment__c = serviceAppointment.Id,
                                ServiceResource__c = srId,
                                Status__c = 'Interested'
                            );
                            newIr.add(newInterestedResource);
                        }
                    }
                }
                insert newIr;
            }
        }
    }
    @AuraEnabled
    public static void updateInterestedResourceChecked(List<Id> saIdsList, Id srId) {
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c = :srId AND Status__c = 'Wanted' AND ServiceAppointment__c IN :saIdsList
        ];
        if (interestedResources.size() != 0) {
            List<Id> workorderIds = new List<Id>();

            for (HOT_InterestedResource__c ir : interestedResources) {
                ir.Status__c = 'Interested';
                workorderIds.add(ir.ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId);
            }

            update interestedResources;

            List<ServiceAppointment> sa = [
                SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId, Status
                FROM ServiceAppointment
                WHERE HOT_WorkOrderLineItem__r.WorkOrderId IN :workorderIds AND Status = 'Released to Freelance'
            ];

            //Check if there is IR on SA with same WO
            if (sa.size() > 1) {
                Set<Id> saIds = new Set<Id>();
                for (ServiceAppointment serviceAppointmentId : sa) {
                    saIds.add(serviceAppointmentId.Id);
                }
                //     //Finding existing IR on SA
                List<HOT_InterestedResource__c> existingIr = [
                    SELECT Id, Status__c, ServiceAppointment__c, ServiceResource__c
                    FROM HOT_InterestedResource__c
                    WHERE ServiceAppointment__c IN :saIds AND ServiceResource__c = :srId
                ];

                List<HOT_InterestedResource__c> newIR = new List<HOT_InterestedResource__c>();

                Map<Id, Id> SAWithoutIR = new Map<Id, Id>();

                for (ServiceAppointment serviceAppointment : sa) {
                    for (HOT_InterestedResource__c ir : existingIr) {
                        if (ir.ServiceAppointment__c == serviceAppointment.Id) {
                            ir.Status__c = 'Interested';
                        } else {
                            SAWithoutIR.put(serviceAppointment.Id, srId);
                        }
                    }
                }
                for (Id saToCreateIR : SAWithoutIR.keySet()) {
                    if (saIdsList.contains(saToCreateIR)) {
                    } else {
                        Id sr = SAWithoutIR.get(saToCreateIR);
                        HOT_InterestedResource__c newInterestedResource = new HOT_InterestedResource__c(
                            ServiceAppointment__c = saToCreateIR,
                            ServiceResource__c = sr,
                            Status__c = 'Interested'
                        );
                        newIr.add(newInterestedResource);
                    }
                }

                insert newIr;
            }
        }
    }
    @AuraEnabled
    public static void declineInterestedResourceChecked(List<Id> saIdsList, Id srId) {
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c = :srId AND Status__c = 'Wanted' AND ServiceAppointment__c IN :saIdsList
        ];
        if (interestedResources.size() != 0) {
            List<Id> workorderIds = new List<Id>();

            for (HOT_InterestedResource__c ir : interestedResources) {
                ir.Status__c = 'Declined';
                workorderIds.add(ir.ServiceAppointment__r.HOT_WorkOrderLineItem__r.WorkOrderId);
            }

            update interestedResources;
        }
    }
    @AuraEnabled
    public static void declineInterestedResource(Id saId, Id srId) {
        HOT_InterestedResource__c interestedResource = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c = :srId AND Status__c = 'Wanted' AND ServiceAppointment__c = :saId
            LIMIT 1
        ];

        if (interestedResource != null) {
            interestedResource.Status__c = 'Declined';

            update interestedResource;
        }
    }
    @InvocableMethod(
        label='Check if wanted SR has overlapping SA and interested IR'
        description='return based on result'
        category='check'
    )
    public static List<String> checkForOverlapOrExisting(List<Request> ids) {
        List<String> status = new List<String>();
        Id saId = (Id) ids[0].saID;
        Id srId = (Id) ids[0].srID;

        List<ServiceAppointment> sa = [
            SELECT Id, EarliestStartTime, DueDate, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Id = :saId
        ];

        ServiceResource serviceResource = [SELECT Id, Name FROM ServiceResource WHERE Id = :srId];

        List<HOT_InterestedResource__c> existingInterestedIR = [
            SELECT Id, ServiceResource__c, Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c = :serviceResource.Id AND ServiceAppointment__c = :sa[0].Id
        ];

        List<HOT_InterestedResource__c> assignedInterestedResources = [
            SELECT
                ServiceResource__c,
                ServiceAppointment__c,
                ServiceAppointmentStartTime__c,
                ServiceAppointmentEndTime__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__c = :serviceResource.Id AND Status__c = 'Assigned'
        ];

        Integer overlapCount = 0;
        DateTime potentialServiceAppointmentStart = sa[0].EarliestStartTime;
        DateTime potentialServiceAppointmentEnd = sa[0].DueDate;

        for (HOT_InterestedResource__c ir : assignedInterestedResources) {
            if (
                potentialServiceAppointmentStart < ir.ServiceAppointmentEndTime__c &&
                potentialServiceAppointmentEnd > ir.ServiceAppointmentStartTime__c
            ) {
                overlapCount++;
                break;
            }
        }
        if (existingInterestedIR.size() > 0) {
            status.add('existing');
        } else {
            status.add(overlapCount > 0 ? 'overlap' : 'no overlap');
        }
        return status;
    }

    @AuraEnabled(cacheable=true)
    public static HOT_InterestedResource__c getWantedInterestedResource(Id saId, Id srId) {
        return [
            SELECT Id, HOT_Wanted_by__c, Status__c, ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :saId AND ServiceResource__c = :srId AND Status__c = 'Wanted'
            LIMIT 1
        ];
    }

    public class Request {
        @InvocableVariable(label='sa Id' description='return based on result' required=false)
        public String saID;
        @InvocableVariable(label='sr Id' description='return based on result' required=false)
        public String srID;
    }
}
