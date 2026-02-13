public without sharing class HOT_ServiceAppointmentHandler extends MyTriggers {
    public override void onBeforeInsert() {
        setOwnerAndStatus((List<ServiceAppointment>) records);
        setDefaultFields((List<ServiceAppointment>) records);
        setCompanyOnServiceAppointment((List<ServiceAppointment>) records);
    }

    public override void onAfterInsert() {
        createContentDocumentLinks((List<ServiceAppointment>) records);
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<ServiceAppointment> serviceAppointmentsStatusFromCannotCompleteToNone = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsChangedOrderedTime = new List<ServiceAppointment>();
        List<ServiceAppointment> recievedNewInterpreter = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithChangedStatusOrResource = new List<ServiceAppointment>();
        List<ServiceAppointment> allServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> releasedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> retractedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> completedImageInterpreterServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> SAnotifyDispatcher = new List<ServiceAppointment>();
        List<ServiceAppointment> annulServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithHoursToSet = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsToSetToDefault = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithActualTimeSet = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithoutActualTimeSet = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsToChangeOwnerToArchive = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithStatusNone = new List<ServiceAppointment>();

        Map<Id, Id> resourceByAppointmentCreateWageClaim = new Map<Id, Id>();

        for (ServiceAppointment serviceAppointment : (List<ServiceAppointment>) records) {
            if (
                triggerOldMap.get(serviceAppointment.Id).get('EarliestStartTime') !=
                serviceAppointment.EarliestStartTime ||
                triggerOldMap.get(serviceAppointment.Id).get('DueDate') != serviceAppointment.DueDate
            ) {
                serviceAppointmentsWithHoursToSet.add(serviceAppointment);
            }
            if (
                //Canceled on behalf of user
                //Canceled by interpreter
                triggerOldMap.get(serviceAppointment.Id).get('HOT_IsNotifyDispatcher__c') !=
                serviceAppointment.HOT_IsNotifyDispatcher__c &&
                serviceAppointment.HOT_IsNotifyDispatcher__c == true
            ) {
                SAnotifyDispatcher.add(serviceAppointment);
            }
            if (
                serviceAppointment.get('HOT_ServiceResource__c') != null &&
                serviceAppointment.get('HOT_ServiceResource__c') !=
                triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')
            ) {
                recievedNewInterpreter.add(serviceAppointment);
            }

            if (
                serviceAppointment.Status == 'None' &&
                triggerOldMap.get(serviceAppointment.Id).get('Status') == 'Cannot Complete'
            ) {
                serviceAppointmentsStatusFromCannotCompleteToNone.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') ||
                serviceAppointment.HOT_ServiceResource__c !=
                triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')
            ) {
                serviceAppointmentsWithChangedStatusOrResource.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                serviceAppointment.Status == 'Released to Freelance'
            ) {
                releasedServiceAppointments.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                serviceAppointment.Status == 'None' &&
                triggerOldMap.get(serviceAppointment.Id).get('Status') == 'Released to Freelance'
            ) {
                retractedServiceAppointments.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                serviceAppointment.Status == 'Completed' &&
                serviceAppointment.ActualStartTime == null &&
                serviceAppointment.ActualEndTime == null &&
                serviceAppointment.HOT_IsImageInterpreter__c == true
            ) {
                completedImageInterpreterServiceAppointments.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                serviceAppointment.Status == 'Annul'
            ) {
                annulServiceAppointments.add(serviceAppointment);
            }
            if (
                serviceAppointment.HOT_ServiceResource__c !=
                triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c') &&
                triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c') != null &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                resourceByAppointmentCreateWageClaim.put(
                    serviceAppointment.Id,
                    (Id) triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')
                );
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                triggerOldMap.get(serviceAppointment.Id).get('Status') == 'Dispatched' &&
                (serviceAppointment.Status == null ||
                serviceAppointment.Status == 'Canceled' ||
                serviceAppointment.Status == 'Annul' ||
                serviceAppointment.Status == 'Scheduled' ||
                serviceAppointment.Status == 'None') &&
                serviceAppointment.HOT_CanceledByInterpreter__c == false
            ) {
                resourceByAppointmentCreateWageClaim.put(
                    serviceAppointment.Id,
                    (Id) triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')
                );
            }

            if (serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status')) {
                setGanttColor(serviceAppointment);
            }
            if (
                serviceAppointment.HOT_ResetToDefault__c !=
                triggerOldMap.get(serviceAppointment.Id).get('HOT_ResetToDefault__c') &&
                serviceAppointment.HOT_ResetToDefault__c == true
            ) {
                serviceAppointmentsToSetToDefault.add(serviceAppointment);
            }
            if (
                (serviceAppointment.ActualStartTime !=
                triggerOldMap.get(serviceAppointment.Id).get('ActualStartTime') &&
                serviceAppointment.ActualStartTime != serviceAppointment.SchedStartTime) ||
                (serviceAppointment.ActualEndTime != triggerOldMap.get(serviceAppointment.Id).get('ActualEndTime') &&
                serviceAppointment.ActualEndTime != serviceAppointment.SchedEndTime)
            ) {
                serviceAppointmentsWithActualTimeSet.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status == 'Completed' &&
                serviceAppointment.ActualStartTime == null &&
                serviceAppointment.ActualEndTime == null &&
                serviceAppointment.SchedStartTime != null &&
                serviceAppointment.SchedEndTime != null
            ) {
                serviceAppointmentsWithoutActualTimeSet.add(serviceAppointment);
            }
            updateDuration(serviceAppointment);
            allServiceAppointments.add(serviceAppointment);

            // Ordered time is changed
            if (
                serviceAppointment.EarliestStartTime !=
                triggerOldMap.get(serviceAppointment.Id).get('EarliestStartTime') ||
                serviceAppointment.DueDate != triggerOldMap.get(serviceAppointment.Id).get('DueDate')
            ) {
                serviceAppointmentsChangedOrderedTime.add(serviceAppointment);
            }
            if (
                triggerOldMap.get(serviceAppointment.Id).get('HOT_DelPol_IsHideRecord__c') !==
                serviceAppointment.HOT_DelPol_IsHideRecord__c && serviceAppointment.HOT_DelPol_IsHideRecord__c
            ) {
                serviceAppointmentsToChangeOwnerToArchive.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                serviceAppointment.Status == 'None'
            ) {
                serviceAppointmentsWithStatusNone.add(serviceAppointment);
            }
        }

        if (recievedNewInterpreter.size() > 0) {
            updateCancelledByInterpreter(recievedNewInterpreter);
        }
        if (serviceAppointmentsStatusFromCannotCompleteToNone.size() > 0) {
            preserveSchedulesTimes(serviceAppointmentsStatusFromCannotCompleteToNone, triggerOldMap);
        }
        if (serviceAppointmentsWithChangedStatusOrResource.size() > 0) {
            createHistoricallyAssignedResources(serviceAppointmentsWithChangedStatusOrResource, triggerOldMap);
        }
        if (releasedServiceAppointments.size() > 0) {
            releaseServiceAppointments(releasedServiceAppointments);
        }
        if (retractedServiceAppointments.size() > 0) {
            retractServiceAppointments(retractedServiceAppointments);
        }
        if (completedImageInterpreterServiceAppointments.size() > 0) {
            setActualTime(completedImageInterpreterServiceAppointments);
        }
        if (SAnotifyDispatcher.size() > 0) {
            HOT_ServiceAppointmentNotification.dispatcherServiceAppointmentChanged(SAnotifyDispatcher, triggerOldMap);
            resetNotifyDispatcher(SAnotifyDispatcher);
        }
        if (annulServiceAppointments.size() > 0) {
            removeCustomAccountLookup(annulServiceAppointments);
        }

        if (serviceAppointmentsWithHoursToSet.size() > 0) {
            setStartAndEndHour(serviceAppointmentsWithHoursToSet);
        }

        if (serviceAppointmentsToSetToDefault.size() > 0) {
            setDefaultFields(serviceAppointmentsToSetToDefault);
        }
        if (!resourceByAppointmentCreateWageClaim.isEmpty()) {
            HOT_WageClaimService.createWageClaims(resourceByAppointmentCreateWageClaim);
        }
        if (serviceAppointmentsWithActualTimeSet.size() > 0) {
            setScheduledTimeBasedOnActualTime(serviceAppointmentsWithActualTimeSet);
        }
        if (serviceAppointmentsWithoutActualTimeSet.size() > 0) {
            setActualTime(serviceAppointmentsWithoutActualTimeSet);
        }
        if (serviceAppointmentsChangedOrderedTime.size() > 0) {
            preserveSchedulesTimes(serviceAppointmentsChangedOrderedTime, triggerOldMap);
        }
        if (serviceAppointmentsToChangeOwnerToArchive.size() > 0) {
            HOT_Utility.setArchiveAsOwner(serviceAppointmentsToChangeOwnerToArchive);
            setRecalculateManualSharingFlag(serviceAppointmentsToChangeOwnerToArchive);
        }
        if (serviceAppointmentsWithStatusNone.size() > 0) {
            setScheduledTimesOnStatusNone(serviceAppointmentsWithStatusNone);
        }
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<ServiceAppointment> serviceAppointmentsToRemoveAssignedResource = new List<ServiceAppointment>();
        List<ServiceAppointment> releasedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> dispatchedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> retractedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithChangedAddress = new List<ServiceAppointment>();
        List<ServiceAppointment> SAnotifyResource = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsOwnerChangedWithAssignedResource = new List<ServiceAppointment>();
        Map<Id, Id> serviceResourceByServiceAppointmentSchedTimeChanged = new Map<Id, Id>();
        Map<Id, ServiceAppointment> oldServiceAppointmentsSchedTimeChanged = new Map<Id, ServiceAppointment>();
        Map<Id, ServiceAppointment> newServiceAppointmentsSchedTimeChanged = new Map<Id, ServiceAppointment>();
        Map<Id, ServiceAppointment> serviceAppointmentWithNewAssignedResource = new Map<Id, ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithUpdatedOwnerOrDispatcher = new List<ServiceAppointment>();
        Set<Id> serviceAppointmentsWithStatusCannotComplete = new Set<Id>();

        for (ServiceAppointment serviceAppointment : (List<ServiceAppointment>) records) {
            if (
                triggerOldMap.get(serviceAppointment.Id).get('OwnerId') != serviceAppointment.OwnerId &&
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.HOT_DelPol_IsHideRecord__c == false
            ) {
                serviceAppointmentsOwnerChangedWithAssignedResource.add(serviceAppointment);
            }
            if (
                (serviceAppointment.Status == 'Canceled' ||
                serviceAppointment.Status == 'Annul' ||
                serviceAppointment.Status == 'None') &&
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status')
            ) {
                serviceAppointmentsToRemoveAssignedResource.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                serviceAppointment.Status == 'Released to Freelance'
            ) {
                releasedServiceAppointments.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                dispatchedServiceAppointments.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                serviceAppointment.Status == 'None' &&
                triggerOldMap.get(serviceAppointment.Id).get('Status') == 'Released to Freelance'
            ) {
                retractedServiceAppointments.add(serviceAppointment);
            }
            if (
                serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') &&
                serviceAppointment.Status == 'Annul' || serviceAppointment.Status == 'Cannot Complete'
            ) {
                retractedServiceAppointments.add(serviceAppointment);
                if (
                    serviceAppointment.SchedEndTime >= System.today() &&
                    serviceAppointment.Status == 'Cannot Complete'
                ) {
                    serviceAppointmentsWithStatusCannotComplete.add(serviceAppointment.Id);
                }
            }
            if (
                serviceAppointment.HOT_AddressFormated__c !=
                triggerOldMap.get(serviceAppointment.Id).get('HOT_AddressFormated__c')
            ) {
                serviceAppointmentsWithChangedAddress.add(serviceAppointment);
            }
            if (
                (serviceAppointment.SchedStartTime != triggerOldMap.get(serviceAppointment.Id).get('SchedStartTime') ||
                serviceAppointment.SchedEndTime != triggerOldMap.get(serviceAppointment.Id).get('SchedEndTime')) &&
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.SchedStartTime != null &&
                triggerOldMap.get(serviceAppointment.Id).get('SchedStartTime') != null &&
                serviceAppointment.SchedEndTime != null &&
                triggerOldMap.get(serviceAppointment.Id).get('SchedEndTime') != null &&
                (serviceAppointment.Status == 'Dispatched' ||
                serviceAppointment.Status == 'Completed')
            ) {
                serviceResourceByServiceAppointmentSchedTimeChanged.put(
                    triggerOldMap.get(serviceAppointment.Id).Id,
                    (Id) triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')
                );
                oldServiceAppointmentsSchedTimeChanged.put(
                    triggerOldMap.get(serviceAppointment.Id).Id,
                    (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id)
                );
                newServiceAppointmentsSchedTimeChanged.put(serviceAppointment.Id, serviceAppointment);
            }
            if (
                serviceAppointment.Status != 'Scheduled' &&
                serviceAppointment.Status != 'Completed' &&
                (serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') ||
                serviceAppointment.HOT_ServiceResource__c !=
                triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')) &&
                (serviceAppointment.HOT_ServiceResource__c != null ||
                triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c') != null)
            ) {
                serviceAppointmentWithNewAssignedResource.put(serviceAppointment.Id, serviceAppointment);
            }

            if (
                triggerOldMap.get(serviceAppointment.Id).get('OwnerId') != serviceAppointment.OwnerId ||
                triggerOldMap.get(serviceAppointment.Id).get('HOT_DispatcherNew__c') !=
                serviceAppointment.HOT_DispatcherNew__c
            ) {
                serviceAppointmentsWithUpdatedOwnerOrDispatcher.add(serviceAppointment);
            }
        }
        HOT_ServiceAppointmentNotification.resourceServiceAppointmentChanged(
            (List<ServiceAppointment>) records,
            triggerOldMap
        );
        HOT_EventController.updateServiceAppointmentEvents((List<ServiceAppointment>) records, triggerOldMap);

        if (serviceAppointmentsToRemoveAssignedResource.size() > 0) {
            removeAssignedResource(serviceAppointmentsToRemoveAssignedResource);
        }
        if (releasedServiceAppointments.size() > 0) {
            updateStatusOnInterestedResources(releasedServiceAppointments, 'None');
        }
        if (dispatchedServiceAppointments.size() > 0) {
            updateStatusOnInterestedResources(dispatchedServiceAppointments, 'Assigned');
        }
        if (retractedServiceAppointments.size() > 0) {
            updateStatusOnInterestedResources(retractedServiceAppointments, 'Service Appointment Retracted');
        }
        if (!serviceAppointmentWithNewAssignedResource.isEmpty()) {
            HOT_InterpreterOnWorkOrderService.setInterpreterOnWorkOrderFromServiceAppointment(
                serviceAppointmentWithNewAssignedResource.keySet()
            );
            HOT_ThreadHandler.setInterpreterOnThreadFromServiceAppointment(
                serviceAppointmentWithNewAssignedResource.keySet()
            );
        }
        if (serviceAppointmentsOwnerChangedWithAssignedResource.size() > 0) {
            Map<String, Map<Id, Id>> appointmentAndResourceByAssignment = getAppointmentAndResourceByAssignment(
                serviceAppointmentsOwnerChangedWithAssignedResource
            );
            HOT_ServiceAppointmentsSharingService.grantAccess(
                appointmentAndResourceByAssignment.get('appointment'),
                appointmentAndResourceByAssignment.get('resource')
            );
        }
        if (!serviceResourceByServiceAppointmentSchedTimeChanged.isEmpty()) {
            Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(
                [
                    SELECT Id, HOT_IsFreelanceInterpreter__c, HOT_AgreementFreelance__c
                    FROM ServiceResource
                    WHERE Id IN :serviceResourceByServiceAppointmentSchedTimeChanged.values()
                ]
            );

            Map<Id, ServiceAppointment> oldServiceAppointmentsWithRequestFields = getServiceAppointmnetsWithAgreementFieldsFromRequest(
                oldServiceAppointmentsSchedTimeChanged
            );
            setScheduledTimesToOldValues(
                oldServiceAppointmentsWithRequestFields,
                oldServiceAppointmentsSchedTimeChanged
            );
            List<HOT_WageClaim__c> wageClaims = HOT_WageClaimService.createWageClaimsForChangedAppointment(
                oldServiceAppointmentsWithRequestFields,
                newServiceAppointmentsSchedTimeChanged,
                serviceResourceByServiceAppointmentSchedTimeChanged,
                serviceResources
            );
            insert wageClaims;
        }

        if (serviceAppointmentsWithUpdatedOwnerOrDispatcher.size() > 0) {
            updateOwnerOrDispatcherOnThread(serviceAppointmentsWithUpdatedOwnerOrDispatcher);
        }

        if (serviceAppointmentsWithStatusCannotComplete.size() > 0) {
            HOT_InterpreterOnWorkOrderService.setInterpreterOnWorkOrderFromServiceAppointment(
                serviceAppointmentsWithStatusCannotComplete
            );
        }
    }

    public static void updateOwnerOrDispatcherOnThread(List<ServiceAppointment> records) {
        Map<Id, Map<Id, Id>> serviceAppointmentWithOwnerDispatcher = new Map<Id, Map<Id, Id>>();
        Set<Id> saIds = new Set<Id>();

        for (ServiceAppointment sa : records) {
            saIds.add(sa.Id);
            serviceAppointmentWithOwnerDispatcher.put(sa.Id, new Map<Id, Id>{ sa.OwnerId => sa.HOT_DispatcherNew__c });
        }
        List<Thread__c> threadList = [
            SELECT Id, CRM_Related_Object__c
            FROM Thread__c
            WHERE CRM_Related_Object__c IN :saIds
        ];

        for (Thread__c thread : threadList) {
            Id relatedId = thread.CRM_Related_Object__c;

            if (serviceAppointmentWithOwnerDispatcher.containsKey(relatedId)) {
                Map<Id, Id> ownerAndDispatchers = serviceAppointmentWithOwnerDispatcher.get(relatedId);
                if (ownerAndDispatchers.size() == 1) {
                    thread.OwnerId = ownerAndDispatchers.keySet().iterator().next();
                    thread.HOT_Dispatcher__c = ownerAndDispatchers.get(thread.OwnerId);
                }
            }
        }
        update threadList;
    }

    private static void setScheduledTimesToOldValues(
        Map<Id, ServiceAppointment> serviceAppointments,
        Map<Id, ServiceAppointment> oldServiceAppointments
    ) {
        for (ServiceAppointment sa : serviceAppointments.values()) {
            sa.SchedStartTime = oldServiceAppointments.get(sa.Id).SchedStartTime;
            sa.SchedEndTime = oldServiceAppointments.get(sa.Id).SchedEndTime;
        }
    }

    private static Map<Id, ServiceAppointment> getServiceAppointmnetsWithAgreementFieldsFromRequest(
        Map<Id, ServiceAppointment> serviceAppointments
    ) {
        Map<Id, ServiceAppointment> serviceAppointmentsWithRequestFields = new Map<Id, ServiceAppointment>(
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
                WHERE Id IN :serviceAppointments.keySet()
            ]
        );
        return serviceAppointmentsWithRequestFields;
    }

    private static void setDefaultFields(List<ServiceAppointment> serviceAppointments) {
        setFieldsBasedOnParent(serviceAppointments);
    }

    private static void removeAssignedResource(List<ServiceAppointment> serviceAppointments) {
        List<AssignedResource> arList = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :serviceAppointments
        ];
        delete arList;
    }

    private static void updateCancelledByInterpreter(List<ServiceAppointment> recievedNewInterpreter) {
        for (ServiceAppointment serviceAppointment : recievedNewInterpreter) {
            serviceAppointment.HOT_CanceledByInterpreter__c = false;
        }
    }
    private static void setFieldsBasedOnParent(List<ServiceAppointment> serviceAppointments) {
        List<Id> workOrderLineItemIds = new List<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            workOrderLineItemIds.add(serviceAppointment.ParentRecordId);
        }
        Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem>(
            [
                SELECT
                    Id,
                    WorkOrder.AccountId,
                    WorkOrder.HOT_Request__c,
                    WorkOrder.OwnerId,
                    Subject,
                    Description,
                    StartDate,
                    EndDate,
                    Street,
                    City,
                    PostalCode,
                    HOT_InterpretationPostalCity__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_InterpretationPostalStreet__c,
                    ServiceTerritoryId
                FROM WorkOrderLineItem
                WHERE Id IN :workOrderLineItemIds
            ]
        );

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_ResetToDefault__c = false;
            serviceAppointment.SchedStartTime = serviceAppointment.EarliestStartTime;
            serviceAppointment.SchedEndTime = serviceAppointment.DueDate;
            serviceAppointment.HOT_IsReleasedToFreelance__c = false;
            serviceAppointment.HOT_IsEmployedInterpreter__c = true;

            if (serviceAppointment.ParentRecordId != null) {
                if (
                    serviceAppointment.HOT_Request__c == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrder.HOT_Request__c != null
                ) {
                    serviceAppointment.HOT_Request__c = workOrderLineItems.get(serviceAppointment.ParentRecordId)
                        .WorkOrder.HOT_Request__c;
                }
                if (
                    serviceAppointment.Subject == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).Subject != null
                ) {
                    serviceAppointment.Subject = workOrderLineItems.get(serviceAppointment.ParentRecordId).Subject;
                }
                if (
                    serviceAppointment.Description == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).Description != null
                ) {
                    serviceAppointment.Description = workOrderLineItems.get(serviceAppointment.ParentRecordId)
                        .Description;
                }
                if (
                    serviceAppointment.HOT_InterpretationPostalCity__c == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).HOT_InterpretationPostalCity__c != null
                ) {
                    serviceAppointment.HOT_InterpretationPostalCity__c = workOrderLineItems.get(
                            serviceAppointment.ParentRecordId
                        )
                        .HOT_InterpretationPostalCity__c;
                }
                if (
                    serviceAppointment.HOT_InterpretationPostalCode__c == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).HOT_InterpretationPostalCode__c != null
                ) {
                    serviceAppointment.HOT_InterpretationPostalCode__c = workOrderLineItems.get(
                            serviceAppointment.ParentRecordId
                        )
                        .HOT_InterpretationPostalCode__c;
                }
                if (
                    serviceAppointment.HOT_InterpretationStreet__c == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).HOT_InterpretationPostalStreet__c != null
                ) {
                    serviceAppointment.HOT_InterpretationStreet__c = workOrderLineItems.get(
                            serviceAppointment.ParentRecordId
                        )
                        .HOT_InterpretationPostalStreet__c;
                }
                if (
                    serviceAppointment.HOT_AssignmentType__c == 'Bildetolkvakt' ||
                    serviceAppointment.HOT_IsScreenInterpreter__c ||
                    serviceAppointment.Country == null
                ) {
                    serviceAppointment.Country = 'Norge';
                }
                if (
                    serviceAppointment.HOT_AssignmentType__c == 'Bildetolkvakt' ||
                    serviceAppointment.HOT_IsScreenInterpreter__c ||
                    (serviceAppointment.City == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).City != null)
                ) {
                    serviceAppointment.City = workOrderLineItems.get(serviceAppointment.ParentRecordId).City;
                    if (
                        serviceAppointment.HOT_AssignmentType__c == 'Bildetolkvakt' ||
                        serviceAppointment.HOT_IsScreenInterpreter__c
                    ) {
                        serviceAppointment.City = '-';
                    }
                }
                if (
                    serviceAppointment.HOT_AssignmentType__c == 'Bildetolkvakt' ||
                    serviceAppointment.HOT_IsScreenInterpreter__c ||
                    (serviceAppointment.PostalCode == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).PostalCode != null)
                ) {
                    serviceAppointment.PostalCode = workOrderLineItems.get(serviceAppointment.ParentRecordId)
                        .PostalCode;
                    if (
                        serviceAppointment.HOT_AssignmentType__c == 'Bildetolkvakt' ||
                        serviceAppointment.HOT_IsScreenInterpreter__c
                    ) {
                        serviceAppointment.PostalCode = '-';
                    }
                }
                if (
                    serviceAppointment.HOT_AssignmentType__c == 'Bildetolkvakt' ||
                    serviceAppointment.HOT_IsScreenInterpreter__c ||
                    (serviceAppointment.Street == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).Street != null)
                ) {
                    serviceAppointment.Street = workOrderLineItems.get(serviceAppointment.ParentRecordId).Street;
                    if (
                        serviceAppointment.HOT_AssignmentType__c == 'Bildetolkvakt' ||
                        serviceAppointment.HOT_IsScreenInterpreter__c
                    ) {
                        serviceAppointment.Street = '-';
                    }
                }
                if (
                    serviceAppointment.EarliestStartTime == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).StartDate != null
                ) {
                    serviceAppointment.EarliestStartTime = workOrderLineItems.get(serviceAppointment.ParentRecordId)
                        .StartDate;
                }
                if (
                    serviceAppointment.DueDate == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).EndDate != null
                ) {
                    serviceAppointment.DueDate = workOrderLineItems.get(serviceAppointment.ParentRecordId).EndDate;
                }
                if (
                    serviceAppointment.SchedStartTime == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).StartDate != null
                ) {
                    serviceAppointment.SchedStartTime = workOrderLineItems.get(serviceAppointment.ParentRecordId)
                        .StartDate;
                }
                if (
                    serviceAppointment.SchedEndTime == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).EndDate != null
                ) {
                    serviceAppointment.SchedEndTime = workOrderLineItems.get(serviceAppointment.ParentRecordId).EndDate;
                }
                if (serviceAppointment.HOT_WorkOrderLineItem__c == null && serviceAppointment.ParentRecordId != null) {
                    serviceAppointment.HOT_WorkOrderLineItem__c = serviceAppointment.ParentRecordId;
                }
                if (workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrder.AccountId != null) {
                    serviceAppointment.HOT_Account__c = workOrderLineItems.get(serviceAppointment.ParentRecordId)
                        .WorkOrder.AccountId;
                }
                if (workOrderLineItems.get(serviceAppointment.ParentRecordId).ServiceTerritoryId != null) {
                    serviceAppointment.ServiceTerritoryId = workOrderLineItems.get(serviceAppointment.ParentRecordId)
                        .ServiceTerritoryId;
                }
                updateDuration(serviceAppointment);
            }
        }
        setStartAndEndHour(serviceAppointments);
    }

    private static void setGanttColor(ServiceAppointment serviceAppointment) {
        Set<String> serviceAppointmentFields = Schema.SObjectType.ServiceAppointment.fields.getMap().keySet();

        if (serviceAppointment.HOT_IsImageInterpreter__c) {
            if (serviceAppointmentFields.contains('fsl__ganttcolor__c')) {
                Map<String, String> ganttColorByStatus = getGanttColorByStatus(
                    serviceAppointment.HOT_IsImageInterpreter__c
                );
                if (ganttColorByStatus.isEmpty()) {
                    serviceAppointment.put('fsl__ganttcolor__c', null);
                } else {
                    serviceAppointment.put('fsl__ganttcolor__c', ganttColorByStatus.get(serviceAppointment.Status));
                }
            }
            serviceAppointment.HOT_AutoDispatch__c = true;
        }
    }

    private static void setOwnerAndStatus(List<ServiceAppointment> serviceAppointments) {
        List<Id> requestIds = new List<Id>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            requestIds.add(ServiceAppointment.HOT_Request__c);
        }

        Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>(
            [SELECT Id, Dispatcher__C FROM HOT_Request__C WHERE Id IN :requestIds]
        );

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.Status = 'None';
            serviceAppointment.HOT_DispatcherNew__c = requests.get(serviceAppointment.HOT_Request__C)?.Dispatcher__c;
            if (serviceAppointment.HOT_Request__c != null) {
                serviceAppointment.OwnerId = serviceAppointment.HOT_RequestOwnerId__c;
            }
        }
    }

    public static List<ServiceAppointment> setStartAndEndHour(List<ServiceAppointment> records) {
        for (ServiceAppointment serviceAppointment : records) {
            serviceAppointment.HOT_StartHour__c = serviceAppointment.EarliestStartTime != null
                ? serviceAppointment.EarliestStartTime.format('HH', 'Europe/Oslo')
                : null;
            serviceAppointment.HOT_EndHour__c = serviceAppointment.DueDate != null
                ? serviceAppointment.DueDate.format('HH', 'Europe/Oslo')
                : null;
        }
        return records;
    }

    private static void createHistoricallyAssignedResources(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, sObject> triggerOldMap
    ) {
        List<HOT_HistoricallyAssignedResource__c> newHistoricallyAssignedResources = new List<HOT_HistoricallyAssignedResource__c>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);

            // First check if we sould create a Historically Assigned Resource for this change
            if (serviceAppointment.HOT_DoNotCreateHAR__c) {
                serviceAppointment.HOT_DoNotCreateHAR__c = false;
            } else {
                // Added resource
                if (
                    serviceAppointment.HOT_ServiceResource__c != null &&
                    oldServiceAppointment.HOT_ServiceResource__c == null
                ) {
                    HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
                    historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
                    historicallyAssignedResource.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
                    historicallyAssignedResource.Status__c = getTranslatedStatus(serviceAppointment.Status);
                    newHistoricallyAssignedResources.add(historicallyAssignedResource);
                }
                // Same resource, but status has changed
                if (
                    serviceAppointment.HOT_ServiceResource__c != null &&
                    serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c &&
                    serviceAppointment.Status != 'None' &&
                    serviceAppointment.Status != null
                ) {
                    HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
                    historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
                    historicallyAssignedResource.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
                    historicallyAssignedResource.Status__c = getTranslatedStatus(serviceAppointment.Status);
                    newHistoricallyAssignedResources.add(historicallyAssignedResource);
                }
                // Changed resource
                if (
                    serviceAppointment.HOT_ServiceResource__c != null &&
                    oldServiceAppointment.HOT_ServiceResource__c != null &&
                    serviceAppointment.HOT_ServiceResource__c != oldServiceAppointment.HOT_ServiceResource__c
                ) {
                    HOT_HistoricallyAssignedResource__c historicallyAssignedResourceOld = new HOT_HistoricallyAssignedResource__c();
                    historicallyAssignedResourceOld.ServiceAppointment__c = serviceAppointment.Id;
                    historicallyAssignedResourceOld.ServiceResource__c = oldServiceAppointment.HOT_ServiceResource__c;
                    historicallyAssignedResourceOld.Status__c = 'Tolk tatt av oppdraget';
                    newHistoricallyAssignedResources.add(historicallyAssignedResourceOld);

                    HOT_HistoricallyAssignedResource__c historicallyAssignedResourceNew = new HOT_HistoricallyAssignedResource__c();
                    historicallyAssignedResourceNew.ServiceAppointment__c = serviceAppointment.Id;
                    historicallyAssignedResourceNew.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
                    historicallyAssignedResourceNew.Status__c = getTranslatedStatus(serviceAppointment.Status);
                    newHistoricallyAssignedResources.add(historicallyAssignedResourceNew);
                }
                // Removed resource
                if (
                    serviceAppointment.HOT_ServiceResource__c == null &&
                    oldServiceAppointment.HOT_ServiceResource__c != null
                ) {
                    HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
                    historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
                    historicallyAssignedResource.ServiceResource__c = oldServiceAppointment.HOT_ServiceResource__c;
                    historicallyAssignedResource.Status__c = 'Tolk tatt av oppdraget';
                    newHistoricallyAssignedResources.add(historicallyAssignedResource);
                }
                // Only status change, no resource connected to service appointment
                if (
                    serviceAppointment.HOT_ServiceResource__c == null &&
                    serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c
                ) {
                    // Do noting
                }
            }
        }
        insert newHistoricallyAssignedResources;
    }
    private static void preserveSchedulesTimes(List<ServiceAppointment> records, Map<Id, sObject> triggerOldMap) {
        for (ServiceAppointment serviceAppointment : records) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);
            if (serviceAppointment.SchedStartTime == null && serviceAppointment.SchedEndTime == null) {
                serviceAppointment.SchedStartTime = oldServiceAppointment.SchedStartTime;
                serviceAppointment.SchedEndTime = oldServiceAppointment.SchedEndTime;
            }
            if (
                serviceAppointment.EarliestStartTime != null &&
                serviceAppointment.DueDate != null &&
                (serviceAppointment.EarliestStartTime != oldServiceAppointment.EarliestStartTime ||
                serviceAppointment.DueDate != oldServiceAppointment.DueDate)
            ) {
                serviceAppointment.SchedStartTime = serviceAppointment.EarliestStartTime;
                serviceAppointment.SchedEndTime = serviceAppointment.DueDate;
            }
        }
    }
    private static void setScheduledTimesOnStatusNone(List<ServiceAppointment> records) {
        for (ServiceAppointment serviceAppointment : records) {
            if (serviceAppointment.EarliestStartTime != null) {
                serviceAppointment.SchedStartTime = serviceAppointment.EarliestStartTime;
            }
            if (serviceAppointment.DueDate != null) {
                serviceAppointment.SchedEndTime = serviceAppointment.DueDate;
            }
        }
    }

    @TestVisible
    private static String getTranslatedStatus(String status) {
        if (status == 'Annul')
            return 'Annullert';
        if (status == 'Canceled')
            return 'Avlyst av bruker';
        if (status == 'Cannot Complete')
            return 'Udekket';
        if (status == 'Completed')
            return 'Dekket';
        if (status == 'Dispatched')
            return 'Tildelt';
        if (status == 'In Progress')
            return 'Pågår';
        if (status == 'None')
            return 'Åpen';
        if (status == 'Released to Freelance')
            return 'Frigitt til frilanstolker';
        if (status == 'Scheduled')
            return 'Reservert';

        return '';
    }

    private static Map<String, String> getGanttColorByStatus(Boolean isImageInterpreter) {
        Map<String, String> ganttColorByStatus = new Map<String, String>();
        if (isImageInterpreter) {
            ganttColorByStatus.put('Scheduled', '#189AB4');
            ganttColorByStatus.put('Dispatched', '#F8EA8C');
            ganttColorByStatus.put('Completed', '#59981A');
        }
        return ganttColorByStatus;
    }

    public static void releaseServiceAppointments(List<ServiceAppointment> serviceAppointments) {
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (serviceAppointment.HOT_FreelanceSubject__c == null) {
                serviceAppointment.HOT_FreelanceSubject__c = serviceAppointment.Subject;
            }
            if (serviceAppointment.HOT_DeadlineDate__c == null) {
                serviceAppointment.HOT_DeadlineDate__c = serviceAppointment.EarliestStartTime.date();
            }
            serviceAppointment.HOT_IsEmployedInterpreter__c = false;
            serviceAppointment.HOT_IsReleasedToFreelance__c = true;
            serviceAppointment.HOT_ReleaseDate__c = Date.today();
            serviceAppointment.HOT_ReleasedBy__c = UserInfo.getName();
        }
    }
    public static void retractServiceAppointments(List<ServiceAppointment> serviceAppointments) {
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (serviceAppointment.HOT_FreelanceSubject__c != null) {
                serviceAppointment.HOT_FreelanceSubject__c = null;
            }
            if (serviceAppointment.HOT_DeadlineDate__c != null) {
                serviceAppointment.HOT_DeadlineDate__c = null;
            }
            serviceAppointment.HOT_IsEmployedInterpreter__c = true;
            serviceAppointment.HOT_IsReleasedToFreelance__c = false;
            serviceAppointment.HOT_ReleaseDate__c = null;
            serviceAppointment.HOT_ReleasedBy__c = null;
        }
    }

    public static void updateStatusOnInterestedResources(
        List<ServiceAppointment> serviceAppointments,
        String newStatus
    ) {
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Status__c, ServiceAppointment__r.Status, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c IN :(new Map<Id, ServiceAppointment>(serviceAppointments)).keySet()
        ];
        for (HOT_InterestedResource__c interestedResource : interestedResources) {
            if (
                newStatus == 'Service Appointment Retracted' &&
                interestedResource.Status__c != 'Wanted' &&
                interestedResource.Status__c != 'Declined' &&
                interestedResource.Status__c != 'Retracted Interest' &&
                interestedResource.Status__c != 'Canceled by Interpreter'
            ) {
                if (
                    interestedResource.ServiceAppointment__r.Status == 'None' ||
                    interestedResource.ServiceAppointment__r.Status == 'Annul' ||
                    interestedResource.ServiceAppointment__r.Status == 'Cannot Complete' &&
                    interestedResource.Status__c == 'Interested'
                ) {
                    interestedResource.Status__c = newStatus;
                }
            }
            if (newStatus == 'None') {
                if (
                    interestedResource.ServiceAppointment__r.Status == 'Released to Freelance' &&
                    (interestedResource.Status__c == 'Service Appointment Retracted' ||
                    interestedResource.Status__c == 'Interested' ||
                    interestedResource.Status__c == 'Not Assigned' ||
                    interestedResource.Status__c == 'Withdrawn')
                ) {
                    interestedResource.Status__c = null;
                }
            }
            if (newStatus == 'Assigned') {
                if (
                    interestedResource.ServiceAppointment__r.Status == 'Dispatched' &&
                    interestedResource.Status__c == 'Reserved'
                ) {
                    for (ServiceAppointment serviceAppointment : serviceAppointments) {
                        if (serviceAppointment.HOT_ServiceResource__c == interestedResource.ServiceResource__c) {
                            interestedResource.Status__c = newStatus;
                            break;
                        }
                    }
                }
            }
        }
        update interestedResources;
    }

    private static ServiceAppointment updateDuration(ServiceAppointment serviceAppointment) {
        if (serviceAppointment.EarliestStartTime != null && serviceAppointment.DueDate != null) {
            serviceAppointment.Duration =
                ((Double) serviceAppointment.DueDate.getTime() -
                (Double) serviceAppointment.EarliestStartTime.getTime()) / 3600000;
        }
        return serviceAppointment;
    }

    public static void setActualTime(List<ServiceAppointment> serviceAppointments) {
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.ActualStartTime = serviceAppointment.SchedStartTime;
            serviceAppointment.ActualEndTime = serviceAppointment.SchedEndTime;
        }
    }

    public static void resetNotifyDispatcher(List<ServiceAppointment> serviceAppointments) {
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_IsNotifyDispatcher__c = false;
        }
    }
    public static void removeCustomAccountLookup(List<ServiceAppointment> serviceAppointments) {
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_Account__c = null;
        }
    }

    public static Map<String, Map<Id, Id>> getAppointmentAndResourceByAssignment(
        List<ServiceAppointment> serviceAppointments
    ) {
        Map<String, Map<Id, Id>> returnMap = new Map<String, Map<Id, Id>>();
        Map<Id, Id> appointmentByAssignment = new Map<Id, Id>();
        Map<Id, Id> resourceByAssignment = new Map<Id, Id>();
        List<AssignedResource> assignedResources = [
            SELECT Id, ServiceAppointmentId, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :serviceAppointments
        ];
        for (AssignedResource assignedResource : assignedResources) {
            appointmentByAssignment.put(assignedResource.Id, assignedResource.ServiceAppointmentId);
            resourceByAssignment.put(assignedResource.Id, assignedResource.ServiceResourceId);
        }
        returnMap.put('appointment', appointmentByAssignment);
        returnMap.put('resource', resourceByAssignment);
        return returnMap;
    }
    public static void setCompanyOnServiceAppointment(List<ServiceAppointment> serviceAppointments) {
        Set<Id> requestIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            if (sa.isClone()) {
                requestIds.add(sa.HOT_Request__c);
            }
        }
        List<HOT_Request__c> requestList = [SELECT Id, Company__c FROM HOT_Request__c WHERE Id IN :requestIds];
        for (ServiceAppointment sa : serviceAppointments) {
            for (HOT_Request__c request : requestList) {
                if (sa.HOT_Request__c == request.Id && request.Company__c != null) {
                    sa.HOT_Company__c = request.Company__c;
                }
            }
        }
    }

    public static void createContentDocumentLinks(List<ServiceAppointment> serviceAppointments) {
        // Collect ServiceAppointment Ids
        Set<Id> saIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            if (sa.Id != null) {
                saIds.add(sa.Id);
            }
        }

        if (saIds.isEmpty()) {
            return;
        }

        // Query ServiceAppointments with WorkOrderId
        List<ServiceAppointment> saWithWorkOrderId = [
            SELECT Id, HOT_Request__c, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Id IN :saIds
            LIMIT 10
        ];

        // Collect WorkOrder Ids
        Set<Id> workOrderIds = new Set<Id>();
        for (ServiceAppointment sa : saWithWorkOrderId) {
            if (sa.HOT_WorkOrderLineItem__r != null && sa.HOT_WorkOrderLineItem__r.WorkOrderId != null) {
                workOrderIds.add(sa.HOT_WorkOrderLineItem__r.WorkOrderId);
            }
        }

        if (workOrderIds.isEmpty()) {
            return;
        }

        // Query WorkOrders with ContentDocumentLinks
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
            [
                SELECT
                    Id,
                    (
                        SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility
                        FROM ContentDocumentLinks
                    )
                FROM WorkOrder
                WHERE Id IN :workOrderIds
            ]
        );

        Map<Id, List<ContentDocumentLink>> serviceAppointmentMap = new Map<Id, List<ContentDocumentLink>>();

        // Map WorkOrder files to ServiceAppointments
        for (ServiceAppointment sa : saWithWorkOrderId) {
            if (sa.HOT_WorkOrderLineItem__r == null) {
                continue;
            }

            Id woId = sa.HOT_WorkOrderLineItem__r.WorkOrderId;
            if (woId == null) {
                continue;
            }

            if (!workOrderMap.containsKey(woId)) {
                continue;
            }

            WorkOrder wo = workOrderMap.get(woId);

            if (wo.ContentDocumentLinks != null && !wo.ContentDocumentLinks.isEmpty()) {
                serviceAppointmentMap.put(sa.Id, wo.ContentDocumentLinks);
            }
        }

        if (!serviceAppointmentMap.isEmpty()) {
            HOT_ContentDocumentLinkService.setContentDocumentLinks(serviceAppointmentMap);
        }
    }

    public static void setScheduledTimeBasedOnActualTime(List<ServiceAppointment> serviceAppointments) {
        for (ServiceAppointment sa : serviceAppointments) {
            if (sa.ActualStartTime != null) {
                sa.SchedStartTime = sa.ActualStartTime;
            }
            if (sa.ActualEndTime != null) {
                sa.SchedEndTime = sa.ActualEndTime;
            }
        }
    }

    public static List<ServiceAppointment> setRecalculateManualSharingFlag(
        List<ServiceAppointment> serviceAppointments
    ) {
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_IsRecalculateManualSharing__c = true;
        }
        return serviceAppointments;
    }
}
