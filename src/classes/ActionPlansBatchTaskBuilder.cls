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
global with sharing class ActionPlansBatchTaskBuilder implements Database.Batchable<SObject>, Database.Stateful{
    
    private List<APTaskTemplate__c> apTasks             { get; set; }
    private List<String>            aptIds              { get; set; }
    private List<Task>              myTasksWithOutEmail { get; set; }
    private List<Task>              myTasksWithEmail    { get; set; }
    
    /**
    * Constructor
    */
    public ActionPlansBatchTaskBuilder( List<String> apttIds ){
        this.aptIds = apttIds;
    }
    
    /**
    * QueryLocator: Select the List of APTaskTemplate__c.
    */
    global Database.QueryLocator start( Database.BatchableContext bc ){
        //Add Action Plan custom object reference Field.
        String soql = 'Select a.User__c, a.Type__c, a.Subject__c, a.Status__c, a.SendEmail__c, a.Reminder__c, a.Minutes_Reminder__c,'+
                      'a.Priority__c, a.Name, a.Id, a.Dependent__c, a.Comments__c, a.ActivityDate__c,'+
                      'a.Action_Plan__c, a.Action_Plan__r.Account__c , a.Action_Plan__r.Contact__c, '+
                      'a.Action_Plan__r.Campaign__c , a.Action_Plan__r.Case__c , a.Action_Plan__r.Contract__c, '+
                      'a.Action_Plan__r.Lead__c, a.Action_Plan__r.Opportunity__c, '+
                      'a.APTaskTemplate__c From APTaskTemplate__c a Where a.Id IN ';
        String inClause = '(';
        for( String iter : this.aptIds ){
            inClause += '\'' + iter + '\',';
        }             
        inClause = inClause.substring( 0, inClause.length() - 1 );
        inClause += ')';
        soql += inClause;
        
        return Database.getQueryLocator( soql );
    }
    
    /**
    *
    * @param bc
    * @param data
    */
    global void execute( Database.BatchableContext bc, List<SObject> data ){
        
        this.myTasksWithEmail       = new List<Task>();
        this.myTasksWithOutEmail    = new List<Task>();
        this.apTasks                = new List<APTaskTemplate__c>();
        
        for( SObject obj : data ){
               APTaskTemplate__c oneData = ( APTaskTemplate__c )obj;
               this.apTasks.add( oneData );
        }

        //Now run this magic!
        for( APTaskTemplate__c apTask : this.apTasks ){
            
            // check if task exists already
            Task t = new Task();
            t.Subject           = apTask.Subject__c;
            t.Priority          = apTask.Priority__c;
            t.OwnerId           = apTask.User__c;
            t.TaskTemplateId__c = apTask.Id; 
                
            // fake link to AP Task Template
            if( apTask.Comments__c != null ){
                t.Description = apTask.Comments__c;
            } 
            
            //set reminder based on user's default reminder setting
            if( apTask.Reminder__c == true && apTask.ActivityDate__c != null ){
                
                t.isReminderSet = apTask.Reminder__c;
                
                t.ReminderDateTime = Datetime.newInstance( apTask.ActivityDate__c.year(), apTask.ActivityDate__c.month(), apTask.ActivityDate__c.day(), 0, 0, 0 );
                t.ReminderDateTime = t.ReminderDateTime.addMinutes( Integer.valueOf( apTask.Minutes_Reminder__c ) );                          
            }              
                
            //link to Action Plan's Related To Object
            if( apTask.Action_Plan__r.Account__c != null ){
                t.WhatId = apTask.Action_Plan__r.Account__c;
            } 
            
            if( apTask.Action_Plan__r.Contact__c != null ){
                t.WhoId = apTask.Action_Plan__r.Contact__c;
            } 
            
            if( apTask.Action_Plan__r.Lead__c != null ){
                t.WhoId = apTask.Action_Plan__r.Lead__c;
            } 
            
            if( apTask.Action_Plan__r.Opportunity__c != null ){
                t.WhatId = apTask.Action_Plan__r.Opportunity__c;
            } 
            
            //Add new version Support to Cases , Contracts ans Campaigns
            if( apTask.Action_Plan__r.Campaign__c != null ){
                t.WhatId = apTask.Action_Plan__r.Campaign__c;
            } 
            
            if( apTask.Action_Plan__r.Case__c != null ){
                t.WhatId = apTask.Action_Plan__r.Case__c;
            }
            
            if( apTask.Action_Plan__r.Contract__c != null ){
                t.WhatId = apTask.Action_Plan__r.Contract__c;
            } 
            //Add here code sample to extend for a custom Object
            /*
            if( apTask.Action_Plan__r.CustomObject__c != null ){
                t.WhatId = apTask.Action_Plan__r.CustonObject__c;
            } 
            */
            
            t.Type          = apTask.Type__c;
            t.Status        = 'Not Started';
            t.ActivityDate  = apTask.ActivityDate__c;  
            
            if( apTask.Dependent__c == 'None' ){
	            if( apTask.SendEmail__c == true ){
	                this.myTasksWithEmail.add( t ); 
	            }
	            else{
	                this.myTasksWithOutEmail.add( t ); 
	            }
            }
        }
    
        Database.DMLOptions dmlo    = new Database.DMLOptions();
        Database.DMLOptions dmlo2   = new Database.DMLOptions();
        
        if( this.myTasksWithEmail.size() > 0 ){
            dmlo.EmailHeader.triggerUserEmail = true;
            database.insert( this.myTasksWithEmail, dmlo );
        }
        
        if( this.myTasksWithOutEmail.size() > 0 ){
            dmlo2.EmailHeader.triggerUserEmail = false;
            database.insert( this.myTasksWithOutEmail, dmlo2 );
        }
    }
    
    /**
    *
    */
    global void finish( Database.BatchableContext bc ){
    
    }
}