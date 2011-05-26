trigger ActionPlanTaskTrigger on Task ( after update ) {
    
    List<String> closedTasks = new List<String>();

    //Get all my Updated complete Task Id's.
    for( Task t : Trigger.new ) {
        if( t.Status == 'Completed' && t.TaskTemplateId__c != null ){
           closedTasks.add( t.TaskTemplateId__c );
        }
    }
	
	//Call to ActionPlansUtilities in order to proceed with creation of dependent Task
    if( !closedTasks.isEmpty() ) {
        ActionPlansTaskTriggerUtilities.initDependentTaskWork( closedTasks );
    }
}