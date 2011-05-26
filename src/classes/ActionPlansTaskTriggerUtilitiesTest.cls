/*
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
@isTest
private class ActionPlansTaskTriggerUtilitiesTest {

    /**
    * test trigger without skipweekends 
    */
    public static testMethod void testTrigger1() {
    	
    	ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
    	ActionPlan__c ap 			= ge.createNewActionPlan( 'accounts', 0 );
    	
    	
    	List<Id> apTTaskIds 		= new List<Id>();
    	List<Task> apTask 			= new List<Task>();
    	List<APTaskTemplate__c> aptt = new List<APTaskTemplate__c>();
    	
		Test.startTest();
		   	for( Integer i = 0; i < 4; i++ ){
		   		APTaskTemplate__c at = new APTaskTemplate__c();
		   		at.Action_Plan__c 	 = ap.Id;
		   		at.DaysFromStart__c  = 2.0;
		   		at.User__c			 = ge.createTestUser().Id;
		   		at.SendEmail__c		 = false;
		   		at.Subject__c		 = 'Test '+ i;
		   		at.Type__c			 = 'Email';
		   		at.Priority__c		 = 'Low';
		   		at.APTaskTemplate__c = ( i > 0 ) ? aptt[ i-1 ].Id : null;
		   		insert at;
		   		aptt.add(at);
		   		apTTaskIds.add( at.Id );
		   		
		   		if( i == 0 ){
		   			Task x 				= new Task();
		   			x.Priority 			= at.Priority__c;
		   			x.Status			= 'Open';
		   			x.TaskTemplateId__c	= at.Id;
		   			x.Subject			= at.Subject__c;
		   			insert x;
		   		}
		   	}
	 	
		   	apTask = [Select Status, Id from Task where TaskTemplateId__c IN : apTTaskIds]; 
		   	for( Task t : apTask ){ 
		   		t.Status = 'Completed';
		   	} 
	   	
	   		update apTask;
			apTask = [Select Id from Task where TaskTemplateId__c =: apTTaskIds[0] ];
			
		Test.stopTest();
		System.assert( !apTask.isEmpty() );
    }
    
	/**
    * test trigger AP Delete 
    */
    public static testMethod void testTrigger2() {
    	
    	ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
    	ActionPlan__c ap 			= ge.createNewActionPlan( 'accounts', 0 );
    	ap.SkipWeekends__c			= true;
    	update ap;
    	
    	List<Id> apTTaskIds 		= new List<Id>();
    	List<Task> apTask 			= new List<Task>();
    	List<APTaskTemplate__c> aptt = new List<APTaskTemplate__c>();
		
		Test.startTest();
		   	for( Integer i = 0; i < 4; i++ ){
		   		APTaskTemplate__c at = new APTaskTemplate__c();
		   		at.Action_Plan__c 	 = ap.Id;
		   		at.DaysFromStart__c  = 2.0;
		   		at.User__c			 = ge.createTestUser().Id;
		   		at.SendEmail__c		 = false;
		   		at.Subject__c		 = 'Test '+ i;
		   		at.Type__c			 = 'Email';
		   		at.Priority__c		 = 'Low';
		   		at.Comments__c		 = 'My Coment';
		   		at.Reminder__c		 = true;
		   		at.APTaskTemplate__c = ( i > 0 ) ? aptt[ i-1 ].Id : null;
		   		insert at;
		   		aptt.add(at);
		   		apTTaskIds.add( at.Id );
		   		
		   		if( i == 0 ){
		   			Task x 				= new Task();
		   			x.Priority 			= at.Priority__c;
		   			x.Status			= 'Open';
		   			x.TaskTemplateId__c	= at.Id;
		   			x.Subject			= at.Subject__c;
		   			insert x;
		   		}
		   	}
		   	delete ap;
		   	apTask = [Select Id from Task where TaskTemplateId__c =: apTTaskIds[1] ];
		   	
		Test.stopTest(); 
		
		System.assert( apTask.isEmpty() );
    }
    
    /**
    * test trigger  
    */
    public static testMethod void testTrigger3() {
    	
    	ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
    	ActionPlan__c ap 			= ge.createNewActionPlan( 'accounts', 0 );
    	ap.SkipWeekends__c			= true;
    	update ap;
    	
    	List<Id> apTTaskIds 		= new List<Id>();
    	List<Task> apTask 			= new List<Task>();
    	List<APTaskTemplate__c> aptt = new List<APTaskTemplate__c>();
		
		Test.startTest();
		   	for( Integer i = 0; i < 4; i++ ){
		   		APTaskTemplate__c at = new APTaskTemplate__c();
		   		at.Action_Plan__c 	 = ap.Id;
		   		at.DaysFromStart__c  = 2.0;
		   		at.User__c			 = ge.createTestUser().Id;
		   		at.SendEmail__c		 = false;
		   		at.Subject__c		 = 'Test '+ i;
		   		at.Type__c			 = 'Email';
		   		at.Priority__c		 = 'Low';
		   		at.Comments__c		 = 'My Coment';
		   		at.Reminder__c		 = true;
		   		at.Minutes_Reminder__c = '510';
		   		at.APTaskTemplate__c = ( i > 0 ) ? aptt[ i-1 ].Id : null;
		   		insert at;
		   		aptt.add(at);
		   		apTTaskIds.add( at.Id );
		   		
		   		if( i == 0 ){
		   			Task x 				= new Task();
		   			x.Priority 			= at.Priority__c;
		   			x.Status			= 'Open';
		   			x.TaskTemplateId__c	= at.Id;
		   			x.Subject			= at.Subject__c;
		   			insert x;
		   		}
		   	}
		   	
		   	
		   	apTask = [Select Status, Id from Task where TaskTemplateId__c IN : apTTaskIds]; 
		   	for( Task t : apTask ){
		   		t.Status = 'Completed';
		   	} 
		   	update apTask;
		   	apTask = [Select Id from Task where TaskTemplateId__c =: apTTaskIds[0] ];
		   	
		Test.stopTest(); 
		
		System.assert( !apTask.isEmpty() );
    }
	
}