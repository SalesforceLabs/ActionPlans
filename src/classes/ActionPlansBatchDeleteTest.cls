public with sharing class ActionPlansBatchDeleteTest {
	public static Boolean isTest = false;
	
    private static testMethod void testDelete() {
		
		test.startTest();
		
		ActionPlansTestUtilities apTUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap =   apTUtil.createNewActionPlan('accounts',1);
		
		List<String> lIds = new List<String>();
		lIds.add(ap.Id);
		
		ActionPlansBatchDelete taskBatch = new ActionPlansBatchDelete(lIds,Userinfo.getUserId());
		Database.ExecuteBatch( taskBatch );
	
		test.stopTest();
	}
	
	private static testMethod void testDeleteException() {
		
		test.startTest();
		
		ActionPlansBatchBuilderTest.isTest = true;
		
		ActionPlansTestUtilities apTUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap =   apTUtil.createNewActionPlan('accounts',1);
		
		List<String> lIds = new List<String>();
		lIds.add(ap.Id);
		
		ActionPlansBatchDelete taskBatch = new ActionPlansBatchDelete(lIds,Userinfo.getUserId());
		Database.ExecuteBatch( taskBatch );
	
		test.stopTest();
	}
	
    
        private static testMethod void testUnDelete() {
		
		test.startTest();
		
		ActionPlansTestUtilities apTUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap =   apTUtil.createNewActionPlan('accounts',1);
		
		
					APTaskTemplate__c at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = Userinfo.getUserId();
	   		at.SendEmail__c		 = false;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		
	   		at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = Userinfo.getUserId();
	   		at.SendEmail__c		 = true;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
		
			Task x 				= new Task();
			x.Priority 			= at.Priority__c;
			x.Status			= 'Open';
			x.TaskTemplateId__c	= at.Id;
			x.Subject			= at.Subject__c;
			insert x;
		
		List<String> lIds = new List<String>();
		lIds.add(ap.Id);
		
		ActionPlansBatchDelete taskBatch = new ActionPlansBatchDelete(lIds,Userinfo.getUserId());
		Database.ExecuteBatch( taskBatch );
	
		test.stopTest();
		
		try{
			undelete ap;
		}catch(Exception e){
		
		}
	}
}