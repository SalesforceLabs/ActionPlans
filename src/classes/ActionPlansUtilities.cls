/*
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
public with sharing class ActionPlansUtilities{
    
    public Double					taskIndexOrder { get; set; }
    public ActionPlanTemplate__c    actionPlanTemplate;
    public List<APTTaskTemplate__c> aptTasks;
    public ActionPlan__c            actionPlan;
    public List<APTaskTemplate__c>  apTasks;
    public List<APTaskTemplate__c>  apTasksOrg ;
    public String                   errorMsg;
    public List<APTTaskTemplate__c> pendingTemplateDeletes;
    public List<APTaskTemplate__c>  pendingDeletes;
    public Integer                  taskLimit;
    public List<String>             relatedObjIds;
    public String                   relatedObjName;
    public Map<String, String> 		relatedObjOwnerList	{ get; set; }
    
    /**
    * Constructor
    * @param action
    */
    public ActionPlansUtilities( ActionPlan__c action ){
        
        this.pendingDeletes = new List<APTaskTemplate__c>();
        this.actionPlan = action;
        this.taskLimit  = 75;
        this.errorMsg	= null;
        this.relatedObjOwnerList = new Map<String, String>();
    }
    
    /**
    * Constructor
    */
    public ActionPlansUtilities(){}
    
    /**
    * Gets the related Object Name
    * @return String
    */
    public String getRelatedObjName(){
        return  this.relatedObjName;
    }
    
    /**
    * Gets the related Object Ids
    * @return relatedObjIds
    */
    public List<String> relatedObjIds(){
        return  this.relatedObjIds;
    }
    
    /**
    * Gets all available Action Plans
    * @return List<ActionPlan__c>
    */
    public List<ActionPlan__c> getActionPlans(){
        
        return [ select a.Id, a.Name, a.CreatedById, a.StartDate__c, a.Action_Plan_Template__r.Name, a.Action_Plan_Template__r.Id, 
                    a.Action_Plan_Template__c, a.Account__c, a.Contact__c, a.Lead__c, a.Opportunity__c ,
                    a.Contract__c, a.Case__c, a.Campaign__c 
                    from ActionPlan__c a limit 1000 ];
    }
    
    /**
    * Checks if Action Plan Tasks has cycling dependency.
    * @return exists
    */
    public Boolean checkCycleDependent(){
    	
        this.errorMsg 	= '';
    	Boolean exists 	= false;
    	Integer index 	= 0;
        
        for( APTaskTemplate__c t : this.apTasks ){
            if( t.Dependent__c != 'None' && t.Dependent__c != null ){
                Integer tempIndex   	= Integer.valueOf( t.Dependent__c );
                APTaskTemplate__c link 	= this.apTasks[tempIndex];
                
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
    * Check for cyclic dependent tasks
    * @param originTask
    * @param destinyTask
    * @param index
    * @return Boolean 
    */
    private Boolean dependantCycle( APTaskTemplate__c originTask, APTaskTemplate__c destinyTask, Integer index ){
        
        Boolean hasDependency = false;
        
        while( !hasDependency ){
    		 if( destinyTask.Dependent__c != 'None' && destinyTask.Dependent__c != null  ){
                Integer tempIndexDestiny 	= Integer.valueOf( destinyTask.Dependent__c );
        		APTaskTemplate__c link 		= this.apTasks[ tempIndexDestiny ];
        		
        		if( link.Dependent__c != 'None' ){
	        		if( Integer.valueOf( link.Dependent__c ) == index ){
		        		hasDependency = true;
		        		break;
		        	}
		        	else{
		        		//gets Next task in dependency chain
		        		Integer tempIndex 	= Integer.valueOf( destinyTask.Dependent__c );
		        		destinyTask 		= this.apTasks[ tempIndex ];
		        	}	
        		}
        		else{
        			break;
        		}
    		 }else{
    		 	break;
    		 }
    	}
    	
    	return hasDependency;
    } 
    
    /**
    * Saves Action Plan Instance and task. Also creates all due dates for tasks, then redirects to the AP list
    */
    public void saveAp(){

        Savepoint sp = Database.setSavepoint();
        
        //check for pendingDeletes
        this.checkPendingDeletes();
        
        ActionPlan__c ap = this.actionPlan;
        
        if( ApexPages.currentPage().getParameters().get( 'refType' ) != null ){
            String oName 	= ApexPages.currentPage().getParameters().get( 'refType' );
            String oId 		= ApexPages.currentPage().getParameters().get( 'refId' );
            
            if( 'Account'.equalsIgnoreCase( oName ) ){
                ap.Account__c = oId;
            }
            if( 'Contact'.equalsIgnoreCase( oName ) ){
                ap.Contact__c = oId;
            }
            if( 'Lead'.equalsIgnoreCase( oName ) ){
                ap.Lead__c = oId;
            }
            if( 'Opportunity'.equalsIgnoreCase( oName ) ){
                ap.Opportunity__c = oId;
            }
            
            //Add new version Support to Cases , Contracts ans Campaigns
            if( 'Case'.equalsIgnoreCase( oName ) ){
                ap.Case__c = oId;
            }
            if( 'Contract'.equalsIgnoreCase( oName ) ){
                ap.Contract__c = oId;
            }
            if( 'Campaign'.equalsIgnoreCase( oName ) ){
                ap.Campaign__c = oId;
            }
        }

        try{
        	upsert ap;
        }catch(DmlException e){
        	if(e.getDmlStatusCode(0) == String.valueOf(Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION)){
        		throw new FieldCustomValidationException(e);
        		
        	}else{
        		throw e;	
        	}
        	Database.rollback( sp );
        }
        
        // save tasks to the template and attach relation to Action Plan
        for( APTaskTemplate__c t : this.apTasks ){
            if( t.Action_Plan__c == null ){
                t.Action_Plan__c = ap.Id;
            }
            
            if( t.User__c == null ){
            	t.User__c = this.getRecordOwnerId( ap );
           	}
            t.Name = ap.Name + ' ' + Label.ap_DefaultTaskName;
        }
        
        try {
            upsert this.apTasks;
        }
        catch( exception e ) {
        	throw e;
            Database.rollback( sp );
            
        }
        
        // run through the tasks and take care of dependents - not done in the previous because we need the Ids
        for( APTaskTemplate__c t : this.apTasks ){
            if( t.Dependent__c != 'None' && t.Dependent__c != null ){ // setup dependency
                Integer tempIndex   = Integer.valueOf( t.Dependent__c );
                t.APTaskTemplate__c = apTasks[tempIndex].Id;
            }
            else{
                t.APTaskTemplate__c = null;
                // create due date
                // calculate the due date of the tasks for skip weekends feature
                if( t.Status__c == null ){
                    t.Status__c = 'Not Started';
                } 
                
                if( ap.SkipWeekends__c == true ){
                    
                    Date dueDate    = ap.StartDate__c.addDays( t.DaysFromStart__c.intValue() );
                    Integer addDays = t.DaysFromStart__c.intValue();
                    
                    // find if the due date fall on a Saturday or Sunday.  Add 1 day for Sunday and 2 for Saturday
                    Date refDate        = Date.newInstance( 1900, 1, 7 );  // Jan 7 1900 = Sun
                    Integer dayOfWeek   = Math.mod(refDate.daysBetween( dueDate ), 7 ); // 0 = Sun ... 6 = Sat
                    
                    if( ap.SkipDay__c == Label.ap_Friday ){ 
                        // push to friday
                        if( dayOfWeek == 0 ) addDays = addDays - 2;
                        if( dayOfWeek == 6 ) addDays--;
                    } 
                    else{ 
                        // push to monday
                        if( dayOfWeek == 0 ){
                            addDays++;
                        } 
                        if( dayOfWeek == 6 ){
                            addDays = addDays + 2;
                        } 
                    }
                    
                    t.ActivityDate__c = ap.StartDate__c.addDays( addDays );
                } 
                else{
                    t.ActivityDate__c = ap.StartDate__c.addDays( t.DaysFromStart__c.intValue() );
                }
            }
        }
        
        try{
            upsert this.apTasks;
        } 
        catch( exception e ){
            Database.rollback( sp );
            throw e;
        }
        
        List<Task> myTasksWithEmail         = new List<Task>();
        List<Task> myTasksWithOutEmail      = new List<Task>();
        
        Map<Id,Task> tasksMap = getTasksFromAPTaskTemplates(this.apTasks);
        
        // run through tasks again and create actual tasks with due dates
        for( APTaskTemplate__c apTask : this.apTasks ){
            if( apTask.APTaskTemplate__c == null ){ 
                // check for no dependency
                if( apTask.Status__c != 'Completed' ){ 
                    // if the task is competed already make no changes to it
                    Task t = tasksMap.get(apTask.Id);
                    
                    // check if task exists already
                    if(t == null){
                        t = new Task();
                    }
                    
                    t.Subject           = apTask.Subject__c;
                    t.Priority          = apTask.Priority__c;
                    t.OwnerId           = apTask.User__c;
                    t.TaskTemplateId__c = apTask.Id; 
                    
                    // fake link to AP Task Template
                    if( apTask.Comments__c != null ){
                        t.Description = apTask.Comments__c;
                    } 

                    if( apTask.Reminder__c == true ){
                        t.isReminderSet = apTask.Reminder__c;
                        datetime dt = datetime.newInstance( apTask.ActivityDate__c.year(), apTask.ActivityDate__c.month(), apTask.ActivityDate__c.day(), 0, 0, 0 );
                        t.ReminderDateTime = dt;
                        t.ReminderDateTime = t.ReminderDateTime.addMinutes( Integer.valueOf( apTask.Minutes_Reminder__c ) );                         
                    }               
                    
                    //link to Action Plan's Related To Object
                    if( ap.Account__c != null ) { 
                        t.WhatId = ap.Account__c;
                    } 
                    
                    if( ap.Contact__c != null ){
                        t.WhoId = ap.Contact__c;
                    } 
                    
                    if( ap.Lead__c != null ){
                        t.WhoId = ap.Lead__c;
                    } 
                    
                    if( ap.Opportunity__c != null ){
                        t.WhatId = ap.Opportunity__c;
                    }
                    
                    if( ap.Case__c != null ){
                        t.WhatId = ap.Case__c;
                    }
                    if( ap.Campaign__c != null ){
                        t.WhatId = ap.Campaign__c;
                    }
                    if( ap.Contract__c != null ){
                        t.WhatId = ap.Contract__c;
                    }
                    
                    
                    t.Type			= apTask.Type__c;
                    t.Status        = 'Not Started';
                    t.ActivityDate  = apTask.ActivityDate__c;

                    // check for send email notification checkbox
                    if( apTask.SendEmail__c && t.Id == null ){
                        myTasksWithEmail.add( t );
                    }
                    else{
                        myTasksWithOutEmail.add( t );
                    }
                }
            }   
            
            try{                        
                    if( myTasksWithEmail.size() > 0 ){
                        Database.DMLOptions dmlo = new Database.DMLOptions();
                        dmlo.EmailHeader.triggerUserEmail = true;
                        database.insert( myTasksWithEmail, dmlo );
                    }
                    
                    if( myTasksWithOutEmail.size() > 0 ){
                        upsert( myTasksWithOutEmail );
                    }
                } 
                catch( exception e ){
                    Database.rollback( sp );   
                    throw e;
                }
        }
    }
    
    /**
    * Check if have Task pending to delete
    */
    public void checkPendingDeletes(){
         
        if( this.pendingDeletes != null ) {
            List<Task>  taskToDelete    = new List<Task>();
            List<Id>    deleteApttIds   = new List<Id>();
            
            for( APTaskTemplate__c deleteAptt : this.pendingDeletes ){
                deleteApttIds.add(deleteAptt.Id);
            }
            
            taskToDelete = [ select t.Id from Task t where t.TaskTemplateId__c IN : deleteApttIds ];
            
            delete taskToDelete;
            delete pendingDeletes;
        }
    }
    
    /**
    * Saves Action Plan Instance and tasks and redirects to that detail page
    * @return newPage
    */
    public PageReference save(){
    	
       	try {
        	saveAp();
        }
        catch ( DmlException e ){
        	throw e;
        	return null;
        }
        
        String oId	 = ApexPages.currentPage().getParameters().get( 'refId' );		
		PageReference newPage = new PageReference( ( oId != null && oId != '' ) ? '/' + oId : '/apex/ActionPlanList' );
        newPage.setRedirect( true );
        
        return newPage;
    }

    /**
    * Saves Action Plan Handler.
    * @return Pagereference called Method
    */
    public PageReference saveHandler(){
        
        String oIds = ApexPages.currentPage().getParameters().get( 'refId' );
        List<String> oIdsList = new List<String>();
        
        if( oIds != null ){
            oIdsList = oIds.split(',');
            return  ( oIdsList.size() > 1 ) ? this.saveMultiple() : this.save();
        }
        else{
            return this.save();
        }
    }  
    
    /**
    * Save Action Plans for Multiple Related Object Instances.
    * @return Pagereference
    */
    public PageReference saveMultiple(){
        
        String oName                    = ApexPages.currentPage().getParameters().get( 'refType' );
        String oIds                     = ApexPages.currentPage().getParameters().get( 'refId' );
        List<ActionPlan__c> apList      = new List<ActionPlan__c>();
        List<APTaskTemplate__c> aptList = new List<APTaskTemplate__c>();
        
        if( ( oName != null || oName != '' ) && ( oIds != null || oIds != '' ) ){
            
            Savepoint sp = Database.setSavepoint();
            List<String> oIdsList = oIds.split(',');

            //Save all AP instance for the current Object and return a List of inserted ap
            apList = this.saveActionPlanObj( oIdsList );
            upsert apList;
            //End of Save all Ap
            
            
            //Now for each inserted AP we should run through tasks and create them
            this.apTasksOrg = new List<APTaskTemplate__c>();
            this.apTasksOrg.addAll( this.apTasks );
            this.apTasks.clear();
            
            for( ActionPlan__c apl : apList ){ 
                this.apTasks.addAll( this.saveAPTaskObj( apl, sp ) );
            }
            
            Database.upsert( this.apTasks );

            List<String> apTasksIds = new List<String>();
            for( APTaskTemplate__c aptt : this.apTasks ){
                apTasksIds.add( aptt.Id );
            }
            
            ActionPlansBatchTaskBuilder taskBatch = new ActionPlansBatchTaskBuilder( apTasksIds );
            Database.ExecuteBatch( taskBatch );
            //End of Save all Task
        }
        
        PageReference newPage = new PageReference( '/' + this.getObjectKeyPrefix( oName ) ); 
        newPage.setRedirect( true );
        
        return newPage;
    }
    
    /**
    * Saves Action Plan Instance.
    * @return List<APTaskTemplate__c>
    */
    public List<APTaskTemplate__c> saveAPTaskObj( ActionPlan__c ap, Savepoint sp ){
        
        List<APTaskTemplate__c> aptList = new List<APTaskTemplate__c>();
        
        //Now for each inserted ap we should run through tasks and create them
            for( APTaskTemplate__c t : this.apTasksOrg ) {            	
                APTaskTemplate__c nt = new APTaskTemplate__c();
                nt = t.clone(); 
                nt.Action_Plan__c       = ap.Id;
                nt.Name                 = ap.Name + ' - ' + Label.ap_DefaultTaskName;
                nt.User__c				= ( nt.User__c != null ) ? nt.User__c : this.getRecordOwnerId( ap );
                aptList.add( nt );
            }
            insert aptList;
        //End of Save all Task
        
        //Now run through the tasks and take care of dependents - not done in the previous because we need the Ids
        for(APTaskTemplate__c t : aptList ){
            
            if( t.Dependent__c != 'None' && t.Dependent__c != null ){
                    Integer tempIndex   = Integer.valueOf( t.Dependent__c );
                    t.APTaskTemplate__c = aptList[tempIndex].Id;
            }
            else{ 
                // create due date
                // calculate the due date of the tasks for skip weekends feature
                if( t.Status__c == null ){
                    t.Status__c = 'Not Started';
                } 
                
                if( ap.SkipWeekends__c == true ){
                    
                    Date dueDate    = ap.StartDate__c.addDays( t.DaysFromStart__c.intValue() );
                    Integer addDays = t.DaysFromStart__c.intValue();
                    
                    // find if the due date fall on a Saturday or Sunday.  Add 1 day for Sunday and 2 for Saturday
                    Date refDate        = Date.newInstance(1900, 1, 7);  // Jan 7 1900 = Sun
                    Integer dayOfWeek   = Math.mod(refDate.daysBetween(dueDate), 7); // 0 = Sun ... 6 = Sat
                    
                    if( ap.SkipDay__c.equalsIgnoreCase( Label.ap_Friday ) ){ 
                        // push to friday
                        addDays = ( dayOfWeek == 0 ) ? addDays - 2 : addDays ;
                        addDays = ( dayOfWeek == 6 ) ? addDays-- : addDays ;
                    } 
                    else{ 
                        // push to monday
                        addDays = ( dayOfWeek == 0 ) ? addDays++   : addDays ;
                        addDays = ( dayOfWeek == 6 ) ? addDays + 2 : addDays ; 
                    }
                    t.ActivityDate__c = ap.StartDate__c.addDays( addDays );
                } 
                else{
                    t.ActivityDate__c = ap.StartDate__c.addDays( t.DaysFromStart__c.intValue() );
                }
            }
        }
        
        //End dependents 
        return aptList;
    }
    
    /**
    * Saves Action Plan Instance.
    * @return List<ActionPlan__c>
    */
    public List<ActionPlan__c> saveActionPlanObj( List<String> oIdsList ){
        
        List<ActionPlan__c> apAux = new List<ActionPlan__c>();
        String oName 	= ApexPages.currentPage().getParameters().get( 'refType' );
        String oIds 	= ApexPages.currentPage().getParameters().get( 'refId' );
        
        for( String relObjId : oIdsLIst ){
            ActionPlan__c ap = new ActionPlan__c();
            ap = this.actionPlan.clone();
                
            if( 'Account'.equalsIgnoreCase( oName ) ){
                ap.Account__c = relObjId;
            }
            
            if( 'Contact'.equalsIgnoreCase( oName ) ){
                ap.Contact__c = relObjId;
            }
            
            if( 'Lead'.equalsIgnoreCase( oName ) ){
                ap.Lead__c = relObjId;
            }
            
            if( 'Opportunity'.equalsIgnoreCase( oName ) ){
                ap.Opportunity__c = relObjId;
            }
            
            //Add Support for EE / UE Version 
            if( 'Case'.equalsIgnoreCase( oName ) ){
                ap.Case__c = relObjId;
            }
            if( 'Campaign'.equalsIgnoreCase( oName ) ){
                ap.Campaign__c = relObjId;
            }
            if( 'Contract'.equalsIgnoreCase( oName ) ){
                ap.Contract__c = relObjId;
            }
            
            apAux.add(ap);
        }

        return apAux;
    }
     
    /**
    * Saves Action Plan Instance and tasks and returns to the creation page with the previous Action Plan's details.
    * @return newPage
    */
    public PageReference saveAndNew(){
        saveAp();
        PageReference newPage = new PageReference( '/apex/ActionPlanCreation?' + 'clone=1' );
        newPage.setRedirect( true );
        
        return newPage;
    }

    /**
    * Gets Tasks related to an Action Plan
    * @return apTasks
    */
    public List<APTaskTemplate__c> getTasks(){
        
        if( this.apTasks == null || this.apTasks.size() == 0 ) {
            if( ApexPages.currentPage().getParameters().get( 'templateId' ) != null ){
                String tempApId = ApexPages.currentPage().getParameters().get( 'templateId' );
                 
                aptTasks = [ select a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c, a.User__r.Name, a.Id, 
                                a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, a.APTTaskTemplate__r.Subject__c, 
                                a.Reminder__c, a.SendEmail__c, a.Comments__c, a.Minutes_Reminder__c, a.taskIndex__c, a.Time_Reminder__c
                                From APTTaskTemplate__c a
                                where a.Action_Plan_Template__c =: TempApId order by taskIndex__c ASC ];
                
                this.apTasks = new List<APTaskTemplate__c>();
                
                Action_Plans_Settings__c mySettings = this.getCustomSetting();
                String userId; 
                for( APTTaskTemplate__c aptTask : aptTasks ){
                	//Read de Custom Settings in order to asign the User to that Task
					if( aptTask.User__c != null ) { 
						userId = aptTask.User__c ; 
					}
					else if( aptTask.User__c == null && ( mySettings != null && !mySettings.Unassigned_Task_Default__c ) ) {
						userId = UserInfo.getUserId();
					}
					else if( aptTask.User__c == null && ( mySettings != null &&  mySettings.Unassigned_Task_Default__c ) ) {
						userId = null;
					} 
					
                    APTaskTemplate__c t 	= new APTaskTemplate__c();
                    t.Type__c           	= aptTask.Type__c;
                    t.Subject__c        	= aptTask.Subject__c;
                    t.Priority__c       	= aptTask.Priority__c;
                    t.Dependent__c      	= aptTask.Dependent__c;
                    t.taskIndex__c			= aptTask.taskIndex__c;
                    t.Name             	 	= aptTask.Name;
                    t.DaysFromStart__c  	= aptTask.DaysFromStart__c;
					t.Minutes_Reminder__c 	= aptTask.Minutes_Reminder__c;
                    t.User__c           	= userId;
                    t.Reminder__c       	= aptTask.Reminder__c;
                    t.SendEmail__c      	= aptTask.SendEmail__c;
                    t.Comments__c       	= aptTask.Comments__c;
                    this.apTasks.add( t );
                }
            }else if( ApexPages.currentPage().getParameters().get( 'Id' ) != null ){
            	String TempApId = ApexPages.currentPage().getParameters().get( 'Id' );
                this.apTasks = this.retrieveTaskFromExistingActionPlan( TempApId );            
            }
            else{
                this.apTasks        	= new List<APTaskTemplate__c>();
                APTaskTemplate__c t 	= new APTaskTemplate__c();
                t.Reminder__c 			= true;
                t.Minutes_Reminder__c 	= '510';
                this.apTasks.add( t );
            }
            
            // Clone. Clear Ids.
            if( ApexPages.currentPage().getParameters().get( 'clone' ) == '1' ){ 
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
    * Creates a blank Task object and adds it to List<Task>
    */
    public Boolean addTask(){
    	
    	Boolean hasNoErrors = true;
    	if( this.apTasks.size() >= taskLimit ){
       		errorMsg = Label.ap_Errors_TaskLimitError;
       	}
       	else{
       		APTaskTemplate__c t = new APTaskTemplate__c();
            t.Reminder__c 		= true;
            t.Name 				= null;
            t.taskIndex__c 		= this.taskIndexOrder;
            
            // validate user, priority, subject and days before adding another
            Action_Plans_Settings__c mySettings = this.getCustomSetting();
            for( APTaskTemplate__c apt : apTasks ) {
            	hasNoErrors = ( ( apt.User__c != null || mySettings.Unassigned_Task_Default__c ) && apt.Subject__c != null );
            	if( apt.DaysFromStart__c < 1 ) { apt.DaysFromStart__c = 1; }
            }
            if( hasNoErrors ){  this.apTasks.add( t ); }
             
		}   
		
		return hasNoErrors;
    }
    
    /**
    * Remove a specific index in the List<Task>
    */
    public Boolean removeTask(){
    	
        Boolean removedTask = false;
        if( ApexPages.currentPage().getParameters().get( 'remove' ) != null ){
            Integer taskIndex       = Integer.valueOf( ApexPages.currentPage().getParameters().get( 'remove' ) );
            
            //check for dependent children and clear them since the parent is being removed.
            apTasks[ taskIndex ].APTaskTemplate__c    = null;
            apTasks[ taskIndex ].Dependent__c         = null;
            
            APTaskTemplate__c apTask;
            Integer dependentApTask;

            //update the current dependent position from tasks below of deleted one.
            for( Integer i = 0; i < this.apTasks.size(); i++ ){
            	apTask = this.apTasks.get( i );
            	if( apTask.Dependent__c != 'None' && apTask.Dependent__c != null ){
            		dependentApTask = Integer.valueOf( apTask.Dependent__c );
            		if( dependentApTask > taskIndex ){
            			apTask.Dependent__c = String.valueOf( dependentApTask - 1 );	
            		}else if( dependentApTask == taskIndex ){
            			apTask.Dependent__c 		= 'None';
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
            if( this.apTasks.size() < taskLimit ){
                 errorMsg = null;
            }
            removedTask = true;
        }
        
        return removedTask;
    }
    
    /**
    * Retrieves size of APT Template Tasks List.
    * @return apTasks
    */
    public Integer getTaskSize(){
        return this.apTasks.size();  
    }
    
    /**
    * creates a selectList of task subjects to be used with creating task dependencies.
    * @return options
    */
    public List<SelectOption> getSubjectItems(){
        
        List<SelectOption> options = new List<SelectOption>();
        options.add( new SelectOption( 'None', '--'+ Label.ap_None +'--' ) );
        integer i = 0;
        
        if( this.apTasks != null ){
            for( APTaskTemplate__c t : this.apTasks ){
                if( t.Subject__c != null ){
                     options.add(new SelectOption( string.valueOf(i), t.Subject__c+' ('+ (i+1) +')') );
                }
                i++;
            }
        }
        
        return options;
    }
    
    /**
    * Retrieves number of completed tasks
    * @return ts
    */
    public Integer getCompleted(){
        
        List<APTaskTemplate__c> ts = new List<APTaskTemplate__c>();
        String tempApId = ApexPages.currentPage().getParameters().get('Id');
        
        ts = [ select t.Id 
                From APTaskTemplate__c t 
                where t.Status__c = 'Completed' and t.ActivityDate__c != null and t.Action_Plan__c =: tempApId ];
        
        return ( ts != null ) ? ts.size() : 0;
    }
    
    /**
    * Deletes the current Action Plan loaded and redirects tot he AP Template List
    * @return newPage
    */
    public PageReference deletePlan(){
        
        Savepoint sp        = Database.setSavepoint();
        ActionPlan__c ap    = actionPlan;
        List<APTaskTemplate__c> aptts = [ select a.Id from APTaskTemplate__c a where a.Action_Plan__c =: ap.Id ];
        
        //delete tasks by cycling through aptts
        for( APTaskTemplate__c aptt : aptts ){
            Task[] testT = [ select t.Id from Task t where TaskTemplateId__c =: aptt.Id ];
            
            if( testT.size() > 0 ){
                try{
                    delete testT[0];
                }catch( exception e ){
                    Database.rollback( sp );
                }
            }
        }
        
        //delete ap, which will also delete aptts via master-detail relationship
        try{
            delete ap;
        } catch( exception e ){
            Database.rollback( sp );
        }
        
        // Send the user to the detail page for the new account.
        PageReference newPage = new PageReference( '/apex/ActionPlanList' );
        newPage.setRedirect( true );
        
        return newPage;
    }
    
    /**
    * Checks if Action Plan Template has been changed since the creation of the Action Plan.
    * @return Boolean
    */
    public Boolean getVersion(){
        if( actionPlan.Action_Plan_Template__c != null ){
            ActionPlanTemplate__c TempApt = [ select LastModifiedDate from ActionPlanTemplate__c where Id =: actionPlan.Action_Plan_Template__c];                                
            if( TempApt.LastModifiedDate > actionPlan.createdDate ){
                return true;
            }  
        }
        return false;
    }
    
    /**
    * Get the "Default" Custom Setting and return it.
    * @return cSetting
    */
    public Action_Plans_Settings__c getCustomSetting(){
    	Action_Plans_Settings__c instance = Action_Plans_Settings__c.getInstance();
    	if(instance == null){
    		instance = new Action_Plans_Settings__c();
    	}
    	return instance;
    }
    
    /**
    * Get prefix of sObject
    * @param objName
    * @return obj.getKeyPrefix()
    */
    public String getObjectKeyPrefix( String objName ){
    	Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get( objName ).getDescribe();
    	return obj.getKeyPrefix();
    }
    
    /**
    * Returns the plain Text for the ObjectFeed 
    * @parm : objName
    * @return fText
    */
    public String getPostObjectBody( String objName  ){
    	Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get( objName ).getDescribe();
    	return Label.ap_PostMessage +' '+ obj.getLabel() +'!';
    }
    
    /**
    * Generate a New FeedPost for the Action Plan param
    * @parm : ap
    * @return oFeed
    */
    public FeedPost generateObjectFeed( ActionPlan__c ap ){
    	
    	String objId;
    	String objName;
    	if( ap.Account__c != null ) 			{ objId = ap.Account__c; objName = 'Account'; }
    	else if( ap.Campaign__c != null ) 		{ objId = ap.Campaign__c; objName = 'Campaign'; }
    	else if( ap.Case__c != null ) 			{ objId = ap.Case__c; objName = 'Case'; }
    	else if( ap.Contract__c != null ) 		{ objId = ap.Contract__c; objName = 'Contract'; }
    	else if( ap.Opportunity__c != null ) 	{ objId = ap.Opportunity__c; objName = 'Opportunity'; }
    	else if( ap.Contact__c != null ) 		{ objId = ap.Contact__c; objName = 'Contact'; }
    	else if( ap.Lead__c != null ) 			{ objId = ap.Lead__c; objName = 'Lead'; }
    	
    	FeedPost oFeed 	= new FeedPost();
    	oFeed.Type 		= 'TextPost';
		oFeed.ParentId 	= objId;
		oFeed.Body		= this.getPostObjectBody( objName );
    	return oFeed;
    }
    
    
    /**
    * Read the Action Plan Object and get the Related Record Owner
    * @return rOwner
    */
    public String getRecordOwnerId( ActionPlan__c ap ){
    	
    	String recoveredValue;
    	String objId;
    	if( ap.Account__c != null ) 		{ objId = ap.Account__c; }
    	else if( ap.Campaign__c != null ) 	{ objId = ap.Campaign__c;}
    	else if( ap.Case__c != null ) 		{ objId = ap.Case__c;}
    	else if( ap.Contract__c != null ) 	{ objId = ap.Contract__c; }
    	else if( ap.Opportunity__c != null ){ objId = ap.Opportunity__c; }
    	else if( ap.Contact__c != null ) 	{ objId = ap.Contact__c;}
    	else if( ap.Lead__c != null ) 		{ objId = ap.Lead__c; }
    	recoveredValue = relatedObjOwnerList.get( objId );
	   	
	   	if( recoveredValue == null ){
	   		recoveredValue = relatedObjOwnerList.get( truncateId(objId) );
	   	}
	   	
	   	return recoveredValue;
    }
    
    /**
    * Get the Name of Related Object in current Action Plan and then check if it is enabled for FeedPost
    * @return this.isFeedEnabled( objName )
    */
    public Boolean isObjectEnabledFeed( ActionPlan__c ap ){
    	
    	String objName;
    	if( ap.Account__c != null ) 		{ objName = 'Account'; }
    	else if( ap.Campaign__c != null ) 	{ objName = 'Campaign';}
    	else if( ap.Case__c != null ) 		{ objName = 'Case';}
    	else if( ap.Contract__c != null ) 	{ objName = 'Contract'; }
    	else if( ap.Opportunity__c != null ){ objName = 'Opportunity'; }
    	else if( ap.Contact__c != null ) 	{ objName = 'Contact';}
    	else if( ap.Lead__c != null ) 		{ objName = 'Lead'; }
    	return this.isFeedEnabled( objName );
    }
    
    /**
    * Check if the Object is enabled for FeedPost
    * @return obj.isFeedEnabled()
    */
    public Boolean isFeedEnabled( String objName ){
    	Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get( objName ).getDescribe();
    	return obj.isFeedEnabled();
    }
    
    /**
    * Return a map the task associated with a value in the TaskTemplateId__c in sobject task.
    * @param aptTasks	a list of APTaskTemplate__c custom object 
    * @return 			a map with key equals TaskTemplateId__c field an value the task associated.
    */
    private Map<Id,Task> getTasksFromAPTaskTemplates( List<APTaskTemplate__c> aptTasks ){
    	
    	Set<Id> aPTTempIdsSet = new Set<Id>();
		for( APTaskTemplate__c apTask : aptTasks ){
			aPTTempIdsSet.add( apTask.Id );
		}
		
		Map<Id,Task> tasksMap = new Map<Id, Task>([ select t.Id , t.TaskTemplateId__c from Task t where t.TaskTemplateId__c IN : aPTTempIdsSet ]);
		
		// create a map with key TaskTemplateId
		Map<Id,Task> tasksRefTemplateMap = new Map<Id,Task>();
		for( Task task : tasksMap.values() ){
			tasksRefTemplateMap.put( task.TaskTemplateId__c, task );
		}
		
		return tasksRefTemplateMap; 
    }
    
     /**
    * Set the Hours for select box of Remainder Hour
    * @return options
    */
    public List<SelectOption> getHoursOption() {
    	
 	 	List<SelectOption> options = new List<SelectOption>();
 	 	options.add( new SelectOption( '30' , '12:30 AM' ) );
		options.add( new SelectOption( '60' , '1:00 AM'  ) );
		options.add( new SelectOption( '90' , '1:30 AM'  ) );
		options.add( new SelectOption( '120', '2:00 AM'  ) );
		options.add( new SelectOption( '150', '2:30 AM'  ) );
		options.add( new SelectOption( '180', '3:00 AM'  ) );
		options.add( new SelectOption( '210', '3:30 AM'  ) );
		options.add( new SelectOption( '240', '4:00 AM'  ) );
		options.add( new SelectOption( '270', '4:30 AM'  ) );
		options.add( new SelectOption( '300', '5:00 AM'  ) );
		options.add( new SelectOption( '330', '5:30 AM'  ) );
		options.add( new SelectOption( '360', '6:00 AM'  ) );
		options.add( new SelectOption( '390', '6:30 AM'  ) );
		options.add( new SelectOption( '420', '7:00 AM'  ) );
		options.add( new SelectOption( '450', '7:30 AM'  ) );
		options.add( new SelectOption( '480', '8:00 AM'  ) );
		options.add( new SelectOption( '510', '8:30 AM'  ) );
		options.add( new SelectOption( '540', '9:00 AM'  ) );
		options.add( new SelectOption( '570', '9:30 AM'  ) );
		options.add( new SelectOption( '600', '10:00 AM' ) );
		options.add( new SelectOption( '630', '10:30 AM' ) );
		options.add( new SelectOption( '660', '11:00 AM' ) );
		options.add( new SelectOption( '690', '11:30 AM' ) );
		options.add( new SelectOption( '720', '12:00 PM' ) );
		options.add( new SelectOption( '750', '12:30 PM' ) );
		options.add( new SelectOption( '780', '1:00 PM'  ) );
		options.add( new SelectOption( '810', '1:30 PM'  ) );
		options.add( new SelectOption( '840', '2:00 PM'  ) );
		options.add( new SelectOption( '870', '2:30 PM'  ) );
		options.add( new SelectOption( '900', '3:00 PM'  ) );
		options.add( new SelectOption( '930', '3:30 PM'  ) );
		options.add( new SelectOption( '960', '4:00 PM'  ) );
		options.add( new SelectOption( '990', '4:30 PM'  ) );
		options.add( new SelectOption( '1020', '5:00 PM' ) );
		options.add( new SelectOption( '1050', '5:30 PM' ) );
		options.add( new SelectOption( '1080', '6:00 PM' ) );
		options.add( new SelectOption( '1110', '6:30 PM' ) );
		options.add( new SelectOption( '1140', '7:00 PM' ) );
		options.add( new SelectOption( '1170', '7:30 PM' ) );
		options.add( new SelectOption( '1200', '8:00 PM' ) );
		options.add( new SelectOption( '1230', '8:30 PM' ) );
		options.add( new SelectOption( '1260', '9:00 PM' ) );
		options.add( new SelectOption( '1290', '9:30 PM' ) );
		options.add( new SelectOption( '1320', '10:00 PM' ) );
		options.add( new SelectOption( '1350', '10:30 PM' ) );
		options.add( new SelectOption( '1380', '11:00 PM' ) );
		options.add( new SelectOption( '1410', '11:30 PM' ) );
		
 	 	return options;
  	}
  	
  	/**
  	* Get a Existing Action Plan Task List
  	* @parms actionPlanId
  	* @return myList
  	*/
  	public List<APTaskTemplate__c> retrieveTaskFromExistingActionPlan( String actionPlanId ){
  		
  		List<APTaskTemplate__c> myList = new List<APTaskTemplate__c>();
  		myList = [ select a.Type__c, a.Subject__c, a.ActivityDate__c, a.Priority__c, a.Status__c, a.Dependent__c, 
                    a.Name, a.User__c, a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.APTaskTemplate__r.Name, 
                    a.APTaskTemplate__r.Subject__c, a.APTaskTemplate__c, a.Action_Plan__c, a.Reminder__c,
                    a.SendEmail__c, a.Comments__c, a.Minutes_Reminder__c , a.taskIndex__c, a.Time_Reminder__c
                    from APTaskTemplate__c a 
                    where a.Action_Plan__c =: actionPlanId order by a.taskIndex__c asc ];
  		return myList;
  	}

  	/**
  	* Check if the action plan has a related object
  	* @return hasRelated;
  	*/
    public Boolean hasRelatedObject(){
    	Boolean hasRelated;
    	hasRelated = 	actionPlan.Account__c != null || actionPlan.Campaign__c != null || actionPlan.Case__c != null ||
    					actionPlan.Contact__c != null || actionPlan.Contract__c != null || actionPlan.Lead__c != null ||
    				 	actionPlan.Opportunity__c != null;
    	return hasRelated;
    }
    
    /**
   	* Getter method to return a list of related object options.
   	* @return options 
    */
    public List<SelectOption> getRelatedObjectOptions(){
    	
            List<SelectOption> options = new List<SelectOption>();
            options.add( getDefaultRelatedObjectOption());
            options.add( new SelectOption( 'Campaign', Schema.Sobjecttype.Campaign.label ) );
          	options.add( new SelectOption( 'Case', Schema.Sobjecttype.Case.label ) );
          	options.add( new SelectOption( 'Contact', Schema.Sobjecttype.Contact.label ) );
          	options.add( new SelectOption( 'Contract', Schema.Sobjecttype.Contract.label ) );
          	options.add( new SelectOption( 'Lead', Schema.Sobjecttype.Lead.label ) );
          	options.add( new SelectOption( 'Opportunity', Schema.Sobjecttype.Opportunity.label ) );
          	
            return options;
        }
        
    /**
    * Getter method to set the default related object option.
    * @return the default option
    */
    public SelectOption getDefaultRelatedObjectOption(){
    	return	new SelectOption( 'Account', Schema.Sobjecttype.Account.label );
    }
    
    /**
    * Returns the related object id from lookup fields.
    * @return the related object id
    */
    public Id relatedObjectId(){
    	Id currentId;
    	if( actionPlan.Account__c != null ) 		{ currentId = actionPlan.Account__c; }
    	else if( actionPlan.Campaign__c != null ) 	{ currentId = actionPlan.Campaign__c;}
    	else if( actionPlan.Case__c != null ) 		{ currentId = actionPlan.Case__c;}
    	else if( actionPlan.Contract__c != null ) 	{ currentId = actionPlan.Contract__c; }
    	else if( actionPlan.Opportunity__c != null ){ currentId = actionPlan.Opportunity__c; }
    	else if( actionPlan.Contact__c != null ) 	{ currentId = actionPlan.Contact__c;}
    	else if( actionPlan.Lead__c != null ) 		{ currentId = actionPlan.Lead__c; }
    	return currentId;
    }

	/**
    * Extract the prefix without the last three caracter at the end.
    * @param londId		the id to be truncated
    * @return 			a truncated string.
    */
    public String truncateId(Object longId){
    	String longIdString = String.valueOf(longId);
    	return longIdString.substring(0,longIdString.length() - 3);
    }
    
    /**
    * Retrieve the owner list from the related object.
    * @param relatedObjIds		list of sobjects' id
    * @param relatedObjectName
    */
    public void retrieveOwnersDataRelatedObject( List<String> relatedObjIds, String relatedObjectName ){
    	
		String shortId;
		String queryRetrieveOwnerIds;
		
		if( !relatedObjIds.isEmpty() ){
			queryRetrieveOwnerIds = 'Select Id, OwnerId from ' + relatedObjectName + ' where Id in (' + concat( relatedObjIds, ',' ) + ')';
			Database.query( queryRetrieveOwnerIds );
			
        	for( SObject obj : Database.query(queryRetrieveOwnerIds) ){
            	shortId = truncateId(obj.get('Id'));
            	relatedObjOwnerList.put( shortId, String.valueOf(obj.get('OwnerId'))); 
        	}
    	}
	}
	
	/**
	* Concat a list of string to a single string.
	* @param stringList		a list to be concated
	* @param separator 		a char separator
	* @return a single 		string concated with elements in the list 
	*/
	private String concat( List<String> stringList, String separator ){
		
		String result = '';
		for( String elem : stringList ){
			if( result != '' ){
				result += separator;
			}
			result += '\''+elem+'\'';	
		}
		
		return result;
	}	
}