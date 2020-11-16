@isTest
private class HOT_ServiceAppointmentHandlerTest{
		@testSetup 
		static void setup(){
	
		WorkType wt = HOT_TestDataFactory.createWorkType();
		insert wt;
	
		HOT_Request__c req = HOT_TestDataFactory.createRequest('Subject', wt);
		req.NumberOfInterpreters__c = 1;
		insert req;

		WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
		insert wo;

		WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
		woli.Status = 'Scheduled';
		insert woli;

		Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];
		User user = HOT_TestDataFactory.createUser('User', profile);
		insert user;
	
		ServiceResource sr =  HOT_TestDataFactory.createServiceResource(user.Id);
		insert sr;

		ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
	    sa.HOT_ServiceResource__c = sr.Id;
		insert sa;
		}
	
		@isTest static void cancelServiceAppointment() {
			ServiceAppointment sa = [SELECT Id, Status, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c FROM ServiceAppointment LIMIT 1];
			System.debug('SRCSA:' + sa.HOT_ServiceResource__c);
            sa.HOT_CanceledByInterpreter__c = true;
			sa.HOT_ServiceResource__c = null;
            System.debug('SR:'+ sa.HOT_ServiceResource__c);
			sa.Status = 'Cancelled';
			update sa;
	
			//Checking if SA is cancelled etc
			system.assertEquals(true, sa.HOT_CanceledByInterpreter__c, 'Could not set CancelledByInterpreter to true');
			system.assertEquals(null, sa.HOT_ServiceResource__c, 'Could not set SR');
			system.assertEquals('Cancelled', sa.Status, 'Could not set Status to Cancelled');

			//Re-schedules the SA
			sa.Status = 'Scheduled';
			update sa;

			Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];
			User user2 = HOT_TestDataFactory.createUser('User2', profile);
			insert user2;

			ServiceResource sr = HOT_TestDataFactory.createServiceResource(user2.Id);
			insert sr;

			sa.HOT_ServiceResource__c = sr.Id;
			update sa;
			System.debug('SA with new SR' + sa);

			//Checks if HOT_CancelledByInterpreter is no longer checked
			System.assertEquals(false, sa.HOT_CanceledByInterpreter__c, 'Could not set CancelledByInterpreter to false');
		}
	}