/*
Action Plans v3
Force.com Labs
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
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
public with sharing class ActionPlanTemplateCreationController{
	
	private Double					taskIndex				{ get; set; }
	public ActionPlanTemplates		actionPlanTemplates		{ get; set; }
	public ActionPlanTemplate__c 	actionPlanTemplate		{ get; set; }
	public String           		actionPlanTemplateId	{ get; set; }
	public Boolean					addedTask				{ get; set; }
	public Boolean					displayReminder			{ get; set; }
	
	/**
     * Constructor
     * If we can obtain the Id from the page parameters then we search for that template and set the variable for that template.
     * If we can't obtain the Id from the page parameters then we create a new template and obtain from the controller.
     * Then we need to check if we are cloning the template, in that case clone the template without Id.
     */
    public ActionPlanTemplateCreationController( ApexPages.StandardController stdController ){

        this.taskIndex = 0;
        this.addedTask = false;
        
        if( System.currentPageReference().getParameters().get( 'id' ) != null ){
        	
			this.actionPlanTemplateId 	= System.currentPageReference().getParameters().get( 'id' );
			this.actionPlanTemplate 	= [ select a.Id, a.Name, a.Description__c, a.SkipWeekends__c, a.SkipDay__c, a.LastModifiedDate, 
												a.LastModifiedBy.Name, a.LastModifiedById, a.CreatedDate, a.CreatedBy.Name, a.CreatedById, 
												a.Owner.Name from ActionPlanTemplate__c a
												Where a.Id =: this.actionPlanTemplateId limit 1 ];
			
			this.taskIndex = this.calculateTaskIndexValue();
		}
		else{
			this.actionPlanTemplate = ( ActionPlanTemplate__c ) stdController.getRecord();
		}
		
       	if( System.currentPageReference().getParameters().get( 'clone' ) == '1' ){
       		ActionPlanTemplate__c apC = actionPlanTemplate.clone( false );
            this.actionPlanTemplate.clear();
            this.actionPlanTemplate = apC;
       	}
       	
        this.actionPlanTemplates = new ActionPlanTemplates( this.actionPlanTemplate );
        this.actionPlanTemplates.taskIndexOrder = this.taskIndex;
        this.displayReminder = this.actionPlanTemplates.getDisplayReminder();
    }

	/**
	 * Call method saveTemplate() inside the class ActionPlanTemplates
	 * @return PageReference
	 */
	public PageReference saveTemplate(){
		return actionPlanTemplates.saveTemplate();
	} 
	
	/**
	 * Call method cancelTemplate() inside the class ActionPlanTemplates
	 * @return PageReference
	 */
	public PageReference cancelTemplate(){
		return actionPlanTemplates.cancelTemplate();
	}
	
	/**
	 * Call method addTemplateTask() inside the class ActionPlanTemplates
	 */
	public void addTemplateTask(){
		
		this.taskIndex++;
		this.actionPlanTemplates.taskIndexOrder = this.taskIndex;
		this.addedTask = actionPlanTemplates.addTemplateTask();
	}
	
	/**
	 * Call method removeTemplateTask() inside the class ActionPlanTemplates
	 */
	public void removeTemplateTask(){
		addedTask = !actionPlanTemplates.removeTemplateTask();
	}
	
	/**
	 * Call method getTemplateTasks() inside the class ActionPlanTemplates
	 */
	public List<ApTTaskWrapper> getTemplateTasks(){
		
		ApTTaskWrapper apTTaskWrapper;
    	List<ApTTaskWrapper> tasksList = new List<ApTTaskWrapper>();
    	
    	if( this.actionPlanTemplates != null ){
    		Integer i = 0;
    		for( APTTaskTemplate__c aptTaskTemplate : this.actionPlanTemplates.getTemplateTasks() ){
    			ApTTaskWrapper = new ApTTaskWrapper( aptTaskTemplate, i );
    			tasksList.add( ApTTaskWrapper );
    			i++;
    		}
    		if( this.addedTask ){
    			tasksList.get( i - 1 ).isLast = true;	
    		}	
    	}
    	
    	return tasksList;
	}
	
	/**
	 * Call method getTemplateTaskSize() inside the class ActionPlanTemplates
	 */
	public Integer getTemplateTaskSize(){
		return actionPlanTemplates.getTemplateTaskSize();
	}
	
	/**
	 * Call method getTemplateSubjectItems() inside the class ActionPlanTemplates
	 */
	public List<SelectOption> getTemplateSubjectItems(){
	    return actionPlanTemplates.getTemplateSubjectItems();
	}
	
	/**
    * Checks if Action Plan Tasks has cycling dependency.
    * @return PageReference
    */
    public PageReference checkCycleDependent(){
    	
    	if( this.actionPlanTemplates.checkCycleDependent() ){
    		return null;
    	}
    	else{
    		return this.saveTemplate();
    	}
    }
    
    /**
    * Getter method to return the error message from
    * action plans utilities
    * @return actionPlanTemplates.errorMsg
    */
    public String getErrorMsg(){
    	return actionPlanTemplates.errorMsg;
    }
    
    /**
    * Calculates the highest task index value
    * @return maxIndex
    */
    public Double calculateTaskIndexValue(){
    	
    	List<APTTaskTemplate__c> aptTasks = [ select id, taskIndex__c from APTTaskTemplate__c 
    											where Action_Plan_Template__c =: this.actionPlanTemplateId ];
    	
    	Double maxIndex = 0;
    	for( APTTaskTemplate__c tsk : aptTasks ){
    		if( tsk.taskIndex__c > maxIndex ){
    			maxIndex = tsk.taskIndex__c;
    		}
    	}
    	
    	return maxIndex;
    }
    
    /**
    * Inner Wrapper Class for Action Plan Template Tasks
    * @author Matias Menafra
    * @createddate 08/08/2010
    */
    public class ApTTaskWrapper{
    	
    	public APTTaskTemplate__c task 	{ get; set; }
		public 	Integer 	position 	{ get; set; }
    	public 	Boolean 	isLast 		{ get; set; }
    	
    	public ApTTaskWrapper( APTTaskTemplate__c apTask, Integer pos ){
    		task 		= apTask;
    		position 	= pos;
    		isLast 		= false;
    	}
    }
    
    public static testMethod void testContructor(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	System.currentPageReference().getParameters().put( 'id', null );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	
    	System.currentPageReference().getParameters().put( 'clone', '1' );
    	apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	
    	Test.StopTest();
    }
    
    public static testMethod void testSave(){
    
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= new ActionPlanTemplate__c();
    	
    	apTemplate.Name = testUtil.createRandomWord();
    	
    	APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();
 		
 		newAPTTask.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask.DaysFromStart__c 	= 2;
 		newAPTTask.Type__c 				= 'Email';
 		newAPTTask.Priority__c 			= 'Hight';
 		
		ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( apTemplate ) );
		apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
		Pagereference page = apTemplateController.saveTemplate();
		
		System.assert( page != null );
		
    	Test.StopTest();
    }
    
    public static testMethod void testCancel(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	apTemplateController.cancelTemplate();
    	
    	Test.StopTest();
    }
    
    public static testMethod void testAddTemplateTask(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	apTemplateController.addTemplateTask();
    	
    	Test.StopTest();
    }
    
    public static testMethod void testRemoveTemplateTask(){
    
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	apTemplateController.removeTemplateTask();
    	
    	Test.StopTest();
    }
    
    public static testMethod void testRetrievingTemplateTasks(){
    
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	List<ApTTaskWrapper> taskList =  apTemplateController.getTemplateTasks();
    	
    	//checks that the list is not empty
    	System.assert( !taskList.isEmpty(), 'Task list was not Empty' );
    	
    	Test.StopTest();
    }
    
    public static testMethod void checkTemplateTaskSize(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	List<ApTTaskWrapper> taskList =  apTemplateController.getTemplateTasks();
    	Integer numTasks = apTemplateController.getTemplateTaskSize();
    	
    	//checks that the list is not empty
    	System.assert( !taskList.isEmpty(), 'Task list was not Empty' );
    	
    	//Checks to see if both methods return same task size
    	System.assertEquals( taskList.size(), numTasks );
    	
    	Test.StopTest();
    }
    
    public static testMethod void checkTemplateSubjectItem(){	
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	
    	List<ApTTaskWrapper> taskList	= apTemplateController.getTemplateTasks();
    	List<SelectOption> subjectItems 	= apTemplateController.getTemplateSubjectItems();
    	
    	Test.StopTest();
    }
    
    public static testMethod void testCyclicDependencyFalse(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	APTTaskTemplate__c newAPTTask 	= new APTTaskTemplate__c();
 		APTTaskTemplate__c newAPTTask2 	= new APTTaskTemplate__c();
 		
 		newAPTTask.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask.DaysFromStart__c 	= 2;
 		newAPTTask.Dependent__c			= 'None';
 		newAPTTask.Type__c 				= 'Email';
 		newAPTTask.Priority__c 			= 'High';
 		
 		newAPTTask2.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask2.DaysFromStart__c 	= 2;
 		newAPTTask2.Dependent__c		= 'None';
 		newAPTTask2.Type__c 			= 'Email';
 		newAPTTask2.Priority__c 		= 'High';
 		
 		
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	
    	apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );

    	apTemplateController.checkCycleDependent();
    	
    	System.assert( apTemplateController.getErrorMsg() == '', 'dependency check failed' );
    	
    	Test.StopTest();
    }
    
    public static testMethod void testCyclicDependencySuccess(){
    	
    	Test.StartTest();
    	
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ActionPlanTemplate__c apTemplate 	= testUtil.createNewActionPlanTemplate( 2 );
    	
    	APTTaskTemplate__c newAPTTask 	= new APTTaskTemplate__c();
 		APTTaskTemplate__c newAPTTask2 	= new APTTaskTemplate__c();
 		APTTaskTemplate__c newAPTTask3 	= new APTTaskTemplate__c();
 		
 		newAPTTask.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask.DaysFromStart__c 	= 2;
 		newAPTTask.Dependent__c			= '2';
 		newAPTTask.Type__c 				= 'Email';
 		newAPTTask.Priority__c 			= 'Hight';
 		
 		newAPTTask2.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask2.DaysFromStart__c 	= 2;
 		newAPTTask2.Dependent__c		= '0';
 		newAPTTask2.Type__c 			= 'Email';
 		newAPTTask2.Priority__c 		= 'Hight';
 		
 		newAPTTask3.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask3.DaysFromStart__c 	= 2;
 		newAPTTask3.Dependent__c		= '1';
 		newAPTTask3.Type__c 			= 'Email';
 		newAPTTask3.Priority__c 		= 'Hight';
 		
 		
    	System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
    	ActionPlanTemplateCreationController apTemplateController = new ActionPlanTemplateCreationController( new ApexPages.StandardController( new ActionPlanTemplate__c() ) );
    	
    	apTemplateController.actionPlanTemplates.aptTasks = new List<APTTaskTemplate__c>();
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask );
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask2 );
		apTemplateController.actionPlanTemplates.aptTasks.add( newAPTTask3 );

    	apTemplateController.checkCycleDependent();
    	System.assert( apTemplateController.getErrorMsg() != null, 'dependency check failed' );
    	Test.StopTest();
    }
}