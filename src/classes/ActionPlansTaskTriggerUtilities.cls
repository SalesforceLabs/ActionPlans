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
public with sharing class ActionPlansTaskTriggerUtilities {

    public  List<String>            closedTasks     { get; set; }
    private List<APTaskTemplate__c> dependentAptts  { get; set; }
    private Map<String, Task>       newTaskMap      { get; set; }
    private List<APTaskTemplate__c> updateApttsList { get; set; }
    private List<Task> tasksSendEmail				{ get; set; }
    private List<Task> tasksSendNoEmail 			{ get; set; }

    /**
     * Constructor
     */
    public ActionPlansTaskTriggerUtilities(){
    	
        tasksSendEmail		= new List<Task>();
        tasksSendNoEmail 	= new List<Task>();
    }
    
    /**
    * Initialize the functionalities to Create All dependent Tasks
    * @parms cTasks
    */
    @future
    public static void initDependentTaskWork( List<String> cTasks ) {
    	
    	ActionPlansTaskTriggerUtilities apUtils = new ActionPlansTaskTriggerUtilities();
    	apUtils.closedTasks = cTasks;
    	
        if( !apUtils.closedTasks.isEmpty() ){
            
            //Mark all APTask as 'Completed' 
            apUtils.updateActionPlansTemplateTask();
            
            //Get all dependent APTask
            apUtils.dependentActionPlansTemplateTask();
            
            //Create actual Task Map
            apUtils.populateNewTaskMap();
            
            //Finaly, Create all New Tasks and Send DMLOption Emails
            apUtils.populateUpdateApttsList();
            
            Database.DMLOptions dmlo = new Database.DMLOptions();
            
            if(!apUtils.tasksSendEmail.isEmpty()){
            	dmlo.EmailHeader.triggerUserEmail = true;	
            	Database.insert( apUtils.tasksSendEmail, dmlo );
            }
            
            if(!apUtils.tasksSendNoEmail.isEmpty()){
            	dmlo.EmailHeader.triggerUserEmail = false;
            	Database.insert( apUtils.tasksSendNoEmail, dmlo );
            }
            
            Database.update( apUtils.updateApttsList );
        }
    }
 
    /**
     * Update associated aptt of completed task to completed as well
     */
    private void updateActionPlansTemplateTask(){
        
        List<APTaskTemplate__c> closeApttList = new List<APTaskTemplate__c>();
        APTaskTemplate__c[] tempApttList = [ select ap.Status__c from APTaskTemplate__c ap where ap.Id IN : this.closedTasks ];
        
        for ( APTaskTemplate__c aptt : tempApttList ){
            aptt.Status__c = 'Completed';
            closeApttList.add( aptt );
        }
        
        update closeApttList ;
    }
    
    /**
     * Get list of dependent Action Plans Template Task
     */
    private void dependentActionPlansTemplateTask() {
        
        this.dependentAptts = new List<APTaskTemplate__c>();
        //Add Action Plan custom object reference Field.
        this.dependentAptts = [select a.Action_Plan__r.SkipWeekends__c, a.Action_Plan__r.Account__c, a.Priority__c, a.Status__c, 
                                 a.Action_Plan__r.Contact__c, a.Action_Plan__r.Lead__c, a.Action_Plan__r.Opportunity__c,
                                 a.Action_Plan__r.Contract__c, a.Action_Plan__r.Case__c, a.Action_Plan__r.Campaign__c ,
                                 a.Action_Plan__r.StartDate__c, a.Action_Plan__c, a.Type__c, a.Subject__c, a.ActivityDate__c, 
                                 a.Dependent__c, a.Name, a.User__c, a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById,
                                 a.APTaskTemplate__r.Subject__c, a.APTaskTemplate__c, a.SendEmail__c,  a.APTaskTemplate__r.Name, 
                                 a.Reminder__c, a.Comments__c, a.Minutes_Reminder__c
                          from APTaskTemplate__c a where a.APTaskTemplate__c IN : this.closedTasks ];
    }
    
    
    /**
     * Cycle through list of dependent Action Plans Template Task and create actual tasks
     */
     private void populateNewTaskMap(){
        
        this.newTaskMap = new Map<String, Task>();
            
        for( APTaskTemplate__c dependentAptts: this.dependentAptts ){
            //Create the new task and template
            Task auxTask                = new Task();
            auxTask.Subject             = dependentAptts.Subject__c;
            auxTask.Priority            = dependentAptts.Priority__c;
            auxTask.OwnerId             = dependentAptts.User__c;
            auxTask.TaskTemplateId__c   = dependentAptts.Id;
            
            if( dependentAptts.Status__c == null ){
                 auxTask.Status = 'Not Started';
            }
            
            // calculate the due date of the tasks for skip weekends feature
            if( dependentAptts.Action_Plan__r.SkipWeekends__c ){
                
                Date dueDate        = dependentAptts.Action_Plan__r.StartDate__c.addDays( dependentAptts.DaysFromStart__c.intValue() );
                Integer addDays     = dependentAptts.DaysFromStart__c.intValue();
                
                // find if the due date fall on a Saturday or Sunday.  Add 1 day for Sunday and 2 for Saturday
                Date refDate        = Date.newInstance( 1900, 1, 7 );  // Jan 7 1900 = Sun
                Integer dayOfWeek   = Math.mod( refDate.daysBetween( dueDate ), 7 ); // 0 = Sun ... 6 = Sat
                
                addDays = ( dayOfWeek == 0 )? addDays + 1 : addDays; 
                addDays = ( dayOfWeek == 6 )? addDays + 2 : addDays;
                
                Date d  = Date.today();
                auxTask.ActivityDate = d.addDays( addDays );
            } 
            else{
                Date d = Date.today();
                auxTask.ActivityDate = d.addDays( dependentAptts.DaysFromStart__c.intValue() );
            }
            
            this.newTaskMap.put( auxTask.TaskTemplateId__c, auxTask );
        } // end for loop
     }
     
     /**
     * Cycle through list of dependent Action Plans Template Task and create tasks
     */
     private void populateUpdateApttsList(){
        
        this.updateApttsList = new List<APTaskTemplate__c>();
        for( APTaskTemplate__c dependentAptt: this.dependentAptts ){
            
            //Create the new task and template
            Task t2              = new Task();
            t2.Subject           = dependentAptt.Subject__c;
            t2.Priority          = dependentAptt.Priority__c;
            t2.OwnerId           = dependentAptt.User__c;
            t2.TaskTemplateId__c = dependentAptt.Id;
            
            dependentAptt.ActivityDate__c = dependentAptt.Action_Plan__r.StartDate__c.addDays( dependentAptt.DaysFromStart__c.intValue() );
            
            if( dependentAptt.Comments__c != null ){
                t2.Description = dependentAptt.Comments__c;
            }
            
            //set reminder based on user's default reminder setting
            if( dependentAptt.Reminder__c ){
                t2.isReminderSet 	= dependentAptt.Reminder__c;
                t2.ReminderDateTime = datetime.newInstance( dependentAptt.ActivityDate__c.year(), dependentAptt.ActivityDate__c.month(), dependentAptt.ActivityDate__c.day(), 0, 0, 0 );
                t2.ReminderDateTime = t2.ReminderDateTime.addMinutes( Integer.valueOf( dependentAptt.Minutes_Reminder__c ) );
            } 
            
            //Get Action Plan WhatID
            if( dependentAptt.Action_Plan__r.Account__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Account__c;
            }
            
            if( dependentAptt.Action_Plan__r.Contact__c != null ){
                t2.WhoId = dependentAptt.Action_Plan__r.Contact__c;
            }
            
            if( dependentAptt.Action_Plan__r.Lead__c != null ){
                t2.WhoId = dependentAptt.Action_Plan__r.Lead__c;
            }
            
            if( dependentAptt.Action_Plan__r.Opportunity__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Opportunity__c;
            }
            
            //Add new version Support to Cases , Contracts ans Campaigns
            if( dependentAptt.Action_Plan__r.Campaign__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Campaign__c;
            } 
            
            if( dependentAptt.Action_Plan__r.Case__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Case__c;
            }
            
            if( dependentAptt.Action_Plan__r.Contract__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.Contract__c;
            } 
            //Add custom object code
            /*
            if( dependentAptt.Action_Plan__r.CustomObject__c != null ){
                t2.WhatId = dependentAptt.Action_Plan__r.CustomObject __c;
            }
            */
            
                
            t2.Type         = dependentAptt.Type__c;
            t2.Status       = 'Not Started';
            t2.ActivityDate = dependentAptt.ActivityDate__c;
            
            this.newTaskMap.put( t2.TaskTemplateId__c, t2 );
            this.updateApttsList.add( dependentAptt ) ;
            
            //populate the list to send emails or not.
            if(dependentAptt.SendEmail__c){
            	tasksSendEmail.add(t2);
            }else{
            	tasksSendNoEmail.add(t2);
            }
        }
     }
     
    /**
    * Return a map the user preference associated with a user.
    * @param aptTasks	a list of APTaskTemplate__c custom object 
    * @return userPrefbyUserMap  a map with key UserId and value a user preference.
    */
     private Map<Id,UserPreference> getUserPrefFromAPTaskTemplates( List<APTaskTemplate__c> aptTasks ){
     	
    	Set<Id> usersSet = new Set<Id>();
		for( APTaskTemplate__c apTask : aptTasks){
			usersSet.add(apTask.User__c);
		}
		Map<Id,UserPreference> userPrefsMap = new Map<Id,UserPreference>([ Select u.Value, u.UserId, u.Preference, u.Id From UserPreference u where u.Preference = '58' and u.UserId in :usersSet ]);
		
		// create a map with key TaskTemplateId
		Map<Id,UserPreference> userPrefbyUserMap = new Map<Id,UserPreference>();
		for( UserPreference userPref : userPrefsMap.values()){
			userPrefbyUserMap.put(userPref.UserId,userPref);
		}
		return userPrefbyUserMap; 
    }
}