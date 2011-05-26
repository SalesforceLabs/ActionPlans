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
public with sharing class ActionPlansBatchDeleteTest {
	public static Boolean isTest = false;
	
    private static testMethod void testDelete() {
		
		test.startTest();
		
		ActionPlansTestUtilities apTUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap =   apTUtil.createNewActionPlan('accounts',1);
		
		List<String> lIds = new List<String>();
		lIds.add(ap.Id);
		
		ActionPlansBatchDelete taskBatch = new ActionPlansBatchDelete(lIds,Userinfo.getUserId());
		Database.ExecuteBatch( taskBatch );
	
		test.stopTest();
	}
	
	private static testMethod void testDeleteException() {
		
		test.startTest();
		
		ActionPlansBatchBuilderTest.isTest = true;
		
		ActionPlansTestUtilities apTUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap =   apTUtil.createNewActionPlan('accounts',1);
		
		List<String> lIds = new List<String>();
		lIds.add(ap.Id);
		
		ActionPlansBatchDelete taskBatch = new ActionPlansBatchDelete(lIds,Userinfo.getUserId());
		Database.ExecuteBatch( taskBatch );
	
		test.stopTest();
	}
	
    
        private static testMethod void testUnDelete() {
		
		test.startTest();
		
		ActionPlansTestUtilities apTUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap =   apTUtil.createNewActionPlan('accounts',1);
		
		
					APTaskTemplate__c at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = Userinfo.getUserId();
	   		at.SendEmail__c		 = false;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		
	   		at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = Userinfo.getUserId();
	   		at.SendEmail__c		 = true;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
		
			Task x 				= new Task();
			x.Priority 			= at.Priority__c;
			x.Status			= 'Open';
			x.TaskTemplateId__c	= at.Id;
			x.Subject			= at.Subject__c;
			insert x;
		
		List<String> lIds = new List<String>();
		lIds.add(ap.Id);
		
		ActionPlansBatchDelete taskBatch = new ActionPlansBatchDelete(lIds,Userinfo.getUserId());
		Database.ExecuteBatch( taskBatch );
	
		test.stopTest();
		
		try{
			undelete ap;
		}catch(Exception e){
		
		}
	}
}