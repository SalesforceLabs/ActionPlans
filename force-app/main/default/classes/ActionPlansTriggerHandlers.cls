global inherited sharing class ActionPlansTriggerHandlers {

    global static void actionPlansSObjectTriggerHandler(List<SObject> newRecords, List<SObject> oldRecords, Map<Id,SObject> newRecordsMap, Map<Id,SObject> oldRecordsMap, System.TriggerOperation triggerEvent, String sObjectName){

		String relationshipName = sObjectName;
		System.debug('relationshipName: ' + relationshipName);
		if(!relationshipName.endsWithIgnoreCase('__c')){
			relationshipName += '__c';
		}
		System.debug('relationshipName: ' + relationshipName);

		//Delete related action plans
		switch on triggerEvent {

			when BEFORE_DELETE {

				Set<Id>  apIds  = new Set<Id>();
				List<ActionPlan__c> deletePermantently_apIds= new List<ActionPlan__c>();

				// GET Action Plans to delete in recycle bin
				String deleteQueryString = 'SELECT Id, Name FROM ActionPlan__c WHERE ' +
				                           relationshipName + ' IN :oldRecords AND isDeleted = true ALL ROWS';
				//System.debug('Query1: ' + deleteQueryString);
				deletePermantently_apIds = Database.query(deleteQueryString);

				if ( deletePermantently_apIds.size() >0 ){
					Database.emptyRecycleBin(deletePermantently_apIds);
				}

				deleteQueryString = 'SELECT Id FROM ActionPlan__c WHERE ' + relationshipName + ' IN :oldRecords';
				List<ActionPlan__c> apList = Database.query(deleteQueryString);
				for( ActionPlan__c ap : apList ){
					apIds.add( ap.Id );
				}

				if ( apIds.size() >0 ){
					ActionPlansBatchDelete aPBatch = new ActionPlansBatchDelete(apIds);
					Database.ExecuteBatch( aPBatch );
				}
			}

			//Undelete related action plans
			when AFTER_UNDELETE {
				String afterUndeleteQuery = 'SELECT Id FROM ActionPlan__c WHERE ' + relationshipName + ' IN :newRecords ALL ROWS';
				List<ActionPlan__c> aPs = Database.query(afterUndeleteQuery);

				try{
					if(ActionPlansTestUtilities.forceError){
						//throw dmlException
						insert new Contact();
					}
					//undelete aPs;
					Database.undelete( aPs, false);
				} catch ( Dmlexception e ){
					for (SObject c: newRecords){
						c.addError(System.Label.ap_RelObjUndeleteError);
					}
				}
			}
		}
	}

	public static void triggerHandler_ActionPlan(List<ActionPlan__c> newRecords, List<ActionPlan__c> oldRecords, Map<Id,ActionPlan__c> newRecordsMap, Map<Id,ActionPlan__c> oldRecordsMap, System.TriggerOperation triggerEvent){

		//System.debug('IN ActionPlan__c ' + triggerEvent.name());

		switch on triggerEvent {

			when BEFORE_INSERT {
				System.debug('before insert action plan');

				Id defaultTaskRTId = ActionPlansMetadataUtility.getDefaultTaskRecordTypeId();

				Set<Id> aptemplates = new Set<Id>();
				for(ActionPlan__c ap : newRecords){
					//System.debug('Action plan in insert: ' + ap);
					if(ap.Action_Plan_Template__c != null && ap.TaskRecordTypeID__c == null){
						aptemplates.add(ap.Action_Plan_Template__c);
					}
					else if(ap.Action_Plan_Template__c == null && ap.TaskRecordTypeID__c == null){
						ap.TaskRecordTypeID__c = defaultTaskRTId;
					}
				}
				if(!aptemplates.isEmpty()){
					Map<Id, ActionPlanTemplate__c> templateMap = new Map<Id, ActionPlanTemplate__c>([SELECT Id, TaskRecordTypeID__c FROM ActionPlanTemplate__c WHERE Id IN :aptemplates]);

					for(ActionPlan__c ap : newRecords){
						if(ap.TaskRecordTypeID__c == null || !(ap.TaskRecordTypeID__c instanceOf Id)){
							//System.debug('no task record type set');
							if(templateMap.containsKey(ap.Action_Plan_Template__c)){
								ap.TaskRecordTypeID__c = templateMap.get(ap.Action_Plan_Template__c).TaskRecordTypeID__c;
							} else {
								ap.TaskRecordTypeID__c = defaultTaskRTId;
							}
						}
					}
				}
				validateActionPlans(newRecords);
			}

			when BEFORE_UPDATE {
				validateActionPlans(newRecords);
			}

			when AFTER_UPDATE {
				Set<Id> actionPlanNewNames = new Set<Id>();
				for(ActionPlan__c ap : newRecords){
					if(ap.Name != oldRecordsMap.get(ap.Id).Name){
						actionPlanNewNames.add(ap.id);
					}
				}
				if(!actionPlanNewNames.isEmpty()){
					List<APTaskTemplate__c> templateTasks = [SELECT Id, Name FROM APTaskTemplate__c WHERE Action_Plan__c IN :actionPlanNewNames];
					for(APTaskTemplate__c a : templateTasks){
						a.Name = null;
					}
					update templateTasks;
				}
			}

			//Execution when a Action Plan is deleted, delete all asociated Tasks
			when BEFORE_DELETE {
				Set<Id> taskIds= new Set<Id>();
				if ( !System.isBatch() && !System.isFuture()){
					// if action plan is deleted, delete all tasks associated with it
					for( Task ap : [SELECT Id FROM Task WHERE IsClosed = false AND TaskAPTaskTemplate__r.Action_Plan__c IN :oldRecordsMap.keyset() ] ){
						taskIds.add( ap.Id );
					}
					if( !taskIds.isEmpty() ){
						// Run a future method
						ActionPlansTaskTriggerUtilities.deleteTasks( taskIds );
					}
				} else {
					delete [SELECT Id FROM Task WHERE IsClosed = false AND TaskAPTaskTemplate__r.Action_Plan__c IN :oldRecordsMap.keyset() ];
				}
			}

			when AFTER_UNDELETE {

				Database.UndeleteResult[] unDel_errors;

				//get Id of all deleted Action Plan Tasks Templates
				Map<Id,APTaskTemplate__c> map_APTasks = new Map<Id,APTaskTemplate__c>([SELECT a.Id, a.Action_Plan__c
				FROM APTaskTemplate__c a WHERE a.Action_Plan__c IN :newRecordsMap.keyset() ALL ROWS ]);

				//get all tasks asociated to this APTasks
				List<Task> taskList = [SELECT a.Id, a.TaskAPTaskTemplate__c, a.IsDeleted
										FROM Task a
										WHERE a.TaskAPTaskTemplate__c IN :map_APTasks.keySet() AND a.isDeleted = true ALL ROWS ];

				if (!taskList.isEmpty()){
					unDel_errors = Database.undelete( taskList,false);
					/* try {
						unDel_errors = Database.undelete( taskList,false);
					} catch(Exception e){
						for(Integer i = 0; i < unDel_errors.size(); i++){
							if(!unDel_errors[i].getErrors().isEmpty()){
								// Process any errors here

								//todo: handle this

							}
						}
					} */
				}
			}
		}
	}

	private static void validateActionPlans(List<ActionPlan__c> actionPlans){

		List<String> actionPlanReferenceFields = ActionPlansMetadataUtility.getCustomRelationshipFields();

		// Validate that 1 and only 1 custom reference field is filled

		for(ActionPlan__c ap : actionPlans){
			Integer filledReferences = 0;

			for(String s : actionPlanReferenceFields){
				if(ap.get(s) != null){
					filledReferences++;
				}
			}
			if(filledReferences != 1){
				ap.addError(System.Label.ap_RelatedCount);
			}
		}
	}

	public static void triggerHandler_ActionPlanTaskTemplate(List<APTaskTemplate__c> newRecords, List<APTaskTemplate__c> oldRecords, Map<Id, APTaskTemplate__c> newRecordsMap, Map<Id, APTaskTemplate__c> oldRecordsMap, System.TriggerOperation triggerEvent){

		//System.debug('IN APTaskTemplate__c ' + triggerEvent.name());

		//Undelete Tasks
		switch on triggerEvent {

			when BEFORE_INSERT, BEFORE_UPDATE {
				//ÍSystem.debug('closed statuses: ' + ActionPlansMetadataUtility.getClosedTaskStatuses());

				for( APTaskTemplate__c a : newRecords ){
					a.IsClosed__c = ActionPlansMetadataUtility.getClosedTaskStatuses().contains(a.Status__c);
				}

				Set<Id> apIDs = new Set<Id>();
				String aptPrefix = ActionPlansMetadataUtility.getObjectKeyPrefix('APTaskTemplate__c');
				//System.debug('aptPrefix ' + aptPrefix);
				for(APTaskTemplate__c apt : newRecords){
					//System.debug('Evaluating ' + apt.Name + ' from subject ' + apt.Subject__c);
					if(oldRecords == null || (apt.Name == null  || apt.Name.startsWithIgnoreCase(aptPrefix) || (oldRecords != null && apt.Subject__c != oldRecordsMap.get(apt.Id).Subject__c)) || !apt.Name.endsWithIgnoreCase(apt.Subject__c) ){
						//System.debug('we will rename using ' + apt.Subject__c);
						apIDs.add(apt.Action_Plan__c);
					}
				}
				if(!apIDs.isEmpty()){
					Map<Id, ActionPlan__c> nameMap = new Map<Id, ActionPlan__c>([SELECT Id, Name FROM ActionPlan__c WHERE Id IN :apIDs]);

					Integer taskTemplateNameLength	= APTaskTemplate__c.Name.getDescribe().getLength();
					for(APTaskTemplate__c apt : newRecords){
						if(nameMap.containsKey(apt.Action_Plan__c)){
							//System.debug('the task has a template and we will rename');
							String apName = nameMap.get(apt.Action_Plan__c).Name;
							String newSubject = apName + ' - ' + apt.Subject__c;
							apt.Name = ActionPlansMetadataUtility.actionPlanSubjectToName(newSubject, taskTemplateNameLength);
							System.debug('renaming aptaskTemplate to ' + newSubject);
						}
					}
				}
			}

			when BEFORE_DELETE {
				try{
				delete [SELECT t.Id FROM Task t WHERE t.TaskAPTaskTemplate__c IN :oldRecordsMap.keyset() AND t.IsClosed = false];
				} catch (Exception e){
					System.debug('Error when deleting Tasks related to APTaskTemplate');
				}
			}

			when AFTER_UNDELETE {

				List<Task> aP_tasks = [SELECT Id FROM Task WHERE TaskAPTaskTemplate__c IN :newRecordsMap.keyset() AND isDeleted = true ALL ROWS ];

				try{
					undelete aP_tasks;
				} catch ( Dmlexception e ){
					for (APTaskTemplate__c a: newRecords){
						a.addError('BROKEN TASK UNDELETE:'+e);
					}
				}
			}
		}
	}

	public static void triggerHandler_ActionPlanTemplate(List<ActionPlanTemplate__c> newRecords, List<ActionPlanTemplate__c> oldRecords, Map<Id,ActionPlanTemplate__c> oldRecordsMap, System.TriggerOperation triggerEvent){
		switch on triggerEvent {

			when BEFORE_INSERT {
				Id defaultTaskRTId = ActionPlansMetadataUtility.getDefaultTaskRecordTypeId();

				for(ActionPlanTemplate__c apt : newRecords){
					if(apt.TaskRecordTypeID__c == null || !(apt.TaskRecordTypeID__c instanceOf Id)){
						apt.TaskRecordTypeID__c = defaultTaskRTId;
					}
				}
			}

			when AFTER_UPDATE {
				Set<Id> changedNames = new Set<Id>();
				for(ActionPlanTemplate__c apt : newRecords){
					if(apt.Name != oldRecordsMap.get(apt.Id).Name){
						changedNames.add(apt.Id);
					}
				}
				if(!changedNames.isEmpty()) {
					List<APTTaskTemplate__c> templateTasks = [SELECT Id, Name FROM APTTaskTemplate__c WHERE Action_Plan_Template__c IN :changedNames];
					for(APTTaskTemplate__c a : templateTasks){
						a.Name = null;
					}
					update templateTasks;
				}
			}
		}
	}

	public static void triggerHandler_ActionPlanTemplateTaskTemplate(List<APTTaskTemplate__c> newRecords, List<APTTaskTemplate__c> oldRecords, Map<Id, APTTaskTemplate__c> oldRecordsMap, System.TriggerOperation triggerEvent){

		//System.debug('IN APTTaskTemplate__c ' + triggerEvent.name());

		switch on triggerEvent {

			when BEFORE_INSERT, BEFORE_UPDATE {
				Set<Id> templateIDs = new Set<Id>();
				String apttPrefix = ActionPlansMetadataUtility.getObjectKeyPrefix('APTTaskTemplate__c');
				//System.debug('apttPrefix ' + apttPrefix);
				for(APTTaskTemplate__c aptt : newRecords){
					//System.debug('Evaluating ' + aptt.Name + ' from subject ' + aptt.Subject__c);
					if( aptt.Name == null || aptt.Name.startsWithIgnoreCase(apttPrefix) || (oldRecords != null && aptt.Subject__c != oldRecordsMap.get(aptt.Id).Subject__c) || !aptt.Name.endsWithIgnoreCase(aptt.Subject__c) ){
						//System.debug('we will rename using ' + aptt.Subject__c);
						templateIDs.add(aptt.Action_Plan_Template__c);
					}
				}
				if(!templateIDs.isEmpty()){
					Map<Id, ActionPlanTemplate__c> nameMap = new Map<Id, ActionPlanTemplate__c>([SELECT Id, Name FROM ActionPlanTemplate__c WHERE Id IN :templateIDs]);

					for(APTTaskTemplate__c aptt : newRecords){
						if( nameMap.containsKey(aptt.Action_Plan_Template__c) ){
							System.debug('the task has a template and we will rename');
							String templateName = nameMap.get(aptt.Action_Plan_Template__c).Name;
							String newSubject = templateName + ' - ' + aptt.Subject__c;
							aptt.Name = ActionPlansMetadataUtility.actionPlanSubjectToName(newSubject);
						} else {
							System.debug('the task has NO template - figure this out');
						}
					}
				}
			}
		}
	}

	public static void triggerHandler_ActionPlanTask(List<Task> newRecords, List<Task> oldRecords, Map<Id, Task> newRecordsMap, Map<Id, Task> oldRecordsMap, System.TriggerOperation triggerEvent){

		//System.debug('IN Task ' + triggerEvent.name());

		switch on triggerEvent {

			when AFTER_UPDATE {
				Map<Id, String> closedTasks = new Map<Id, String>();
				Map<Id, String> inProgressTasks = new Map<Id, String>();
				Set<Id> APTasksIds = new Set<Id>();

				Map<Id, Task> triggerTasksWithTemplateTaskStatus = new Map<Id, Task>();
				for(Task ta : [SELECT Id, Status, TaskAPTaskTemplate__r.Status__c, TaskAPTaskTemplate__r.APTaskTemplate__c, TaskAPTaskTemplate__r.APTaskTemplate__r.Status__c FROM Task WHERE Id IN :newRecords]){
					triggerTasksWithTemplateTaskStatus.put(ta.Id, ta);
				}

				Boolean taskHasRecordType = ActionPlansMetadataUtility.HAS_RECORD_TYPE;

				//System.debug('do we have a task record type? ' + taskHasRecordType);

				Set<String> closedStatuses = ActionPlansMetadataUtility.getClosedTaskStatuses();

				// Map of record ID to "true" if the related task template is OPEN

				Set<Id> tasktemplatesToValidate = new Set<Id>();

				for( Task t : newRecords ){
					if(t.TaskAPTaskTemplate__c != null){
						tasktemplatesToValidate.add(t.TaskAPTaskTemplate__c);
					}
				}
				Map<Id, Boolean> allowMap = allowChangeParentStatus(tasktemplatesToValidate);

				// TODO: Fix the check for an open parent task status
				//Get all my Updated complete Task Id's.
				for( Task t : newRecords ) {

					if (t.TaskAPTaskTemplate__c != null){
						//store APTasks Id in a list to obtain all asociated APTasks objects
						APTasksIds.add(t.TaskAPTaskTemplate__c);

						// Find default task status
						String defaultTaskStatus;

						if(!taskHasRecordType){
							defaultTaskStatus = (String)Task.Status.getDescribe().getDefaultValue();
						} else {
							Task tsk = (Task)Task.sObjectType.newSObject((String)t.get('recordtypeid'), true);
							defaultTaskStatus = tsk.Status;
						}
						//System.debug('defaultTaskStatus: ' + defaultTaskStatus);

						if( t.Status != defaultTaskStatus ){
							//if (allowChangeParentStatus(t.TaskAPTaskTemplate__c))
							if(allowMap.containsKey(t.TaskAPTaskTemplate__c) && allowMap.get(t.TaskAPTaskTemplate__c)){
								if( !t.IsClosed){
									inProgressTasks.put( t.TaskAPTaskTemplate__c, t.Status );
									//System.debug('task is in progress');
								} else if (t.IsClosed) {
									closedTasks.put( t.TaskAPTaskTemplate__c, t.Status );
									//System.debug('task is closed');
								}
							} else {
								//throw exception
								t.Status.addError(System.Label.ap_UpdateStatusError);
							}
						}
					}
				}

				//Call to ActionPlansUtilities in order to proceed with creation of dependent Task
				if( !closedTasks.isEmpty() ) {
					ActionPlansTaskTriggerUtilities.initDependentTaskWork( closedTasks );
				}
				//update status to in progress for AP Tasks
				if( !inProgressTasks.isEmpty() ) {
					ActionPlansTaskTriggerUtilities.updateAPTasksStatus( inProgressTasks );
				}

				//Query APTaskTemplate__c objects to update fields
				if ( !APTasksIds.isEmpty() ){
					Map<Id,APTaskTemplate__c> mapAPTasks = new Map<Id,APTaskTemplate__c>([SELECT a.Status__c, a.Id, a.APTaskTemplate__r.Status__c, a.ActivityDate__c, a.Minutes_Reminder__c,
																							a.Action_Plan__r.Name
																							FROM APTaskTemplate__c a
																							WHERE a.Id IN :APTasksIds ]);
					List<APTaskTemplate__c> lUpsert = new List<APTaskTemplate__c>();

					//Integer taskTemplateNameLength	= APTaskTemplate__c.Name.getDescribe().getLength();
					for( Task t : newRecords ) {
						if ( mapAPTasks.containsKey(t.TaskAPTaskTemplate__c) ){
							APTaskTemplate__c tmp = mapAPTasks.get(t.TaskAPTaskTemplate__c);
							tmp.Subject__c = t.Subject;
							tmp.Name = tmp.Id;
							tmp.Comments__c = t.Description;
							tmp.Priority__c = t.Priority;
							tmp.User__c		= t.OwnerId;
							lUpsert.add(tmp);
						}
					}
					if (!lUpsert.isEmpty()){
						upsert lUpsert;
					}
				}
			}

			when BEFORE_DELETE {
				Set<Id> taskTempIds = new Set<Id>();
				for( Task t : oldRecords ){
					if( t.TaskAPTaskTemplate__c != null ){
						taskTempIds.add( t.TaskAPTaskTemplate__c );
					}
				}
				//only delete Action Plan Template Tasks that are not deleted
				//create any task depending on this one
				ActionPlansTaskTriggerUtilities.initDependentTasksAndReset(taskTempIds);
			}

			when AFTER_DELETE {
				Set<Id> taskTempIds = new Set<Id>();
				Set<Id> finalIds = new Set<Id>();
				for( Task t : oldRecords ){
					if( t.TaskAPTaskTemplate__c != null ){
						taskTempIds.add( t.TaskAPTaskTemplate__c );
					}
				}
				//only delete Action Plan Template Tasks that are not deleted

				for( APTaskTemplate__c ta : [SELECT a.Id, a.Action_Plan__c
						FROM APTaskTemplate__c a
						WHERE Id IN :taskTempIds AND isDeleted = false ALL ROWS ] ){
					finalIds.add( ta.Id );
				}

				if (!finalIds.isEmpty()){
					if ( System.isBatch() || System.isFuture() ){
						//delete
						delete [SELECT aPT.Id FROM APTaskTemplate__c aPT WHERE aPT.Id IN :finalIds];
					} else {
						ActionPlansTaskTriggerUtilities.deleteAPTasks( finalIds );
					}
				}
			}

			when BEFORE_INSERT {
				if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
					//System.debug('Task BEFORE_INSERT Record Type to be set');
					Map<Id, Id> taskTemplateToIntendedRecordTypeId = new Map<Id, Id>();
					Set<Id> taskTemplateIDs = new Set<Id>();
					for(Task t : newRecords){
						if(t.TaskAPTaskTemplate__c != null){
							//System.debug('inserting task for template ' + t.TaskAPTaskTemplate__c);
							taskTemplateIDs.add(t.TaskAPTaskTemplate__c);
						}
					}
					//System.debug('We have ' + taskTemplateIDs.size() + ' templates represented');
					//System.debug('Task Template Query ' + [SELECT Id, Action_Plan__r.TaskRecordTypeID__c FROM APTaskTemplate__c WHERE Id IN :taskTemplateIDs]);
					for(APTaskTemplate__c aptt : [SELECT Id, Action_Plan__r.TaskRecordTypeID__c FROM APTaskTemplate__c WHERE Id IN :taskTemplateIDs]){
						//System.debug('Template has task Record Type ' + aptt.Action_Plan__r.TaskRecordTypeID__c);
						taskTemplateToIntendedRecordTypeId.put(aptt.Id, aptt.Action_Plan__r.TaskRecordTypeID__c);
					}
					//System.debug('Here is the map: ' + taskTemplateToIntendedRecordTypeId);
					for(Task t : newRecords){
						//System.debug('looking at Task with Template ' + t.TaskAPTaskTemplate__c);
						if(!taskTemplateToIntendedRecordTypeId.containsKey(t.TaskAPTaskTemplate__c)){
							//System.debug('Template not queried');
						}
						if(!ActionPlansMetadataUtility.getTaskRecordTypeStatusDefaultValues().containsKey(taskTemplateToIntendedRecordTypeId.get(t.TaskAPTaskTemplate__c))){
							//System.debug('Map contains invalid value');
						}
						if(t.TaskAPTaskTemplate__c != null && taskTemplateToIntendedRecordTypeId.containsKey(t.TaskAPTaskTemplate__c)
						&& ActionPlansMetadataUtility.getTaskRecordTypeStatusDefaultValues().containsKey(taskTemplateToIntendedRecordTypeId.get(t.TaskAPTaskTemplate__c))){
							//System.debug('Putting RecordTypeId ' + taskTemplateToIntendedRecordTypeId.get(t.TaskAPTaskTemplate__c));
							t.put('RecordTypeId', taskTemplateToIntendedRecordTypeId.get(t.TaskAPTaskTemplate__c));
						} else {
							//System.debug('We did not link Task to Template');
						}
					}
				}
			}
		}
	}

	/**
	* Validates if the given tasks can change status to in progress or completed.
	* If the task : depends on another that is open, returns false
	* This bulkified method avoids SOQL queries in a loop
	* @param apTaskTemplateIds - bulkified set of task IDs to consider
	* @return dependsOnInProgressTask
	*/
	public static Map<Id, Boolean> allowChangeParentStatus(Set<Id> apTaskTemplateIds){
		Map<Id, Boolean> allowTasksMap = new Map<Id, Boolean>();
		Set<String> openStatuses = ActionPlansMetadataUtility.getOpenTaskStatuses();

		/* List<APTaskTemplate__c> aptList =  [SELECT a.Status__c, a.APTaskTemplate__c, a.APTaskTemplate__r.Status__c
											FROM APTaskTemplate__c a
											WHERE a.Id = :apTaskIds]; */

		for(APTaskTemplate__c apt : [SELECT a.Status__c, a.APTaskTemplate__c, a.APTaskTemplate__r.Status__c
											FROM APTaskTemplate__c a
											WHERE a.Id IN :apTaskTemplateIds]){
			//if( apt.APTaskTemplate__c != null ){
				allowTasksMap.put(apt.Id, apt.APTaskTemplate__c == null || !openStatuses.contains(apt.APTaskTemplate__r.Status__c) );
			//}
		}

		return allowTasksMap;
	}

	/**
	 * Handle ActionPlans related to Leads after conversion
	 */
	public static void triggerHandler_ActionPlanLead(List<Lead> newRecords, List<Lead> oldRecords, Map<Id,Lead> newRecordsMap, Map<Id,Lead> oldRecordsMap, System.TriggerOperation triggerEvent){
		switch on triggerEvent {

			when AFTER_UPDATE {
				List<ActionPlan__c> leadAPs = [SELECT Id, Lead__c, Contact__c, Account__c, Opportunity__c, Description__c FROM ActionPlan__c WHERE Lead__c IN :newRecordsMap.keySet()];
				Map<Id, ActionPlan__c> apMap = new Map<Id, ActionPlan__c>();
				for(ActionPlan__c ap : leadAPs){
					apMap.put(ap.Lead__c, ap);
				}

				Action_Plans_Settings__c mySettings = ActionPlansMetadataUtility.getCustomSetting();
				String destinationObject = mysettings.Default_Object_on_Lead_Conversion__c;
				if(destinationObject != null){
					destinationObject = destinationObject.toLowerCase();
					System.debug('destinationObject: ' + destinationObject);
				} else {
					return;
				}

				for(Lead l : newRecords){
					ActionPlan__c ap = apMap.get(l.Id);

					switch on destinationObject {
						when 'account' {
							ap.Account__c = l.ConvertedAccountId;
						}
						when 'opportunity' {
							ap.Opportunity__c = l.ConvertedOpportunityId;
						} when else {
							ap.Contact__c = l.ConvertedContactId;
						}
					}
					ap.Lead__c = null;
				}
				update apMap.values();
			}
		}
	}

	public static void triggerHandler_ActionPlanAccount(List<Account> newRecords, List<Account> oldRecords, Map<Id,Account> newRecordsMap, Map<Id,Account> oldRecordsMap, System.TriggerOperation triggerEvent){

		//Delete related action plans
		switch on triggerEvent {

			when BEFORE_DELETE {

				// GET Action Plans to delete in recycle bin
				List<ActionPlan__c>  deletePermantently_apIds = [SELECT Id FROM ActionPlan__c WHERE (Contact__r.AccountId IN :oldRecords OR Case__r.AccountId IN :oldRecords OR Contract__r.AccountId IN :oldRecords OR Opportunity__r.AccountId IN :oldRecords) AND isDeleted = true ALL ROWS];

				if ( deletePermantently_apIds.size() >0 ){
					Database.emptyRecycleBin(deletePermantently_apIds);
				}

				Set<Id>  apIds  = new Set<Id>();
				for( ActionPlan__c ap : [SELECT Id FROM ActionPlan__c WHERE (Contact__r.AccountId IN :oldRecords OR Case__r.AccountId IN :oldRecords OR Contract__r.AccountId IN :oldRecords OR Opportunity__r.AccountId IN :oldRecords)] ){
					apIds.add( ap.Id );
				}

				if ( apIds.size() > 0 ){
					ActionPlansBatchDelete aPBatch = new ActionPlansBatchDelete(apIds);
					Database.ExecuteBatch( aPBatch );
				}
			}

			//Undelete related action plans
			when AFTER_UNDELETE {

				Set<Id> relatedIDs = new Set<Id>();
				for(Contact c : [SELECT Id FROM Contact WHERE AccountId IN :newRecordsMap.keyset()]){
					relatedIDs.add(c.Id);
				}
				for(Contract c : [SELECT Id FROM Contract WHERE AccountId IN :newRecordsMap.keySet()]){
					relatedIDs.add(c.Id);
				}
				for(Opportunity c : [SELECT Id FROM Opportunity WHERE AccountId IN :newRecordsMap.keySet()]){
					relatedIDs.add(c.Id);
				}

				List<ActionPlan__c> aPs = [SELECT Id FROM ActionPlan__c WHERE Contact__c IN :relatedIDs OR Contract__c IN :relatedIDs OR Opportunity__c IN :relatedIDs ALL ROWS];

				try{
					if(ActionPlansTestUtilities.forceError){
						//throw dmlException
						insert new Contact();
					}
					//undelete aPs;
					Database.undelete( aPs, false);
				} catch ( Dmlexception e ){
					for (Account c : newRecords){
						c.addError(System.Label.ap_RelObjUndeleteError);
					}
				}
			}
		}
	}
}