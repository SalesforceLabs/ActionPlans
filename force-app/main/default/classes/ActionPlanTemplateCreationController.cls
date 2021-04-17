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
public inherited sharing class ActionPlanTemplateCreationController{

	private Double					taskIndex;
	@testvisible private ActionPlanTemplate__c	actionPlanTemplate;
	public String					subTitle				{ get; private set; }
	private Boolean					addedTask;
	public Boolean					canDisplayReminder			{ get; private set; }
	public Boolean					taskHasRecordType		{ get; private set; }
	public List<APTTaskTemplate__c> 		pendingTemplateDeletes;
	public List<APTTaskTemplate__c> 		aptTasks;

	/**
	 * Constructor
	 * If we can obtain the Id from the page parameters then we search for that template and set the variable for that template.
	 * If we can't obtain the Id from the page parameters then we create a new template and obtain from the controller.
	 * Then we need to check if we are cloning the template; in that case clone the template without Id.
	 */
	public ActionPlanTemplateCreationController( ApexPages.StandardController stdController ){

		this.taskIndex = 0;
		this.addedTask = false;

		if( System.currentPageReference().getParameters().get( 'clone' ) == '1' ){
			//System.debug('CLONING ACTION PLAN TEMPLATE');

 			ActionPlanTemplate__c apC = [SELECT Name, Description__c, SkipDay__c, SkipWeekends__c, TaskRecordTypeID__c FROM ActionPlanTemplate__c WHERE Id = :ApexPages.currentPage().getParameters().get('id') LIMIT 1];

			actionPlanTemplate = new ActionPlanTemplate__c();
			actionPlanTemplate.Name = apC.Name;
			actionPlanTemplate.Description__c = apC.Description__c;
			actionPlanTemplate.SkipDay__c = apC.SkipDay__c;
			actionPlanTemplate.SkipWeekends__c = apC.SkipWeekends__c;
			actionPlanTemplate.TaskRecordTypeID__c = apC.TaskRecordTypeID__c;
			//System.debug('cloned aptemplate ' + actionPlanTemplate);
		} else {
			actionPlanTemplate = ( ActionPlanTemplate__c )stdController.getRecord();
			//System.debug('did not clone');
		}

		this.canDisplayReminder = ActionPlansMetadataUtility.getCanDisplayReminder();
		this.taskHasRecordType = ActionPlansMetadataUtility.HAS_RECORD_TYPE;

		if( actionPlanTemplate.Id != null ){
			taskIndex = calculateTaskIndexValue();
			subTitle = ActionPlanTemplate.Name;
			//System.debug('subtitle ' + subTitle);
		}
		else {
			if(taskHasRecordType){
				actionPlanTemplate.TaskRecordTypeID__c = getDefaultTaskRecordTypeId();
			}
			this.taskIndex = 0;
			this.subTitle = System.Label.ap_New + ' ' + Schema.getGlobalDescribe().get( 'ActionPlanTemplate__c' ).getDescribe().getLabel();
		}

	}

	/**
	* Saves Action Plan Template and all tasks, then redirects to the AP template list.
	* First check for pending templates for delete, in case that exists then delete those objects.
	* Then insert or update the Action Plan Template pending to save and save tasks to the template
	* and attach relation to Action Plan.
	* @return newPage
	*/
	public PageReference saveTemplate(){

		Savepoint sp = Database.setSavepoint();

		// check for pendingDeletes, if something is pending send it to delete
		if( pendingTemplateDeletes != null ){
			delete pendingTemplateDeletes;
		}

		// update Action Plan Template object, in case of Exception then rollback the actions with the database
		try{
			System.debug('upserting ' + actionPlanTemplate);
			upsert actionPlanTemplate;
		} catch( Exception e ){
			ApexPages.addMessages(e);
			Database.rollback( sp );
			return null;
		}

		// save tasks to the template and attach relation to Action Plan
		for( APTTaskTemplate__c t : aptTasks ){
				t.Action_Plan_Template__c = actionPlanTemplate.Id;
			if( t.DaysFromStart__c < 0 ){
				 t.DaysFromStart__c = 0;
		   	}
			t.DaysFromStart__c = math.abs( t.DaysFromStart__c );
		}

		try{
			upsert aptTasks;
		} catch( Exception e ){
			Database.rollback( sp );
			ApexPages.addMessages(e);
			return null;
		}

		// run through the tasks and take care of dependents
		for( APTTaskTemplate__c t : aptTasks ){
			if( t.Dependent__c != null && t.Dependent__c != 'None' ){
				t.APTTaskTemplate__c 	= aptTasks[ Integer.valueOf( t.Dependent__c ) ].Id;
			}
			else {
				t.APTTaskTemplate__c = null;
			}
		}

		try{
			update aptTasks;
		} catch( Exception e ){
			Database.rollback( sp );
			ApexPages.addMessages(e);
			return null;
		}

		// Send the user to the detail page for the new account.
		PageReference newPage = Page.ActionPlanTemplateDetail;
		newPage.getParameters().put('Id', actionPlanTemplate.Id);
		newPage.setRedirect( true );
		return newPage;
	}

	/**
	 * Save and go to New page for Save and New
	 * @return PageReference
	 */
	public Pagereference saveAndNew(){
		try{
			saveTemplate();
		} catch (Exception ex){
			ApexPages.addMessages(ex);
		}
		Pagereference newPage = Page.ActionPlanTemplateCreation;
		newPage.setRedirect( true );
		return newPage;
	}

	/**
	 * Call method cancelTemplate()
	 * @return PageReference
	 */
	public PageReference cancelTemplate(){

		PageReference newPage;

		if( actionPlanTemplate.Id == null ){
			// Send the user to the list of templates.
			newPage = new PageReference('/' + Schema.ActionPlanTemplate__c.SObjectType.getDescribe().getKeyPrefix() + '/o' );
		}
		else {
			// Send the user to the detail page for the new account.
			newPage = Page.ActionPlanTemplateDetail;
			newPage.getParameters().put('Id', actionPlanTemplate.Id);
		}
		newPage.setRedirect( true );
		System.debug('cancel Page: ' + newPage);
		return newPage;
	}

	/**
	 * Call method addTemplateTask()
	 */
	public Boolean addTemplateTask(){
		System.debug('in addTemplateTask');

		this.taskIndex++;

		Boolean hasNoErrors = false;

		if( ApexPages.currentPage().getParameters().get( 'add' ) == '1' ){

			//in case the task LIMIT is reached set a message error to display
			if( this.aptTasks.size() >= ActionPlansConstants.MAX_APTASKS ){
				this.errorMsg = System.Label.ap_Errors_TaskLimitError;
			}
			else {
				APTTaskTemplate__c t = (APTTaskTemplate__c)APTTaskTemplate__c.getSObjectType().newSObject(null, true);
				t.Reminder__c 	= false;
				t.TaskIndex__c 	= this.taskIndex;
				t.Priority__c   = (String)Task.Priority.getDescribe().getDefaultValue();
				//t.Type__c   = (String)Task.Type.getDescribe().getDefaultValue();
				System.debug('taskIndex ' + t.TaskIndex__c);
				System.debug('t.Priority__c ' + t.Priority__c);
				System.debug('aptTasks: ' + aptTasks);

				// validate user, priority, subject and days before adding another
				hasNoErrors = true;

				for( APTTaskTemplate__c aptt : aptTasks ){
					System.debug('aptt Priority ' + aptt.Priority__c);
					System.debug('aptt Subject ' + aptt.Subject__c);

					hasNoErrors = ( aptt.Priority__c != null && aptt.Subject__c != null );
					if( aptt.DaysFromStart__c < 0 ) {
						aptt.DaysFromStart__c = 0;
					}
				}
				if( hasNoErrors ){
					this.aptTasks.add( t );
					System.debug('we have no errors');
					hasNoErrors = true;
				}
				else {
					System.debug('apparently we have errors');
					hasNoErrors = false;
				}
			}
		}
		else {
			System.debug('added but no page parameter');
		}

		this.addedTask =  hasNoErrors;

		return hasNoErrors;
	}

	/**
	 * Call method removeTemplateTask()
	 */
	public void removeTemplateTask(){
		Boolean removedTask = false;
		if( ApexPages.currentPage().getParameters().get( 'remove' ) != null ){
			Integer taskIndex = Integer.valueOf( ApexPages.currentPage().getParameters().get( 'remove' ) );

			//check for dependent children and clear them since the parent is being removed.
			aptTasks[ taskIndex ].APTTaskTemplate__c    = null;
			aptTasks[ taskIndex ].Dependent__c          = null;

			Integer dependentApTask;

		   //update the current dependent position from tasks below of deleted one.
			for( Integer i = 0; i < this.aptTasks.size(); i++ ){
				APTTaskTemplate__c aptTask = this.aptTasks.get( i );
				if( aptTask.Dependent__c != null && aptTask.Dependent__c != 'None' ){
					dependentApTask = Integer.valueOf( aptTask.Dependent__c );
					if( dependentApTask > taskIndex ){
						aptTask.Dependent__c = String.valueOf( dependentApTask - 1 );
					} else if( dependentApTask == taskIndex ){
						aptTask.Dependent__c = 'None';
						aptTask.APTTaskTemplate__c    = null;
					}
				}
			}

			// before remove check if it's exists in the DB, if so, add to pendingTemplateDeletes to be deleted on save.
			if( this.aptTasks[taskIndex].Id != null ){
				if( pendingTemplateDeletes == null ){
					 pendingTemplateDeletes = new List<APTTaskTemplate__c>();
				}
				pendingTemplateDeletes.add( aptTasks[ taskIndex] );
			}

			aptTasks.remove( taskIndex );

			// clear errorMsg if it's set.
			if( aptTasks.size() < ActionPlansConstants.MAX_APTASKS ){
				 errorMsg = null;
			}
			removedTask = true;
		}

		addedTask = !removedTask;
	}

	/**
	 * Call method getTemplateTasks()
	 */
	public List<ApTTaskWrapper> getTemplateWrappers(){

		ApTTaskWrapper apTTaskWrapper;
		List<ApTTaskWrapper> tasksList = new List<ApTTaskWrapper>();

		Integer i = 0;
		for( APTTaskTemplate__c aptTaskTemplate : getTemplateTasks() ){
			System.debug('adding the ' + i + ' template for display');
			ApTTaskWrapper = new ApTTaskWrapper( aptTaskTemplate, i , this.actionPlanTemplate.TaskRecordTypeID__c);
			tasksList.add( ApTTaskWrapper );
			i++;
		}
		if( this.addedTask ){
			tasksList.get( i - 1 ).isLast = true;
		}

		System.debug('tasksList: ' + tasksList);
		return tasksList;
	}

	/**
	* Get all tasks related to the Action Template.
	* @return aptTasks
	*/
	public List<APTTaskTemplate__c> getTemplateTasks(){

		if( aptTasks == null || aptTasks.size() == 0 ){
			//String tempApId = ApexPages.currentPage().getParameters().get('Id');

			Id tempApId = actionPlanTemplate.Id;

			if( tempApId != null ) {
				aptTasks = [SELECT a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c, TaskIndex__c,
							 a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, a.APTTaskTemplate__c,
							 a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c
							 FROM APTTaskTemplate__c a
							 WHERE a.Action_Plan_Template__c = :tempApId  ORDER BY TaskIndex__c ASC];
			}
			else {
				aptTasks 				= new List<APTTaskTemplate__c>();
				APTTaskTemplate__c t 	= (APTTaskTemplate__c)APTTaskTemplate__c.getSObjectType().newSObject(null, true);
				t.Reminder__c	 		= false;
				t.Priority__c           = (String)Task.Priority.getDescribe().getDefaultValue();
				aptTasks.add( t );
			}

			// clone and clear ids
			if( ApexPages.currentPage().getParameters().get( 'clone' ) == '1' ){
				List<APTTaskTemplate__c> tC = aptTasks.deepClone( false );
				aptTasks.clear();
				aptTasks = tC;

				// clear lookup relationship also
				for( APTTaskTemplate__c t : aptTasks ){
					if( t.Action_Plan_Template__c != null ){
						 t.Action_Plan_Template__c = null;
					}
				}
			}
		}

		return ( aptTasks.isEmpty() ) ? new List<APTTaskTemplate__c>() : aptTasks ;
	}

	/**
	 * Return size of the APTTemplate Tasks List.
	 */
	public Integer getTemplateTaskSize(){
		return aptTasks.size();
	}

	/**
	 * Call method getTemplateSubjectItems()
	 */
	public List<SelectOption> getTemplateSubjectItems(){
		List<SelectOption> options = new List<SelectOption>();
		options.add( new SelectOption( 'None', '--' + System.Label.ap_None +'--' ) );
		Integer i = 0;

		if( this.aptTasks != null ){
			for( APTTaskTemplate__c t : this.aptTasks ){
				 if( t.Subject__c != null ){
					 options.add( new SelectOption( String.valueOf( i ), t.Subject__c+' (' + ( i + 1 ) +')' ) );
				}
				i++;
			}
		}

		return options;
	}

	/**
	* Checks if Action Plan Tasks has cyclic dependency.
	* @return PageReference
	*/
	public PageReference checkCycleDependent(){

		if( this.templateCycleDependent() ){
			return null;
		}
		else {
			return this.saveTemplate();
		}
	}

	/**
	* Checks if Action Plans Tasks has cyclic dependency.
	* @return exists
	*/
	public Boolean templateCycleDependent(){

		this.errorMsg   = null;
		Boolean exists  = false;
		Integer index   = 0;

		for( APTTaskTemplate__c t : this.aptTasks ){
			if( t.Dependent__c != null && t.Dependent__c != 'None' ){
				//Integer tempIndex   	= ;
				APTTaskTemplate__c link = this.aptTasks[ Integer.valueOf( t.Dependent__c ) ];

				//task can not depend on themselves
				if( Integer.valueOf( t.Dependent__c ) == index){
					this.errorMsg = System.Label.ap_ItselfDependencyError;
					return true;
				}

				if( this.dependantCycle( t, link, index ) ){
					this.errorMsg = System.Label.ap_Errors_RemoveCyclicDependency;
					return true;
				}
			}
			index++;
		}
		return exists;
	}

	/**
	*
	* @param originTask
	* @param destinyTask
	* @param index
	* @return Boolean
	*/
	private Boolean dependantCycle( APTTaskTemplate__c originTask, APTTaskTemplate__c destinyTask, Integer index ){

		Boolean hasDependency = false;
		Set<Integer> visitedTasks = new Set<Integer>();

		while( !hasDependency ){

			if (destinyTask.Dependent__c != null && destinyTask.Dependent__c != 'None'){
				if (visitedTasks.contains(Integer.valueOf( destinyTask.Dependent__c ))){
					hasDependency = true;
					break;
				} else {
					visitedTasks.add(Integer.valueOf( destinyTask.Dependent__c ));
				}
			}

			if( destinyTask.Dependent__c != null && destinyTask.Dependent__c != 'None' ){
				Integer tempIndexDestiny 	= Integer.valueOf( destinyTask.Dependent__c );
				APTTaskTemplate__c link 		= this.aptTasks[ tempIndexDestiny];

				if( link.Dependent__c != null && link.Dependent__c != 'None' ){
					if( Integer.valueOf( link.Dependent__c ) == index ){
						hasDependency = true;
						break;
					}
					else {
						//get Next task in dependency chain
						//Integer tempIndex 	= ;
						destinyTask 		= this.aptTasks[ Integer.valueOf( destinyTask.Dependent__c ) ];
					}
				}
				else {
					break;
				}
 			}
 			else {
 				break;
			}
		}

		return hasDependency;
	}

	/**
	* Getter method to return the error message from
	* action plans utilities
	* @return errorMsg
	*/
	private String errorMsg;
	public String getErrorMsg(){
		return this.errorMsg;
	}

	/**
	* Calculates the highest task index value
	* @return maxIndex
	*/
	public Double calculateTaskIndexValue(){

		Double maxIndex = 0;
		for( APTTaskTemplate__c tsk : [SELECT Id, TaskIndex__c FROM APTTaskTemplate__c
												WHERE Action_Plan_Template__c = :actionPlanTemplate.Id] ){
			if( tsk.TaskIndex__c > maxIndex ){
				maxIndex = tsk.TaskIndex__c;
			}
		}

		return maxIndex;
	}

	/**
	 * Find user default recordtype
	 */
	public Id getDefaultTaskRecordTypeId(){
		return ActionPlansMetadataUtility.getDefaultTaskRecordTypeId();
	}

	/**
	 * Generate picklist of Task Record Types
	 */
	public List<SelectOption> getTaskRTPicklistValues(){
		return ActionPlansMetadataUtility.getTaskRTPicklistValues();
	}

	/**
	 * Generate picklist of Task Types
	 */
	public List<SelectOption> getTaskTypes(){
		Boolean hasDefaultValue = String.isNotBlank((String)Task.Type.getDescribe().getDefaultValue());
		return ActionPlansMetadataUtility.getFieldOptions('Task', 'Type', hasDefaultValue);
	}

	/**
	 * Generate picklist of Task Priorities
	 */
	public List<SelectOption> getTaskPriorities(){
		Boolean hasDefaultValue = String.isNotBlank((String)Task.Priority.getDescribe().getDefaultValue());
		return ActionPlansMetadataUtility.getFieldOptions('Task', 'Priority', hasDefaultValue);
	}

	/**
	* Inner Wrapper Class for Action Plan Template Tasks
	* @author Matias Menafra
	* @createddate 08/08/2010
	*/
	public class ApTTaskWrapper{

		public APTTaskTemplate__c task	{ get; set; }
		public Integer	position	{ get; set; }
		public Boolean	isLast		{ get; set; }

		public ApTTaskWrapper( APTTaskTemplate__c apTask, Integer pos, Id defaultTaskRTId ){
			task		= apTask;
			position	= pos;
			isLast		= false;
			if(task.Id == null){
				System.debug('passing RTID ' + defaultTaskRTId);
				if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
					task.Priority__c = ActionPlansMetadataUtility.getTaskRecordTypePriorityDefaultValues().get(defaultTaskRTId);
				} else {
					task.Priority__c = ActionPlansMetadataUtility.getTaskRecordTypePriorityDefaultValues().get(null);
				}
			}
		}
	}
}