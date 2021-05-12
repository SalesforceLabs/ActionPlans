@IsTest
private class ActionPlanTemplateCreationCntrlTest {
	@IsTest
	private static void testContructor(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		System.currentPageReference().getParameters().put( 'id', null );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		aptcc.getTemplateTasks();

		System.currentPageReference().getParameters().put( 'clone', '1' );
		aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		aptcc.getTemplateWrappers();
		aptcc.getDefaultTaskRecordTypeId();
		aptcc.getTaskRTPicklistValues();
		aptcc.getTaskTypes();
		aptcc.getTaskPriorities();

		Test.StopTest();
	}

	@IsTest
	private static void testSave(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = new ActionPlanTemplate__c();

		apTemplate.Name = testUtil.createRandomWord('Name');

		APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();

		newAPTTask.Subject__c 		 = testUtil.createRandomWord('subject');
		newAPTTask.DaysFromStart__c = 2;
		newAPTTask.Type__c 			 = 'Email';
		newAPTTask.Priority__c 		 = 'High';

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		aptcc.aptTasks = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.add( newAPTTask );
		Pagereference page = aptcc.saveTemplate();

		Test.StopTest();

		System.assert( page != null );
		System.assert( aptcc.saveAndNew() != null);

	}

	//Test Saves Action Plan Template and all tasks
	@IsTest
	private static void testSaveTemplate(){

		Test.setCurrentPage(Page.ActionPlanTemplateCreation);

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c   apt = testutil.createNewActionPlanTemplate( 5 );
		User tUser = testutil.createTestUser();
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apt));
		Test.StartTest();

		aptcc.pendingTemplateDeletes = new List<APTTaskTemplate__c>();
		//aptcc.aptTasks = new List<APTTaskTemplate__c>();
		aptcc.pendingTemplateDeletes.add( testutil.createNewActionPlanTemplateTask(apt, 3, tUser, 'Email', 'High') );
		insert aptcc.pendingTemplateDeletes;
		aptcc.aptTasks.add( testutil.createNewActionPlanTemplateTask(apt, 3, null, 'Email', 'High') );
		aptcc.aptTasks.add( testutil.createNewActionPlanTemplateTask(apt, 3, tUser, 'Email', 'High') );
		aptcc.aptTasks.get(0).Dependent__c = '1';

		aptcc.saveTemplate();

		System.assert( !aptcc.pendingTemplateDeletes.isEmpty() );

		//Enter Task Catch()
		aptcc.pendingTemplateDeletes = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.clear();
		aptcc.aptTasks.add( new APTTaskTemplate__c( DaysFromStart__c = -3 ) );
		aptcc.saveTemplate();

		System.assert( !aptcc.aptTasks.isEmpty());

		//Enter APT Catch()
		aptcc.actionPlanTemplate = null;
		aptcc.saveTemplate();
		System.assert( !aptcc.aptTasks.isEmpty());

		Test.StopTest();
	}

	@IsTest
	private static void testCancel(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
		aptcc.cancelTemplate();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		aptcc.cancelTemplate();

		Test.StopTest();
	}

	@IsTest
	private static void testForceNoRecordType(){
		ActionPlansTestUtilities.forceHasRecordType = false;

		Test.setCurrentPage(Page.ActionPlanTemplateCreation);

		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(5);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );

		Test.StopTest();

		System.assertEquals(false, aptcc.taskHasRecordType);
	}

	@IsTest
	static void checkMaxTasksError(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( ActionPlansConstants.MAX_APTASKS + 1 );

		//System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		aptcc.getTemplateTasks();
		System.currentPageReference().getParameters().put( 'add ', '1' );
		aptcc.addTemplateTask();
		Test.stopTest();
		String errorMsg = aptcc.getErrorMsg();
		System.debug(errorMsg);
		System.debug(String.valueof(ActionPlansConstants.MAX_APTASKS));
		System.assert(errorMsg.containsIgnoreCase(String.valueOf(ActionPlansConstants.MAX_APTASKS)));

	}

	@IsTest
	private static void testAddTemplateTask(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		//aptcc.getTemplateTasks();
		System.currentPageReference().getParameters().put( 'add ', '1' );
		aptcc.addTemplateTask();

		Test.StopTest();
	}

	@IsTest
	private static void testAddNewActionPlanTemplateTask(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );

		//System.currentPageReference().getParameters().put( 'add', '1') ;

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(actionPlanTemplate));

		/* aptcc.aptTasks = [SELECT a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c,
		a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c,
		a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c
		FROM APTTaskTemplate__c a
		WHERE a.Action_Plan_Template__c = :actionPlanTemplate.Id]; */

		Boolean error = aptcc.addedTask;
		aptcc.addTemplateTask();

		System.assert( aptcc.geterrorMsg() == null, 'A error was returned when adding a template task ');

		ActionPlanTemplate__c actionPlanTemplate2 = testUtil.createNewActionPlanTemplate( ActionPlansConstants.MAX_APTASKS );
		aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(actionPlanTemplate2));
		//System.currentPageReference().getParameters().put( 'add', '1') ;

		aptcc.getTemplateTasks();

		aptcc.addTemplateTask();
		error = aptcc.addedTask;
		System.assert(!aptcc.addedTask);

		System.assert( aptcc.geterrorMsg() != null, 'A error was not returned when adding a template task' );

		Test.StopTest();
	}

	@IsTest
	private static void testRemoveTemplateTask(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 4 );

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		aptcc.getTemplateTasks();
		System.currentPageReference().getParameters().put( 'remove', '1' );
		aptcc.removeTemplateTask();

		Test.StopTest();
	}

	@IsTest
	private static void testRemovingActionPlanTemplateTask(){

		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 5 );

		System.assertEquals(5, [SELECT Count() FROM APTTaskTemplate__c], 'We created 5 tasks');



		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(actionPlanTemplate));
		aptcc.getTemplateTasks();
		System.assertEquals(5, aptcc.aptTasks.size(), 'Should have 5 tasks on the template');

		System.currentPageReference().getParameters().put( 'remove', '1') ;
		aptcc.removeTemplateTask();

		aptcc.saveTemplate();

		Test.StopTest();
		aptcc.getTemplateTasks();

		System.assert( aptcc.aptTasks.size() == 4, 'Task was not deleted correctly' );
		System.assertEquals(4, aptcc.getTemplateTasks().size(), 'Tasks get after delete failed');
	}

	@IsTest
	private static void testRetrievingTemplateTasks(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList =  aptcc.getTemplateWrappers();

		//checks that the list is not empty
		System.assert( !taskList.isEmpty(), 'Task list was not Empty' );

		Test.StopTest();
	}

	@IsTest
	private static void testLongNameTemplateTasks(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		apTemplate.Name = '1234567890123456789012345678901234567890'; // 40 characters
		update apTemplate;

		List<APTTaskTemplate__c> aptts = [SELECT Id, Subject__c FROM APTTaskTemplate__c];
		for(APTTaskTemplate__c a : aptts){
			a.Subject__c = 'abcdefghijabcdefghijabcdefghijabcdefghij'; // 40 characters
		}
		update aptts;

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList =  aptcc.getTemplateWrappers();

		//checks that the list is not empty
		System.assert( !taskList.isEmpty(), 'Task list was not Empty' );

		Test.StopTest();
	}

	@IsTest
	private static void checkTemplateTaskSize(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList =  aptcc.getTemplateWrappers();
		Integer numTasks = aptcc.getTemplateTaskSize();

		//checks that the list is not empty
		System.assert( !taskList.isEmpty(), 'Task list was not Empty' );

		//Checks to see if both methods return same task size
		System.assertEquals( taskList.size(), numTasks );

		Test.StopTest();
	}

	@IsTest
	private static void checkTemplateSubjectItem(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );

		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList = aptcc.getTemplateWrappers();
		List<SelectOption> subjectItems = aptcc.getTemplateSubjectItems();

		Test.StopTest();
	}

	@IsTest
	private static void testCyclicDependencyFail(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		APTTaskTemplate__c newAPTTask1 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask2 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask3 = new APTTaskTemplate__c();

		newAPTTask1.Subject__c 		 = testUtil.createRandomWord('subject');
		newAPTTask1.DaysFromStart__c = 2;
		newAPTTask1.Dependent__c	 = '2';
		newAPTTask1.Type__c 		 = 'Email';
		newAPTTask1.Priority__c 	 = 'High';
		newAPTTask1.TaskIndex__c        = 0;

		newAPTTask2.Subject__c           = testUtil.createRandomWord('subject');
		newAPTTask2.DaysFromStart__c     = 2;
		newAPTTask2.Dependent__c         = '0';
		newAPTTask2.Type__c              = 'Email';
		newAPTTask2.Priority__c          = 'High';
		newAPTTask2.TaskIndex__c         = 1;

		newAPTTask3.Subject__c 		 = testUtil.createRandomWord('subject');
		newAPTTask3.DaysFromStart__c = -2;
		newAPTTask3.Dependent__c	 = '1';
		newAPTTask3.Type__c 		 = 'Email';
		newAPTTask3.Priority__c 	 = 'High';
		newAPTTask3.TaskIndex__c        = 2;

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );

		aptcc.aptTasks = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.add( newAPTTask1 );
		aptcc.aptTasks.add( newAPTTask2 );
		aptcc.aptTasks.add( newAPTTask3 );

		aptcc.checkCycleDependent();

		System.assert( aptcc.getErrorMsg() != null, 'dependency check failed' );

		Test.StopTest();
	}

	@IsTest
	private static void testItselfCyclicDependencyFail(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		APTTaskTemplate__c newAPTTask1 = new APTTaskTemplate__c();

		newAPTTask1.Subject__c 		 = testUtil.createRandomWord('subject');
		newAPTTask1.DaysFromStart__c = 2;
		newAPTTask1.Dependent__c	 = '0';
		newAPTTask1.Type__c 		 = 'Email';
		newAPTTask1.Priority__c 	 = 'High';
		newAPTTask1.TaskIndex__c        = 0;

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );

		aptcc.aptTasks = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.add( newAPTTask1 );

		aptcc.checkCycleDependent();

		System.assert( aptcc.getErrorMsg() != null, 'dependency check failed' );

		Test.StopTest();
	}

	@IsTest
	private static void testCyclicDependencySuccess(){
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );

		APTTaskTemplate__c newAPTTask1 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask2 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask3 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask4 = new APTTaskTemplate__c();

		newAPTTask1.Subject__c 		 = testUtil.createRandomWord('subject');
		newAPTTask1.DaysFromStart__c = 2;
		newAPTTask1.TaskIndex__c      = 0;
		newAPTTask1.Dependent__c		 = '2';
		newAPTTask1.Type__c 			 = 'Email';
		newAPTTask1.Priority__c 		 = 'High';

		newAPTTask2.Subject__c 		 = testUtil.createRandomWord('subject');
		newAPTTask2.DaysFromStart__c = 2;
		newAPTTask2.TaskIndex__c     = 1;
		newAPTTask2.Dependent__c	 = '0';
		newAPTTask2.Type__c 		 = 'Email';
		newAPTTask2.Priority__c 	 = 'High';

		newAPTTask3.Subject__c 		 = testUtil.createRandomWord('subject');
		newAPTTask3.DaysFromStart__c = 2;
		newAPTTask3.TaskIndex__c     = 2;
		newAPTTask3.Dependent__c	 = '1';
		newAPTTask3.Type__c 		 = 'Email';
		newAPTTask3.Priority__c 	 = 'High';

		newAPTTask4.Subject__c 		 = testUtil.createRandomWord('subject');
		newAPTTask4.DaysFromStart__c = 2;
		newAPTTask4.TaskIndex__c     = 3;
		newAPTTask4.Dependent__c	 = '1';
		newAPTTask4.Type__c 		 = 'Email';
		newAPTTask4.Priority__c 	 = 'High';

		System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );

		aptcc.aptTasks = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.add( newAPTTask1 );
		aptcc.aptTasks.add( newAPTTask2 );
		aptcc.aptTasks.add( newAPTTask3 );
		aptcc.aptTasks.add( newAPTTask4 );

		aptcc.checkCycleDependent();
		System.assert( aptcc.getErrorMsg() != null, 'dependency check failed' );

		System.currentPageReference().getParameters().put( 'remove', '1' );
		aptcc.removeTemplateTask();
		aptcc.saveTemplate();

		Test.StopTest();
	}

}