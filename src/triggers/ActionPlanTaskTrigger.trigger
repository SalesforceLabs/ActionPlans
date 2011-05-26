trigger ActionPlanTaskTrigger on Task ( after update, after delete , before delete) {
    
    if (trigger.isUpdate && trigger.isAfter){
    	
	    List<String> closedTasks = new List<String>();
	    List<String> inProgressTasks = new List<String>();
	    List<String> APTasksIds = new List<String>();
	
	    
		ActionPlansUtilities apUtil = new ActionPlansUtilities();
	
	    //Get all my Updated complete Task Id's.
	    for( Task t : Trigger.new ) {
	
	    	if (t.TaskTemplateId__c != null){
	    		//store APTasks Id in a list to obtain all asociated APTasks objects
	    		APTasksIds.add(t.TaskTemplateId__c);
	    		
		    	if( t.Status == 'Completed' || t.Status == 'In Progress'){
		    		//check that the task does not depent on another task with status = In Progress
		        	if (apUtil.validateChangeStatus(t.TaskTemplateId__c)){
		        		 if( t.Status == 'In Progress' ){
							inProgressTasks.add( t.TaskTemplateId__c );
		        		}else{
		        			closedTasks.add( t.TaskTemplateId__c );
		        		}
		        	}else{
		        		//throw exception
		        		trigger.new[0].Status.addError(Label.ap_UpdateStatusError);
		        	}
		        } 
	    	}
	        
	    }
		
		//Call to ActionPlansUtilities in order to proceed with creation of dependent Task
	    if( !closedTasks.isEmpty() ) {
	        ActionPlansTaskTriggerUtilities.initDependentTaskWork( closedTasks);
	    }
	    //update status to in progress for AP Tasks
	     if( !inProgressTasks.isEmpty() ) {
	        ActionPlansTaskTriggerUtilities.updateAPTasksStatus( inProgressTasks );
	    }
	    
	       //Query APTaskTemplate__c objects to update fields
	    if (APTasksIds.size()>0){
			Map<String,APTaskTemplate__c> mapAPTasks = new Map<String,APTaskTemplate__c>();
			List<APTaskTemplate__c> aptList =  [select  a.Status__c,a.Id,a.APTaskTemplate__r.Status__c,a.ActivityDate__c,a.Minutes_Reminder__c
											from APTaskTemplate__c a 
											where a.Id in: APTasksIds ];
	    	//create a MAP with APTask id, and APTask object						
	    	for(APTaskTemplate__c apt : aptList){
	    		mapAPTasks.put(apt.Id, apt);
	    	}
			List<APTaskTemplate__c> lUpsert = new List<APTaskTemplate__c>();
			APTaskTemplate__c tmp ;
			Integer taskTemplateNameLength	= APTaskTemplate__c.Name.getDescribe().getLength();
			for( Task t : Trigger.new ) {
				tmp = mapAPTasks.get(t.TaskTemplateId__c);
				if (tmp != null){
					tmp.Subject__c  = t.Subject;
					tmp.Name  = t.Subject.substring( 0, math.min( taskTemplateNameLength, t.Subject.length() ) ) ;//t.Subject;
					tmp.Comments__c = t.Description;
					tmp.Priority__c = t.Priority;
					tmp.User__c		= t.OwnerId; 
					lUpsert.add(tmp);	
				}
			}
			if (lUpsert.size()>0){
				upsert lUpsert;
			}
		}
	    
	  
    }
    
	if ( trigger.isDelete  ){
    	
    	List<String> taskTempIds = new List<String>();	
    		
		 if (trigger.isAfter){
			List<String> finalIds = new List<String>();
	    	for( Task t : trigger.old ){
	        	if( t.TaskTemplateId__c != null ){
					taskTempIds.add( t.TaskTemplateId__c );
	        	} 
	   		}
	   		//only delete Action Plan Template Tasks that are not deleted
			
			for( APTaskTemplate__c ta : [select  a.Id ,a.Action_Plan__c 
										from APTaskTemplate__c a 
										where id  in: taskTempIds and isDeleted = false  ALL ROWS ] ){
	        	finalIds.add( ta.Id );
	   		}									
												  		
	   		if (finalIds.size()>0){
	   			  if (ProcessorControl.inBatchContext){
		        	//delete 
		        	delete [select aPT.id from APTaskTemplate__c aPT where aPT.id in : finalIds];
		       	}else{
		        	ActionPlansTaskTriggerUtilities.deleteAPTasks( finalIds );
		        }
	   		}
   		}
   		if (trigger.isBefore){
    		
	    	for( Task t : trigger.old ){
	        	if( t.TaskTemplateId__c != null ){
					taskTempIds.add( t.TaskTemplateId__c );
	        	} 
	   		}
	   		//only delete Action Plan Template Tasks that are not deleted
	   		//create any task depending on this one	
	   		ActionPlansTaskTriggerUtilities.initDependentTasksAndReset( taskTempIds);
   		}
		
	}
    
}