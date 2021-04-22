/*
Action Plans v4
Updated by David Schach 2021

Action Plans v3
Force.com Labs
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2011, salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, inc. nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
@IsTest
private with sharing class ActionPlanCreationControllerTest {

	@TestSetup
	static void makeData(){
		Action_Plans_Settings__c aps = Action_Plans_Settings__c.getOrgDefaults();
		aps.Chatter_Object_Brag__c = true;
		aps.Unassigned_Task_Default__c = true;
		try{
			upsert aps;
		} catch (Exception e){
			update aps;
		}
	}

	@IsTest
	private static void constructorTests(){

		Test.StartTest();
		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'contact', 2 );

		ApexPages.currentPage().getParameters().put( 'id', null );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );

		//ApexPages.currentPage().getParameters().put( 'id', actionPlan.Id );
		apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );

		ApexPages.currentPage().getParameters().put( 'id', null );
		ApexPages.currentPage().getParameters().put( 'clone', '1' );
		apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );

		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 3 );

		ApexPages.currentPage().getParameters().put( 'id', null );
		ApexPages.currentPage().getParameters().put( 'clone', null );
		ApexPages.currentPage().getParameters().put( 'templateId', apTemplate.Id );
		apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );

		Contact contact = testUtil.createNewContact();

		ApexPages.currentPage().getParameters().put( 'id', null );
		ApexPages.currentPage().getParameters().put( 'refId', contact.Id );
		//ApexPages.currentPage().getParameters().put( 'refType', 'Contact' );
		apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
		String refid    = apCreateController.refId;
		String reftype  = apCreateController.refType;

		apCreateController.refreshRelatedObjectsLookUp();
		apCreateController.getTaskRTPicklistValues();
		apCreateController.getTaskTypes();
		apCreateController.getTaskPriorities();
		apCreateController.getHoursOption();
		apCreateController.getDisplayTemplateLookup();
		apCreateController.getRecordTypeName();

		apCreateController.save();

		Test.StopTest();
	}

	@IsTest
	private static void testActionPlanSave(){

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
		ActionPlan__c ap = testUtil.createNewActionPlan('contact', 3);
		Contact contact = [SELECT Id FROM Contact LIMIT 1];

		ApexPages.currentPage().getParameters().put( 'id', ap.Id );
		ApexPages.currentPage().getParameters().put( 'refId', contact.Id );
		ApexPages.currentPage().getParameters().put( 'refType', 'Contact' );

		Test.StartTest();

		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( ap ) );

		apCreateController.actionPlan.name = 'updated name';

		apCreateController.save();

		Test.setCurrentPage(Page.ActionPlanCreation);
		apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( ap ) );

		apCreateController.actionPlan.SkipWeekends__c = true;
		apCreateController.actionPlan.SkipDay__c = 'Friday';

		apCreateController.save();

		Test.StopTest();

		List<ActionPlan__c> results = [SELECT Id, name, Contact__c FROM ActionPlan__c LIMIT 10000];
		System.debug(results);

		System.assert( !results.isEmpty(), 'Action Plan not created' );
		System.assert( results.size() == 1, 'Too many Action Plans created' );

		apCreateController.cancel();
	}

	@IsTest
	private static void testActionPlanSaveAndNew(){

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan            = new ActionPlan__c();

		Contact contact = testUtil.createNewContact();

		actionPlan.Name         = testUtil.createRandomWord();
		actionPlan.Contact__c   = contact.Id;
		actionPlan.StartDate__c = Date.today();

		APTaskTemplate__c apTask = new APTaskTemplate__c();

		apTask.Subject__c           = testUtil.createRandomWord();
		apTask.User__c              = testUtil.createTestUser().Id;
		apTask.DaysFromStart__c     = 2;
		apTask.Type__c              = 'Email';
		apTask.Priority__c          = 'High';

		ApexPages.currentPage().getParameters().put( 'id', null );
		ApexPages.currentPage().getParameters().put( 'refId', contact.Id );
		ApexPages.currentPage().getParameters().put( 'refType', 'Contact' );

		Test.StartTest();

		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );

		apCreateController.apTasks = new List<APTaskTemplate__c>();
		apCreateController.apTasks.add( apTask );
		apCreateController.saveAndNew();
		Test.StopTest();
		List<ActionPlan__c> results = [SELECT Id FROM ActionPlan__c LIMIT 10000];

		System.assert( !results.isEmpty(), 'Action Plan not created' );
		System.assert( results.size() == 1, 'ONE Action Plan not created' );
		System.debug(results.size() + ' action plans created');

	}

	@IsTest
	private static void testRelateToMultipleContacts(){

		final Integer CONCOUNT = 200;
		final Integer APTTASKCOUNT = 2;

		List<Contact> contacts = new List<Contact>();
		for(Integer i = 0; i < CONCOUNT; i++){
			Contact newContact 	= new Contact();
			newContact.LastName = 'con' + math.rint(math.random() * 100000);
			contacts.add(newContact);
		}

		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.allowSave = true;
		dml.DuplicateRuleHeader.runAsCurrentUser = true;
		List<Database.SaveResult> sr = Database.insert(contacts, dml);

		List<Id> conIDs = new List<Id>();
		for(Contact c : contacts){
			conIDs.add(c.Id);
		}
		String conIdsList = String.join(conIDs,',');

		ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( APTTASKCOUNT );

		Test.startTest();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ApexPages.currentPage().getParameters().put( 'id', null );
		ApexPages.currentPage().getParameters().put( 'templateId', apTemplate.Id);
		ApexPages.currentPage().getParameters().put( 'refId', conIDsList );
		ApexPages.currentPage().getParameters().put( 'refType', 'Contact' );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );

		apCreateController.getTasks();
		System.assertEquals(APTTASKCOUNT, apCreateController.getTasks().size());

		apCreateController.save();

		Test.stopTest();
		System.debug('TEST STOPPED');
		System.assertEquals(APTTASKCOUNT, [SELECT Count() FROM APTTaskTemplate__c]);
		System.assertEquals(CONCOUNT, [SELECT Count() FROM ActionPlan__c], 'Failed to make one AP per contact');
		System.debug('successfully related to ' + CONCOUNT + ' Contacts');

		System.debug([SELECT Name FROM ActionPlan__c]);

		System.assertEquals( CONCOUNT * APTTASKCOUNT, [SELECT Count() FROM APTaskTemplate__c], 'Not enough Action Plan Tasks created');

		System.assertEquals( CONCOUNT * APTTASKCOUNT, [SELECT Count() FROM Task], 'Wrong number of Tasks created');
	}

	@IsTest
	private static void checkCompletedTasks(){

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'account', 2 );

		Test.StartTest();

		//ApexPages.currentPage().getParameters().put( 'id', actionPlan.Id );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );

		Integer numTasksComplete = apCreateController.getCompleted();

		System.assert( numTasksComplete == 0, 'Action plan task completed count is incorrect' );

		Test.StopTest();
	}

	@IsTest
	private static void longNameTasks(){

		Test.StartTest();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'account', 2 );

		// add code for shortening long record names
		actionPlan.Name = '1234567890123456789012345678901234567890'; // 40 characters
		update actionPlan;
		List<APTaskTemplate__c> apts = [SELECT Id, Subject__c FROM APTaskTemplate__c];
		for(APTaskTemplate__c a : apts){
			a.Subject__c = 'abcdefghijabcdefghijabcdefghijabcdefghij'; // 40 characters
		}
		update apts;

		//ApexPages.currentPage().getParameters().put( 'id', actionPlan.Id );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );

		Integer numTasksComplete = apCreateController.getCompleted();

		System.assert( numTasksComplete == 0, 'Action plan task completed is incorrect' );

		Test.StopTest();

		for(APTaskTemplate__c a : [SELECT Id, Name FROM APTaskTemplate__c]){
			System.assertEquals(80, a.Name.length(), 'APTask Template name was not updated');
		}
	}

	@IsTest
	private static void testAddNewTask(){
		ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
		User ownerUser = testUtil.createTestUser();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'account', 0 );

		APTaskTemplate__c apTask = new APTaskTemplate__c();
		apTask.Action_Plan__c       = actionPlan.Id;
		apTask.Subject__c           = testUtil.createRandomWord();
		apTask.User__c              = ownerUser.Id;
		apTask.DaysFromStart__c     = 2;
		apTask.Type__c              = 'Email';
		apTask.Priority__c          = 'High';
		insert apTask;

		Id defaultTaskRTId = [SELECT Id, TaskRecordTypeID__c FROM ActionPlan__c LIMIT 1].TaskRecordTypeID__c;
		System.debug('defaultTaskRTID: ' + defaultTaskRTId);

		Test.StartTest();

		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
		apCreateController.apTasks = new List<APTaskTemplate__c>();
		apCreateController.getTasks();
		System.assertEquals(1, apCreateController.getTasks().size());
		apCreateController.addTask();
		apCreateController.getTasks();
		System.assertEquals(2, apCreateController.getTasks().size());

		ActionPlanCreationController.ApTaskWrapper apt = apCreateController.getTasks()[1];

		apt.task.Subject__c = testUtil.createRandomWord();
		apt.task.DaysFromStart__c = 3;
		apt.task.User__c = ownerUser.Id;
		apt.task.Priority__c = ActionPlansMetadataUtility.getTaskRecordTypePriorityDefaultValues().get(defaultTaskRTId);
		System.debug('Priority is set to ' + ActionPlansMetadataUtility.getTaskRecordTypePriorityDefaultValues().get(defaultTaskRTId));
		apCreateController.save();

		Test.StopTest();

		System.assertEquals(2, [SELECT Count() FROM APTaskTemplate__c]);
	}

	@IsTest
	private static void testRemoveActionPlanTask(){

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'account', 3 );

		Test.StartTest();

		ApexPages.currentPage().getParameters().put( 'id', actionPlan.Id );
		ApexPages.currentPage().getParameters().put( 'remove', '1' );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );

		apCreateController.getTasks();
		apCreateController.removeTask();
		apCreateController.save();

		Test.StopTest();

		System.assertEquals(2, [SELECT Count() FROM APTaskTemplate__c]);
	}

	@IsTest
	private static void checkActionPlanTaskList(){

		Test.StartTest();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'account', 2 );

		ApexPages.currentPage().getParameters().put( 'id', actionPlan.Id );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );

		List<ActionPlanCreationController.ApTaskWrapper> apTaskList = apCreateController.getTasks();

		System.assert( !apTaskList.isEmpty(), 'Action plan task list is empty' );

		Test.StopTest();
	}

	@IsTest
	private static void checkSubjectItems(){

		Test.StartTest();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'account', 2 );

		ApexPages.currentPage().getParameters().put( 'id', actionPlan.Id );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
		apCreateController.apTasks = [SELECT a.Type__c, a.Subject__c, a.ActivityDate__c, a.Priority__c, a.Status__c, a.Dependent__c,
														a.Name, a.User__c, a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.APTaskTemplate__r.Name,
														a.APTaskTemplate__r.Subject__c, a.APTaskTemplate__c, a.Action_Plan__c, a.Reminder__c,
														a.SendEmail__c, a.Comments__c
														FROM APTaskTemplate__c a
														WHERE a.Action_Plan__c = :actionPlan.Id ORDER BY a.createdDate asc];

		List<Selectoption> options = apCreateController.getSubjectItems();

		System.assert( !options.isEmpty(), 'SELECT options is empty' );
		System.assert( options.size() == 3, 'incorrect number of select options' );

		Test.StopTest();
	}

	@IsTest
	private static void testCyclicDependencyTaskSuccess(){

		Test.StartTest();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 0 );

		APTaskTemplate__c newAPTask1 = new APTaskTemplate__c();
		APTaskTemplate__c newAPTask2 = new APTaskTemplate__c();
		APTaskTemplate__c newAPTask3 = new APTaskTemplate__c();

		newAPTask1.Subject__c           = testUtil.createRandomWord();
		newAPTask1.DaysFromStart__c     = 2;
		newAPTask1.Dependent__c         = '2';
		newAPTask1.Type__c              = 'Email';
		newAPTask1.Priority__c          = 'High';
		newAPTask1.Action_Plan__c       = actionPlan.Id;
		upsert newAPTask1;

		newAPTask2.Subject__c           = testUtil.createRandomWord();
		newAPTask2.DaysFromStart__c     = 2;
		newAPTask2.Dependent__c         = 'None';
		newAPTask2.Type__c              = 'Email';
		newAPTask2.Priority__c          = 'High';
		newAPTask2.Action_Plan__c       = actionPlan.Id;
		upsert newAPTask2;

		newAPTask3.Subject__c           = testUtil.createRandomWord();
		newAPTask3.DaysFromStart__c     = 2;
		newAPTask3.Dependent__c         = '1';
		newAPTask3.Type__c              = 'Email';
		newAPTask3.Priority__c          = 'High';
		newAPTask3.Action_Plan__c       = actionPlan.Id;
		upsert newAPTask3;

		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );

		apCreateController.apTasks = new List<APTaskTemplate__c>();
		apCreateController.apTasks.add( newAPTask1 );
		apCreateController.apTasks.add( newAPTask2 );
		apCreateController.apTasks.add( newAPTask3 );

		apCreateController.save();

		System.assert( apCreateController.getErrorMsg() == ''  || String.isBlank(apCreateController.getErrorMsg()) );

		Test.StopTest();
	}

	@IsTest
	private static void testCyclicDependencyTasksFail(){

		Test.StartTest();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'account', 0 );

		APTaskTemplate__c newAPTask1 = new APTaskTemplate__c();
		APTaskTemplate__c newAPTask2 = new APTaskTemplate__c();
		APTaskTemplate__c newAPTask3 = new APTaskTemplate__c();

		newAPTask1.Subject__c           = testUtil.createRandomWord();
		newAPTask1.DaysFromStart__c     = 2;
		newAPTask1.Dependent__c         = '2';
		newAPTask1.Type__c              = 'Email';
		newAPTask1.Priority__c          = 'High';

		newAPTask2.Subject__c           = testUtil.createRandomWord();
		newAPTask2.DaysFromStart__c     = 2;
		newAPTask2.Dependent__c         = '0';
		newAPTask2.Type__c              = 'Email';
		newAPTask2.Priority__c          = 'High';

		newAPTask3.Subject__c           = testUtil.createRandomWord();
		newAPTask3.DaysFromStart__c     = 2;
		newAPTask3.Dependent__c         = '1';
		newAPTask3.Type__c              = 'Email';
		newAPTask3.Priority__c          = 'High';

		ApexPages.currentPage().getParameters().put( 'id', actionPlan.Id );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );

		apCreateController.apTasks = new List<APTaskTemplate__c>();
		apCreateController.apTasks.add( newAPTask1 );
		apCreateController.apTasks.add( newAPTask2 );
		apCreateController.apTasks.add( newAPTask3 );

		apCreateController.save();

		System.assert( apCreateController.getErrorMsg() != null );

		Test.StopTest();
	}

	@IsTest
	private static void checkReferredObject(){

		Test.StartTest();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		Contact contact         = testUtil.createNewContact();
		Account account         = testUtil.createNewAccount();
		Lead lead               = testUtil.createNewLead();
		Opportunity opportunity = testUtil.createNewOpportunity();

		ApexPages.currentPage().getParameters().put( 'id', null );
		ApexPages.currentPage().getParameters().put( 'refId', contact.id );
		ApexPages.currentPage().getParameters().put( 'refType', 'Contact' );

		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
		apCreateController.referedObjectInit();
		System.assertEquals('Contact', apCreateController.refType);

		System.assert( apCreateController.relatedObjNameList.size() == 2 );

		ApexPages.currentPage().getParameters().put( 'id', null );
		ApexPages.currentPage().getParameters().put( 'refId', account.Id );
		ApexPages.currentPage().getParameters().put( 'refType', 'Account' );

		apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
		apCreateController.referedObjectInit();

		System.assert( apCreateController.relatedObjNameList.size() == 2 );

		ApexPages.currentPage().getParameters().put( 'id', null );
		ApexPages.currentPage().getParameters().put( 'refId', lead.Id );
		ApexPages.currentPage().getParameters().put( 'refType', 'Lead' );

		apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
		apCreateController.referedObjectInit();

		System.assert( apCreateController.relatedObjNameList.size() == 2 );

		ApexPages.currentPage().getParameters().put( 'id', null );
		ApexPages.currentPage().getParameters().put( 'refId', opportunity.Id );
		ApexPages.currentPage().getParameters().put( 'refType', 'Opportunity' );

		apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
		apCreateController.referedObjectInit();

		System.assert( apCreateController.relatedObjNameList.size() == 2 );
		System.assert( apCreateController.getRelatedObjectOptions().size() == apCreateController.getRelatedObjectOptions().size() );

		Test.StopTest();
	}

	@IsTest
	private static void testCustomMessage(){

		try{
			Account c = new Account();
			insert c;
		}
		catch( DmlException e1 ) {
			try{
				throw new ActionPlanCreationController.FieldCustomValidationException( e1 );
			}
			catch( ActionPlanCreationController.FieldCustomValidationException e2 ){
				System.assert( e2.getCustomMessage() != '' );
			}

		}
	}

	@IsTest
	private static void testSetTaskRecordType() {

		Test.startTest();

		ActionPlansTestUtilities testutil =  new ActionPlansTestUtilities();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlan__c ap = testutil.createNewActionPlan( 'contact',  5 );

		ApexPages.currentPage().getParameters().put( 'id', ap.Id );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( ap ) );

		apCreateController.refreshRelatedObjectsLookUp();
		apCreateController.actionPlan.TaskRecordTypeID__c = ActionPlansTestUtilities.getNonDefaultAvailableTaskRecordType();
		apCreateController.actionPlan.SkipWeekends__c = true;
		apCreateController.actionPlan.SkipDay__c = 'Friday';
		apCreateController.getTasks();

		System.assert( !apCreateController.getTasks().isEmpty() );

		apCreateController.save();

		Test.stopTest();

		if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
			if(ActionPlansTestUtilities.getNonDefaultAvailableTaskRecordType() != null){
				String taskQuery = 'SELECT Id, RecordTypeId FROM Task';

				for(SObject t : Database.query(taskQuery)){
					System.debug([SELECT Id, Name FROM RecordType WHERE Id = :(Id)t.get('RecordTypeId')].Name);
					System.assertNotEquals(ActionPlansMetadataUtility.getDefaultTaskRecordTypeId(), t.get('RecordTypeId'), 'Record Type is default');
				}
			}
		}
	}

	@IsTest
	private static void testForceNoRecordTypes(){
		ActionPlansTestUtilities.forceHasRecordType = false;

		System.debug('hasrt: ' + ActionPlansMetadataUtility.HAS_RECORD_TYPE);

		ActionPlansMetadataUtility.getTaskRecordTypeStatusDefaultValues();
		ActionPlansMetadataUtility.getTaskRecordTypePriorityDefaultValues();

		Test.startTest();

		ActionPlansTestUtilities testutil =  new ActionPlansTestUtilities();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlan__c actionPlan = testutil.createNewActionPlan( 'contact', 2 );

		ApexPages.currentPage().getParameters().put( 'id', actionPlan.Id );
		ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan) );

		Test.stopTest();
		System.assertEquals(null, apCreateController.getDefaultTaskRecordTypeId());

		System.assert(!ActionPlansMetadataUtility.HAS_RECORD_TYPE);

	}

}