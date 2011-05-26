public with sharing class ActionPlansBatchTaskBuilderTest {
	
	
	private static testMethod void runBatchAccount(){
		
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		Test.startTest();
	   		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder( ge.batchIds( 'accounts' ) );
	        ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);		
	}
	
	private static testMethod void runBatchContact(){
		
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		Test.startTest();
	   		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder( ge.batchIds( 'contacts' ) );
	        ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
		
	}
	
	
	private static testMethod void runBatchOpportunity(){
		
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		Test.startTest();
	   		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder( ge.batchIds( 'opportunitys' ) );
	        ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
		
	}
	
	private static testMethod void runBatchLeed(){
		
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		Test.startTest();
	   		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder( ge.batchIds( 'leads' ) );
	        ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();
		
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
		
	}
	
}