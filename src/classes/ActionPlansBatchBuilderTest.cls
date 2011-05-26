public with sharing class ActionPlansBatchBuilderTest {

	public static Boolean isTest = false;
	private static testMethod void runBatchAccount(){
		
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		Test.startTest();
		
			ActionPlan__c ap = ge.createNewActionPlan( 'accounts' ,2);
			ap.Name= 'check_undelete';
			List<APTaskTemplate__c> apTasks = new List<APTaskTemplate__c>();
			User u = ge.createTestUser();
			
			APTaskTemplate__c at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = u.Id;
	   		at.SendEmail__c		 = false;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasks.add(at);
	   		
	   		at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = u.Id;
	   		at.SendEmail__c		 = true;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasks.add(at);
		
			Account ac = new Account();
			ac.Name ='Doe';
			insert ac;
			
			Account ac1 = new Account();
			ac1.Name ='Doe';
			insert ac1;
			
			List<string> oIdsList = new List<String>();
			oIdsList.add(ac.Id);
			oIdsList.add(ac1.Id);
			
	   		ActionPlansBatchBuilder testBatch = new ActionPlansBatchBuilder( ap,apTasks,'Account',oIdsList);
	        ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);	
		/*
		List<ActionPlan__c> l_ap = [Select Id from ActionPlan__c where name ='check_undelete'];
		
		if (l_ap.size()>0){
			delete l_ap;
			List <String> ids = new List <String>();
			ids.add(l_ap[0].Id);
			try{
				database.undelete (ids);
			}catch(Dmlexception e){
				//System.assert( e.getMessage().contains('Undelete failed.'),e.getMessage() );
			}
		}*/
	}
	
	private static testMethod void runBatchContact(){
		
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		Test.startTest();
		
			ActionPlan__c ap = ge.createNewActionPlan( 'contacts' ,2);
			List<APTaskTemplate__c> apTasks = new List<APTaskTemplate__c>();
			User u = ge.createTestUser();
			
			APTaskTemplate__c at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = u.Id;
	   		at.SendEmail__c		 = false;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasks.add(at);
	   		
	   		at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = u.Id;
	   		at.SendEmail__c		 = true;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasks.add(at);
		
			Contact op = new Contact();
			op.LastName ='Doe';
			insert op;
			
			Contact op2 = new Contact();
			op2.LastName ='Doe';
			insert op2;
			
			List<string> oIdsList = new List<String>();
			oIdsList.add(op.Id);
			oIdsList.add(op2.Id);
			
	   		ActionPlansBatchBuilder testBatch = new ActionPlansBatchBuilder( ap,apTasks,'Contact',oIdsList);
	        ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
		
	}
	
	
	private static testMethod void runBatchOpportunity(){
		
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		Test.startTest();
		
		
			ActionPlan__c ap = ge.createNewActionPlan( 'opportunitys' ,2);
			List<APTaskTemplate__c> apTasks = new List<APTaskTemplate__c>();
		
			APTaskTemplate__c at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = ge.createTestUser().Id;
	   		at.SendEmail__c		 = false;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasks.add(at);
	   		
	   		at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = ge.createTestUser().Id;
	   		at.SendEmail__c		 = true;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasks.add(at);
		
			Opportunity op = new Opportunity();
			op.Name ='Op1';
			op.StageName = 'Won';
			op.CloseDate = Date.today();
			insert op;
			
			Opportunity op2 = new Opportunity();
			op2.Name ='Op2';
			op2.StageName = 'Won';
			op2.CloseDate = Date.today();
			insert op2;
			
			List<string> oIdsList = new List<String>();
			oIdsList.add(op.Id);
			oIdsList.add(op2.Id);
			
	   		ActionPlansBatchBuilder testBatch = new ActionPlansBatchBuilder( ap,apTasks,'Opportunity',oIdsList);
	        ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
		
		
	}
	
	private static testMethod void runBatchException(){
		ActionPlansBatchBuilderTest.isTest = true;
/*		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'leads' ,2);
		List<APTaskTemplate__c> apTasks = new List<APTaskTemplate__c>();
		List<string> oIdsList = new List<String>();
		
		Test.startTest();
	   		ActionPlansBatchBuilder testBatch = new ActionPlansBatchBuilder( ap,apTasks,'Opportunity',oIdsList);
	        ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);*/
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		Test.startTest();
		
		
			ActionPlan__c ap = ge.createNewActionPlan( 'opportunitys' ,2);
			List<APTaskTemplate__c> apTasks = new List<APTaskTemplate__c>();
		
			APTaskTemplate__c at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = ge.createTestUser().Id;
	   		at.SendEmail__c		 = false;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasks.add(at);
	   		
	   		at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = ge.createTestUser().Id;
	   		at.SendEmail__c		 = true;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasks.add(at);
		
			Opportunity op = new Opportunity();
			op.Name ='Op1';
			op.StageName = 'Won';
			op.CloseDate = Date.today();
			insert op;
			
			Opportunity op2 = new Opportunity();
			op2.Name ='Op2';
			op2.StageName = 'Won';
			op2.CloseDate = Date.today();
			insert op2;
			
			List<string> oIdsList = new List<String>();
			oIdsList.add(op.Id);
			oIdsList.add(op2.Id);
			
	   		ActionPlansBatchBuilder testBatch = new ActionPlansBatchBuilder( ap,apTasks,'Opportunity',oIdsList);
	        ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
		
	}

}