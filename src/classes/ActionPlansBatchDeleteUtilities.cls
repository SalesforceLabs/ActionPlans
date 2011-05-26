/**
 * This class contains all logic involved in Action Plans deletion
 * It is invoked from Batch Job and single AP creation flow
 * @author amorales@timbasoftware.com
 * @createdDate 11/22/2010
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