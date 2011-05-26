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
public with sharing class ActionPlansUtilitiesTest {

	private static testMethod void APUtestSaveMethod() {
		
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'accounts', 0 );
   		
   		ApexPages.currentPage().getParameters().put( 'refType', 'Account' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Account__c);
   		
		ActionPlansUtilities apu = new ActionPlansUtilities( ap );   		
   		apu.apTasks = new List<APTaskTemplate__c>();
   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );
   		
		String str 				 = apu.getRelatedObjName();
		
		System.assert(apu.hasRelatedObject(), 'Should be a related object Account');
		List<String>strl 		 = apu.relatedObjIds();
		List<ActionPlan__c> apl	 = apu.getActionPlans();	
	   		
		apu.save();
		
		ActionPlan__c rap = [select Id from ActionPlan__c where Id =: ap.Id];
		System.assert( rap != null );
	}
	
	private static testMethod void APUtestSaveMasiveMethod() {
		
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		ActionPlan__c ap = ge.createNewActionPlan( 'accounts', 0 );
   		ap.SkipWeekends__c 	= true;
		ap.SkipDay__c = Label.ap_Friday;
		update ap;
   		ApexPages.currentPage().getParameters().put( 'refType', 'Account' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Account__c);
		ActionPlansUtilities apu = new ActionPlansUtilities( ap );
   		apu.apTasks = new List<APTaskTemplate__c>();
   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );
	   		
		apu.saveMultiple();
		ActionPlan__c rap = [select Id, Account__c from ActionPlan__c where Id =: ap.Id];
		System.assert( rap.Account__c == ap.Account__c );
		
		ap = ge.createNewActionPlan( 'leads', 0 );
		ap.SkipWeekends__c 	= true;
		ap.SkipDay__c = Label.ap_Friday;
		update ap;
   		ApexPages.currentPage().getParameters().put( 'refType', 'Lead' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Lead__c);
		apu = new ActionPlansUtilities( ap );
   		apu.apTasks = new List<APTaskTemplate__c>();
   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );
	   		
		apu.saveMultiple();
		rap = [select Id, Lead__c from ActionPlan__c where Id =: ap.Id];
		System.assert( rap.Lead__c == ap.Lead__c );
		
		ap = ge.createNewActionPlan( 'opportunitys', 0 );
		ap.SkipWeekends__c 	= true;
		ap.SkipDay__c = Label.ap_Friday;
		update ap;
   		ApexPages.currentPage().getParameters().put( 'refType', 'Opportunity' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Opportunity__c);
		apu = new ActionPlansUtilities( ap );
   		apu.apTasks = new List<APTaskTemplate__c>();
   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );
	   		
		apu.saveMultiple();
		rap = [select Id, Opportunity__c from ActionPlan__c where Id =: ap.Id];
		System.assert( rap.Opportunity__c == ap.Opportunity__c);
		
		ap = ge.createNewActionPlan( 'contacts', 0 );
		ap.SkipWeekends__c 	= true;
		ap.SkipDay__c = Label.ap_Friday;
		update ap;
   		ApexPages.currentPage().getParameters().put( 'refType', 'Contact' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Contact__c);
		apu = new ActionPlansUtilities( ap );
   		apu.apTasks = new List<APTaskTemplate__c>();
   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );
   		rap = [select Id, Contact__c from ActionPlan__c where Id =: ap.Id];
		System.assert( rap.Contact__c == ap.Contact__c);
	   		
		apu.saveMultiple();
	}
	
	private static testMethod void APUtestSaveMasiveMethod2() {
		
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'opportunitys', 0 );
		ap.SkipWeekends__c 	= true;
		ap.SkipDay__c = 'Monday';
		update ap;
   		
   		ApexPages.currentPage().getParameters().put( 'refType', 'Opportunity' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Opportunity__c);
		ActionPlansUtilities apu = new ActionPlansUtilities( ap );
   		apu.apTasks = new List<APTaskTemplate__c>();
   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );

		apu.save();
		
		ap = ge.createNewActionPlan( 'contacts', 0 );
		ap.SkipWeekends__c 	= true;
		ap.SkipDay__c = Label.ap_Friday;
		update ap;
   		
   		ApexPages.currentPage().getParameters().put( 'refType', 'Contact' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Contact__c);

   		apu.apTasks = new List<APTaskTemplate__c>();
   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );
   		
		apu.save();
		
		ActionPlanTemplate__c apt = ge.createNewActionPlanTemplate( 5 );
		ApexPages.currentPage().getParameters().put( 'templateId', apt.Id );
		apu = new ActionPlansUtilities( new ActionPlan__c() );
		apu.apTasks = apu.getTasks();
		
		System.assert( !apu.apTasks.isEmpty() );
	}	
	
	public static APTaskTemplate__c apptask ( ActionPlan__c ap ){
		
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		APTaskTemplate__c at = new APTaskTemplate__c();
   		at.Action_Plan__c 	 = ap.Id;
   		at.Dependent__c		 = 'None';
   		at.DaysFromStart__c  = 2.0;
   		at.User__c			 = ge.createTestUser().Id;
   		at.SendEmail__c		 = false;
   		at.Subject__c		 = 'Test ';
   		at.Type__c			 = 'Email';
   		at.Priority__c		 = 'Low';
   		at.Comments__c		 = 'Test';
   		at.Reminder__c		 = true;
   		at.Minutes_Reminder__c = '510';
   		
   		return at;
	}
}