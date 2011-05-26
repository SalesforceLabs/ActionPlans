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
public with sharing class ActionPlansBatchBuilderUtilities {
    private List<SObject> relObjects                { get; set; }
    private ActionPlan__c baseAPlan                 { get; set; }
    private List<APTaskTemplate__c> baseAPTaskList  { get; set; }
     
    private List<ActionPlan__c> relActionPlans      { get; set; }
    private List<APTaskTemplate__c> relAPTaskList   { get; set; }
    
    private String tmpRefType                      { get; set; }
    private List<String> tmpOIdsLIst               { get; set; }
    
    private String newActionPlanId;
    private String mode;
    
    private List<Task>  myTasksWithOutEmail         { get; set; }
    private List<Task>  myOldTasksWithEmail         { get; set; }
    private List<Task>  myNewTasksWithEmail         { get; set; }
    
    
    //constructor
    public ActionPlansBatchBuilderUtilities(ActionPlan__c baseObj,List<APTaskTemplate__c> aPTList, String refType, List<String> oIdsLIst){
    
		baseAPlan  = baseObj;
		baseAPTaskList = aPTList;
		relActionPlans = new List<ActionPlan__c>();
		tmpRefType  = refType;
		tmpOIdsLIst = oIdsLIst;
 
		// if the actionPlan has already an Id, then we are editing an AP and not creating a new one
		if (baseObj.id != null){
			mode = 'edit';
			this.relActionPlans.add(baseObj);
		}else{
        
			for( String relObjId : oIdsLIst ){
				ActionPlan__c ap = new ActionPlan__c();
				ap = baseObj.clone();
                
				if( 'Account'.equalsIgnoreCase( refType ) ){
				    ap.Account__c = relObjId;
				}
				if( 'Contact'.equalsIgnoreCase( refType ) ){
				    ap.Contact__c = relObjId;
				}
				if( 'Lead'.equalsIgnoreCase( refType ) ){
				    ap.Lead__c = relObjId;
				}
				if( 'Opportunity'.equalsIgnoreCase( refType ) ){
				    ap.Opportunity__c = relObjId;
				}
            
				//Add Support for EE / UE Version 
				if( 'Case'.equalsIgnoreCase( refType ) ){
				    ap.Case__c = relObjId;
				}
				if( 'Campaign'.equalsIgnoreCase( refType ) ){
				    ap.Campaign__c = relObjId;
				}
				if( 'Contract'.equalsIgnoreCase( refType ) ){
				    ap.Contract__c = relObjId;
				}
				//add Action Plan to list that will be inserted later and referenced from ActionPlanTasks
				this.relActionPlans.add(ap);
            }   
            mode = 'new';       
        }
        
    }
    
    public String getNewActionPlanId(){
        return this.newActionPlanId;
    }
    
    public  Iterable<sObject> getObjects( Database.BatchableContext bc ){         
        return this.relActionPlans;
    }
    
    
     public  void generateActionPlans() {
        
		List<APTaskTemplate__c> aptList 		= null;
		List<APTaskTemplate__c> aptTOTALList 	= new List<APTaskTemplate__c>();
		List<String> aptTOTALListId 			= new List<String>();
		Map<String,APTaskTemplate__c> mapAP 	= new Map<String,APTaskTemplate__c>();
		Map<String,ActionPlan__c> mapIDAP 		= new Map<String,ActionPlan__c>();
		ActionPlan__c apAux;
        Map<String,Task> mapApTasks 			= new Map<String,Task>();
        Integer taskTemplateNameLength			= APTaskTemplate__c.Name.getDescribe().getLength();
        
        this.myOldTasksWithEmail    = new List<Task>();
        this.myNewTasksWithEmail    = new List<Task>();
        this.myTasksWithOutEmail    = new List<Task>();
        this.relAPTaskList          = new List<APTaskTemplate__c>();

		ActionPlansUtilities apUtil = new ActionPlansUtilities( baseAPlan);
		apUtil.retrieveOwnersDataRelatedObject( tmpOIdsLIst, tmpRefType );
            
		//insert ActionPlans to DB
		upsert this.relActionPlans;
            
		//create ActionPlanTemplatetasks && tasks from base ActionPLan Task List
		for(ActionPlan__c ap :  this.relActionPlans){
			
			mapIDAP.put(ap.Id,ap);
			aptList = new List<APTaskTemplate__c>();
			//Now for each inserted ap we should run through tasks and create them
			if (this.mode != 'edit'){
				String taskName = Label.ap_DefaultTaskName;
				for( APTaskTemplate__c t : this.baseAPTaskList ) {               
				    APTaskTemplate__c nt = new APTaskTemplate__c();
				    nt = t.clone(); 
				    nt.Action_Plan__c       = ap.Id;
				    nt.Name                 = t.Subject__c.substring( 0, math.min( taskTemplateNameLength, t.Subject__c.length() ) ) ;
				    nt.DaysFromStart__c     = ( nt.DaysFromStart__c < 1 ) ? 1 : nt.DaysFromStart__c;
				    nt.User__c              = ( nt.User__c != null ) ? nt.User__c : apUtil.getRecordOwnerId( ap );
				    aptList.add( nt );
				} 
				upsert aptList;
                    
			}else{
				for( APTaskTemplate__c t : this.baseAPTaskList ) {
					t.DaysFromStart__c     = ( t.DaysFromStart__c < 1 ) ? 1 : t.DaysFromStart__c;
					t.Name                 = t.Subject__c.substring( 0, math.min( taskTemplateNameLength, t.Subject__c.length() ) ) ;
				}  
				aptList = this.baseAPTaskList;
			}
			//End of Save all Task
			
			//Now run through the tasks and take care of dependents - not done in the previous because we need the Ids
			for(APTaskTemplate__c t : aptList ){
                    
				aptTOTALListId.add(t.Id);
                    
				if(t.Action_Plan__c == null && ap.Id != null){
					t.Action_Plan__c = ap.Id;
				}
        
				if( t.Status__c == null ){
					t.Status__c = 'Not Started';
				} 

				if( t.Dependent__c != 'None' && t.Dependent__c != null ){
					Integer tempIndex   = Integer.valueOf( t.Dependent__c );
					t.APTaskTemplate__c = aptList[tempIndex].Id;
					t.ActivityDate__c = null;    
				}
				else{ 
                        
					t.APTaskTemplate__c = null;
					// create due date, calculate the due date of the tasks for skip weekends feature
					   
					//set dependency taskId to none if none was selected
					if (t.Dependent__c == null){
						t.Dependent__c = 'None';
					}
                        
					if( ap.SkipWeekends__c == true && ap.SkipDay__c != null){
					    Date dueDate    = ap.StartDate__c.addDays( t.DaysFromStart__c.intValue() );
					    Integer addDays = t.DaysFromStart__c.intValue();
					    
					    // find if the due date fall on a Saturday or Sunday.  Add 1 day for Sunday and 2 for Saturday
					    Date refDate        = Date.newInstance(1900, 1, 7);  // Jan 7 1900 = Sun
					    Integer dayOfWeek   = Math.mod(refDate.daysBetween(dueDate), 7); // 0 = Sun ... 6 = Sat
					    
					    if( ap.SkipDay__c.equalsIgnoreCase( Label.ap_Friday ) ){ 
					        // push to friday
					        addDays = ( dayOfWeek == 0 ) ? addDays - 2  : addDays ;
					        addDays = ( dayOfWeek == 6 ) ? addDays - 1  : addDays ;
					    } 
					    else{ 
					        // push to monday
					        addDays = ( dayOfWeek == 0 ) ? addDays + 1  : addDays ;
					        addDays = ( dayOfWeek == 6 ) ? addDays + 2  : addDays ; 
					    }
					    t.ActivityDate__c = ap.StartDate__c.addDays( addDays );
					    
					} 
					else{
					    
					    t.ActivityDate__c = ap.StartDate__c.addDays( t.DaysFromStart__c.intValue() );
					    
					}
				}
                    
				mapAP.put(t.Id,t);
			}           
                
			aptTOTALList.addAll(aptList);
			upsert aptList;
                
		}


        for( Task task_tmp : [ Select Id,TaskTemplateId__c, Subject from Task where TaskTemplateId__c   in: mapAP.keySet()] ) { 
            mapApTasks.put(task_tmp.TaskTemplateId__c,task_tmp);  
        }
               
		Task t;
		for( APTaskTemplate__c t_t : aptTOTALList ) {  
			// check if task exists already
			t = mapApTasks.get( t_t.Id); 
			if (t == null){
			    //Create the new task and template
			    t   = new Task();
			}        
			t.Subject           = t_t.Subject__c;
			t.Priority          = t_t.Priority__c;
			t.OwnerId           = t_t.User__c;
			t.TaskTemplateId__c = t_t.Id; 
        
			if( t_t.Comments__c != null ){
			    t.Description = t_t.Comments__c;
			} 
            
			//set reminder based on user's default reminder setting
			if( t_t.Reminder__c == true && t_t.ActivityDate__c != null ){
			    
			    t.isReminderSet = t_t.Reminder__c;
			    t.ReminderDateTime = Datetime.newInstance( t_t.ActivityDate__c.year(), t_t.ActivityDate__c.month(), t_t.ActivityDate__c.day(), 0, 0, 0 );
			    t.ReminderDateTime = t.ReminderDateTime.addMinutes( Integer.valueOf( t_t.Minutes_Reminder__c ) );                          
			}
			else{
			    t.isReminderSet = false;
			}              
             
			APTaskTemplate__c apt = mapAP.get(t_t.Id); 
			if ( apt != null ){
			    apAux = mapIDAP.get(apt.Action_Plan__c);
			}
                
			if ( apAux==null ){
			    apAux = t_t.Action_Plan__r;
			}
			//link to Action Plan's Related To Object
			if( apAux.Account__c != null ){
			    t.WhatId = apAux.Account__c;
			} 
			if( apAux.Contact__c != null ){
			    t.WhoId = apAux.Contact__c;
			} 
			if( apAux.Lead__c != null ){
			    t.WhoId = apAux.Lead__c;
			} 
			if( apAux.Opportunity__c != null ){
			    t.WhatId = apAux.Opportunity__c;
			} 
			
			//Add new version Support to Cases , Contracts ans Campaigns
			if( apAux.Campaign__c != null ){
			    t.WhatId = apAux.Campaign__c;
			} 
                
			if( apAux.Case__c != null ){
			    t.WhatId = apAux.Case__c;
			}
			
			if( apAux.Contract__c != null ){
			    t.WhatId = apAux.Contract__c;
			} 
            //Add here code sample to extend for a custom Object
                /*
            if( apTask.Action_Plan__r.CustomObject__c != null ){
                t.WhatId = apTask.Action_Plan__r.CustonObject__c;
            } 
            */
            
			t.Type          = t_t.Type__c;
			
			if (t.Id == null){
			    t.Status        = 'Not Started';
			}
			t.ActivityDate  = t_t.ActivityDate__c;  
                 
            if( t_t.Dependent__c == 'None' ){
                if( t_t.SendEmail__c == true ){
                    if( t.id == null )  {this.myNewTasksWithEmail.add( t );}
                    else                {this.myOldTasksWithEmail.add( t ); }
                }
                else{ 
                    this.myTasksWithOutEmail.add( t );
                }
            }else{ 
                //only update dependant tasks that are already created
                if( t.Id != null  ){   
                        this.myTasksWithOutEmail.add( t );
                }
            }
             
        }

        Database.DMLOptions dmlo    = new Database.DMLOptions();
        Database.DMLOptions dmlo2   = new Database.DMLOptions();
    
        if( this.myNewTasksWithEmail.size() > 0 ){
            dmlo.EmailHeader.triggerUserEmail = true;
            database.insert( this.myNewTasksWithEmail, dmlo );
        }
        
        if( this.myOldTasksWithEmail.size() > 0 ){
            dmlo.EmailHeader.triggerUserEmail = true;
            database.update( this.myOldTasksWithEmail, dmlo );
        }
    
        if( this.myTasksWithOutEmail.size() > 0 ){
            if (this.mode =='edit'){
                upsert( this.myTasksWithOutEmail );
            }else{
                dmlo2.EmailHeader.triggerUserEmail = false;
                database.insert( this.myTasksWithOutEmail, dmlo2 );
            }
        }
        
        //If we Only Create an Action Plan save the Id of the new object
        if (this.relActionPlans.size()==1){
            this.newActionPlanId = this.relActionPlans[0].id;
        }
        
        if (this.mode != 'edit'){
         //Execution When a Action Plan is Created, that check the Custom Setings in order to Post a new Feed ( Object )
            Action_Plans_Settings__c mySettings = apUtil.getCustomSetting(); 
            
            //We need check first if the Related Object is Enabled to FeedPost
            //Just need the first Object of list to know the Related Object.
            Boolean isEnabledForFeed = apUtil.isObjectEnabledFeed( this.relActionPlans[0]);
            
            if( isEnabledForFeed && mySettings != null && mySettings.Chatter_Object_Brag__c ) {
                apUtil.generateObjectFeed(this.relActionPlans[0].id);
            }
		}
	}
	
}