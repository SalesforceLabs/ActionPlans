@IsTest
private class ActionPlanTemplateDetailCntrlTest {
	@IsTest
	private static void testConstructor(){
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );

		apTemplate = [SELECT Id, TaskRecordTypeId__c FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id LIMIT 1];

		if(ActionPlansUtilities.HAS_RECORD_TYPE){

			System.assertNotEquals(null, apTemplate.TaskRecordTypeID__c);
		}

		Test.StartTest();

		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );

		//apTemplate = [SELECT Id FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id LIMIT 1];

		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		apTemplateDetailController = new ActionPlanTemplateDetailController( new ApexPages.StandardController( apTemplate ) );

		if(apTemplateDetailController.taskHasRecordType){
			System.assertNotEquals('', apTemplateDetailController.getRecordTypeName());
		} else {
			System.assertEquals('', apTemplateDetailController.getRecordTypeName());
		}

		//apTemplateDetailController.getMaxAPTasks();

		Test.StopTest();

		System.assert(!apTemplateDetailController.getTemplateTasks().isEmpty());
	}

	@IsTest
	private static void testForceNoRecordType(){
		ActionPlansTestUtilities.forceHasRecordType = false;

		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );

		apTemplate = [SELECT Id, TaskRecordTypeId__c FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id LIMIT 1];
		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );

		Test.StartTest();

		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController( new ApexPages.StandardController( apTemplate ));

		Test.StopTest();

		System.assertEquals('', apTemplateDetailController.getRecordTypeName());
	}

	@IsTest
	private static void testDeleteActionPlanTemplate(){
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		Test.StartTest();

		ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController( new ApexPages.StandardController( apTemplate ) );

		apTemplateDetailController.deleteTemplate();

		List<ActionPlanTemplate__c> auxTemplate = [SELECT Id FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id];

		//Checks to see if action plan template has been deleted
		System.assert( auxTemplate.isEmpty(), 'action plan Template was not deleted' );

		Test.StopTest();
	}

	@IsTest
	private static void testRetrievingTemplateTasks(){

		ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 3 );

		System.assertEquals(3, [SELECT Count() FROM APTTaskTemplate__c]);

		Test.StartTest();
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		//System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController( new ApexPages.StandardController( apTemplate ) );

		List<APTTaskTemplate__c> taskList = apTemplateDetailController.getTemplateTasks();

		//Checks to see if template tasks is not empty
		System.assert( !taskList.isEmpty(), 'action plan Template tasks is empty' );

		//checks that list contains total number of created tasks
		System.assertEquals( 3, taskList.size() );

		Test.StopTest();
	}

	@IsTest
	private static void testRetrievingActionPlanTemplate(){
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		Test.StartTest();

		ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 3 );

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController( new ApexPages.StandardController( apTemplate ) );

		ActionPlanTemplate__c apTemplate2 = apTemplateDetailController.actionPlanTemplate;

		//Checks to see if action plan template is retrieved
		System.assert( apTemplate2 != null, 'action plan Template tasks is empty' );

		//checks to see if both action plan templates are the same
		System.assertEquals( apTemplate2.Id, apTemplate.Id  );

		Test.StopTest();
	}

	@IsTest
	private static void exportTest(){
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 3 );

		ActionPlanTemplateDetailController controller = new ActionPlanTemplateDetailController( new ApexPages.StandardController( apTemplate ) );

		controller.exportTemplateToXMLDoc();

		System.assert( controller.actionPlanExportXMLId != null );

		Test.StopTest();
	}
}