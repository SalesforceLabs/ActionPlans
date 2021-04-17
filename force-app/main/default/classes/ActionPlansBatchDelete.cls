/*
Action Plans v4
Updated by David Schach 2021

Action Plans v3
Force.com Labs
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2011, salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
	* Neither the name of the salesforce.com, inc. nor the names of its contributors
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
global inherited sharing class ActionPlansBatchDelete implements Database.Batchable<SObject>, Database.Stateful{

	ActionPlansBatchDeleteUtilities apBatchDeleteUtil;

	/**
	* Constructor
	*/
	public ActionPlansBatchDelete( Set<Id> oIDsSet){

		 apBatchDeleteUtil = new ActionPlansBatchDeleteUtilities(oIDsSet);

	}

	/**
	* Use the start method to collect the records or objects to be passed to the interface method execute
	*/
	global Database.QueryLocator start( Database.BatchableContext bc ){
		return this.apBatchDeleteUtil.getObjects(bc);
	}

	/**
	*
	* @param bc
	* @param data
	*/
	global void execute( Database.BatchableContext bc, List<SObject> data ){
		try{
			this.apBatchDeleteUtil.deleteActionPlans();
			if (ActionPlansTestUtilities.forceError){
				String str = null;
				str.toLowerCase();
			}
		} catch(Exception e){
			AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
				FROM AsyncApexJob WHERE Id = :bc.getJobId()];
		   // If there were any errors Send an email to the Apex job's submitter
		   // notifying of job completion
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] {a.CreatedBy.Email};
			mail.setToAddresses(toAddresses);
			mail.setSubject('EXCEPTION during Action Plans Batch deletion  ' + a.Status);
			mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches.\nError :' + e );
			if(ActionPlansMetadataUtility.canSendEmails()){
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			}
		}
	}

	/**
	*
	*/
	global void finish( Database.BatchableContext bc ){}

}