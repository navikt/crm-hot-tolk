public without sharing class HOT_AssignedResourceHandler extends MyTriggers {
    public override void onBeforeInsert() {
        setResourceFieldsOnServiceAppointment((List<AssignedResource>) records);
        throwExceptionIfARHasSAOverlap((List<AssignedResource>) records, false);
    }
    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<AssignedResource> assignedResourcesFiltered = new List<AssignedResource>();
        for (AssignedResource assignedResource : (List<AssignedResource>) records) {
            if (assignedResource.ServiceResourceId != triggerOldMap.get(assignedResource.Id).get('ServiceResourceId')) {
                assignedResourcesFiltered.add(assignedResource);
            }
        }
        if (assignedResourcesFiltered.size() > 0) {
            setResourceFieldsOnServiceAppointment(assignedResourcesFiltered);
            throwExceptionIfARHasSAOverlap(assignedResourcesFiltered, true);
        }
    }
    public override void onBeforeDelete() {
        Set<Id> potentialSAWithThreadsIds = new Set<Id>();
        for (AssignedResource ar : (List<AssignedResource>) records) {
            potentialSAWithThreadsIds.add(ar.ServiceAppointmentId);
        }
        List<Thread__c> exisitingThreadsToBeTransferred = [
            SELECT Id, HOT_IsEmployeeThread__c, CRM_Account__c, CRM_Related_Object__c, HOT_ServiceAppointment__c
            FROM Thread__c
            WHERE CRM_Related_Object__c IN :potentialSAWithThreadsIds AND CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
        ];
        //Finn ir hvor accountid og serviceappointment id er samme
        Set<Id> accountIds = new Set<Id>();
        for (Thread__c thread : exisitingThreadsToBeTransferred) {
            accountIds.add(thread.CRM_Account__c);
        }
        List<HOT_InterestedResource__c> irList = [
            SELECT Id, ServiceAppointment__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__r.AccountId IN :accountIds AND ServiceAppointment__c IN :potentialSAWithThreadsIds
        ];
        //LOOP om threads sin related record er samme serviceappointmentId. Så sett ir sin id som related object
        Map<Id, List<Id>> saIdToIrIdListMap = new Map<Id, List<Id>>();
        for (HOT_InterestedResource__c ir : irList) {
            if (!saIdToIrIdListMap.containsKey(ir.ServiceAppointment__c)) {
                saIdToIrIdListMap.put(ir.ServiceAppointment__c, new List<Id>{ ir.Id });
            } else {
                saIdToIrIdListMap.get(ir.ServiceAppointment__c).add(ir.Id);
            }
        }

        if (exisitingThreadsToBeTransferred.size() != 0) {
            for (Thread__c thread : exisitingThreadsToBeTransferred) {
                if (
                    saIdToIrIdListMap.containsKey(thread.HOT_ServiceAppointment__c) &&
                    thread.HOT_IsEmployeeThread__c == false
                ) {
                    thread.CRM_Related_Object__c = saIdToIrIdListMap.get(thread.HOT_ServiceAppointment__c)[0];
                    thread.HOT_InterestedResource__c = saIdToIrIdListMap.get(thread.HOT_ServiceAppointment__c)[0];
                }
                if (thread.HOT_IsEmployeeThread__c == true) {
                    thread.CRM_Related_Object__c = null;
                }
            }
            update exisitingThreadsToBeTransferred;
        }
    }

    public override void onAfterInsert() {
        List<ServiceAppointment> serviceAppointments = setServiceResourceFieldsOnServiceAppointment(
            (List<AssignedResource>) records
        );
        update serviceAppointments;
        List<HOT_InterestedResource__c> interestedResource = createInterestedResources(
            (List<AssignedResource>) records
        );
        insert interestedResource;
        List<HOT_InterestedResource__c> interestedResources = updateInterestedResourceStatus(
            (List<AssignedResource>) records
        );
        update interestedResources;

        Set<Id> potentialSAWithThreadsIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            potentialSAWithThreadsIds.add(sa.Id);
        }
        List<Thread__c> exisitingThreadsToBeTransferred = [
            SELECT Id, HOT_IsEmployeeThread__c, CRM_Account__c, CRM_Related_Object__c, HOT_ServiceAppointment__c
            FROM Thread__c
            WHERE CRM_Related_Object__c IN :potentialSAWithThreadsIds AND CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
        ];

        //Finn ir hvor accountid og serviceappointment id er samme
        Set<Id> accountIds = new Set<Id>();
        for (Thread__c thread : exisitingThreadsToBeTransferred) {
            accountIds.add(thread.CRM_Account__c);
        }
        List<HOT_InterestedResource__c> irList = [
            SELECT Id, ServiceAppointment__c
            FROM HOT_InterestedResource__c
            WHERE ServiceResource__r.AccountId IN :accountIds AND ServiceAppointment__c IN :potentialSAWithThreadsIds
        ];
        //LOOP om threads sin related record er samme serviceappointmentId. Så sett ir sin id som related object
        Map<Id, List<Id>> saIdToIrIdListMap = new Map<Id, List<Id>>();
        for (HOT_InterestedResource__c ir : irList) {
            if (!saIdToIrIdListMap.containsKey(ir.ServiceAppointment__c)) {
                saIdToIrIdListMap.put(ir.ServiceAppointment__c, new List<Id>{ ir.Id });
            } else {
                saIdToIrIdListMap.get(ir.ServiceAppointment__c).add(ir.Id);
            }
        }

        if (exisitingThreadsToBeTransferred.size() != 0) {
            for (Thread__c thread : exisitingThreadsToBeTransferred) {
                if (
                    saIdToIrIdListMap.containsKey(thread.HOT_ServiceAppointment__c) &&
                    thread.HOT_IsEmployeeThread__c == false
                ) {
                    thread.CRM_Related_Object__c = saIdToIrIdListMap.get(thread.HOT_ServiceAppointment__c)[0];
                    thread.HOT_InterestedResource__c = saIdToIrIdListMap.get(thread.HOT_ServiceAppointment__c)[0];
                }
                if (thread.HOT_IsEmployeeThread__c == true) {
                    thread.CRM_Related_Object__c = null;
                }
            }
            update exisitingThreadsToBeTransferred;
        }
        List<HOT_InterestedResource__c> potentialIRWithThreads = [
            SELECT Id, ServiceAppointment__c
            FROM HOT_InterestedResource__c
            WHERE Status__c = 'Assigned' AND ServiceAppointment__c IN :potentialSAWithThreadsIds
        ];
        if (potentialIRWithThreads.size() != 0) {
            Map<Id, HOT_InterestedResource__c> threadMap = new Map<Id, HOT_InterestedResource__c>();
            Set<Id> potentialIRWithThreadsIds = new Set<Id>();
            for (HOT_InterestedResource__c ir : potentialIRWithThreads) {
                potentialIRWithThreadsIds.add(ir.Id);
                threadMap.put(ir.Id, ir);
            }
            List<Thread__c> threadsToTransfer = [
                SELECT Id, CRM_Related_Object__c
                FROM Thread__c
                WHERE CRM_Related_Object__c IN :potentialIRWithThreadsIds
            ];

            for (Thread__c threads : threadsToTransfer) {
                HOT_InterestedResource__c ir = threadMap.get(threads.CRM_Related_Object__c);
                if (ir != null) {
                    threads.CRM_Related_Object__c = ir.ServiceAppointment__c;
                    threads.HOT_ServiceAppointment__c = ir.ServiceAppointment__c;
                }
            }
            update threadsToTransfer;
        }
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<AssignedResource> assignedResourcesFiltered = new List<AssignedResource>();
        for (AssignedResource assignedResource : (List<AssignedResource>) records) {
            if (assignedResource.ServiceResourceId != triggerOldMap.get(assignedResource.Id).get('ServiceResourceId')) {
                assignedResourcesFiltered.add(assignedResource);
            }
        }
        if (assignedResourcesFiltered.size() > 0) {
            notifyResource((List<AssignedResource>) triggerOldMap.values());

            List<ServiceAppointment> serviceAppointments = setServiceResourceFieldsOnServiceAppointment(
                (List<AssignedResource>) records
            );
            update serviceAppointments;
            List<HOT_InterestedResource__c> interestedResource = createInterestedResources(
                (List<AssignedResource>) records
            );
            insert interestedResource;
            List<HOT_InterestedResource__c> interestedResources = updateInterestedResourceStatus(
                (List<AssignedResource>) records
            );
            update interestedResources;

            updateThreads((List<AssignedResource>) records);
        }
    }

    public List<ServiceAppointment> setServiceResourceFieldsOnServiceAppointment(List<AssignedResource> records) {
        //Creates Map and List for SOQL and reference later
        Map<Id, AssignedResource> assignedResourceByServiceAppointmentId = new Map<Id, AssignedResource>();
        List<Id> serviceResourceIds = new List<Id>();
        for (AssignedResource ar : (List<AssignedResource>) records) {
            assignedResourceByServiceAppointmentId.put(ar.ServiceAppointmentId, ar);
            serviceResourceIds.add(ar.ServiceResourceId);
        }

        //Fetches ServiceAppointments to be updated and userId of the ServiceResources
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_AssignedResourceId__c, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE Id IN :assignedResourceByServiceAppointmentId.keySet()
        ];
        Map<Id, ServiceResource> serviceResourceById = new Map<Id, ServiceResource>(
            [SELECT Id, RelatedRecordId, Name FROM ServiceResource WHERE Id IN :serviceResourceIds]
        );

        //Setting fields on ServiceAppointment
        for (ServiceAppointment sa : serviceAppointments) {
            Id serviceResourceId = assignedResourceByServiceAppointmentId.get(sa.Id).ServiceResourceId;
            sa.HOT_ServiceResource__c = serviceResourceId;
            sa.HOT_AssignedResourceId__c = serviceResourceById.get(serviceResourceId).RelatedRecordId;
        }
        return serviceAppointments;
    }

    public override void onAfterDelete() {
        List<Id> serviceAppointmentIds = new List<Id>();
        Map<Id, Id> interestedresourceMap = new Map<Id, Id>();
        for (AssignedResource ar : (List<AssignedResource>) records) {
            serviceAppointmentIds.add(ar.ServiceAppointmentId);
            interestedresourceMap.put(ar.ServiceAppointmentId, ar.ServiceResourceId);
        }
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_ResetToDefault__c, HOT_AssignedResourceId__c, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ];

        for (ServiceAppointment sa : serviceAppointments) {
            sa.HOT_AssignedResourceId__c = null;
            sa.HOT_ServiceResource__c = null;
            sa.HOT_ResetToDefault__c = true;
        }
        update serviceAppointments;

        List<Id> serviceAppointmentIdsList = new List<Id>(interestedresourceMap.keySet());

        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, Status__c, ServiceAppointment__c, ServiceAppointment__r.Status, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c IN :serviceAppointmentIdsList AND ServiceAppointment__r.Status != 'Canceled'
        ];

        for (HOT_InterestedResource__c ir : interestedResources) {
            if (
                ir.ServiceResource__c == interestedresourceMap.get(ir.ServiceAppointment__c) &&
                ir.Status__c != 'Canceled by Interpreter'
            ) {
                ir.Status__c = 'Withdrawn';
            }
        }
        update interestedResources;

        removeEmployeeThreads(serviceAppointmentIds);
    }
    static public void removeEmployeeThreads(List<Id> saIds) {
        if (!saIds.isEmpty()) {
            List<Thread__c> existingThreads = [
                SELECT Id, HOT_IsEmployeeThread__c, CRM_Account__c, CRM_Related_Object__c, HOT_ServiceAppointment__c
                FROM Thread__c
                WHERE
                    CRM_Related_Object__c IN :saIds
                    AND CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
                    AND HOT_IsEmployeeThread__c = TRUE
            ];
            if (!existingThreads.isEmpty()) {
                for (Thread__c thread : existingThreads) {
                    thread.CRM_Related_Object__c = null;
                }
                update existingThreads;
            }
        }
    }

    List<HOT_InterestedResource__c> createInterestedResources(List<AssignedResource> records) {
        List<HOT_InterestedResource__c> interestedResources = new List<HOT_InterestedResource__c>();

        //Creates map to be used in query of InterestedResources
        Map<Id, Id> serviceResourceIdByServiceAppointmentId = new Map<Id, Id>();
        for (AssignedResource assignedResource : records) {
            serviceResourceIdByServiceAppointmentId.put(
                assignedResource.ServiceAppointmentId,
                assignedResource.ServiceResourceId
            );
        }
        //Fetches possible matches with Interested Resources
        List<HOT_InterestedResource__c> existingInterestedResources = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE
                ServiceAppointment__c IN :serviceResourceIdByServiceAppointmentId.keySet()
                AND ServiceResource__c IN :serviceResourceIdByServiceAppointmentId.values()
        ];
        //Fetches Freelance interpreters included in the assigned resource records, and gets their Ids
        List<ServiceResource> serviceResources = [
            SELECT Id
            FROM ServiceResource
            WHERE Id IN :serviceResourceIdByServiceAppointmentId.values() AND HOT_IsFreelanceInterpreter__c = TRUE
        ];
        List<Id> freelanceResourceIds = new List<Id>();
        for (ServiceResource serviceResource : serviceResources) {
            freelanceResourceIds.add(serviceResource.Id);
        }

        //Runs through all AR records, and if the ServiceResource is a freelance interpreter, runs through the Interested Resources and checks for matches on SA and SR
        //If there is no match, an IR should be created.
        for (AssignedResource assignedResource : records) {
            if (freelanceResourceIds.contains(assignedResource.ServiceResourceId)) {
                Boolean shouldCreateInterestedResource = true;
                for (HOT_InterestedResource__c interestedResource : existingInterestedResources) {
                    if (
                        assignedResource.ServiceAppointmentId == interestedResource.ServiceAppointment__c &&
                        assignedResource.ServiceResourceId == interestedResource.ServiceResource__c
                    ) {
                        shouldCreateInterestedResource = false;
                        break;
                    }
                }
                if (shouldCreateInterestedResource) {
                    HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c();
                    interestedResource.ServiceAppointment__c = assignedResource.ServiceAppointmentId;
                    interestedResource.ServiceResource__c = assignedResource.ServiceResourceId;
                    interestedResources.add(interestedResource);
                }
            }
        }
        return interestedResources;
    }

    static public List<HOT_InterestedResource__c> updateInterestedResourceStatus(
        List<AssignedResource> assignedResources
    ) {
        List<Id> serviceAppointmentIds = new List<Id>();
        for (AssignedResource assignedResource : assignedResources) {
            serviceAppointmentIds.add(assignedResource.ServiceAppointmentId);
        }
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, Status__c, ServiceAppointment__c, ServiceResource__c, ServiceAppointment__r.Status
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c IN :serviceAppointmentIds
        ];
        for (AssignedResource assignedResource : assignedResources) {
            for (HOT_InterestedResource__c interestedResource : interestedResources) {
                if (assignedResource.ServiceAppointmentId == interestedResource.ServiceAppointment__c) {
                    if (interestedResource.ServiceResource__c == assignedResource.ServiceResourceId) {
                        if (interestedResource.ServiceAppointment__r.Status == 'Dispatched') {
                            interestedResource.Status__c = 'Assigned';
                        } else {
                            interestedResource.Status__c = 'Reserved';
                        }
                    }
                    if (
                        interestedResource.ServiceResource__c != assignedResource.ServiceResourceId &&
                        interestedResource.Status__c == 'Assigned' &&
                        interestedResource.ServiceAppointment__r.Status != 'Canceled'
                    ) {
                        interestedResource.Status__c = 'Withdrawn';
                    }
                    if (
                        interestedResource.ServiceResource__c != assignedResource.ServiceResourceId &&
                        interestedResource.Status__c == 'Withdrawn'
                    ) {
                    } else if (
                        interestedResource.ServiceResource__c != assignedResource.ServiceResourceId &&
                        (interestedResource.Status__c == 'Declined' ||
                        interestedResource.Status__c == 'Retracted Interest' ||
                        interestedResource.Status__c == 'Canceled by Interpreter')
                    ) {
                    } else if (
                        interestedResource.ServiceResource__c != assignedResource.ServiceResourceId &&
                        interestedResource.Status__c == 'Wanted'
                    ) {
                    } else if (
                        interestedResource.ServiceResource__c != assignedResource.ServiceResourceId &&
                        interestedResource.Status__c != 'Not Assigned'
                    ) {
                        interestedResource.Status__c = 'Not Assigned';
                    }
                }
            }
        }
        return interestedResources;
    }
    public static void updateThreads(List<AssignedResource> assignedResources) {
        List<Id> serviceAppointmentIds = new List<Id>();

        for (AssignedResource assignedResource : assignedResources) {
            serviceAppointmentIds.add(assignedResource.ServiceAppointmentId);
        }
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, Status__c, ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c IN :serviceAppointmentIds
        ];

        //key IR
        Map<Id, AssignedResource> threadToAR = new Map<Id, AssignedResource>();
        //key SA
        Map<Id, HOT_InterestedResource__c> threadToIR = new Map<Id, HOT_InterestedResource__c>();

        for (AssignedResource assignedResource : assignedResources) {
            for (HOT_InterestedResource__c interestedResource : interestedResources) {
                if (assignedResource.ServiceAppointmentId == interestedResource.ServiceAppointment__c) {
                    if (
                        interestedResource.ServiceResource__c == assignedResource.ServiceResourceId &&
                        interestedResource.Status__c == 'Assigned'
                    ) {
                        //FRA IR TIL SA
                        threadToAR.put(interestedResource.Id, assignedResource);
                    } else if (
                        //Må vel endres om til Withdrawn siden
                        interestedResource.ServiceResource__c != assignedResource.ServiceResourceId &&
                        interestedResource.Status__c == 'Not Assigned' || interestedResource.Status__c == 'Withdrawn'
                    ) {
                        //FRA SA TIL IR
                        threadToIR.put(assignedResource.ServiceAppointmentId, interestedResource);
                    }
                }
            }
        }
        List<Thread__c> arThreadList = [
            SELECT Id, CRM_Related_Object__c, HOT_IsEmployeeThread__c
            FROM Thread__c
            WHERE CRM_Related_Object__c IN :serviceAppointmentIds AND HOT_IsEmployeeThread__c = TRUE
        ];
        if (!arThreadList.isEmpty()) {
            for (Thread__c thread : arThreadList) {
                thread.CRM_Related_Object__c = null;
            }
            update arThreadList;
        }
        if (!threadToIR.isEmpty()) {
            List<Thread__c> threadListToIR = [
                SELECT Id, CRM_Related_Object__c, HOT_IsEmployeeThread__c
                FROM Thread__c
                WHERE CRM_Related_Object__c IN :threadToIR.keySet() AND HOT_IsEmployeeThread__c = FALSE
            ];
            if (!threadListToIR.isEmpty()) {
                for (Thread__c thread : threadListToIR) {
                    HOT_InterestedResource__c interestedResource = threadToIR.get(thread.CRM_Related_Object__c);
                    if (interestedResource != null) {
                        thread.CRM_Related_Object__c = interestedResource.Id;
                    }
                }
                update threadListToIR;
            }
        }
        //den som fjerner eksisterende tråd på sa burde kjøres først.
        if (!threadToAR.isEmpty()) {
            List<Thread__c> threadListToAR = [
                SELECT Id, CRM_Related_Object__c
                FROM Thread__c
                WHERE CRM_Related_Object__c IN :threadToAR.keySet()
            ];
            if (!threadListToAR.isEmpty()) {
                //Loop igjennom alle trådene og sett ny crm related object to SA id istedet
                for (Thread__c thread : threadListToAR) {
                    AssignedResource assignedResource = threadToAR.get(thread.CRM_Related_Object__c);
                    if (assignedResource != null) {
                        thread.CRM_Related_Object__c = assignedResource.ServiceAppointmentId;
                    }
                }
                update threadListToAR;
            }
        }
    }

    public static void setResourceFieldsOnServiceAppointment(List<AssignedResource> assignedResources) {
        List<Id> serviceAppointmentIds = new List<Id>();
        List<Id> serviceResourceIds = new List<Id>();
        for (AssignedResource assignedResource : assignedResources) {
            serviceAppointmentIds.add(assignedResource.ServiceAppointmentId);
            serviceResourceIds.add(assignedResource.ServiceResourceId);
        }
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT
                    Id,
                    HOT_IsReleasedToFreelance__c,
                    HOT_IsEmployedInterpreter__c,
                    ServiceTerritoryId,
                    EarliestStartTime,
                    DueDate,
                    SchedStartTime,
                    SchedEndTime,
                    Subject,
                    HOT_FreelanceSubject__c
                FROM ServiceAppointment
                WHERE Id IN :serviceAppointmentIds
            ]
        );
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(
            [
                SELECT Id, HOT_IsFreelanceInterpreter__c, HOT_IsEmployedInterpreter__c, HOT_ServiceTerritory__c
                FROM ServiceResource
                WHERE Id IN :serviceResourceIds
            ]
        );

        Map<Id, ServiceAppointment> serviceAppointmentsToUpdate = new Map<Id, ServiceAppointment>();
        for (AssignedResource assignedResource : assignedResources) {
            ServiceAppointment currentServiceAppointment = serviceAppointments.get(
                assignedResource.ServiceAppointmentId
            );
            ServiceResource currentServiceResource = serviceResources.get(assignedResource.ServiceResourceId);
            // Set Interpreter/Freelance fields
            if (
                currentServiceResource.HOT_IsEmployedInterpreter__c !=
                currentServiceAppointment.HOT_IsEmployedInterpreter__c
            ) {
                currentServiceAppointment.HOT_IsEmployedInterpreter__c = currentServiceResource
                    .HOT_IsEmployedInterpreter__c;
                currentServiceAppointment.HOT_IsReleasedToFreelance__c = currentServiceResource
                    .HOT_IsFreelanceInterpreter__c;
                serviceAppointmentsToUpdate.put(assignedResource.ServiceAppointmentId, currentServiceAppointment);
            }
            if (
                currentServiceAppointment.HOT_IsReleasedToFreelance__c == true &&
                currentServiceAppointment.HOT_FreelanceSubject__c == null
            ) {
                currentServiceAppointment.HOT_FreelanceSubject__c = currentServiceAppointment.Subject;
            }
            // Set ServiceTerritory
            if (currentServiceAppointment.ServiceTerritoryId != currentServiceResource.HOT_ServiceTerritory__c) {
                currentServiceAppointment.ServiceTerritoryId = currentServiceResource.HOT_ServiceTerritory__c;
                serviceAppointmentsToUpdate.put(assignedResource.ServiceAppointmentId, currentServiceAppointment);
            }
        }
        update serviceAppointmentsToUpdate.values();
    }

    public static void notifyResource(List<AssignedResource> assignedResources) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'HOT_Service_Appointment_Changed'
        ];

        List<Id> serviceResourceIds = new List<Id>();
        List<Id> serviceAppointmentIds = new List<Id>();
        for (AssignedResource assignedResource : assignedResources) {
            serviceResourceIds.add(assignedResource.ServiceResourceId);
            serviceAppointmentIds.add(assignedResource.ServiceAppointmentId);
        }
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(
            [SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN :serviceResourceIds]
        );
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, AppointmentNumber, EarliestStartTime, Status, HOT_IsEmployedInterpreter__c
                FROM ServiceAppointment
                WHERE Id IN :serviceAppointmentIds
            ]
        );

        for (AssignedResource assignedResource : assignedResources) {
            if (serviceAppointments.get(assignedResource.ServiceAppointmentId).Status != 'Scheduled') {
                HOT_ServiceAppointmentNotification.resourceChanged(
                    notificationType,
                    new Set<Id>{ serviceAppointments.get(assignedResource.ServiceAppointmentId).Id },
                    new Set<String>{ serviceResources.get(assignedResource.ServiceResourceId).RelatedRecordId }
                );
            }
        }
    }

    public static void throwExceptionIfARHasSAOverlap(List<AssignedResource> assignedResources, Boolean isUpdate) {
        List<Id> serviceAppointmentIds = new List<Id>();
        List<Id> serviceResourceIds = new List<Id>();
        for (AssignedResource assignedResource : assignedResources) {
            serviceAppointmentIds.add(assignedResource.ServiceAppointmentId);
            serviceResourceIds.add(assignedResource.ServiceResourceId);
        }

        List<String> exludedStatuses = new List<String>{ 'Annul', 'Canceled', 'Completed' };
        // Find all service appointments related to assigned resources
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT
                    Id,
                    HOT_AssignedResourceId__c,
                    HOT_ServiceResource__c,
                    HOT_NumberOfAssignedResources__c,
                    EarliestStartTime,
                    DueDate
                FROM ServiceAppointment
                WHERE Id IN :serviceAppointmentIds
            ]
        );

        // Find all service resources related to assigned resources
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(
            [
                SELECT
                    Id,
                    (
                        SELECT Id, EarliestStartTime, DueDate, HOT_ServiceResource__c
                        FROM HOT_ServiceAppointments__r
                        WHERE Status NOT IN :exludedStatuses
                    )
                FROM ServiceResource
                WHERE Id IN :serviceResourceIds
            ]
        );

        // If new AR with SR is added from SA when AR on SA already exists - do not allow
        // If SR is changed on AR - allow - as long as time slot is available
        for (AssignedResource ar : assignedResources) {
            if (
                !isUpdate &&
                (serviceAppointments.get(ar.ServiceAppointmentId).HOT_AssignedResourceId__c != null ||
                serviceAppointments.get(ar.ServiceAppointmentId).HOT_NumberOfAssignedResources__c != 0)
            ) {
                ar.addError('Du kan ikke sette opp flere ressurser på et oppdrag.');
                continue;
            }
            // Check if AR already has service appointment overlapping with current SA - loop over list of related SAs on AR's related SR
            for (Integer i = 0; i < serviceResources.get(ar.ServiceResourceId).HOT_ServiceAppointments__r.size(); i++) {
                if (
                    HOT_DateTimeHandler.checkOverlappingDateTimes(
                        serviceResources.get(ar.ServiceResourceId).HOT_ServiceAppointments__r[i].EarliestStartTime,
                        serviceResources.get(ar.ServiceResourceId).HOT_ServiceAppointments__r[i].DueDate,
                        serviceAppointments.get(ar.ServiceAppointmentId).EarliestStartTime,
                        serviceAppointments.get(ar.ServiceAppointmentId).DueDate
                    )
                ) {
                    ar.addError('Ressursen har allerede et oppdrag i dette tidsrommet.');
                }
            }
        }
    }
}
