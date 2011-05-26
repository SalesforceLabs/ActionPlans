trigger ContactTrigger on Contact (after undelete, before delete) {

	List<ID> 		cIds	= new List<ID>();
	List<String> 	apIds	= new List<String>();
	List<ActionPlan__c>	deletePermantently_apIds= new List<ActionPlan__c>();	
	
	//Delete related action plans
	if ( trigger.isdelete ){
		for( Contact c : trigger.old ){
        	cIds.add( c.Id );
   		}
   		
		/* GET Action Plans to delete from recycle bin */
   		deletePermantently_apIds = [ select Id, Name , LastModifiedDate from ActionPlan__c where Contact__c in : cIds and isDeleted = true ALL ROWS ];
   		
   		if ( deletePermantently_apIds.size() >0 ){   		
			Database.emptyRecycleBin(deletePermantently_apIds);
   		}   		
   		
		List<ActionPlan__c> apList =  [ select Id from ActionPlan__c where Contact__c in : cIds ];
		for( ActionPlan__c ap : [ select Id from ActionPlan__c where Contact__c in : cIds ] ){
        	apIds.add( ap.Id );
   		}
   		
   		if ( apIds.size() >0 ){
   			ActionPlansBatchDelete aPBatch = new ActionPlansBatchDelete(apIds, Userinfo.getUserId());
			Database.ExecuteBatch( aPBatch );
   		}			
	}
	
	//Undelete related action plans
	if ( trigger.isUnDelete ){
		for( Contact c : trigger.new ){
        	cIds.add( c.Id );
   		}
   		list <ActionPlan__c> aPs = [ select Id from ActionPlan__c where Contact__c in : cIds ALL ROWS ];
   		
   		try{
   			if(ActionPlanObjectTriggerTest.isTest){
   				//throw dmlException
   				insert new Contact();	
   			}
   			//undelete aPs;
   			Database.undelete( aPs,false);
   		} catch ( Dmlexception e ){
   			for (Contact c: trigger.new){
				c.addError('You can not undelete an action plan whose related object is deleted.');
			}
   		}
	}

}