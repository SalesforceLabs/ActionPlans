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
public inherited sharing class ActionPlansTaskTriggerUtilities {

	public  Set<Id>                 closedTasks;
	public  Set<Id>                 inProgressTasks;
	private List<APTaskTemplate__c> dependentAptts   { get; set; }
	private Map<Id, Task>           newTaskMap       { get; set; }
	private List<APTaskTemplate__c> updateApttsList  { get; set; }
	private List<Task>              tasksSendEmail   { get; set; }
	private List<Task>              tasksSendNoEmail { get; set; }

	/**
	* Constructor
	*/
	public ActionPlansTaskTriggerUtilities(){

		this.tasksSendEmail		= new List<Task>();
		this.tasksSendNoEmail 	= new List<Task>();
		this.dependentAptts = new List<APTaskTemplate__c>();
	}

	/**
	* Initialize the functionalities to Create All dependent Tasks
	* @param cTasks
	*/
	@future
	public static void initDependentTaskWork( Map<Id, String> cTasks) {
		System.debug('FUTURE initDependentTaskWork');
		ActionPlansTaskTriggerUtilities apTTUtils = new ActionPlansTaskTriggerUtilities();
		apTTUtils.closedTasks = cTasks.keyset();

		if( !apTTUtils.closedTasks.isEmpty() ){

			//Mark all APTask as 'Completed'
			apTTUtils.updateActionPlansTemplateTask(cTasks);

			//Get all dependent APTask
			apTTUtils.dependentActionPlansTemplateTask();

			//Create actual Task Map
			apTTUtils.populateNewTaskMap();

			//Finaly, Create all New Tasks and Send DMLOption Emails
			apTTUtils.populateUpdateApttsList();

			Database.DMLOptions dmlo = new Database.DMLOptions();

			if(!apTTUtils.tasksSendEmail.isEmpty()){
				dmlo.EmailHeader.triggerUserEmail = true;
				Database.insert( apTTUtils.tasksSendEmail, dmlo );
			}

			if(!apTTUtils.tasksSendNoEmail.isEmpty()){
				dmlo.EmailHeader.triggerUserEmail = false;
				Database.insert( apTTUtils.tasksSendNoEmail, dmlo );
			}

			Database.update( apTTUtils.updateApttsList );
		}
	}

	/**
	* Update associated aptt of task to match status
	*/
	private void updateActionPlansTemplateTask(Map<Id, String> cTasks){

		List<APTaskTemplate__c> updateApttList = new List<APTaskTemplate__c>();

		for ( APTaskTemplate__c aptt : [SELECT ap.Id, ap.Status__c FROM APTaskTemplate__c ap WHERE ap.Id IN :cTasks.keyset()] ){
			aptt.Status__c = cTasks.get(aptt.Id);
			updateApttList.add( aptt );
		}

		update updateApttList ;
	}

	/**
	* Get list of dependent Action Plans Template Task
	*/
	private List<APTaskTemplate__c> dependentActionPlansTemplateTask() {

		this.dependentAptts = new List<APTaskTemplate__c>();
		//Add Action Plan custom object reference Field.

		String apdependentQuery = 'SELECT Action_Plan__r.SkipWeekends__c, ';

		apdependentQuery += 'Action_Plan__r.' + String.join(ActionPlansMetadataUtility.getCustomRelationshipFields(), ', Action_Plan__r.') + ', ';

		apdependentQuery += ' Action_Plan__r.StartDate__c, Action_Plan__c, Type__c, Subject__c, ActivityDate__c, ' +
		'Dependent__c, Name, User__c, User__r.Name, Id, DaysFromStart__c, CreatedById, ' +
		'APTaskTemplate__r.Subject__c, APTaskTemplate__c, SendEmail__c,  APTaskTemplate__r.Name, ' +
		'Reminder__c, Priority__c, Status__c, Comments__c, Minutes_Reminder__c, Task_RecordTypeId__c' +
		' FROM APTaskTemplate__c WHERE APTaskTemplate__c IN :closedTasks';
		System.debug('APDEPENDENTQUERY: ' + apdependentQuery);

		this.dependentAptts = Database.query(apdependentQuery);
		return this.dependentAptts;

	}

	/**
	* Cycle through list of dependent Action Plans Template Task and create actual tasks
	*/
	private void populateNewTaskMap(){
		List<APTaskTemplate__c> updList = new List<APTaskTemplate__c>();
		Task auxTask;
		this.newTaskMap = new Map<Id, Task>();

		for( APTaskTemplate__c dependentAptt : this.dependentAptts ){

			//Create the new task and template
			//check if the task was already created
			List<Task> lt = [SELECT Id FROM Task WHERE TaskAPTaskTemplate__c = :dependentAptt.Id];
			if (!lt.isEmpty()){
				auxTask	= lt[0];
			} else {
				//Create the new task and template
				auxTask	= new Task();
			}

			auxTask.Subject             = dependentAptt.Subject__c;
			auxTask.Priority            = dependentAptt.Priority__c;
			auxTask.OwnerId             = dependentAptt.User__c;
			//auxTask.Type				= dependentAptt.Type__c;
			auxTask.TaskAPTaskTemplate__c   = dependentAptt.Id;
			if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
				auxTask.put('RecordTypeId', dependentAptt.Task_RecordTypeId__c);
			}

			if( dependentAptt.Status__c == null ){
				String defaultStatus;
				if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
					defaultStatus = ActionPlansMetadataUtility.getTaskRecordTypeStatusDefaultValues().get(ActionPlansMetadataUtility.getDefaultTaskRecordTypeId());
				} else {
					defaultStatus = ActionPlansMetadataUtility.getTaskRecordTypeStatusDefaultValues().get(null);
				}
				auxTask.Status = defaultStatus;
				dependentAptt.Status__c = defaultStatus;//update status of Task Template
				updList.add(dependentAptt);
			}

			// calculate the due date of the tasks for skip weekends feature
			if( dependentAptt.Action_Plan__r.SkipWeekends__c ){

				Date dueDate        = this.getCompletedATPTaskDate(dependentAptt.Id);
				Integer addDays     = dependentAptt.DaysFromStart__c.intValue();

				// find if the due date fall on a Saturday or Sunday.  Add 1 day for Sunday and 2 for Saturday
				Date refDate        = Date.newInstance( 1900, 1, 7 );  // Jan 7 1900 = Sun

				Integer dayOfWeek   = Math.mod( refDate.daysBetween( dueDate ), 7 ); // 0 = Sun ... 6 = Sat

				addDays = ( dayOfWeek == 0 )? addDays + 1 : addDays;
				addDays = ( dayOfWeek == 6 )? addDays + 2 : addDays;

				Date d = this.getCompletedATPTaskDate(dependentAptt.Id);
				auxTask.ActivityDate = d.addDays( addDays );
			}
			else {
				Date d = this.getCompletedATPTaskDate(dependentAptt.Id);
				dependentAptt.ActivityDate__c = d.addDays( dependentAptt.DaysFromStart__c.intValue() );
			}

			this.newTaskMap.put( auxTask.TaskAPTaskTemplate__c, auxTask );
		} // end for loop

		//will update records for AP Tasks templates whose related tasks was created as Non Started
		if (!updList.isEmpty()){
			upsert updList;
		}
	}

	/**
	* Cycle through list of dependent Action Plans Template Task and create tasks
	*/
	private void populateUpdateApttsList(){
		Task t2 ;
		this.updateApttsList = new List<APTaskTemplate__c>();

		for( APTaskTemplate__c dependentAptt : this.dependentAptts ){

			//Create the new task and template
			List<Task> lt = [SELECT Id FROM Task WHERE TaskAPTaskTemplate__c   = :dependentAptt.Id];
			if (!lt.isEmpty()){
				t2	= lt[0];
			} else {
				//Create the new task and template
				t2	= new Task();
			}

			t2.Subject           = dependentAptt.Subject__c;
			t2.Priority          = dependentAptt.Priority__c;
			t2.OwnerId           = dependentAptt.User__c;
			t2.TaskAPTaskTemplate__c = dependentAptt.Id;
			if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
				t2.put('RecordTypeId', dependentAptt.Task_RecordTypeId__c);
			}

			Date d = this.getCompletedATPTaskDate(dependentAptt.Id);
			dependentAptt.ActivityDate__c = d.addDays( dependentAptt.DaysFromStart__c.intValue() );

			if( dependentAptt.Comments__c != null ){
				t2.Description = dependentAptt.Comments__c;
			}

			//set reminder based on user's default reminder setting
			if( dependentAptt.Reminder__c ){
				t2.isReminderSet 	= dependentAptt.Reminder__c;
				t2.ReminderDateTime = datetime.newInstance( dependentAptt.ActivityDate__c.year(), dependentAptt.ActivityDate__c.month(), dependentAptt.ActivityDate__c.day(), 0, 0, 0 );
				t2.ReminderDateTime = t2.ReminderDateTime.addMinutes( Integer.valueOf( dependentAptt.Minutes_Reminder__c ) );
			}

			ActionPlan__c ap = dependentAptt.Action_Plan__r;

			for( String s : ActionPlansMetadataUtility.getCustomRelationshipFields() ){
				String f = s;
				if(!f.equalsIgnoreCase('Contact__c') && !f.equalsIgnoreCase('Lead__c') && ap.get(f) != null){
					t2.WhatId = (Id)ap.get(f);
					break;
				}
			}

			if( dependentAptt.Action_Plan__r.Contact__c != null ){
				t2.WhoId = dependentAptt.Action_Plan__r.Contact__c;
			}

			if( dependentAptt.Action_Plan__r.Lead__c != null ){
				t2.WhoId = dependentAptt.Action_Plan__r.Lead__c;
			}

			t2.Type         = dependentAptt.Type__c;
			String defaultStatus;
			if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
				defaultStatus = ActionPlansMetadataUtility.getTaskRecordTypeStatusDefaultValues().get(ActionPlansMetadataUtility.getDefaultTaskRecordTypeId());
			} else {
				defaultStatus = ActionPlansMetadataUtility.getTaskRecordTypeStatusDefaultValues().get(null);
			}
			t2.Status = defaultStatus;
			//t2.Status       = defaultStatus;
			t2.ActivityDate = dependentAptt.ActivityDate__c;

			this.newTaskMap.put( t2.TaskAPTaskTemplate__c, t2 );
			this.updateApttsList.add( dependentAptt ) ;

			//populate the list to send emails or not.
			if(dependentAptt.SendEmail__c){
				tasksSendEmail.add(t2);
			} else {
				tasksSendNoEmail.add(t2);
			}
		}
	}

	private Date getCompletedATPTaskDate( Id aptTaskId ){
		Date d;
		APTaskTemplate__c lAPT = [SELECT APTaskTemplate__r.id, APTaskTemplate__r.ActivityDate__c FROM APTaskTemplate__c WHERE Id = :aptTaskId];

		if ( lAPT != null &&  lAPT.APTaskTemplate__r.ActivityDate__c != null){
			d = lAPT.APTaskTemplate__r.ActivityDate__c;
		} else {
			d = Date.today();
		}

		return d;
	}

	/**
	* Update APTasks status as passed into method
	* @param cTasks
	*/
	@future
	public static void updateAPTasksStatus( Map<Id, String> cTasks ) {

		ActionPlansTaskTriggerUtilities apTTUtils = new ActionPlansTaskTriggerUtilities();
		apTTUtils.inProgressTasks = cTasks.keyset();

		if( !apTTUtils.inProgressTasks.isEmpty() ){

			//Update all APTasks
			//apTTUtils.updateActionPlansTemplateTask('In Progress');

			List<APTaskTemplate__c> updateApttList = new List<APTaskTemplate__c>();

			for ( APTaskTemplate__c aptt : [SELECT Id, ap.Status__c FROM APTaskTemplate__c ap WHERE ap.Id IN :cTasks.keyset()] ){
				aptt.Status__c = cTasks.get(aptt.Id);
				updateApttList.add( aptt );
			}

			update updateApttList ;
		}
	}

	/**
	* Delete Action Plan Tasks
	* @param aPTasks
	*/
	@future
	public static void deleteAPTasks( Set<Id> aPTasks ) {
		try{
		delete [SELECT aPT.Id FROM APTaskTemplate__c aPT WHERE aPT.Id IN :aPTasks];
		} catch (Exception e){
			System.debug('Error deleting APTTemplate - probably a circular error when deleting a APTTemplate, then its Task, then the template again.');
		}
	}

	/**
	* Delete Action Plan Tasks related Tasks
	* @param apttIds
	*/
	@future
	public static void deleteTasks( Set<Id> apttIds ) {
		delete [SELECT Id FROM Task WHERE IsClosed = false AND Id IN :apttIds];
	}

	/*
	This method reviews the task list and removes the one with TaskIndex__c field matching tmp_taskIndex.
	Rearranges the dependencies between tasks.
	*/
	private static void generateDependentTasksAndReset(List<APTaskTemplate__c> apTasks, Decimal tmp_taskIndex ){
		Set<Id> pendingIdsToDelete = new Set<Id>();

		//APTaskTemplate__c apTask;
		Integer taskIndex, dependentApTask ;

		for( Integer t_i = 0; t_i < apTasks.size();  t_i++ ){
			APTaskTemplate__c apTask = apTasks[ t_i ];
			if (apTask.TaskIndex__c == tmp_taskIndex){
				taskIndex = t_i;
			}
		}

		//update the current dependent position from tasks below of deleted one.
		for( Integer i = 0; i < apTasks.size(); i++ ){

			APTaskTemplate__c apTask = apTasks[ i ];

			if( apTask.Dependent__c != null && apTask.Dependent__c != 'None' ){
				dependentApTask = Integer.valueOf( apTask.Dependent__c );

				if( dependentApTask > taskIndex ){
					apTask.Dependent__c = String.valueOf( dependentApTask - 1 );
				} else {
					if( dependentApTask == taskIndex ){
						apTask.Dependent__c 		= 'None';
						apTask.APTaskTemplate__c    = null;
					}
				}
			}
		}

		// before remove check if it exists in the DB; if so, add to pendingDeletes to be deleted on save.
		if( apTasks[taskIndex].Id != null ){
			pendingIdsToDelete.add(apTasks[taskIndex].Id);
		}

		apTasks.remove( taskIndex );

		ActionPlansTaskTriggerUtilities apTTUtils = new ActionPlansTaskTriggerUtilities();
		apTTUtils.closedTasks = pendingIdsToDelete;

		if( !apTTUtils.closedTasks.isEmpty() ){

			//Get all dependent APTask
			apTTUtils.dependentActionPlansTemplateTask();

			//Create actual Task Map
			apTTUtils.populateNewTaskMap();

			//Finaly, Create all New Tasks and Send DMLOption Emails
			apTTUtils.populateUpdateApttsList();

			Database.DMLOptions dmlo = new Database.DMLOptions();

			if(!apTTUtils.tasksSendEmail.isEmpty()){
				dmlo.EmailHeader.triggerUserEmail = true;
				Database.insert( apTTUtils.tasksSendEmail, dmlo );
			}

			if(!apTTUtils.tasksSendNoEmail.isEmpty()){
				dmlo.EmailHeader.triggerUserEmail = false;
				Database.insert( apTTUtils.tasksSendNoEmail, dmlo );
			}

		}

		Database.update(apTasks);
	}

	/**
	* Before deleting a APTemplate task, Initialize the functionalities to Create All dependent Tasks and reset index
	* @param cTasks list with Task templates to be deleted
	*/
	public static void initDependentTasksAndReset( Set<Id> cTasks ) {

		try{

			ActionPlansTaskTriggerUtilities apTTUtils = new ActionPlansTaskTriggerUtilities(); // why is this line here?
			Map<Id, APTaskTemplate__c> apIdsMaps = new Map<Id, APTaskTemplate__c>();
			List<APTaskTemplate__c>  lAPT = [SELECT  a.Id, a.Action_Plan__c, a.TaskIndex__c, a.Dependent__c
											FROM APTaskTemplate__c a
											WHERE Id IN: cTasks];

			//create a map with : (APTaskId, APTaskTemplate)
			for(APTaskTemplate__c ap : lAPT){
				apIdsMaps.put(ap.Action_Plan__c, ap);
			}

			List<APTaskTemplate__c> tmp_lAPT;
			APTaskTemplate__c aux;
			for(Id apId : apIdsMaps.keySet()){

				tmp_lAPT = [SELECT  a.Id, a.Action_Plan__c, a.TaskIndex__c, a.Dependent__c
							FROM APTaskTemplate__c a
							WHERE a.Action_Plan__c  = :apId];
				//
				aux = apIdsMaps.get(apId);
				ActionPlansTaskTriggerUtilities.generateDependentTasksAndReset(tmp_lAPT, aux.TaskIndex__c);

			}
		} catch(Exception e){
			System.debug(Logginglevel.INFO,'\n\n====EXCEPTION : ' + e);
		}

	}
}