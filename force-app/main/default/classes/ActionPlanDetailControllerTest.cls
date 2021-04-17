@IsTest
private class ActionPlanDetailControllerTest {

	@IsTest
	private static void constructorTests(){

		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);

		Test.StartTest();

		System.currentPageReference().getParameters().put( 'id', null );
		ActionPlanDetailController apDetailController = new ActionPlanDetailController( new ApexPages.StandardController( new ActionPlan__c() ) );

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 1 );

		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		ActionPlanDetailController apDetailController2 = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );

		Test.StopTest();
	}

	@IsTest
	private static void printConstructorTests(){

		Test.setCurrentPage(Page.ActionPlanPrint);

		Test.StartTest();

		//System.currentPageReference().getParameters().put( 'id', null );
		ActionPlanDetailController apDetailController = new ActionPlanDetailController( new ApexPages.StandardController( new ActionPlan__c() ) );

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 1 );
		System.debug(actionPlan);

		//System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		ActionPlanDetailController apDetailController2 = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );

		apDetailController2.getRecordTypeName();

		Test.StopTest();

		System.assertEquals([SELECT Name FROM Account LIMIT 1].Name, apDetailController2.getRelatedObjectName());
		System.assertEquals('Account', apDetailController2.getRelatedObjectLabel());

	}

	@IsTest
	private static void checkTasks(){
		PageReference pageRef = Page.ActionPlanPrint;
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 3 );

		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		ActionPlanDetailController apDetailController = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		List<APTaskTemplate__c> apTasks = apDetailController.getTasks();

		//Checks to see that list of tasks is not empty
		System.assert( !apTasks.isEmpty(), 'task list is empty' );

		Test.StopTest();
	}

	/* @IsTest
	private static void checkTaskSize(){
		PageReference pageRef = Page.ActionPlanDetail;
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 3 );

		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		ActionPlanDetailController apDetailController = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );

		List<APTaskTemplate__c> apTasks = apDetailController.getTasks();
		Integer numTasks                = apDetailController.getTaskSize();

		//Checks to see that list of tasks is not empty
		System.assert( !apTasks.isEmpty(), 'task list is empty' );

		//check that both methods return correct number of task objects
		System.assertEquals( numTasks, apTasks.size() );

		Test.StopTest();
	} */

	@IsTest
	private static void checkCompletedTasks(){
		PageReference pageRef = Page.ActionPlanDetail;
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 3 );

		//System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		ActionPlanDetailController apDetailController = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		Integer completedTasks = apDetailController.getCompleted();

		//verifies number of completed tasks
		System.assertEquals( 0, completedTasks );

		Test.StopTest();
	}

	@IsTest
	private static void checkActionPlanTemplateVersion(){
		PageReference pageRef = Page.ActionPlanDetail;
		Test.StartTest();

		ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'account', 2 );
		ActionPlanTemplate__c apTemplate    = testUtil.createNewActionPlanTemplate( 2 );

		actionPlan.Action_Plan_Template__c = apTemplate.Id;
		update actionPlan;

		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		ActionPlanDetailController apDetailController = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		boolean versionName = apDetailController.getVersion();

		//Checks if Action Plan Template has not been changed since the creation of the Action Plan.
		//System.assert( !versionName );

		apTemplate.Name = 'new name';
		update apTemplate;

		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		apDetailController = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		versionName = apDetailController.getVersion();

		//Checks if Action Plan Template has been changed since the creation of the Action Plan.
		//System.assert( versionName );

		Test.StopTest();
	}

	@IsTest
	private static void checkDeleteActionPlan(){
		PageReference pageRef = Page.ActionPlanDetail;
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 2 );

		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		ActionPlanDetailController apDetailController = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		apDetailController.deletePlan();

		List<ActionPlan__c> actionPlanList = [SELECT Id FROM ActionPlan__c WHERE Id = :actionPlan.Id LIMIT 1];

		//Checks if Action Plan Template has been changed since the creation of the Action Plan.
		System.assert( actionPlanList.isEmpty(), 'Action Plan was not deleted' );

		Test.StopTest();
	}

	@IsTest
	private static void checkGetRelatedObjectName(){
		PageReference pageRef = Page.ActionPlanDetail;
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 0 );
		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		ActionPlanDetailController APDC = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		String name = APDC.getRelatedObjectName();
		System.assert(name != null);

		actionPlan = testUtil.createNewActionPlan( 'campaign', 0 );
		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		APDC = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		name = APDC.getRelatedObjectName();
		System.assert(name != null);

		actionPlan = testUtil.createNewActionPlan( 'case', 0 );
		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		APDC = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		name = APDC.getRelatedObjectName();
		System.assert(name != null);

		actionPlan = testUtil.createNewActionPlan( 'contact', 0 );
		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		APDC = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		name = APDC.getRelatedObjectName();
		System.assert(name != null);

		actionPlan = testUtil.createNewActionPlan( 'contract', 0 );
		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		APDC = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		name = APDC.getRelatedObjectName();
		System.assert(name != null);

		actionPlan = testUtil.createNewActionPlan( 'lead', 0 );
		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		APDC = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		name = APDC.getRelatedObjectName();
		System.assert(name != null);

		actionPlan = testUtil.createNewActionPlan( 'opportunity', 0 );
		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		APDC = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );
		name = APDC.getRelatedObjectName();
		System.assert(name != null);
	}

	@IsTest
	private static void testForceNoRecordType(){
		ActionPlansTestUtilities.forceHasRecordType = false;

		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);

		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 1 );

		System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
		ActionPlanDetailController apDetailController2 = new ActionPlanDetailController( new ApexPages.StandardController( actionPlan ) );

		Test.StopTest();

		System.assertEquals(false, apDetailController2.hasRecordType);
		System.assertEquals('', apDetailController2.getRecordTypeName());
	}
}