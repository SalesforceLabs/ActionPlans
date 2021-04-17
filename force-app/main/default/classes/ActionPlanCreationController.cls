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
public inherited sharing class ActionPlanCreationController{

	private Double                  taskIndex;
	public ActionPlan__c            actionPlan;
	private Id                      templateId;
	//public String                   templateName            { get; private set; }
	public Set<Id>                  relatedObjIds           { get; set; }
	public String                   relatedObjNamePlural          { get; set; }
	public List<String>             relatedObjNameList      { get; set; }
	public Boolean                  hasRelated              { get; set; }
	public Boolean                  hasRelatedObject        { get; set; }
	public String                   relatedObjectSelected   { get; set; }
	//private Action_Plans_Settings__c defaultSettings
	public String                   throwError              { get; set; }
	public Boolean                  addedTask;
	public Boolean                  canDisplayReminder      { get; set; }
	private Map<Id, ApTaskWrapper>   mapTasksListBkp;
	//public Integer                    maxAPTasks                { get; set; }
	public Boolean                    taskHasRecordType        { get; set; }
	public String                    subtitle                { get; set; }
	private String                   errorMsg;
	public List<APTaskTemplate__c>  apTasks;
	public List<APTaskTemplate__c>  apTasksOrg ;
	public List<APTaskTemplate__c>  pendingDeletes;
	public List<APTTaskTemplate__c> aptTasks;
	private String                   cloneParam = '0';
	private Boolean inVisualforceContext = true;

	/**
	* Constructor
	*/
	public ActionPlanCreationController( ApexPages.StandardController stdController ){
		this.inVisualforceContext = true;

		this.taskIndex          = 0;
		this.addedTask          = false;
		this.hasRelated         = false;
		this.hasRelatedObject   = false;
		this.relatedObjNameList = new List<String>();
		this.relatedObjIds      = new Set<Id>();
		this.mapTasksListBkp    = new Map<Id, ApTaskWrapper>();
		this.actionPlan         = ( ActionPlan__c ) stdController.getRecord();
		System.debug('constructor actionplanId ' + this.actionPlan.Id);
		//this.maxAPTasks         = ActionPlansConstants.MAX_APTASKS;
		this.apTasks            = getAPTasks();

		this.cloneParam         = System.currentPageReference().getParameters().get( 'clone' );

		this.templateId         = ApexPages.currentPage().getParameters().get( 'templateId' );
		this.refId              = ApexPages.currentPage().getParameters().get( 'refId' );
		System.debug('refId ' + refId);
		this.refType            = ApexPages.currentPage().getParameters().get( 'refType' );

		if ( cloneParam == '1' )                                            {initCloneActionPlan();}
		else if ( this.actionPlan.Id != null )                              {initEditActionPlan();}
		else if ( this.templateId != null )                                 {initNewActionPlanFromTemplate(this.inVisualforceContext);}
		else                                                                {initNewActionPlan();}

		//this.defaultSettings    = ActionPlansMetadataUtility.getCustomSetting();
		this.canDisplayReminder    = ActionPlansMetadataUtility.getCanDisplayReminder();
		this.taskHasRecordType = ActionPlansMetadataUtility.HAS_RECORD_TYPE;
		if(this.refType != null){
			this.relatedObjectSelected = refType;
		} else {
			this.relatedObjectSelected = getRelatedObjectOptions()[0].getValue();
		}

		ActionPlansTestUtilities.showDebugParameters = true;
		ActionPlansTestUtilities.debugParameters();

	}

	// For calling from non-Visualforce contexts

	/* public ActionPlanCreationController(Id paramRefId, Id paramTemplateId){
		setupNonVisualforce(paramRefId, paramTemplateId, null);
	}
	public ActionPlanCreationController(Id paramRefId, ActionPlanTemplate__c apt){
		setupNonVisualforce(paramRefId, null, apt);
	}

	private void setupNonVisualforce(Id paramRefId, Id paramTemplateId, ActionPlanTemplate__c apt){
		this.inVisualforceContext = false;
		this.taskIndex          = 0;
		this.addedTask          = false;
		this.hasRelated         = false;
		this.hasRelatedObject   = false;
		this.relatedObjNameList = new List<String>();
		this.relatedObjIds      = new Set<Id>();
		this.mapTasksListBkp    = new Map<Id, ApTaskWrapper>();
		this.actionPlan         = new ActionPlan__c();

		String cloneParam            = '0';

		//ApexPages.currentPage().getParameters().put( 'templateId', templateId );
		//ApexPages.currentPage().getParameters().put( 'refId', refId );

		if(apt != null){
			this.templateId = apt.Id;
		}
		else if(paramTemplateId != null){
			this.templateId = paramTemplateId;
		}

		this.refId = paramRefId;
		Schema.SObjectType token = paramRefId.getSObjectType();
		this.refType = token.getDescribe().getName();
		if(this.templateId != null){ initNewActionPlanFromTemplate(this.inVisualforceContext, apt); }

		//this.defaultSettings    = ActionPlansMetadataUtility.getCustomSetting();
		this.canDisplayReminder    = ActionPlansMetadataUtility.getCanDisplayReminder();

		this.taskHasRecordType = ActionPlansMetadataUtility.HAS_RECORD_TYPE;
	} */

	/**
	* Initalize controller for editing an Action Plan
	*/
	public void initEditActionPlan(){

		this.hasRelatedObject           = this.hasRelatedObject();
		this.taskIndex                  = this.calculateAPTaskIndexValue();
		this.subtitle                    = this.actionPlan.Name;
	}

	/**
	* Initalize controller for cloning an Action Plan
	*/
	public void initCloneActionPlan(){

		this.actionPlan.StartDate__c    = Date.today();
		this.actionPlan.SkipWeekends__c = false;
		this.actionPlan.Name            = null;
		this.subtitle                   = this.actionPlan.Name;

		List<APTaskTemplate__c> tcAux   = this.getAPTasks();
		List<APTaskTemplate__c> tC      = this.apTasks.deepClone( false, true );

		this.apTasks.clear();
		this.apTasks = tC;

		// clear task relations
		for( APTaskTemplate__c t : this.apTasks ){
			t.Action_Plan__c = null;
		}

		for(String s : ActionPlansMetadataUtility.getCustomRelationshipFields()){
			this.actionPlan.put( s, null );
		}

		this.hasRelatedObject = false;
		this.hasRelated = false;
		//this.taskIndex = this.calculateAPTaskIndexValue();
	}

	/**
	* Initalize controller for creating a new Action Plan from a template
	*/
	public void initNewActionPlanFromTemplate(Boolean visualforceContext){
		initNewActionPlanFromTemplate(visualforceContext, null);
	}

	public void initNewActionPlanFromTemplate(Boolean visualforceContext, ActionPlanTemplate__c apt){
		this.initNewActionPlan();
		ActionPlanTemplate__c actionPlanTemplate;
		if(apt == null){
			List<ActionPlanTemplate__c> listAPT = [SELECT a.Id, a.Name, a.Description__c, a.LastModifiedDate,
													a.SkipWeekends__c, a.SkipDay__c, TaskRecordTypeID__c FROM ActionPlanTemplate__c a
													WHERE a.Id = :this.templateId];
			if(!listAPT.isEmpty()){
				actionPlanTemplate = listAPT.get(0);
			}
		} else {
			actionPlanTemplate = apt;
		}

		this.actionPlan.Name                         = ActionPlansMetadataUtility.actionPlanSubjectToName(actionPlanTemplate.Name);
		this.actionPlan.Description__c               = actionPlanTemplate.Description__c;
		this.actionPlan.SkipWeekends__c              = actionPlanTemplate.SkipWeekends__c;
		this.actionPlan.SkipDay__c                   = actionPlanTemplate.SkipDay__c;
		this.actionPlan.Action_Plan_Template__c      = actionPlanTemplate.Id;
		this.actionPlan.TaskRecordTypeID__c          = actionPlanTemplate.TaskRecordTypeID__c;

			//this.templateName                            =actionPlanTemplate.Name;

		if(visualforceContext){
			this.taskIndex  = this.calculateAPTTaskIndexValue();
			this.subtitle = System.Label.ap_New + ' ' + Schema.getGlobalDescribe().get( 'ActionPlan__c' ).getDescribe().getLabel();
		}
		this.apTasks = this.getAPTasks();
	}

	/**
	* Initalize controller for creating a new Action Plan
	*/
	public void initNewActionPlan(){

		this.actionPlan.StartDate__c    = Date.today();
		this.actionPlan.SkipWeekends__c = false;
		if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
			System.debug('set default action plan task record type id');
			this.actionPlan.TaskRecordTypeID__c = getDefaultTaskRecordTypeId();
		}
		if( refId != null ){
			this.hasRelated = true;
			this.referedObjectInit();
		}
		//this.relatedObjectSelected = getRelatedObjectOptions()[0].getValue();
		this.subtitle = System.Label.ap_New + ' ' + Schema.getGlobalDescribe().get( 'ActionPlan__c' ).getDescribe().getLabel();
	}

	/**
	* Getter and Setter for refId
	*/
	public String refId {
		get{
			if( refId == null ){
				refId = ApexPages.currentPage().getParameters().get( 'refId' );
			}
			return refId;
		} set;
	}

	/**
	* Getter and Setter for RefType
	*/
	public String refType {
		get{
			if( refType == null && refId != null){
				Id shortId = refId.left(15);
				refType = shortId.getSobjectType().getDescribe().getLabel();
			} else if(refId == null) {
				refType = ApexPages.currentPage().getParameters().get( 'refType' );
			}
			return refType;
		} set;
	}

	/**
	* Returns the related object Id FROM lookup fields.
	* @return the related object id
	*/
	public Id relatedObjectId(){
		Id currentId;
		for(String s : ActionPlansMetadataUtility.getCustomRelationshipFields()){
			if(actionPlan.get(s) != null){
				currentId = (Id)actionPlan.get(s);
				break;
			}
		}

		return currentId;
	}

	/**
	* Check if the action plan has a related object
	* @return hasRelated;
	*/
	public Boolean hasRelatedObject(){

		for( String f : ActionPlansMetadataUtility.getCustomRelationshipFields() ){

			if(actionPlan.get(f) != null){
				return true;
			}
		}
		return false;

	}

	/**
	* Check if have Task pending to delete
	*/
	public void checkPendingDeletes(){

		if( this.pendingDeletes != null ) {
			List<Task>  taskToDelete    = new List<Task>();
			Set<Id>    deleteApttIds   = new Set<Id>();

			for( APTaskTemplate__c deleteAptt : this.pendingDeletes ){
				deleteApttIds.add(deleteAptt.Id);
			}
			//do not delete completed tasks
			taskToDelete = [SELECT t.Id FROM Task t WHERE t.TaskAPTaskTemplate__c IN :deleteApttIds AND t.IsClosed = false];
			System.debug('We will delete some open tasks: ' + taskToDelete);
			delete taskToDelete;
			delete pendingDeletes;
		}
	}

	/**
	* Action which saves a new Action Plan
	* @return PageReference
	*/
	public PageReference save(){

		System.debug('CALLING SAVE');
		this.throwError         = null;
		PageReference pageRef   = null;
		if(!this.actionPlan.SkipWeekends__c){
			this.actionPlan.SkipDay__c = null;
		}

		try{
			System.debug('trying to save');
			if( !this.checkCycleDependent() ){
				System.debug('cycle dependence check is negative');
				//referedObjectOwnerInit();
				pageRef = this.saveHandler();
				System.debug('intended pageRef ' + pageRef);
			}
		}
		catch( Exception e ){
			System.debug('caught save exception 1 ' + e.getMessage());
			Apexpages.addMessages( e );
			if(Test.isRunningTest()){
				throw e;
			}
			return null;
		}

		return pageRef;
	}

	/**
	* Saves Action Plan Instance and task. Also creates all due dates for tasks, then redirects to the AP list
	*/
	public Id saveAp(){

		Id actionPlanId;
		Id objId;
		String objName;
		List<Id> oIdsList     = new List<Id>();
		Savepoint sp = Database.setSavepoint();
		if (refId == null){
			for(String s : ActionPlansMetadataUtility.getCustomRelationshipFields()){
				if(actionPlan.get(s) != null){
					objId = (Id)actionPlan.get(s);
					Schema.DescribeSObjectResult dsr = objId.getSObjectType().getDescribe();
					objName = dsr.getName();
					System.debug('OBJECT NAME ' + objName);
					break;
				}
			}

			oIdsList.add(objId);
			System.debug('refId is null');
			System.debug('objId ' + objId);
		} else {
			objName    = refType;
			//objId    = refId;
			oIdsList= refId.split(',');
			System.debug('parameters: ' + objName + ' ' + oIdsList);
		}

		//check for pendingDeletes
		this.checkPendingDeletes();

		System.debug('pending delete check is done');
		System.debug('objName: ' + objName);
		if( String.isNotBlank(objName) &&  oIdsList.size() == 1 ){
			Set<Id> parentIDs = new Set<Id>();
			parentIDs.addAll(oIdsList);
			try{
				//Now for each inserted AP we should run through tasks and create them
				this.apTasksOrg = new List<APTaskTemplate__c>();
				this.apTasksOrg.addAll( this.apTasks );

				System.debug('checking actionPlan.Id ' + actionPlan.Id);
				if (actionPlan.Id == null && !this.inVisualforceContext && !System.isFuture() && !System.isBatch()){
					System.debug('actionPlan.Id is null');
					System.debug('actionPlan ' + this.actionPlan);
					System.debug('apTasksOrg ' + apTasksOrg);
					System.debug('objName ' + objName);
					System.debug('oIdsList ' + oIdsList);
					Database.ExecuteBatch( new ActionPlansBatchBuilder(this.actionPlan, this.apTasks, objName, parentIDs) );
				} else {
					System.debug('actionPlan.Id is NOT null or we are going synchronous');
					System.debug('actionPlan ' + this.actionPlan);
					System.debug('apTasksOrg ' + apTasksOrg);
					System.debug('objName ' + objName);
					System.debug('oIdsList ' + oIdsList);
					System.debug('apTasks ' + apTasks);
					ActionPlansBatchBuilderUtilities taskBatch = new ActionPlansBatchBuilderUtilities(this.actionPlan, this.apTasks, objName, parentIDs);
					actionPlanId = taskBatch.generateActionPlans();
				}
			} catch( Exception e ){
				System.debug('saveAP Exception ' + e.getMessage());
				Database.rollback( sp );
				throw e;
			}
		}
		System.debug('actionplan.Id = ' + actionPlan.Id);
		System.debug('actionplanId = ' + actionPlanId);
		return actionPlanId;
	}

	/**
	* Saves Action Plan Instance and tasks and returns to the creation page with the previous Action Plan's details.
	* @return newPage
	*/
	public PageReference saveAndNew(){
		saveAp();

		PageReference newPage = Page.ActionPlanCreation;
		newPage.setRedirect( true );

		return newPage;
	}

	/**
	* Save Action Plans for Multiple Related Object Instances.
	* Invokes batch process that creates : ActionPlan, ActionPlanTasksTemplate AND Tasks
	* @return Pagereference
	*/
	public PageReference saveMultiple(){
		System.debug('in saveMultiple');
		String oName                    = ApexPages.currentPage().getParameters().get( 'refType' );
		String oIds                     = ApexPages.currentPage().getParameters().get( 'refId' );
		List<ActionPlan__c> apList      = new List<ActionPlan__c>();
		List<APTaskTemplate__c> aptList = new List<APTaskTemplate__c>();
		Savepoint sp = Database.setSavepoint();

		if( ( oName != null || oName != '' ) && ( oIds != null || oIds != '' ) ){
			try{

				List<Id> oIdsList = oIds.split(',');
				Set<Id> parentIDs = new Set<Id>();
				parentIDs.addAll(oIdsList);
				//Now for each inserted AP we should run through tasks and create them
				System.debug('parentIDs ' + parentIDs);
				System.debug('passing this.apTasks to APBB ' + this.apTasks);
				ActionPlansBatchBuilder taskBatch = new ActionPlansBatchBuilder(this.actionPlan, this.apTasks, oName, parentIDs);
				Database.ExecuteBatch( taskBatch );

			} catch(Exception e){
				Database.rollback( sp );
			}
		}

		PageReference newPage = new PageReference( '/' + ActionPlansMetadataUtility.getObjectKeyPrefix( oName ) + '/o' );
		newPage.setRedirect( true );
		return newPage;
	}

	/**
	* Saves Action Plan Handler.
	* Decides if we are assigning to multiple parent records or just one
	* @return Pagereference called Method
	*/
	public PageReference saveHandler(){

		String oIds = ApexPages.currentPage().getParameters().get( 'refId' );
		List<String> oIdsList = new List<String>();

		if( oIds != null ){
			oIdsList = oIds.split(',');
			System.debug('oids: ' + oIdsList);
			return  ( oIdsList.size() > 1 ) ? this.saveMultiple() : this.savePageRef();
		}
		else {
			System.debug('in saveHandler_else');
			return this.savePageRef();
		}
	}

	/**
	* Saves Action Plan Instance and tasks and redirects to that detail page
	* @return newPage
	*/
	public PageReference savePageRef(){

		Id newApId;
		String ap_Prefix;

		try {
			newApId = saveAp();
		}
		catch ( DmlException e ){
			System.debug('savePageRef_dmlexception ' + e.getMessage());
			//throw e;
			return null;
		}

		ap_Prefix =  ActionPlansMetadataUtility.getObjectKeyPrefix( 'ActionPlan__c' ) ;
		if(newApId != null){
			ap_Prefix = newApId;
		}

		PageReference newPage = new PageReference(  '/' + ap_Prefix );
		newPage.setRedirect( true );

		return newPage;
	}

	/**
	* Action that forwards to previous page
	* @return PageReference
	*/
	public PageReference cancel(){
		String objectType   = ApexPages.currentPage().getParameters().get( 'refType' );
		String objectIds    = ApexPages.currentPage().getParameters().get( 'refId' );
		String retURL       = ApexPages.currentPage().getParameters().get( 'retURL' );
		String paramid      = this.actionPlan.Id != null ? this.actionPlan.Id : ApexPages.currentPage().getParameters().get( 'id' );
		String pageRef;
		String aPlanListUrl;

		ActionPlansTestUtilities.showDebugParameters = true;
		ActionPlansTestUtilities.debugParameters();

		// Reference action plan detail page
		if( paramid != null ){
			PageReference cancelPage = Page.ActionPlanDetail;
			cancelPage.getParameters().put('id',paramid);
			cancelPage.setRedirect( true );
			return cancelPage;
			//pageRef = '/' + paramid;

		}

		// Reference action plans template
		else if( this.templateId != null ){
			//aPlanListUrl = Schema.ActionPlanTemplate__c.sObjectType.getDescribe().getKeyPrefix();
			pageRef = '/' + this.templateId;
		}
		else if( objectType != null && objectIds != null ){
			List<String> oIdsList = objectIds.split(',');
			// Reference object list page
			if (oIdsList.size()>1){
				pageRef = '/' + ActionPlansMetadataUtility.getObjectKeyPrefix( objectType );
			}
			// Reference object detail page
			else {
				pageRef = '/' + oIdsList.get(0);
			}
		}
		// Reference previous page if defined
		else if( retURL != null){
			pageRef = retUrl;
		}

		// Reference action plans list by default
		else {
			aPlanListUrl = Schema.ActionPlan__c.sObjectType.getDescribe().getKeyPrefix();
			pageRef = '/' + aPlanListUrl;
		}

		PageReference previousPage = new PageReference( pageRef );
		previousPage.setRedirect( true );

		return previousPage;
	}

	/**
	* Retrieves number of completed tasks
	* @return Integer
	*/
	public Integer getCompleted(){
		if(actionPlan.Id == null){ return 0; }

		List<APTaskTemplate__c> ts = [SELECT t.Id
			FROM APTaskTemplate__c t
			WHERE t.Status__c IN :ActionPlansMetadataUtility.getClosedTaskStatuses()
			AND t.ActivityDate__c != null AND t.Action_Plan__c = :actionPlan.Id];

		return ( ts != null ) ? ts.size() : 0;
	}

	/**
	* Creates a blank Task object and adds it to List<Task>
	*/
	public void addTask(){
		System.debug('Existing tasks: ' + this.apTasks);
		System.debug('existing taskIndex ' + this.taskIndex);
		this.taskIndex++;

		Boolean hasNoErrors = true;
		if( this.apTasks.size() >= ActionPlansConstants.MAX_APTASKS ){
			errorMsg = System.Label.ap_Errors_TaskLimitError;
		}
		else {
			APTaskTemplate__c t     = new APTaskTemplate__c();
			t.Reminder__c             = ActionPlansMetadataUtility.getCheckReminderByDefault();
			t.Minutes_Reminder__c    = ActionPlansMetadataUtility.getDefaultReminderMinutes();
			t.Name                  = null;
			t.TaskIndex__c             = this.taskIndex;
			//t.Action_Plan__c        = this.actionPlan.Id;

			System.debug('taskIndex ' + t.TaskIndex__c);
			System.debug('t.Priority__c ' + t.Priority__c);
			System.debug('apTasks: ' + apTasks);

			// validate user, priority, subject and days before adding another
			Action_Plans_Settings__c mySettings = ActionPlansMetadataUtility.getCustomSetting();
			for( APTaskTemplate__c apt : apTasks ) {

				System.debug('apt.User: ' + apt.User__c);
				System.debug('taskDefault: ' + mySettings.Unassigned_Task_Default__c);
				System.debug('Subject: ' + apt.Subject__c);
				hasNoErrors = ( ( apt.User__c != null || mySettings.Unassigned_Task_Default__c ) && apt.Subject__c != null );
				System.debug('do we have NO errors? ' + hasNoErrors);
				apt.DaysFromStart__c     = ( apt.DaysFromStart__c < 0 ) ? 0 : apt.DaysFromStart__c;
			}
			if( hasNoErrors ){
				this.apTasks.add( t );
			}

		}

		this.addedTask = hasNoErrors;

		System.debug('New list of tasks: ' + this.apTasks);
	}

	/**
	* Action for removing a existing task
	*/
	public void removeTask(){
		Boolean removedTask = false;
		if( ApexPages.currentPage().getParameters().get( 'remove' ) != null ){
			Integer taskIndex       = Integer.valueOf( ApexPages.currentPage().getParameters().get( 'remove' ) );

			//check for dependent children and clear them since the parent is being removed.
			apTasks[ taskIndex].APTaskTemplate__c    = null;
			apTasks[ taskIndex].Dependent__c         = null;

			APTaskTemplate__c apTask;
			Integer dependentApTask;

			//update the current dependent position from tasks below of deleted one.
			for( Integer i = 0; i < this.apTasks.size(); i++ ){
				apTask = this.apTasks.get( i );
				if( apTask.Dependent__c != null && apTask.Dependent__c != 'None' ){
					dependentApTask = Integer.valueOf( apTask.Dependent__c );
					if( dependentApTask > taskIndex ){
						apTask.Dependent__c = String.valueOf( dependentApTask - 1 );
					} else if( dependentApTask == taskIndex ){
						apTask.Dependent__c         = 'None';
						apTask.APTaskTemplate__c    = null;
					}
				}
			}

			// before remove check if it's exists in the DB, if so, add to pendingDeletes to be deleted on save.
			if( this.apTasks[taskIndex].Id != null ){
				if( pendingDeletes == null ){
					pendingDeletes = new List<APTaskTemplate__c>();
				}
				pendingDeletes.add( this.apTasks[taskIndex] );
			}

			apTasks.remove( taskIndex );

			// clear errorMsg if it's set.
			if( this.apTasks.size() < ActionPlansConstants.MAX_APTASKS ){
				errorMsg = null;
			}
			removedTask = true;
		}
		addedTask = !removedTask;
	}

	/**
	* Method which retrieves all tasks for a Action Plan
	* @return List<APTaskTemplate__c>
	*/
	public List<ApTaskWrapper> getTasks(){

		List<ApTaskWrapper> tasksList = new List<ApTaskWrapper>();

		ApTaskWrapper tmpAptask;

		Integer i = 0;
		//for( APTaskTemplate__c apTaskTemplate : this.apTasks ){
		for( APTaskTemplate__c apTaskTemplate : this.getAPTasks() ){
			//check if the lookUp has to be shown
			if (apTaskTemplate.Id != null){
				tmpAptask = this.mapTasksListBkp.get(apTaskTemplate.Id);
			}

			Boolean userRequired  = false;
			Boolean displayLookUp = false;

			Action_Plans_Settings__c mySettings = Action_Plans_Settings__c.getInstance();
			// User is Required if the task id is null and we don't give unassigned to record owner
			// We always display the lookup because we never FORCE the task to be assigned to the record owner

			// userRequired is TRUE if not "unassigned defaults to record owner"

			if (tmpAptask == null){
				displayLookUp   = apTaskTemplate.User__c != null || (apTaskTemplate.User__c == null && !mySettings.Unassigned_Task_Default__c);
				userRequired    = !mySettings.Unassigned_Task_Default__c; // true if not unassigned to record owner
			} else { // editing existing task
				displayLookUp   = tmpAptask.displayLookUp; // false if user is filled and don't default to record owner
				userRequired    = tmpAptask.userRequired; // true if not unassigned to record owner
			}

			ApTaskWrapper apTWrapper = new ApTaskWrapper( apTaskTemplate, i, displayLookup, userRequired, this.actionPlan.TaskRecordTypeID__c );
			tasksList.add( apTWrapper );
			if ( String.isNotBlank(apTaskTemplate.Id) ){
				this.mapTasksListBkp.put(apTaskTemplate.Id, apTWrapper);
			}

			i++;
		}
		if( addedTask ){
			tasksList.get( i - 1 ).isLast = true;
		}

		System.debug('tasksList: ' + tasksList);
		return tasksList;
	}

	/**
	* Gets Tasks related to an Action Plan
	* @return apTasks
	*/
	public List<APTaskTemplate__c> getAPTasks(){
		System.debug('in creationcontroller.getAPTasks');

		if( this.apTasks == null || this.apTasks.size() == 0 ) {

			if(templateId != null){
				System.debug('Template provided by variable');
			} else if( ApexPages.currentPage().getParameters().get( 'templateId' ) != null ){
				templateId = ApexPages.currentPage().getParameters().get( 'templateId' );
				System.debug('pulled template from page parameters ' + templateId);
			}

			if( templateId != null ){
				System.debug('templateId != null');
				//String templateId = ApexPages.currentPage().getParameters().get( 'templateId' );

				aptTasks = [SELECT a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c, a.User__r.Name, a.Id,
							a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, a.APTTaskTemplate__r.Subject__c,
							a.Reminder__c, a.SendEmail__c, a.Comments__c, a.TaskIndex__c, a.Action_Plan_Template__r.TaskRecordTypeID__c
							FROM APTTaskTemplate__c a
							WHERE a.Action_Plan_Template__c = :templateId ORDER BY TaskIndex__c ASC];
				System.debug('We found this many template tasks: ' + aptTasks.size());

				this.apTasks = new List<APTaskTemplate__c>();

				Action_Plans_Settings__c mySettings = ActionPlansMetadataUtility.getCustomSetting();
				Id userId;
				for( APTTaskTemplate__c aptTask : aptTasks ){
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
						//RSC 2011-05-27 This appears to be in error
						//results in an emtpy assign to field being populate with the current user's info
						//userId = UserInfo.getUserId();//null;
						System.debug('DEFAULT ASSIGNMENT');
						userId = null;
					}

					APTaskTemplate__c t     = new APTaskTemplate__c();
					t.Type__c               = aptTask.Type__c;
					t.Subject__c            = aptTask.Subject__c;
					t.Priority__c           = aptTask.Priority__c;
					t.Dependent__c          = aptTask.Dependent__c;
					t.TaskIndex__c          = aptTask.TaskIndex__c;
					//t.Name                  = aptTask.Name; // will be overridden by the object trigger
					t.DaysFromStart__c      = aptTask.DaysFromStart__c;
					t.User__c               = userId;
					t.Reminder__c           = aptTask.Reminder__c;
					t.Minutes_Reminder__c   = ActionPlansMetadataUtility.getDefaultReminderMinutes();

					t.SendEmail__c          = aptTask.SendEmail__c;
					t.Comments__c           = aptTask.Comments__c;
					this.apTasks.add( t );
				}
			} else if( actionPlan.Id != null ){
				System.debug('paramId != null');
				this.apTasks = retrieveTaskFromExistingActionPlan( actionPlan.Id );
				//check reminders and set 'send email' as false
				String tmp_reminderDefaultTime = ActionPlansMetadataUtility.getDefaultReminderMinutes();
				for( APTaskTemplate__c t : this.apTasks ){
					if (t.Reminder__c == null || t.Reminder__c == false){
						t.Minutes_Reminder__c    = tmp_reminderDefaultTime;
					}
					t.SendEmail__c = false;
				}
			}
			else {
				System.debug('getTasks.else');
				this.apTasks             = new List<APTaskTemplate__c>();
				APTaskTemplate__c t      = new APTaskTemplate__c();
				t.Reminder__c            = ActionPlansMetadataUtility.getCheckReminderByDefault();
				t.Minutes_Reminder__c    = ActionPlansMetadataUtility.getDefaultReminderMinutes();
				this.apTasks.add( t );
			}

			// Clone. Clear ids.
			if( cloneParam == '1' ){
				List<APTaskTemplate__c> tC = this.apTasks.deepClone(false);
				this.apTasks.clear();
				this.apTasks = tC;

				// clear task relations
				for( APTaskTemplate__c t : this.apTasks ){
					t.Action_Plan__c = null;
				}
			}
		}

		return this.apTasks;
	}

	/**
	* Get a Existing Action Plan Task List
	* @param actionPlanId
	* @return myList
	*/
	public static List<APTaskTemplate__c> retrieveTaskFromExistingActionPlan( Id actionPlanId ){

		List<APTaskTemplate__c> myList = [SELECT a.Type__c, a.Subject__c, a.ActivityDate__c, a.Priority__c, a.Status__c, a.Dependent__c,
		a.Name, a.User__c, a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.APTaskTemplate__r.Name,
		a.APTaskTemplate__r.Subject__c, a.APTaskTemplate__c, a.Action_Plan__c, a.Reminder__c,
		a.SendEmail__c, a.Comments__c, a.Minutes_Reminder__c, a.TaskIndex__c, a.Time_Reminder__c,
		Task_RecordTypeId__c, a.IsClosed__c
		FROM APTaskTemplate__c a
		WHERE a.Action_Plan__c = :actionPlanId ORDER BY a.TaskIndex__c asc];
		System.debug('retrieve from existing actionplan: ' + myList);
		return myList;
	}

	/**
	* Retrieves if template lookup must be displayed
	* @return Boolean
	*/
	public Boolean getDisplayTemplateLookup(){
		return (this.hasRelated || this.templateId != null);
	}

	/**
	* Returns list of Dependent tasks to fill drop down
	* @return List<SelectOption>
	*/
	public List<SelectOption> getSubjectItems(){
		List<SelectOption> options = new List<SelectOption>();
		options.add( new SelectOption( 'None', '--' + System.Label.ap_None +'--' ) );
		Integer i = 0;

		if( this.apTasks != null ){
			for( APTaskTemplate__c t : this.apTasks ){
				if( t.Subject__c != null ){
					options.add(new SelectOption( String.valueOf(i), t.Subject__c+' (' + (i+1) +')') );
				}
				i++;
			}
		}
		return options;
	}

	/**
	* Set the Refered object to Create New Action Plan
	*/
	public void referedObjectInit(){

		String nameParam = '';
		String idsParam;

		if( refType != null){
			nameParam        = String.escapeSingleQuotes( refType );
			idsParam         = String.escapeSingleQuotes( refId );

			if( idsParam != null && idsParam != '' ){
				List<Id> paramList = idsParam.split(',');
				this.relatedObjIds = new Set<Id>(paramList);
			}
		}

		retrieveNameRelatedObject(relatedObjIds, nameParam);
	}

	/**
	*
	* @param relatedObjIds
	* @param relatedObjectName
	*/
	private void retrieveNameRelatedObject( Set<Id> relatedObjIds, String relatedObjectName ){
		String objectlower = relatedObjectName.toLowerCase();
		System.debug('related object name is ' + objectlower);

		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.SObjectType sot = gd.get(objectlower);
		relatedObjNamePlural = sot.getDescribe().getLabelPlural();

		switch on objectlower{

			when 'case' {
				for( Case ca : [SELECT Subject, CaseNumber FROM Case WHERE Id IN :relatedObjIds] ){
					this.relatedObjNameList.add( (ca.Subject != null) ?  ca.CaseNumber + ': ' + ca.Subject : ca.CaseNumber );
				}
			}
			when 'contract' {
				for( Contract contr : [SELECT ContractNumber FROM Contract WHERE Id IN :relatedObjIds] ){
					this.relatedObjNameList.add( Contract.Name.getDescribe().getLabel() + ' ' + contr.ContractNumber );
				}
			}
			when else {
					String relNameQuery = 'SELECT Id, Name FROM ' + objectlower + ' WHERE Id IN :relatedObjIds';
					System.debug('relNameQuery ' + relNameQuery);
					for(SObject so : Database.query(relNameQuery)){
						this.relatedObjNameList.add( (String)so.get('Name'));
					}
			}
			//Add custom object code Segment here.
			/* when 'customobject' {
				for( CustomObject custObj : [SELECT Name from CustomObject WHERE Id IN :relatedObjIds] ){
					this.relatedObjNameList.add( custObj.Name );
				}
			} */
		}
	}

	/**
	* Checks if Action Plan Tasks has cyclic dependency.
	* @return exists
	*/
	public Boolean checkCycleDependent(){

		this.errorMsg     = null;
		Boolean exists    = false;
		Integer index     = 0;

		for( APTaskTemplate__c t : this.apTasks ){
			if( t.Dependent__c != null && t.Dependent__c != 'None'){
				//Integer tempIndex       = ;
				APTaskTemplate__c link     = this.apTasks[ Integer.valueOf( t.Dependent__c ) ];

				//task can not depend on themselves
				if( Integer.valueOf( t.Dependent__c ) == index){ //  || t.Id == t.APTaskTemplate__c
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
	* Check for cyclic dependent tasks
	* @param originTask
	* @param destinyTask
	* @param index
	* @return Boolean
	*/
	private Boolean dependantCycle( APTaskTemplate__c originTask, APTaskTemplate__c destinyTask, Integer index ){

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

				APTaskTemplate__c link         = this.apTasks[ Integer.valueOf( destinyTask.Dependent__c ) ];

				if( link.Dependent__c != null && link.Dependent__c != 'None' ){
					if( Integer.valueOf( link.Dependent__c ) == index ){
						hasDependency = true;
						break;
					}
					else {
						//get Next task in dependency chain
						//Integer tempIndex     = ;
						destinyTask         = this.apTasks[ Integer.valueOf( destinyTask.Dependent__c ) ];
					}
				}
				else {
					break;
				}
			} else {
				break;
			}
		}

		return hasDependency;
	}

	/**
	* Getter method to return the error message from
	* action plans utilities
	*/
	public String getErrorMsg(){
		System.debug('ERROR MESSAGE: ' + errorMsg);
		return errorMsg;
	}

	/**
	* Calculates the highest task index value for Action Plan Tasks
	* @return maxIndex
	*/
	public Double calculateAPTaskIndexValue(){
		Double maxIndex = 0;
		List<AggregateResult> arList = [SELECT MAX(TaskIndex__c) m FROM APTaskTemplate__c WHERE Action_Plan__c = :this.actionPlan.Id];
		if(!arList.isEmpty()){
			maxIndex = (Double)arList[0].get('m');
			maxIndex = (maxIndex == null ? 0 : maxIndex);
		}
		System.debug('maxIndex ' + maxIndex);
		return maxIndex;
	}

	/**
	* Calculates the highest task index value for Action Plan Template Tasks
	* @return maxIndex
	*/
	public Double calculateAPTTaskIndexValue(){
		Double maxIndex = 0;
		List<AggregateResult> arList = [SELECT MAX(TaskIndex__c) m FROM APTTaskTemplate__c WHERE Action_Plan_Template__c = :this.templateId];
		if(!arList.isEmpty()){
			maxIndex = (Double)arList[0].get('m');
			maxIndex = (maxIndex == null ? 0 : maxIndex);
		}
		System.debug('maxIndex ' + maxIndex);
		return maxIndex;
	}

	/**
	* Getter method with the related object options by default.
	*/
	public List<SelectOption> getRelatedObjectOptions(){

		List<SelectOption> options = new List<SelectOption>();

		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

		for(String s : ActionPlansMetadataUtility.getCustomRelationshipFields()){
			String value = s;
			if(s.endsWithIgnoreCase('__c')){
				s = s.removeEndIgnoreCase('__c');
			}
			Schema.SObjectType sot = gd.get(s.toLowerCase());
			String label = sot.getDescribe().getLabel();
			options.add( new SelectOption( label, label ));
		}

		/* options.add( new SelectOption( 'Account', Schema.sObjectType.Account.getlabel() ) );
		options.add( new SelectOption( 'Campaign', Schema.sObjectType.Campaign.getlabel() ) );
		options.add( new SelectOption( 'Case', Schema.sObjectType.Case.getlabel() ) );
		options.add( new SelectOption( 'Contact', Schema.sObjectType.Contact.getlabel() ) );
		options.add( new SelectOption( 'Contract', Schema.sObjectType.Contract.getlabel() ) );
		options.add( new SelectOption( 'Lead', Schema.sObjectType.Lead.getlabel() ) );
		options.add( new SelectOption( 'Opportunity', Schema.sObjectType.Opportunity.getlabel() ) ); */
		options.sort();
		return options;
	}

	/**
	* Getter method to set the default related object option.
	* @return the default option
	*/
	/* public SelectOption getDefaultRelatedObjectOption(){
		return	new SelectOption( 'Account', Schema.sObjectType.Account.getlabel() );
	} */

	/**
	* Refresh the related object lookup field.
	*/
	public PageReference refreshRelatedObjectsLookUp(){
		relatedObjectSelected = Apexpages.currentPage().getParameters().get( 'relatedObjectSelected' );
		return null;
	}

	/**
	* Find user default task recordtype
	@return default task record type
	*/
	public Id getDefaultTaskRecordTypeId(){
		return ActionPlansMetadataUtility.getDefaultTaskRecordTypeId();
	}

	/**
	 * Convert Record Type Id to Record Type Name
	 * @return Record Type Name
	 */
	public String getRecordTypeName(){
		String toReturn = '';
		if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
			Map<Id,Schema.RecordTypeInfo> rtMapById = Task.SObjectType.getDescribe().getRecordTypeInfosById();
			if(!rtMapById.isEmpty() && rtMapById.containsKey(actionPlan.TaskRecordTypeID__c)){
				return rtMapById.get(actionPlan.TaskRecordTypeID__c).getName();
			}
		}
		return toReturn;
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

	public List<SelectOption> getHoursOption(){
		return ActionPlansMetadataUtility.getHoursOption();
	}

	/**
	* Wrapper Class for AP task Object
	* @author Rodrigo Birriel
	* @createddate 08/01/2010
	* @author David Schach
	* @updatedDate 4/11/2021
	*/
	public class ApTaskWrapper{

		public APTaskTemplate__c task       { get; set; }
		public  Integer     position        { get; set; }
		public  Boolean     isLast          { get; set; }
		public  Boolean     displayLookUp   { get; set; }
		public  Boolean     userRequired    { get; set; }

		public ApTaskWrapper( APTaskTemplate__c apTask, Integer pos, Boolean looKp, Boolean userReq, Id defaultTaskRTId ){
			task            = apTask;
			position        = pos;
			isLast          = false;
			displayLookUp   = looKp;
			userRequired    = userReq;

			Id taskRTID = null;
			if(ActionPlansMetadataUtility.HAS_RECORD_TYPE){
				taskRTID = defaultTaskRTId;
			}

			if(task.Id == null){
				task.Priority__c = task.Priority__c != null ? task.Priority__c : ActionPlansMetadataUtility.getTaskRecordTypePriorityDefaultValues().get(defaultTaskRTId);
				task.Status__c = task.Status__c != null ? task.Status__c : ActionPlansMetadataUtility.getTaskRecordTypeStatusDefaultValues().get(defaultTaskRTId);
			}
		}
	}

	public class FieldCustomValidationException extends Exception{

		private DmlException dmlException;

		/**
		* Constructor
		*/
		public FieldCustomValidationException( DmlException e ){

			this.dmlException = e;
		}

		public String getCustomMessage(){

			String message = this.dmlException.getDmlMessage( 0 );

			return message;
		}
	}

	/**
	* Pull maximum tasks from javascript to an Apex constant
	*/
	/* public Integer getMaxAPTasks(){
		return ActionPlansConstants.MAX_APTASKS;
	} */

}