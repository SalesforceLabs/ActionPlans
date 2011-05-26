trigger ActionPlanTaskTemplateTrigger on APTaskTemplate__c (after undelete, after update) {

	set<ID> aPTaksIds= new set<ID>();
		
		//Undelete Tasks
		if ( trigger.isUnDelete ){
			
			for( APTaskTemplate__c a : trigger.new ){
	        	aPTaksIds.add( a.Id );
	   		}
	   		//only undelete Tasks that are currently on the recycle bin
	   		list <Task> aP_tasks = [ select Id from Task where TaskTemplateId__c in : aPTaksIds and isDeleted = true ALL ROWS ];

	   		try{
	   			undelete aP_tasks;
	   		} catch ( Dmlexception e ){
	   			for (APTaskTemplate__c a: trigger.new){
					a.addError('BROKEN :'+e);
				}
	   		}
		}

}