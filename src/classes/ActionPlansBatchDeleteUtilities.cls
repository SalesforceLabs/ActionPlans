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
public with sharing class ActionPlansBatchDeleteUtilities {

 	private List<String> 			relActionPlansIds	{ get; set; } 
 	private List<ActionPlan__c> 	relActionPlans		{ get; set; }
 	
    //constructor
	public ActionPlansBatchDeleteUtilities(List<String> oIdsLIst, ID userId){
    
		relActionPlansIds = oIdsLIst;
		
    }
    
    
    public  Database.QueryLocator getObjects( Database.BatchableContext bc ){         
        
        String soql		= 	'Select a.Id '+
                      		'From ActionPlan__c a Where a.Id IN ';
        String inClause = 	'(';
        
        for( String iter : this.relActionPlansIds ){
            inClause += '\'' + iter + '\',';
        }             
        inClause	= inClause.substring( 0, inClause.length() - 1 );
        inClause 	+= ')';
        soql 		+= inClause;

        return Database.getQueryLocator( soql );
    }
    
    
     public  void deleteActionPlans() {
		  
		List<APTaskTemplate__c> relTaskTemplateList = new List<APTaskTemplate__c>();
		List<String> relTaskTemplateIds 			= new List<String>();
		List<Task> relTaskList 						= new List<Task>();
		
		try{	
			relActionPlans = [Select Id from ActionPlan__c where Id in:this.relActionPlansIds limit :ActionPlansConstants.maxAPToDelete];
			// 	task templates are deleted as they are the detail part or the relationship
			Map<Id,APTaskTemplate__c> relTaskTemplateMap = new Map<Id,APTaskTemplate__c>([Select Id from APTaskTemplate__c where Action_Plan__c in:this.relActionPlansIds]);
			relTaskList = [Select Id from Task t where t.TaskTemplateId__c in:relTaskTemplateMap.keySet()];
			
			delete relActionPlans;
			delete relTaskList;
			
		}catch(Exception e){
			/*
    		todo: handle this
    		*/       
		}
     
     }


}