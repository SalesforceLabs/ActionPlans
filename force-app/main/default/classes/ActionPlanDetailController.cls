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
public inherited sharing class ActionPlanDetailController{

	private ActionPlan__c            actionPlan;
	public Boolean                  hasRecordType   { get; set; }

	/**
	* Constructor
	*/
	public ActionPlanDetailController( ApexPages.StandardController stdController ){

		this.actionPlan = ( ActionPlan__c ) stdController.getRecord();

		System.debug('constructor actionplanId ' + this.actionPlan.Id);

		this.hasRecordType = ActionPlansUtilities.HAS_RECORD_TYPE;
	}

	/**
	* Deletes the current Action Plan loaded and redirects to the AP Template List
	* @return newPage
	*/
	public PageReference deletePlan(){

		System.debug('retURL: ' + ApexPages.currentPage().getParameters().get('retURL'));

		Savepoint sp        	= Database.setSavepoint();
		//ActionPlan__c ap    = actionPlan;
		//Set<Id> recordIds	= new Set<Id>{actionPlan.Id};

		//delete ap, which will also delete apts via master-detail relationship
		try{

			//ActionPlansBatchDeleteUtilities taskBatch = new ActionPlansBatchDeleteUtilities(recordIds);
			//taskBatch.deleteActionPlans();

			delete actionPlan;

		} catch( Exception e ){
			Database.rollback( sp );
		}
		String retURL = '/' + ActionPlansUtilities.getObjectKeyPrefix( 'ActionPlan__c' ) + '/o' ;

		String theme = UserInfo.getUiThemeDisplayed();

		if(ApexPages.currentPage().getParameters().get('templateId') != null){
			retUrl = '/' + ApexPages.currentPage().getParameters().get('templateId');
		}
		else if(ApexPages.currentPage().getParameters().get('retURL') != null && (theme == 'Theme2' || theme == 'Theme3')){
			retURL = ApexPages.currentPage().getParameters().get('retURL');
		}
		// Send the user to the tab.
		PageReference newPage = new PageReference( retURL );
		newPage.setRedirect( true );

		return newPage;
	}

	/**
	* Gets all tasks for a given ActionPlan
	*/
	private List<APTaskTemplate__c> apTasks;

	public List<APTaskTemplate__c> getTasks(){

		System.debug('existing apTasks ' + this.aptasks);
		if( apTasks == null || apTasks.isEmpty() ) {
			apTasks = [SELECT Action_Plan__c, ActivityDate__c, APTaskTemplate__c, APTaskTemplate__r.Subject__c, Comments__c, DaysFromStart__c, Dependent__c, Id,
							IsClosed__c, Minutes_Reminder__c, Name, Priority__c, Reminder__c, Time_Reminder__c, SendEmail__c, Status__c, Subject__c, Task_RecordTypeId__c,
							TaskIndex__c, Type__c, User__c, User__r.Name, (SELECT Id, Subject FROM Template_Tasks__r)
							FROM APTaskTemplate__c WHERE Action_Plan__c = :actionPlan.Id ORDER BY TaskIndex__c ASC];
		}
		return apTasks;
	}

	/**
	* Returns number of completed tasks
	*/
	public Integer getCompleted(){
		if(actionPlan.Id == null){ return 0; }

		List<APTaskTemplate__c> ts = [SELECT t.Id
				FROM APTaskTemplate__c t
				WHERE t.Status__c IN :ActionPlansUtilities.getClosedTaskStatuses()
				AND t.ActivityDate__c != null AND t.Action_Plan__c = :actionPlan.Id];

		return ( ts != null ) ? ts.size() : 0;
	}

	/**
	* Checks if Action Plan Template has been changed since the creation of the Action Plan.
	* @return Boolean
	*/
	public Boolean getVersion(){
		if( actionPlan.Action_Plan_Template__c != null ){
			ActionPlanTemplate__c TempApt = [SELECT LastModifiedDate FROM ActionPlanTemplate__c WHERE Id = :actionPlan.Action_Plan_Template__c];
			if( TempApt.LastModifiedDate > actionPlan.createdDate ){
				return true;
			}
		}
		return false;
	}

	public String getRelatedObjectLabel(){

		String objLabel='';

		for( String f : ActionPlansUtilities.getCustomRelationshipFields() ){

			if(actionPlan.get(f) != null){
				Id objId = (Id)actionPlan.get(f);
				Schema.DescribeSObjectResult dsr = objId.getSObjectType().getDescribe();
				objLabel = dsr.getLabel();
				break;
			}
		}

		return objLabel;
	}


	public String getrelatedRecordName(){

		System.debug(actionPlan);

		String objName='';
		Id objId;

		for( String f : ActionPlansUtilities.getCustomRelationshipFields() ){
			//System.debug('evaluating string ' + f + ' value ' + actionPlan.get(f));

			if(actionPlan.get(f) != null){
				objId = (Id)actionPlan.get(f);
				//System.debug('we have a value objId ' + objId);
				Schema.DescribeSObjectResult dsr = objId.getSObjectType().getDescribe();
				objName = dsr.getName();
				//System.debug('object name is ' + objName);
				break;
			} else {
				System.debug('no value in field ' + f);
			}
		}



		switch on objName {
			when 'Case' {
				Case c = [SELECT Id, Subject, CaseNumber FROM Case WHERE Id = :objId LIMIT 1];
				return c.CaseNumber + ': ' + c.Subject;
			}
			when 'Contract' {
				Contract c = [SELECT Id, ContractNumber FROM Contract WHERE Id = :objId LIMIT 1];
				return c.ContractNumber;
			}
			when else {
				String relNameQuery = 'SELECT Id, Name FROM ' + objName + ' WHERE Id = \'' + objId + '\'';
				System.debug('relNameQuery ' + relNameQuery);
				SObject so = Database.query(relNameQuery)[0];

				return (String)so.get('Name');
			}
		}
	}

	/**
	 * Convert Record Type Id to Record Type Name
	 * @return Record Type Name
	 */
	public String getRecordTypeName(){
		String toReturn = '';
		if(ActionPlansUtilities.HAS_RECORD_TYPE){
			Map<Id,Schema.RecordTypeInfo> rtMapById = Task.SObjectType.getDescribe().getRecordTypeInfosById();
			if(!rtMapById.isEmpty() && rtMapById.containsKey(actionPlan.TaskRecordTypeID__c)){
				return rtMapById.get(actionPlan.TaskRecordTypeID__c).getName();
			}
		}
		return toReturn;
	}

}