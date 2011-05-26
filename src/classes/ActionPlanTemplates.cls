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
 public with sharing class ActionPlanTemplates{
 	
 	public Double							taskIndexOrder			{ get; set; }
    public ActionPlanTemplate__c    		actionPlanTemplate;
    public List<APTTaskTemplate__c> 		pendingTemplateDeletes;
    public List<APTTaskTemplate__c> 		aptTasks;
    public Map<String, APTTaskTemplate__c> 	taskMap 				{ get; set; }
    public Integer                  		taskLimit;
    public String                   		errorMsg;
    
    /**
    * Constructor
    * @param actionPT
    */
    public ActionPlanTemplates( ActionPlanTemplate__c actionPT ){
    	this.taskMap			= new Map<String, APTTaskTemplate__c>();
    	this.errorMsg			= null;
        this.taskLimit  		= 75;
        this.actionPlanTemplate = actionPT;
    }
    
    /** 
	* Gets all available Action Plan Templates and return a list of ActionPlan__c
	* @return List<ActionPlanTemplate__c>
	\*/
    public List<ActionPlanTemplate__c> getActionPlanTemplates(){
    	
        return [ select a.Id, a.Name, a.Description__c, a.SkipWeekends__c, a.LastModifiedDate, a.LastModifiedBy.Name, 
        			a.LastModifiedById,	a.CreatedDate, a.CreatedBy.Name, a.CreatedById 
        			from ActionPlanTemplate__c a order by a.Name ASC limit 1000 ];
    }
    
    /** 
    * (1)Gets a specific Action Plan based on query Id and return an ActionPlan__c object
    * (2)In case the Id is not passed by URL then create a new instance of the object.
    * (3)Then if the method is called trying to clone an Action Plane Template, clone the template without Id.
    * @return actionPlanTemplate
    */
    public ActionPlanTemplate__c getActionPlanTemplate(){
    	
        if( this.actionPlanTemplate == null ){
            if( ApexPages.currentPage().getParameters().get( 'Id' ) != null ){
                /* (1) */
                String tempApId = ApexPages.currentPage().getParameters().get( 'Id' );
                this.actionPlanTemplate = [ select a.Id, a.Name, a.Description__c, a.SkipWeekends__c, a.SkipDay__c, a.LastModifiedDate, 
                								a.LastModifiedBy.Name, a.LastModifiedById, a.CreatedDate, a.CreatedBy.Name, a.CreatedById, a.Owner.Name 
                								from ActionPlanTemplate__c a 
                								where a.Id =: tempApId ];
            }
            else{
                /* (2) */
                this.actionPlanTemplate = new ActionPlanTemplate__c();
            }
            
            if( ApexPages.currentPage().getParameters().get( 'clone' ) == '1' ){
                /* (3) */
                ActionPlanTemplate__c apC = actionPlanTemplate.clone( false );
                this.actionPlanTemplate.clear();
                this.actionPlanTemplate = apC;
            }
        }
        
        return actionPlanTemplate;
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
        	List<APTTaskTemplate__c> toDelete = new List<APTTaskTemplate__c>();
        	toDelete.addAll( pendingTemplateDeletes );
        	delete toDelete;
        }
        // update Action Plan Template object, in case of exception then rollback the actions with the database
        ActionPlanTemplate__c apt = actionPlanTemplate;
        try{
            upsert apt;
        }catch( exception e ){
            Database.rollback( sp );
            return null;    
        }
        
        // save tasks to the template and attach relation to Action Plan
        for( APTTaskTemplate__c t : aptTasks ){
            if( t.Action_Plan_Template__c == null ){
            	t.Action_Plan_Template__c = apt.Id;
            } 
            if( t.DaysFromStart__c < 1 ){
            	 t.DaysFromStart__c = 1; 
           	}
            t.DaysFromStart__c = math.abs( t.DaysFromStart__c );
        }
        
        try{
            upsert aptTasks;
        }catch( exception e ){
            Database.rollback( sp );
            return null;    
        }
        
        // run through the tasks and take care of dependents
        for( APTTaskTemplate__c t : aptTasks ){
            if( t.Dependent__c != 'None' && t.Dependent__c != null ){
                Integer tempIndex 		= Integer.valueOf( t.Dependent__c );
                t.APTTaskTemplate__c 	= aptTasks[ tempIndex ].Id;
            }
            else{
            	t.APTTaskTemplate__c = null;
            }
        }
        
        try{
            update aptTasks;
        }catch( exception e ){
            Database.rollback( sp );
            return null;    
        }   
        
        // Send the user to the detail page for the new account.
        PageReference newPage = new PageReference( '/apex/ActionPlanTemplateDetail?Id=' + apt.Id );
        newPage.setRedirect( true );
        return newPage;
    }
    
    /** 
    * Deletes the current Action Plan Template loaded and redirects to the AP Template List.
    * @return newPage
    */
    public PageReference deleteTemplate(){
    	
        ActionPlanTemplate__c apt = this.actionPlanTemplate;
        try{
            delete apt;
        } catch( exception e ){
        }
        
        // Send the user to the detail page for the new account.
        PageReference newPage = new PageReference( '/' + Schema.ActionPlanTemplate__c.SObjectType.getDescribe().getKeyPrefix() );
        newPage.setRedirect( true );
        
        return newPage;
    }
    
    /** 
    * Cancel the current Action Plan Template loaded and redirects to the AP Template List.
    * @return newPage
    */
    public PageReference cancelTemplate(){
    	
        PageReference newPage;
        
        if( this.actionPlanTemplate.Id == null ){
        	// Send the user to the list of templates.
            newPage = new PageReference( '/' + Schema.ActionPlanTemplate__c.SObjectType.getDescribe().getKeyPrefix() );
            newPage.setRedirect( true );
        }
        else{
            // Send the user to the detail page for the new account.
            newPage = new PageReference( '/apex/ActionPlanTemplateDetail?Id=' + actionPlanTemplate.Id );
            newPage.setRedirect( true );  
        }
        
        return newPage;
    }
    
    /** 
    * Get all tasks related to the Action Template.
    * @return aptTasks
    */
    public List<APTTaskTemplate__c> getTemplateTasks(){
    	
        if( aptTasks == null || aptTasks.size() == 0 ){
            String TempApId = ApexPages.currentPage().getParameters().get('Id');
            
            if( TempApId != null ) {
                aptTasks = [ select a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c, taskIndex__c,
            				 a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, a.APTTaskTemplate__c,
            				 a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c
            				 From APTTaskTemplate__c a 
            				 where a.Action_Plan_Template__c =: TempApId  order by taskIndex__c ASC ];
            }
            else {
                aptTasks 				= new List<APTTaskTemplate__c>();
                APTTaskTemplate__c t 	= new APTTaskTemplate__c();
                t.Reminder__c	 		= false;
                aptTasks.add( t );
            }
            
            // clone and clear Ids
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
    * Creates a blank Task object and adds it to List<Task>.
    */
    public Boolean addTemplateTask(){
    	
    	Boolean hasNoErrors = false;
    	
        if( ApexPages.currentPage().getParameters().get( 'add' ) == '1' ){
        	
            //in casethe task limit is reach set a message error to display
            if( this.aptTasks.size() >= this.taskLimit ){
                this.errorMsg = Label.ap_Errors_TaskLimitError;
            } 
            else{
                APTTaskTemplate__c t = new APTTaskTemplate__c();
                t.Reminder__c 	= false;
                t.taskIndex__c 	= this.taskIndexOrder;
                
                // validate user, priority, subject and days before adding another
                hasNoErrors = true;
                for( APTTaskTemplate__c apt : aptTasks ){
                	hasNoErrors = ( apt.Priority__c != null && apt.Subject__c != null );
                	if( apt.DaysFromStart__c < 1 ) {
	                	apt.DaysFromStart__c = 1;
	                }
                }
                if( hasNoErrors ){
                    this.aptTasks.add( t );
                    hasNoErrors = true;
                }
                else{
                	hasNoErrors = false;
                }
            }
        }
        
        return hasNoErrors;      
    }
    
    /** 
    * Remove a specific index in the List<APTTaskTemplate__c>.
    */
    public Boolean removeTemplateTask(){
    	
    	Boolean removedTask = false;
        if( ApexPages.currentPage().getParameters().get( 'remove' ) != null ){
            Integer taskIndex       = Integer.valueOf( ApexPages.currentPage().getParameters().get( 'remove' ) );
            
            APTTaskTemplate__c aptTask;
            
            //check for dependent children and clear them since the parent is being removed.
            aptTasks[ taskIndex ].APTTaskTemplate__c    = null;
            aptTasks[ taskIndex ].Dependent__c         	= null;
            
            Integer dependentApTask;
            
           //update the current dependent position from tasks below of deleted one.
            for( Integer i = 0; i < this.aptTasks.size(); i++ ){
            	aptTask = this.aptTasks.get( i );
            	if( aptTask.Dependent__c != 'None' && aptTask.Dependent__c != null ){
            		dependentApTask = Integer.valueOf( aptTask.Dependent__c );
            		if( dependentApTask > taskIndex ){
            			aptTask.Dependent__c = String.valueOf( dependentApTask - 1 );	
            		}else if( dependentApTask == taskIndex ){
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
                pendingTemplateDeletes.add( aptTasks[ taskIndex ] );
            }
            
            aptTasks.remove( taskIndex );
            
            // clear errorMsg if it's set.
            if( aptTasks.size() < taskLimit ){
            	 errorMsg = null;
            }
            removedTask = true;
        }
        
         return removedTask;
    }
    
    /** 
    * Return size of the APT Template Tasks List.
    */
    public Integer getTemplateTaskSize(){
        return aptTasks.size(); 
    }
    
    /** 
    * Creates a SelectOption list of task subjects to be used with creating task dependencies.
    */
    public List<SelectOption> getTemplateSubjectItems(){
    	
        List<SelectOption> options = new List<SelectOption>();
        options.add( new SelectOption( 'None', '--'+ Label.ap_None +'--' ) );
        integer i = 0;
        
        if( this.aptTasks != null ){
            for( APTTaskTemplate__c t : this.aptTasks ){
                 if( t.Subject__c != null ){
                	 options.add( new SelectOption( string.valueOf( i ), t.Subject__c+' ('+ ( i + 1 ) +')' ) );
                }
                i++;
            }
        }
        
        return options;
    }

    /**
    * Checks if Action Plans Tasks has cycling dependency.
    * @return exists
    */
    public Boolean checkCycleDependent(){

    	this.errorMsg 	= '';
    	Boolean exists 	= false;
    	Integer index 	= 0;
        
        for( APTTaskTemplate__c t : this.aptTasks ){
            if( t.Dependent__c != 'None' && t.Dependent__c != null ){
                Integer tempIndex   	= Integer.valueOf( t.Dependent__c );
                APTTaskTemplate__c link = this.aptTasks[tempIndex];
                
                //task can not depend on themselves
                if(tempIndex == index){
                	this.errorMsg = Label.ap_ItselfDependencyError;	
                	return true;
                }
                
                if( this.dependantCycle( t, link, index ) ){
                	this.errorMsg = Label.ap_Errors_RemoveCyclicDependency;	
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
        	
        	if (destinyTask.Dependent__c != 'None'){
        		if (visitedTasks.contains(Integer.valueOf( destinyTask.Dependent__c ))){
        			hasDependency = true;
	        		break;
        		}else{
        			visitedTasks.add(Integer.valueOf( destinyTask.Dependent__c ));
        		}
        	}
        	
			if( destinyTask.Dependent__c != 'None' && destinyTask.Dependent__c != null  ){
				Integer tempIndexDestiny 	= Integer.valueOf( destinyTask.Dependent__c );
				APTTaskTemplate__c link 		= this.aptTasks[ tempIndexDestiny ];
	
				if( link.Dependent__c != 'None' ){
					if( Integer.valueOf( link.Dependent__c ) == index ){
						hasDependency = true;
    					break;
    				}
    				else{
    					//get Next task in dependency chain
    					Integer tempIndex 	= Integer.valueOf( destinyTask.Dependent__c );
    					destinyTask 		= this.aptTasks[ tempIndex ];
    				}	
				}
				else{
					break;
				}
 			}
 			else{
 				break;
			}
    	}

    	return hasDependency;
	} 
	
	/**
    * Verifies that the user is able to add reminders.
    * @return Boolean 
    */
    public Boolean getDisplayReminder(){
    	ActionPlansUtilities apu = new ActionPlansUtilities();
		return apu.getDisplayReminder();
    }
	
	/**
	* Test Methods
	*/
	public static testMethod void constructorTest(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void testRetrievingTemplateTasks(){
		
		//clear all action plan templates
		List<ActionPlanTemplate__c> apTemplateList = [ select id from ActionPlanTemplate__c ];
		delete apTemplateList;
		
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		List<ActionPlanTemplate__c> apTemplates = apTemplate.getActionPlanTemplates();
		
		System.assert( !apTemplates.isEmpty(), 'action plan template list is empty' );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	//TODO finish this test for all condicionals
	public static testMethod void testRetrievingActionPlanTemplate(){
	
		//clear all action plan templates
		List<ActionPlanTemplate__c> apTemplateList = [ select id from ActionPlanTemplate__c ];
		delete apTemplateList;
		
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );

		ActionPlanTemplate__c resultActionPlanTemplate = apTemplate.getActionPlanTemplate();
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	//TODO finish this big method
	public static testMethod void checkSavingActionPlanTemplate(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void testActionPlanTemplateDelete(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		apTemplate.actionPlanTemplate = actionPlanTemplate;
		apTemplate.deleteTemplate();
		
		List<ActionPlanTemplate__c> results = [ select id from ActionPlanTemplate__c where Id =: actionPlanTemplate.Id ];
		
		System.assert( results.isEmpty(), 'Action plan template not deleted' );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void testActionPlanTemplateCancel(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		ActionPlanTemplates apTemplate 	= new ActionPlanTemplates( actionPlanTemplate );
		apTemplate.actionPlanTemplate 	= actionPlanTemplate;
		apTemplate.cancelTemplate();
		
		ActionPlanTemplate__c apTemplate2 = new ActionPlanTemplate__c();
		apTemplate = new ActionPlanTemplates( apTemplate2 );
		apTemplate.cancelTemplate();
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void testRetrievingActionPlanTemplateTasks(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		System.currentPageReference().getParameters().put( 'id', actionPlanTemplate.Id );
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		apTemplate.actionPlanTemplate 			= actionPlanTemplate;
		List<APTTaskTemplate__c> templateTasks 	= apTemplate.getTemplateTasks();
		
		System.assert( !templateTasks.isEmpty(), 'template task list is empty');
		System.assert( templateTasks.size() == 3, 'template tasks size not correct' );
		
		System.currentPageReference().getParameters().put( 'id', null );
		apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		apTemplate.actionPlanTemplate 				= actionPlanTemplate;
		List<APTTaskTemplate__c> templateTasks2 	= apTemplate.getTemplateTasks();
		
		System.assert( !templateTasks2.isEmpty(), 'template task list is empty');
		System.assert( templateTasks2.size() == 1, 'template tasks size not correct' );
		
		System.currentPageReference().getParameters().put( 'clone', '1') ;
		apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		apTemplate.actionPlanTemplate 				= actionPlanTemplate;
		List<APTTaskTemplate__c> templateTasks3 	= apTemplate.getTemplateTasks();
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void testAddNewActionPlanTemplateTask(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		System.currentPageReference().getParameters().put( 'add', '1') ;
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		apTemplate.aptTasks = new List<APTTaskTemplate__c>();
		apTemplate.aptTasks = [ select a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c,
                				 a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, 
                				 a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c 
                				 From APTTaskTemplate__c a 
                				 where a.Action_Plan_Template__c =: actionPlanTemplate.Id ];
		
		Boolean error = apTemplate.addTemplateTask();
		
		System.assert( apTemplate.errorMsg == null, 'A error was returned when adding a template task ');
		
		ActionPlanTemplate__c actionPlanTemplate2 = testUtil.createNewActionPlanTemplate( 75 );
		
		System.currentPageReference().getParameters().put( 'add', '1') ;
		apTemplate 			= new ActionPlanTemplates( actionPlanTemplate );
		apTemplate.aptTasks = new List<APTTaskTemplate__c>();
		apTemplate.aptTasks = [ select a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c,
                				 a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, 
                				 a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c 
                				 From APTTaskTemplate__c a 
                				 where a.Action_Plan_Template__c =: actionPlanTemplate2.Id ];
		
		error = apTemplate.addTemplateTask();
		
		System.assert( apTemplate.errorMsg != null, 'A error was not returned when adding a template task' );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void testRemovingActionPlanTemplateTask(){
		
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		System.currentPageReference().getParameters().put( 'remove', '1') ;
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		apTemplate.aptTasks = new List<APTTaskTemplate__c>();
		apTemplate.aptTasks = [ select a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c,
                				 a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, 
                				 a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c 
                				 From APTTaskTemplate__c a 
                				 where a.Action_Plan_Template__c =: actionPlanTemplate.Id ];
		
		apTemplate.removeTemplateTask();
		
		System.assert( apTemplate.aptTasks.size() == 2, 'Task was not deleted correctly' );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void checkRetrievingTemplateTasks(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 4 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		apTemplate.aptTasks = new List<APTTaskTemplate__c>();
		apTemplate.aptTasks = [ select a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c,
                				 a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, 
                				 a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c 
                				 From APTTaskTemplate__c a 
                				 where a.Action_Plan_Template__c =: actionPlanTemplate.Id ];
                				 
		List<APTTaskTemplate__c> apTemplateTasks = apTemplate.getTemplateTasks();
		
		System.assert( apTemplateTasks.size() == 4, 'Incorrect size returned' );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void checkRetrievingTemplateTasksListSize(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 4 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		apTemplate.aptTasks = new List<APTTaskTemplate__c>();
		apTemplate.aptTasks = [ select a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c,
                				 a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, 
                				 a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c 
                				 From APTTaskTemplate__c a 
                				 where a.Action_Plan_Template__c =: actionPlanTemplate.Id ];
                				 
		List<APTTaskTemplate__c> apTemplateTasks 	= apTemplate.getTemplateTasks();
		Integer numTasks 							= apTemplate.getTemplateTaskSize();
		
		System.assert( apTemplateTasks.size() == numTasks, 'Incorrect size returned' );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void checkRetrievingSubjectItems(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 5 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		apTemplate.aptTasks = new List<APTTaskTemplate__c>();
		apTemplate.aptTasks = [ select a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c,
                				 a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, 
                				 a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c 
                				 From APTTaskTemplate__c a 
                				 where a.Action_Plan_Template__c =: actionPlanTemplate.Id ];
		
		List<Selectoption> options = apTemplate.getTemplateSubjectItems();
		
		System.assert( options.size() == 6 , 'Incorrect Size for select options' );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void testActionPlanTemplateTaskDependencySuccess(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		APTTaskTemplate__c newAPTTask 	= new APTTaskTemplate__c();
 		APTTaskTemplate__c newAPTTask2 	= new APTTaskTemplate__c();
 		
 		newAPTTask.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask.DaysFromStart__c 	= 2;
 		newAPTTask.Dependent__c			= 'None';
 		newAPTTask.Type__c 				= 'Email';
 		newAPTTask.Priority__c 			= 'High';
 		
 		newAPTTask2.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask2.DaysFromStart__c 	= 2;
 		newAPTTask2.Dependent__c		= '0';
 		newAPTTask2.Type__c 			= 'Email';
 		newAPTTask2.Priority__c 		= 'High';
 		
		apTemplate.aptTasks = new List<APTTaskTemplate__c>();
		apTemplate.aptTasks.add( newAPTTask );
		apTemplate.aptTasks.add( newAPTTask2 );		
                				 
        Boolean result = apTemplate.checkCycleDependent();
		
		System.assert( !result, 'Dependency check failed' );
		
		Test.StopTest();
	}
	
	/**
	* Test Methods
	*/
	public static testMethod void testActionPlanTemplateTaskDependencyFail(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		ActionPlanTemplates apTemplate = new ActionPlanTemplates( actionPlanTemplate );
		
		APTTaskTemplate__c newAPTTask 	= new APTTaskTemplate__c();
 		APTTaskTemplate__c newAPTTask2 	= new APTTaskTemplate__c();
 		APTTaskTemplate__c newAPTTask3 	= new APTTaskTemplate__c();
 		
 		newAPTTask.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask.DaysFromStart__c 	= 2;
 		newAPTTask.Dependent__c			= '1';
 		newAPTTask.Type__c 				= 'Email';
 		newAPTTask.Priority__c 			= 'High';
 		
 		newAPTTask2.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask2.DaysFromStart__c 	= 2;
 		newAPTTask2.Dependent__c		= '2';
 		newAPTTask2.Type__c 			= 'Email';
 		newAPTTask2.Priority__c 		= 'High';
 		
 		newAPTTask3.Subject__c 			= testUtil.createRandomWord();
 		newAPTTask3.DaysFromStart__c 	= 2;
 		newAPTTask3.Dependent__c		= '0';
 		newAPTTask3.Type__c 			= 'Email';
 		newAPTTask3.Priority__c 		= 'High';
 		
		apTemplate.aptTasks = new List<APTTaskTemplate__c>();
		apTemplate.aptTasks.add( newAPTTask );
		apTemplate.aptTasks.add( newAPTTask2 );		
		apTemplate.aptTasks.add( newAPTTask3 );		
                				 
        Boolean result = apTemplate.checkCycleDependent();
		
		System.assert( result, 'Dependency did not fail' );
		
		Test.StopTest();
	}
	
	/**
	* Test getActionPlanTemplate Method : 
	*/
	private static testMethod void Run(){
		
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		ActionPlanTemplate__c   apt	= ge.createNewActionPlanTemplate( 5 );
		System.currentPageReference().getParameters().put( 'Id', apt.Id );
		Test.StartTest();
			//Gets a specific Action Plan based on query Id 
			ActionPlanTemplates apTemplate = new ActionPlanTemplates( apt );
			apTemplate.actionPlanTemplate = null;
			apTemplate.getActionPlanTemplate();
			System.assert( apTemplate.actionPlanTemplate != null );
			
			//In case the Id is not passed by URL then create a new instance of the object.
			System.currentPageReference().getParameters().remove( 'Id' );
			apTemplate = new ActionPlanTemplates( apt );
			apTemplate.actionPlanTemplate = null;
			apTemplate.getActionPlanTemplate();
			System.assert( apTemplate.actionPlanTemplate != null );
			
			//Then if the method is called trying to clone an Action Plane Template, clone the template without Id.
			System.currentPageReference().getParameters().put( 'clone', '1' );
			apTemplate = new ActionPlanTemplates( apt );
			apTemplate.actionPlanTemplate = null;
			apTemplate.getActionPlanTemplate();
			System.assert( apTemplate.actionPlanTemplate != null );
		Test.StopTest();
	}
	
	/** 
    * Test Saves Action Plan Template and all tasks
    */
   	private static testMethod void testSaveTemplate(){
   		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
   		ActionPlanTemplate__c   apt	= ge.createNewActionPlanTemplate( 5 );
   		User tUser = ge.createTestUser();
   		ActionPlanTemplates apTemplate = new ActionPlanTemplates( apt );
   		Test.StartTest();

   			apTemplate.pendingTemplateDeletes = new List<APTTaskTemplate__c>();
   			apTemplate.aptTasks = new List<APTTaskTemplate__c>();
   			apTemplate.pendingTemplateDeletes.add( ge.createNewActionPlanTemplateTask(apt, 3, tUser, 'Email', 'High') );
   			apTemplate.aptTasks.add( ge.createNewActionPlanTemplateTask(apt, 3, tUser, 'Email', 'High') );
   			apTemplate.aptTasks.add( ge.createNewActionPlanTemplateTask(apt, 3, tUser, 'Email', 'High') );
   			apTemplate.aptTasks.get(0).Dependent__c = '1';
   			apTemplate.saveTemplate();
   			
   			System.assert( apTemplate.actionPlanTemplate != null );
   			System.assert( !apTemplate.pendingTemplateDeletes.isEmpty() );
   			
   			//Enter to Task Catch()
   			apTemplate.pendingTemplateDeletes = new List<APTTaskTemplate__c>();
   			apTemplate.aptTasks.clear();
			apTemplate.aptTasks.add( new APTTaskTemplate__c( DaysFromStart__c = 3 ) );	
   			apTemplate.saveTemplate();
   			
			System.assert( !apTemplate.aptTasks.isEmpty());
			
			//Enter to APT Catch()
			apTemplate.actionPlanTemplate = null;
   			apTemplate.saveTemplate();
			System.assert( !apTemplate.aptTasks.isEmpty());
   			
   		Test.StopTest();
   	}
}