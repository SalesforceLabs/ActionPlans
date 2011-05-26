trigger ActionPlanTrigger on ActionPlan__c ( before delete, after insert, after undelete ){


 		set<ID> apIds= new set<ID>();
        set<ID> apttIds= new set<ID>();
        set<ID> taskIds= new set<ID>();
        List<Task> tasks = new List<Task>();

    //Execution when a Action Plan is Deleted, delete all asociated Task
    if( trigger.isDelete && trigger.isBefore ) {
    	if ( !ProcessorControl.inBatchContext){
	        // if action plan is deleted, delete all tasks associated with it
	        for( ActionPlan__c ap : trigger.old ){
	            apIds.add( ap.Id );
	        }
	       
			for( APTaskTemplate__c aptt : [ select Id from APTaskTemplate__c where Action_Plan__c in :apIds ] ){
	            apttIds.add( aptt.Id );
	        } 
	 		for( Task ap : [select Id from Task where Status != 'Completed' and TaskTemplateId__c in :apttIds ] ){
	            taskIds.add( ap.Id );
	        } 
	        
	        if( taskIds.size() > 0 ){
		    	ActionPlansTaskTriggerUtilities.deleteTasks( taskIds );
			}
        }
    }
   
    
    if ( trigger.isUnDelete && trigger.isAfter ){
    	Database.UndeleteResult[] unDel_errors;
    	//get All Action PLan Ids
    	for( ActionPlan__c ap : trigger.new ){
            apIds.add( ap.Id );
        }
    	//get Id of all deleted Action Plan Tasks Templates
    	Map<Id,APTaskTemplate__c> map_APTasks =new Map<ID, APTaskTemplate__c>([select  a.Id ,a.Action_Plan__c 
													from APTaskTemplate__c a 
													where a.Action_Plan__c  in: apIds  ALL ROWS ]);
    						
    	//get all tasks asociated to this APTasks
    	List<Task> taskList =  [select  a.Status , a.Id, a.ReminderDateTime, a.TaskTemplateId__c, a.Subject, a.isDeleted
										from Task a 
										where a.TaskTemplateId__c in: map_APTasks.keySet()  and a.isDeleted = true  ALL ROWS ];	
																											
		if (taskList.size()>0){
			try{
				unDel_errors =Database.undelete( taskList,false);
			}catch(Exception e){
				for(integer i =0; i< unDel_errors.size(); i++)
		            if(unDel_errors[i].getErrors().size()>0){
		              // Process any errors here  
		             	 /*
			    			todo: handle this
			    		*/
		    		}
			}
		}																					
    	
    }
}