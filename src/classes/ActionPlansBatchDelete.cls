/**                    
* Create the Batch process for Action Plan creation
* @author amorales@timbasoftware.com
*/

global with sharing class ActionPlansBatchDelete implements Database.Batchable<SObject>, Database.Stateful{

	ActionPlansBatchDeleteUtilities taskBatch;

 	 /**
    * Constructor
    */
    public ActionPlansBatchDelete( List<String> oIdsLIst, ID userId){
    	 
    	 taskBatch = new ActionPlansBatchDeleteUtilities(oIdsLIst, userId);
            
      	
    }
    
    /**
    * Use the start method to collect the records or objects to be passed to the interface method execute
    */
    global Database.QueryLocator start( Database.BatchableContext bc ){         
        return this.taskBatch.getObjects(bc);
    }
    
    /**
    *
    * @param bc
    * @param data
    */
    global void execute( Database.BatchableContext bc, List<SObject> data ){
    	ProcessorControl.inBatchContext = true;
    	try{
			this.taskBatch.deleteActionPlans();
			if (ActionPlansBatchBuilderTest.isTest){ 
    			String str= null;
    			str.toLowerCase();
    		}
    	}catch(Exception e){
			AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
		      TotalJobItems, CreatedBy.Email,ExtendedStatus
		      from AsyncApexJob where Id =
		      :bc.getJobId()];
		   // If there were any errors Send an email to the Apex job's submitter 
		   // notifying of job completion       
			   Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			   String[] toAddresses = new String[] {a.CreatedBy.Email};
			   mail.setToAddresses(toAddresses);
			   mail.setSubject('EXCEPTION during  Action Plans Batch deletion  ' + a.Status);
			   mail.setPlainTextBody
			   ('The batch Apex job processed ' + a.TotalJobItems +
			   ' batches.\nError :'+e);
			   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
    }
    
    /**
    *
    */
    global void finish( Database.BatchableContext bc ){/**/}
	

}