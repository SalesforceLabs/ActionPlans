trigger AccountTrigger on Account (before delete, after undelete) {
	
	set<ID> 			aIds	= new set<ID>();
	List<String>		apIds	= new List<String>();
	List<ActionPlan__c>	deletePermantently_apIds= new List<ActionPlan__c>();
	
	//Delete related action plans
	if ( trigger.isdelete ){
		for( Account a : trigger.old ){
        	aIds.add( a.Id );
   		}
	
		/* GET Action Plans to delete from recycle bin */
   		deletePermantently_apIds = [ select Id, Name , LastModifiedDate from ActionPlan__c where Account__c in : aIds and isDeleted = true ALL ROWS ];
   		
   		if ( deletePermantently_apIds.size() >0 ){   		
			Database.emptyRecycleBin(deletePermantently_apIds);
   		}
	
		//Get all action plans associated with Accounts
   		for( Account a : [Select (Select Id , isDeleted From Action_Plans__r) From Account a where Id in : aIds]){
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
		Database.UndeleteResult[] unDel_errors;
		for( Account a : trigger.new ){
        	aIds.add( a.Id );
   		}
   		list <ActionPlan__c> aPs = [ select Id, Name , LastModifiedDate from ActionPlan__c where Account__c in : aIds and isDeleted = true ALL ROWS ];
   		
   		try{
   			if(ActionPlanObjectTriggerTest.isTest){
   				//throw dmlException
   				insert new Contact();	
   			}
   			
   			unDel_errors =Database.undelete( aPs,false);
   		} catch ( Dmlexception e ){				
   			for (Account a: trigger.new){
				a.addError('You can not undelete an action plan whose related object is deleted.');
			}
   		}
	}
	
}