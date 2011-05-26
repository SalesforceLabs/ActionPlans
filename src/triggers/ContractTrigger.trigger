trigger ContractTrigger on Contract (after undelete, before delete) {

	set<ID> 		cIds	= new set<ID>();
	List<String> 	apIds	= new List<String>();
	List<ActionPlan__c>	deletePermantently_apIds= new List<ActionPlan__c>();	
	//Delete related action plans
	if ( trigger.isdelete ){
		for( Contract c : trigger.old ){
        	cIds.add( c.Id );
   		}
   		
		/* GET Action Plans to delete from recycle bin */
   		deletePermantently_apIds = [ select Id, Name , LastModifiedDate from ActionPlan__c where Contract__c in : cIds and isDeleted = true ALL ROWS ];
   		
   		if ( deletePermantently_apIds.size() >0 ){   		
			Database.emptyRecycleBin(deletePermantently_apIds);
   		}   		
   		
		//Get all action plans associated with Campaigns
   		for( Contract a : [Select (Select Id From Action_Plans__r) From Contract a where Id in : cIds]){
			if (a.Action_Plans__r.size() >0 ){
				for(ActionPlan__c ap :a.Action_Plans__r ){
					apIds.add(ap.Id);
				}
			}
   		}
   		if ( apIds.size() >0 ){   		
			ActionPlansBatchDelete aPBatch = new ActionPlansBatchDelete(apIds, Userinfo.getUserId());
			Database.ExecuteBatch( aPBatch );		
   		}
	}
	
	//Undelete related action plans
	if ( trigger.isUnDelete ){
		for( Contract c : trigger.new ){
        	cIds.add( c.Id );
   		}
   		list <ActionPlan__c> aPs = [ select Id from ActionPlan__c where Contract__c in : cIds ALL ROWS ];
   		
   		try{
   			if(ActionPlanObjectTriggerTest.isTest){
   				//throw dmlException
   				insert new Contact();	
   			}
   			//undelete aPs;
   			Database.undelete( aPs,false);
   		} catch ( Dmlexception e ){
   			for (Contract c: trigger.new){
				c.addError('You can not undelete an action plan whose related object is deleted.');
			}
   		}
	}

}