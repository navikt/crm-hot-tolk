public without sharing class HOT_CreateWorkOrderService {
	
	@InvocableVariable public String requestId;
	@InvocableVariable public Datetime startDate;
	@InvocableVariable public Datetime endDate;
	@InvocableVariable public String recurringType;
	@InvocableVariable public Boolean monday;
	@InvocableVariable public Boolean tuesday;
	@InvocableVariable public Boolean wendesday;
	@InvocableVariable public Boolean thursday;
	@InvocableVariable public Boolean friday;
	@InvocableVariable public Boolean saturday;
	@InvocableVariable public Boolean sunday;
	@InvocableVariable public Date recurringEndDate;

	@InvocableMethod
	public static List<String> createWorkOrders(List<HOT_CreateWorkOrderService> inputVariables){
		
		HOT_CreateWorkOrderService input = inputVariables[0];
		Integer maxNumberOfRecurrences = 200;
		List<String> errors = new List<String>();

		if(input.endDate <= input.startDate) {
			errors.add('Slutt tid må være etter Start tid.');
			return errors;
		}

		if(input.recurringType != 'Never' && input.recurringEndDate <= input.startDate.date()) {
			errors.add('Sluttdato må være etter Startdato.');
			return errors;
		}

		if(input.recurringType == 'Weekly' && !input.monday && !input.tuesday && !input.wendesday && !input.thursday && !input.friday && !input.saturday && !input.sunday) {
			errors.add('Må velge minst en dag.');
			return errors;
		}

		if(input.recurringType == 'Never') {
			
			WorkOrder workOrder = new workOrder(HOT_Request__c = input.requestId, StartDate = input.startDate, EndDate = input.endDate);
			
			try{
				insert workOrder;
			} catch(Exception e) {
				errors.add('Opprettelsen av arbeidsordren feilet.');
			}
			
			return errors;
		}

		else if(input.recurringType == 'Daily') {
			
			List<WorkOrder> workOrders = new List<WorkOrder>();
			Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);
			
			if(numberOfRecurrences > maxNumberOfRecurrences) {
				errors.add('Kan ikke opprette mere en 200 arbeidsordre av gangen');
				return errors;
			}
			
			for(Integer i = 0; i <= numberOfRecurrences; i++) {
				Datetime startDate = input.startDate.addDays(i);
				Datetime endDate = input.endDate.addDays(i);
				WorkOrder workOrder = new workOrder(HOT_Request__c = input.requestId, StartDate = startDate, EndDate = endDate);
				workOrders.add(workOrder);
			}
			
			try{
				insert workOrders;
			} catch(Exception e) {
				errors.add('Opprettelsen av arbeidsordrene feilet.');
			}
			
			return errors;
		}

		else if(input.recurringType == 'Weekly') {
			
			List<WorkOrder> workOrders = new List<WorkOrder>();
			Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);
			
			for(Integer i = 0; i <= numberOfRecurrences; i++) {
				Datetime startDate = input.startDate.addDays(i);
				Datetime endDate = input.endDate.addDays(i);
				String dayOfWeek = startDate.format('EEEE');
				System.debug('dayOfWeek: '+ dayOfWeek);
				if(
					input.monday && dayOfWeek == 'Monday'
					||
					input.tuesday && dayOfWeek == 'Tuesday'
					||
					input.wendesday && dayOfWeek == 'Wednesday'
					||
					input.thursday && dayOfWeek == 'Thursday'
					||
					input.friday && dayOfWeek == 'Friday'
					||
					input.saturday && dayOfWeek == 'Saturday'
					||
					input.sunday && dayOfWeek == 'Sunday'
				) {
					WorkOrder workOrder = new workOrder(HOT_Request__c = input.requestId, StartDate = startDate, EndDate = endDate);
					workOrders.add(workOrder);
				}
			}
			
			if(workOrders.size() > maxNumberOfRecurrences) {
				errors.add('Kan ikke opprette mere en 200 arbeidsordre av gangen');
				return errors;
			}
			
			try{
				insert workOrders;
			} catch(Exception e) {
				errors.add('Opprettelsen av arbeidsordrene feilet.');
			}
			
			return errors;
		}

		else if(input.recurringType == 'Biweekly') {
			
			List<WorkOrder> workOrders = new List<WorkOrder>();
			Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);
			
			for(Integer i = 0; i <= numberOfRecurrences; i++) {
				Datetime startDate = input.startDate.addDays(i);
				Datetime endDate = input.endDate.addDays(i);
				String dayOfWeek = startDate.format('EEEE');
				System.debug('dayOfWeek: '+ dayOfWeek);
				if(
					input.monday && dayOfWeek == 'Monday'
					||
					input.tuesday && dayOfWeek == 'Tuesday'
					||
					input.wendesday && dayOfWeek == 'Wednesday'
					||
					input.thursday && dayOfWeek == 'Thursday'
					||
					input.friday && dayOfWeek == 'Friday'
					||
					input.saturday && dayOfWeek == 'Saturday'
					||
					input.sunday && dayOfWeek == 'Sunday'
				) {
					WorkOrder workOrder = new workOrder(HOT_Request__c = input.requestId, StartDate = startDate, EndDate = endDate);
					workOrders.add(workOrder);
				}
				if(dayOfWeek == 'Sunday') {
					i = i + 7;
				}
			}
			
			if(workOrders.size() > maxNumberOfRecurrences) {
				errors.add('Kan ikke opprette mere en 200 arbeidsordre av gangen');
				return errors;
			}
			
			try{
				insert workOrders;
			} catch(Exception e) {
				errors.add('Opprettelsen av arbeidsordrene feilet.');
			}
			
			return errors;
		}

		else if(input.recurringType == 'Monthly') {
			
			List<WorkOrder> workOrders = new List<WorkOrder>();
			Integer numberOfRecurrences = input.startDate.date().monthsBetween(input.recurringEndDate);
		
			if(numberOfRecurrences > maxNumberOfRecurrences) {
				errors.add('Kan ikke opprette mere en 200 arbeidsordre av gangen');
				return errors;
			}
		
			for(Integer i = 0; i <= numberOfRecurrences; i++) {
				Datetime startDate = input.startDate.addMonths(i);
				Datetime endDate = input.endDate.addMonths(i);
				WorkOrder workOrder = new workOrder(HOT_Request__c = input.requestId, StartDate = startDate, EndDate = endDate);
				if(startDate.date() <= input.recurringEndDate) {
					workOrders.add(workOrder);
				}
			}
			
			try{
				insert workOrders;
			} catch(Exception e) {
				errors.add('Opprettelsen av arbeidsordrene feilet.');
			}
			
			return errors;
		}

		return errors;
	}
}
