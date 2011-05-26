/*
Action Plans v3
Force.com Labs
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
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
global with sharing class ActionPlansBatchBuilder implements Database.Batchable<SObject>, Database.Stateful{

    ActionPlansBatchBuilderUtilities taskBatch;

     /**
    * Constructor
    */
    public ActionPlansBatchBuilder(ActionPlan__c baseObj,List<APTaskTemplate__c> aPTList, String refType, List<String> oIdsLIst){
         
         taskBatch = new ActionPlansBatchBuilderUtilities(baseObj,aPTList, refType,oIdsList);
            
    }
    
    /**
    * Use the start method to collect the records or objects to be passed to the interface method execute
    */
    global Iterable<sObject> start( Database.BatchableContext bc ){         
        return this.taskBatch.getObjects(bc);
    }
    
    /**
    *
    * @param bc
    * @param data
    */
    global void execute( Database.BatchableContext bc, List<SObject> data ){
        try{
            
            this.taskBatch.generateActionPlans();
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
            mail.setSubject('EXCEPTION during  Action Plans Batch creation  ' + a.Status);
            mail.setPlainTextBody ('The batch Apex job processed ' + a.TotalJobItems +
                                    ' batches.\nError :'+e);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
        }
    }
    
    /**
    *
    */
   
    global void finish(Database.BatchableContext BC){/**/}

}