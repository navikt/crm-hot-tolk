public without sharing class HOT_ServiceAppointmentHandler extends MyTriggers {
    public override void onBeforeInsert() {
        setDefaultFields((List<ServiceAppointment>) records);
        setOwner((List<ServiceAppointment>) records);
        setFieldsByPreferredResource((List<ServiceAppointment>) records);
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<ServiceAppointment> serviceAppointmentsStatusFromCannotCompleteToNone = new List<ServiceAppointment>();
        List<ServiceAppointment> recievedNewInterpreter = new List<ServiceAppointment>();
        List<ServiceAppointment> updatedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithDeletedPreferredResources = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithChangedStatusOrResource = new List<ServiceAppointment>();
        List<ServiceAppointment> allServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> releasedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> retractedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> completedImageInterpreterServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> SAnotifyDispatcher = new List<ServiceAppointment>();
        List<ServiceAppointment> annulServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithHoursToSet = new List<ServiceAppointment>();

        for (ServiceAppointment serviceAppointment : (List<ServiceAppointment>) records) {
            if (
                triggerOldMap.get(serviceAppointment.Id).get('SchedStartTime') != serviceAppointment.SchedStartTime ||
                triggerOldMap.get(serviceAppointment.Id).get('SchedEndTime') != serviceAppointment.SchedEndTime
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
                triggerOldMap.get(serviceAppointment.Id).get('HOT_PreferredResource__c') !=
                ServiceAppointment.HOT_PreferredResource__c &&
                serviceAppointment.HOT_PreferredResource__c != null &&
                serviceAppointment.HOT_ServiceResource__c == null
            ) {
                updatedServiceAppointments.add(serviceAppointment);
            }
            if (
                triggerOldMap.get(serviceAppointment.Id).get('HOT_PreferredResource__c') !=
                ServiceAppointment.HOT_PreferredResource__c &&
                serviceAppointment.HOT_PreferredResource__c == null &&
                serviceAppointment.HOT_ServiceResource__c == null
            ) {
                serviceAppointmentsWithDeletedPreferredResources.add(serviceAppointment);
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
            serviceAppointment = updateDuration(serviceAppointment);
            allServiceAppointments.add(serviceAppointment);
        }
        if (!updatedServiceAppointments.isEmpty()) {
            updatedServiceAppointments = setFieldsByPreferredResource(updatedServiceAppointments);
        }
        if (!serviceAppointmentsWithDeletedPreferredResources.isEmpty()) {
            serviceAppointmentsWithDeletedPreferredResources = setFieldsIfPreferredResourceDeleted(
                serviceAppointmentsWithDeletedPreferredResources
            );
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
            HOT_ServiceAppointmentNotification.notifyDispatchers_serviceAppointmentChanged(
                SAnotifyDispatcher,
                triggerOldMap
            );
            resetNotifyDispatcher(SAnotifyDispatcher);
        }
        if (annulServiceAppointments.size() > 0) {
            removeCustomAccountLookup(annulServiceAppointments);
        }

        if (serviceAppointmentsWithHoursToSet.size() > 0) {
            setStartAndEndHour(serviceAppointmentsWithHoursToSet);
        }
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<ServiceAppointment> serviceAppointmentsToRemoveAssignedResource = new List<ServiceAppointment>();
        List<ServiceAppointment> releasedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> retractedServiceAppointments = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsWithChangedAddress = new List<ServiceAppointment>();
        List<ServiceAppointment> SAnotifyResource = new List<ServiceAppointment>();

        for (ServiceAppointment serviceAppointment : (List<ServiceAppointment>) records) {
            if (
                //canceled by user
                //time change
                //address change
                //removed resource
                serviceAppointment.Status == 'Canceled' &&
                triggerOldMap.get(serviceAppointment.Id).get('Status') != 'Canceled' ||
                (serviceAppointment.SchedStartTime != triggerOldMap.get(serviceAppointment.Id).get('SchedStartTime') ||
                serviceAppointment.SchedEndTime != triggerOldMap.get(serviceAppointment.Id).get('SchedEndTime')) ||
                serviceAppointment.HOT_AddressFormated__c !=
                triggerOldMap.get(serviceAppointment.Id).get('HOT_AddressFormated__c') ||
                (triggerOldMap.get(serviceAppointment.Id).get('Status') == 'Completed' ||
                triggerOldMap.get(serviceAppointment.Id).get('Status') == 'Dispatched' ||
                triggerOldMap.get(serviceAppointment.Id).get('Status') == 'In Progress') &&
                (serviceAppointment.Status == null ||
                serviceAppointment.Status == 'None') ||
                (serviceAppointment.HOT_IsScreenInterpreterNew__c !=
                triggerOldMap.get(serviceAppointment.Id).get('HOT_IsScreenInterpreterNew__c'))
            ) {
                SAnotifyResource.add(serviceAppointment);
            }
            if (
                (serviceAppointment.Status == 'Canceled' || serviceAppointment.Status == 'Annul') &&
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
                serviceAppointment.Status == 'None' &&
                triggerOldMap.get(serviceAppointment.Id).get('Status') == 'Released to Freelance'
            ) {
                retractedServiceAppointments.add(serviceAppointment);
            }
            if (
                serviceAppointment.HOT_AddressFormated__c !=
                triggerOldMap.get(serviceAppointment.Id).get('HOT_AddressFormated__c')
            ) {
                serviceAppointmentsWithChangedAddress.add(serviceAppointment);
            }
        }

        if (serviceAppointmentsToRemoveAssignedResource.size() > 0) {
            removeAssignedResource(serviceAppointmentsToRemoveAssignedResource);
        }
        if (releasedServiceAppointments.size() > 0) {
            updateStatusOnInterestedResources(releasedServiceAppointments, 'Interested');
        }
        if (retractedServiceAppointments.size() > 0) {
            updateStatusOnInterestedResources(retractedServiceAppointments, 'Service Appointment Retracted');
        }
        if (serviceAppointmentsWithChangedAddress.size() > 0) {
            updateRelatedEvents(serviceAppointmentsWithChangedAddress);
        }
        if (serviceAppointmentsToRemoveAssignedResource.size() > 0) {
            deleteRelatedEvents(serviceAppointmentsToRemoveAssignedResource);
        }
        if (SAnotifyResource.size() > 0) {
            HOT_ServiceAppointmentNotification.notifyInterpreter_serviceAppointmentChanged(
                SAnotifyResource,
                triggerOldMap
            );
        }
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

    private static void setDefaultFields(List<ServiceAppointment> serviceAppointments) {
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
                    HOT_InterpretationPostalStreet__c
                FROM WorkOrderLineItem
                WHERE Id IN :workOrderLineItemIds
            ]
        );

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.Status = 'None';
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
                    serviceAppointment.City == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).City != null
                ) {
                    serviceAppointment.City = workOrderLineItems.get(serviceAppointment.ParentRecordId).City;
                }
                if (
                    serviceAppointment.PostalCode == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).PostalCode != null
                ) {
                    serviceAppointment.PostalCode = workOrderLineItems.get(serviceAppointment.ParentRecordId)
                        .PostalCode;
                }
                if (
                    serviceAppointment.Street == null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).Street != null
                ) {
                    serviceAppointment.Street = workOrderLineItems.get(serviceAppointment.ParentRecordId).Street;
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
                if (
                    serviceAppointment.ParentRecordId != null &&
                    workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrder.AccountId != null
                ) {
                    serviceAppointment.HOT_Account__c = workOrderLineItems.get(serviceAppointment.ParentRecordId)
                        .WorkOrder.AccountId;
                }
                serviceAppointment = updateDuration(serviceAppointment);

                //Image Interpreter
                if (serviceAppointment.HOT_IsImageInterpreter__c) {
                    if (serviceAppointment.get('FSL__GanttColor__c') != null) {
                        Map<String, String> ganttColorByStatus = getGanttColorByStatus(
                            serviceAppointment.HOT_IsImageInterpreter__c
                        );
                        serviceAppointment.put('FSL__GanttColor__c', ganttColorByStatus.get(serviceAppointment.Status));
                    }
                    serviceAppointment.HOT_AutoDispatch__c = true;
                }
            }
        }
        setStartAndEndHour(serviceAppointments);
    }

    private static void setOwner(List<ServiceAppointment> serviceAppointments) {
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (serviceAppointment.HOT_Request__c != null) {
                serviceAppointment.OwnerId = serviceAppointment.HOT_RequestOwnerId__c;
            }
        }
    }

    public void setStartAndEndHour(List<ServiceAppointment> records) {
        for (ServiceAppointment serviceAppointment : records) {
            serviceAppointment.HOT_StartHour__c = serviceAppointment.SchedStartTime != null
                ? serviceAppointment.SchedStartTime.format('HH', 'Europe/Oslo')
                : null;
            serviceAppointment.HOT_EndHour__c = serviceAppointment.SchedEndTime != null
                ? serviceAppointment.SchedEndTime.format('HH', 'Europe/Oslo')
                : null;
        }
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
    private static void preserveSchedulesTimes(
        List<ServiceAppointment> serviceAppointmentsStatusFromCannotCompleteToNone,
        Map<Id, sObject> triggerOldMap
    ) {
        for (ServiceAppointment serviceAppointment : serviceAppointmentsStatusFromCannotCompleteToNone) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);
            if (serviceAppointment.SchedStartTime == null && serviceAppointment.SchedEndTime == null) {
                serviceAppointment.SchedStartTime = oldServiceAppointment.SchedStartTime;
                serviceAppointment.SchedEndTime = oldServiceAppointment.SchedEndTime;
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

    public static List<ServiceAppointment> setFieldsByPreferredResource(List<ServiceAppointment> serviceAppointments) {
        List<Id> PreferredResourceId = new List<Id>();
        List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (serviceAppointment.HOT_PreferredServiceResourceId__c != null) {
                PreferredResourceId.add(serviceAppointment.HOT_PreferredServiceResourceId__c);
                serviceAppointmentsToUpdate.add(serviceAppointment);
            }
        }
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(
            [
                SELECT Id, HOT_ServiceTerritory__c, HOT_IsFreelanceInterpreter__c, HOT_IsEmployedInterpreter__c
                FROM ServiceResource
                WHERE Id IN :PreferredResourceId
            ]
        );
        for (ServiceAppointment serviceAppointment : serviceAppointmentsToUpdate) {
            if (
                serviceAppointment.ServiceTerritoryId !=
                serviceResources.get(serviceAppointment.HOT_PreferredServiceResourceId__c).HOT_ServiceTerritory__c
            ) {
                serviceAppointment.ServiceTerritoryId = serviceResources.get(
                        serviceAppointment.HOT_PreferredServiceResourceId__c
                    )
                    .HOT_ServiceTerritory__c;
            }

            if (
                serviceAppointment.HOT_IsReleasedToFreelance__c !=
                serviceResources.get(serviceAppointment.HOT_PreferredServiceResourceId__c).HOT_IsFreelanceInterpreter__c
            ) {
                serviceAppointment.HOT_IsReleasedToFreelance__c = serviceResources.get(
                        serviceAppointment.HOT_PreferredServiceResourceId__c
                    )
                    .HOT_IsFreelanceInterpreter__c;
                serviceAppointment.HOT_IsEmployedInterpreter__c = serviceResources.get(
                        serviceAppointment.HOT_PreferredServiceResourceId__c
                    )
                    .HOT_IsEmployedInterpreter__c;
            }
        }
        return serviceAppointmentsToUpdate;
    }

    public static List<ServiceAppointment> setFieldsIfPreferredResourceDeleted(
        List<ServiceAppointment> serviceAppointments
    ) {
        List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
        List<Id> requestIds = new List<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            requestIds.add(serviceAppointment.HOT_Request__c);
        }

        List<HOT_Request__c> requests = [SELECT Id, ServiceTerritory__c FROM HOT_Request__c WHERE Id IN :requestIds];
        Map<Id, HOT_Request__c> requestMap = new Map<Id, HOT_Request__c>(requests);

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.ServiceTerritoryId = requestMap.get(serviceAppointment.HOT_Request__c)
                ?.ServiceTerritory__c;
            serviceAppointment.HOT_IsReleasedToFreelance__c = false;
            serviceAppointment.HOT_IsEmployedInterpreter__c = true;
            serviceAppointmentsToUpdate.add(serviceAppointment);
        }
        return serviceAppointmentsToUpdate;
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
            SELECT Status__c, ServiceAppointment__r.Status
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c IN :serviceAppointments
        ];
        for (HOT_InterestedResource__c interestedResource : interestedResources) {
            if (newStatus == 'Service Appointment Retracted') {
                if (
                    interestedResource.ServiceAppointment__r.Status == 'None' &&
                    interestedResource.Status__c == 'Interested'
                ) {
                    interestedResource.Status__c = newStatus;
                }
            }
            if (newStatus == 'Interested') {
                if (
                    interestedResource.ServiceAppointment__r.Status == 'Released to Freelance' &&
                    (interestedResource.Status__c == 'Service Appointment Retracted' ||
                    interestedResource.Status__c == 'Not Assigned')
                ) {
                    interestedResource.Status__c = newStatus;
                }
            }
        }
        update interestedResources;
    }

    public static void updateRelatedEvents(List<ServiceAppointment> serviceAppointments) {
        List<Event> events = [SELECT Id, Location FROM Event WHERE WhatId IN :serviceAppointments];
        for (Event event : events) {
            event.Location = 'TO_UPDATE';
        }
        update events;
    }

    private static ServiceAppointment updateDuration(ServiceAppointment serviceAppointment) {
        if (serviceAppointment.EarliestStartTime != null && serviceAppointment.DueDate != null) {
            serviceAppointment.Duration =
                ((Double) serviceAppointment.DueDate.getTime() -
                (Double) serviceAppointment.EarliestStartTime.getTime()) / 3600000;
        }
        return serviceAppointment;
    }
    public static void deleteRelatedEvents(List<ServiceAppointment> serviceAppointments) {
        List<Event> events = [SELECT Id FROM Event WHERE WhatId IN :serviceAppointments];
        delete events;
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
}
