/*
Action Plans v4
Updated by David Schach 2021

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

BSD 3-Clause License

Copyright (c) 2021, salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
global inherited sharing class ActionPlanCreateInvocable {

	@InvocableMethod(label='Create Action Plan From Template' description='Takes a Template Name and Record Id and makes an Action Plan.' category='ActionPlans')
	global static List<Id> makeActionPlanFromTemplate(List<CreateActionPlanRequest> requests) {

		List<Id> resultIDs = new List<Id>();

		Set<String> templateNamesOrIDs = new Set<String>();
		for(CreateActionPlanRequest r : requests){
			templateNamesOrIDs.add(r.templateNameOrID);
		}

		Map<String, ActionPlanTemplate__c> templateNameOrIdToTemplate = new Map<String, ActionPlanTemplate__c>();

		List<ActionPlanTemplate__c> possibleTemplates =
							[SELECT Id, Description__c, Name, OwnerId, SkipDay__c, SkipWeekends__c, TaskRecordTypeID__c,
								(SELECT Type__c, Subject__c, Priority__c, Dependent__c, Name, User__c, User__r.Name, Id,
								DaysFromStart__c, Action_Plan_Template__c, APTTaskTemplate__r.Subject__c,
								Reminder__c, SendEmail__c, Comments__c, TaskIndex__c, Action_Plan_Template__r.TaskRecordTypeID__c
								FROM ApTasks__r ORDER BY TaskIndex__c ASC)
							FROM ActionPlanTemplate__c WHERE Name IN :templateNamesOrIDs OR Id IN :templateNamesOrIDs];

		for(ActionPlanTemplate__c apt : possibleTemplates){
			templateNameOrIdToTemplate.put(apt.id, apt);
			templateNameOrIdToTemplate.put(apt.Name, apt);
		}

		if(templateNameOrIdToTemplate.isEmpty()){
			System.debug('NO MATCHING TEMPLATES');
			return resultIDs;
		}

		Set<Id> relatedIDs = new Set<Id>();
		Map<Id, SObject> relatedObjects = new Map<Id, SObject>();
		String relatedObjectName = requests[0].relatedRecordID.getSObjectType().getDescribe().getName();
		for(CreateActionPlanRequest r : requests){
			relatedIDs.add(r.relatedRecordID);
		}

		String objNameQuery = 'SELECT Id, Name FROM ' + relatedObjectName + ' WHERE Id IN :relatedIDs';

		for(SObject sobj : Database.query(objNameQuery)){
			relatedObjects.put((Id)sobj.get('Id'), sobj);
		}

		Map<Id, ActionPlan__c> actionPlansToInsert = new Map<Id, ActionPlan__c>();
		List<APTaskTemplate__c> aptasksToInsert = new List<APTaskTemplate__c>();

		Action_Plans_Settings__c mySettings = ActionPlansUtilities.getCustomSetting();

		Map<Id, Id> relatedObjectOwners = ActionPlansBatchBuilderUtilities.retrieveOwnersDataRelatedObject(relatedIDs, relatedObjectName);

		for(CreateActionPlanRequest r : requests){

			ActionPlanTemplate__c actionPlanTemplate = templateNameOrIdToTemplate.get(r.templateNameOrID);

			ActionPlan__c ap = new ActionPlan__c();
			ap.Name                         = ActionPlansUtilities.actionPlanSubjectToName(actionPlanTemplate.Name);
			ap.Description__c               = actionPlanTemplate.Description__c;
			ap.SkipWeekends__c              = actionPlanTemplate.SkipWeekends__c;
			ap.SkipDay__c                   = actionPlanTemplate.SkipDay__c;
			ap.Action_Plan_Template__c      = actionPlanTemplate.Id;
			ap.TaskRecordTypeID__c          = actionPlanTemplate.TaskRecordTypeID__c;
			ap.StartDate__c                 = Date.today().addDays(r.daysToActionPlanStart == null ? 0 : r.daysToActionPlanStart);

			for(String s : ActionPlansUtilities.getCustomRelationshipFields()){
				ap.put(s, null);
			}

			// TODO: Check if we have the proper object relationship on ActionPlan

			Id relatedId = r.relatedRecordID;
			Schema.SObjectType token = relatedId.getSObjectType();
			String relObjName = token.getDescribe().getName().toLowerCase();
			String relObjField = relObjName;
			if(!relObjName.endsWithIgnoreCase('__c')){
				relObjField += '__c';
			}
			ap.put(relObjField, relatedId);
			System.debug('inserting action plan ' + ap);
			actionPlansToInsert.put(r.relatedRecordID, ap);
		}

		insert actionPlansToInsert.values();

		for(CreateActionPlanRequest r : requests){

			ActionPlan__c ap = actionPlansToInsert.get(r.relatedRecordID);

			ActionPlanTemplate__c actionPlanTemplate = templateNameOrIdToTemplate.get(r.templateNameOrID);

			Id relatedId = r.relatedRecordID;
			Schema.SObjectType token = relatedId.getSObjectType();
			String relObjName = token.getDescribe().getName().toLowerCase();
			String relObjField = relObjName;
			if(!relObjName.endsWithIgnoreCase('__c')){
				relObjField += '__c';
			}

			for( APTTaskTemplate__c aptTask : actionPlanTemplate.apTasks__r ){
				System.debug('iterating over apTasks__r');
				Id userId;
				//Read the Custom Settings in order to asign the User to that Task
				if( aptTask.User__c != null ) {
					userId = aptTask.User__c ;
					System.debug('USER WAS ALREADY FILLED!');
				}
				else if( aptTask.User__c == null && ( mySettings != null && !mySettings.Unassigned_Task_Default__c ) ) {
					userId = UserInfo.getUserId();
					System.debug('DEFAULT TO CURRENT USER');
				}
				else if( aptTask.User__c == null && ( mySettings != null &&  mySettings.Unassigned_Task_Default__c ) ) {
					System.debug('ASSIGN TO RELATED OWNER');
					userId = relatedObjectOwners.get(relatedId);
				}

				APTaskTemplate__c apTask     = new APTaskTemplate__c();
				apTask.Type__c               = aptTask.Type__c;
				apTask.Subject__c            = aptTask.Subject__c;
				apTask.Priority__c           = aptTask.Priority__c;
				apTask.Dependent__c          = aptTask.Dependent__c;
				apTask.TaskIndex__c          = aptTask.TaskIndex__c;
				apTask.DaysFromStart__c      = aptTask.DaysFromStart__c;
				apTask.User__c               = userId;
				apTask.Comments__c           = aptTask.Comments__c;

				apTask.Reminder__c           = aptTask.Reminder__c;
				apTask.Minutes_Reminder__c   = ActionPlansUtilities.getDefaultReminderMinutes();
				apTask.SendEmail__c          = aptTask.SendEmail__c;

				apTask.Action_Plan__c        = ap.Id;

				System.debug('SETTING AP.ID to ' + ap.id);

				if(ActionPlansUtilities.HAS_RECORD_TYPE){
					apTask.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());
				} else {
					apTask.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(null);
				}

				if( apTask.Dependent__c != null && apTask.Dependent__c != 'None' ){
					apTask.APTaskTemplate__c = actionPlanTemplate.apTasks__r[Integer.valueOf( apTask.Dependent__c )].Id;
					apTask.ActivityDate__c = null;
				}
				else {

					apTask.APTaskTemplate__c = null;

					//set dependency taskId to none if none was selected
					if (apTask.Dependent__c == null){
						apTask.Dependent__c = 'None';
					}

					// create due date, calculate the due date of the tasks for skip weekends feature
					if( ap.SkipWeekends__c == true && ap.SkipDay__c != null){

						apTask.ActivityDate__c = ActionPlansUtilities.adjustTaskDueDate(ap.StartDate__c, apTask.DaysFromStart__c.intValue(), ap.SkipDay__c);
					}
					else {
						apTask.ActivityDate__c = ap.StartDate__c.addDays( apTask.DaysFromStart__c.intValue() );
					}
				}
				aptasksToInsert.add( apTask );
			}
		}
		insert aptasksToInsert;

		Map<Id,Task> mapApTasks              = new Map<Id,Task>();
		List<Task> myTasksWithOutEmail       = new List<Task>();
		List<Task>  myNewTasksWithEmail      = new List<Task>();

		Map<Id, APTaskTemplate__c> mapAP = new Map<Id, APTaskTemplate__c>();
		for(APTaskTemplate__c a : aptasksToInsert){
			mapAP.put(a.Id, a);
		}

		Map<Id, ActionPlan__c> insertedActionPlans = new Map<Id, ActionPlan__c>();
		for(ActionPlan__c ap : actionPlansToInsert.values()){
			insertedActionPlans.put(ap.Id, ap);
		}

		//Task t;
		for( APTaskTemplate__c t_t : aptasksToInsert ) {
			ActionPlan__c apAux;
			// check if task exists already
			Task t = new Task();
			t.Subject           = t_t.Subject__c;
			t.Priority          = t_t.Priority__c;
			t.OwnerId           = t_t.User__c;
			t.TaskAPTaskTemplate__c = t_t.Id;

			if( t_t.Comments__c != null ){
				t.Description = t_t.Comments__c;
			}

			//set reminder based on user's default reminder setting
			if( t_t.Reminder__c == true && t_t.ActivityDate__c != null ){

				t.isReminderSet = true;
				t.ReminderDateTime = Datetime.newInstance( t_t.ActivityDate__c.year(), t_t.ActivityDate__c.month(), t_t.ActivityDate__c.day(), 0, 0, 0 );
				t.ReminderDateTime = t.ReminderDateTime.addMinutes( Integer.valueOf( t_t.Minutes_Reminder__c ) );
			}
			else {
				t.isReminderSet = false;
			}

			APTaskTemplate__c apt = mapAP.get(t_t.Id);

			if ( apt != null ){

				apAux = insertedActionPlans.get(apt.Action_Plan__c);
				//System.debug('apAux is first set to ' + apAux);
			}

			//link to Action Plan's Related To Object
			for( String s : ActionPlansUtilities.getCustomRelationshipFields() ){
				String f = s;
				if(!f.equalsIgnoreCase('Contact__c') && !f.equalsIgnoreCase('Lead__c') && apAux.get(f) != null){
					t.WhatId = (Id)apAux.get(f);
					break;
				}
			}

			if( apAux.Contact__c != null ){
				t.WhoId = apAux.Contact__c;
			}
			if( apAux.Lead__c != null ){
				t.WhoId = apAux.Lead__c;
			}

			t.Type = t_t.Type__c;

			if (t.Id == null){
				t.Status        = t_t.Status__c;
			}
			t.ActivityDate  = t_t.ActivityDate__c;

			if( t_t.Dependent__c == 'None' ){
				if( t_t.SendEmail__c == true ){
					myNewTasksWithEmail.add( t );
				}
				else {
					myTasksWithOutEmail.add( t );
				}
			}
		}

		Database.DMLOptions dmlo    = new Database.DMLOptions();
		dmlo.EmailHeader.triggerUserEmail = true;

		Database.DMLOptions dmlo2   = new Database.DMLOptions();
		dmlo2.EmailHeader.triggerUserEmail = false;

		if( myNewTasksWithEmail.size() > 0 ){
			Database.insert( myNewTasksWithEmail, dmlo );
		}

		if( myTasksWithOutEmail.size() > 0 ){
			Database.insert( myTasksWithOutEmail, dmlo2 );
		}

		//We need to check first if the Related Object is Enabled to FeedPost
		//Just need the first Object of list to know the Related Object.
		//Boolean isEnabledForFeed = ActionPlansUtilities.isObjectEnabledFeed( actionPlansToInsert.values()[0]);

		Set<Id> relObjectIDs = new Set<Id>();
		for(ActionPlan__c ap : actionPlansToInsert.values()){
			relObjectIDs.add(ap.Id);
		}

		if(mySettings != null && mySettings.Chatter_Object_Brag__c ) {
			ActionPlansBatchBuilderUtilities.generateObjectFeeds(relObjectIDs);
		}

		for(CreateActionPlanRequest request : requests){
			resultIDs.add(actionPlansToInsert.get(request.relatedRecordID).Id);
		}

		System.debug('RETURNING RESULT IDs COUNT ' + resultIDs.size());

		return resultIDs;
	}

	global class CreateActionPlanRequest {

		@InvocableVariable(required=true label='The Template Id or Name to use' description='Name is not unique, so ID is preferred')
		global String templateNameOrID;

		@InvocableVariable(required=true label='The parent Record ID' description='Must have a relationship from Action Plan object')
		global Id relatedRecordID;

		@InvocableVariable(required=false label='Days from trigger to start Action Plan' description='Defaults to 0, the day the plan is created')
		global Integer daysToActionPlanStart;
	}

}