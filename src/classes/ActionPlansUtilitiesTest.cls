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
public with sharing class ActionPlansUtilitiesTest {

	private static testMethod void APUtestSaveMethod() {
		
		test.startTest();
		
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'accounts', 0 );
   		
   		ApexPages.currentPage().getParameters().put( 'refType', 'Account' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Account__c);
   		
		ActionPlansUtilities apu = new ActionPlansUtilities( ap );   		
   		apu.apTasks = new List<APTaskTemplate__c>();
   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );
   		
   		
		String str = apu.getRelatedObjName();
		
		System.assert(apu.hasRelatedObject(), 'Should be a related object Account');
		List<String>strl 		 = apu.relatedObjIds();
		List<ActionPlan__c> apl	 = apu.getActionPlans();	
	   		
		apu.save();
		
		ActionPlan__c rap = [select Id from ActionPlan__c where Id =: ap.Id];
		System.assert( rap != null );

	
		test.stopTest();
	
	}

	private static testMethod void APUtestSaveMultiple() {
		test.startTest();
				
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

		test.stopTest();
	}
	
	
	private static testMethod void APUtestSaveMasiveContact() {
		test.startTest();
				
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'contacts', 0 );
		ap.SkipWeekends__c 	= true;
		ap.SkipDay__c = Label.ap_Friday;
		update ap;
   		
   		ApexPages.currentPage().getParameters().put( 'refType', 'Contact' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Contact__c);
		
		ActionPlansUtilities apu = new ActionPlansUtilities( ap );
   		apu.apTasks = new List<APTaskTemplate__c>();
   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );
   		
		apu.save();
		
		ActionPlanTemplate__c apt = ge.createNewActionPlanTemplate( 5 );
		ApexPages.currentPage().getParameters().put( 'templateId', apt.Id );
		ActionPlansUtilities apu2 = new ActionPlansUtilities( new ActionPlan__c() );
		apu2.apTasks = apu2.getTasks();
		
		System.assert( !apu2.apTasks.isEmpty() );
		
		test.stopTest();		
	}	
	
	
	private static testMethod void APUtestSaveMasiveMethodOpportunities() {
		test.startTest();
				
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
		
		ActionPlanTemplate__c apt = ge.createNewActionPlanTemplate( 5 );
		ApexPages.currentPage().getParameters().put( 'templateId', apt.Id );
		apu = new ActionPlansUtilities( new ActionPlan__c() );
		apu.apTasks = apu.getTasks();
		
		System.assert( !apu.apTasks.isEmpty() );
		
		test.stopTest();		
	}	
	
	
	private static testMethod void APUtestSaveMasiveMethodCase() {
		
		Map<String,String> objectDetails = new Map<String,String>();
		objectDetails.put('cases','Case');
		APUtestSaveMasiveMethod(objectDetails);
	}

	private static testMethod void APUtestSaveMasiveMethodContact() {
		Map<String,String> objectDetails = new Map<String,String>();
		objectDetails.put('contacts','Contact');
		APUtestSaveMasiveMethod(objectDetails);
	}

	private static testMethod void APUtestSaveMasiveMethodLead() {
		Map<String,String> objectDetails = new Map<String,String>();
		
		objectDetails.put('leads','Lead');
		APUtestSaveMasiveMethod(objectDetails);
	}
	
	private static testMethod void APUtestSaveMasiveMethodContract() {
		
		Map<String,String> objectDetails = new Map<String,String>();
		objectDetails.put('contracts','Contract');
		APUtestSaveMasiveMethod(objectDetails);
	}

	private static testMethod void APUtestSaveMasiveMethodCampaign() {
		Map<String,String> objectDetails = new Map<String,String>();

		objectDetails.put('campaigns','Campaign');
		APUtestSaveMasiveMethod(objectDetails);
	}

	private static testMethod void APUtestSaveMasiveMethodOpportunity() {
		Map<String,String> objectDetails = new Map<String,String>();

		objectDetails.put('opportunitys','Opportunity');
		APUtestSaveMasiveMethod(objectDetails);
	}

	private static void APUtestSaveMasiveMethod(Map<String,String> objectDetails) {
		
		test.startTest();
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		ActionPlan__c ap = null;		
		for(String k : objectDetails.keySet()){
			ap = ge.createNewActionPlan( k, 0 );
			ap.SkipWeekends__c 	= true;
			ap.SkipDay__c = 'Monday';
			update ap;
			
			ApexPages.currentPage().getParameters().put( 'refType', objectDetails.get(k) );
			
			
			ActionPlansUtilities apu = new ActionPlansUtilities( ap );
	   		apu.apTasks = new List<APTaskTemplate__c>();
	   		apu.apTasks.add( ActionPlansUtilitiesTest.apptask( ap ) );
	
			apu.save();
			
			ActionPlanTemplate__c apt = ge.createNewActionPlanTemplate( 5 );
			ApexPages.currentPage().getParameters().put( 'templateId', apt.Id );
			apu = new ActionPlansUtilities( new ActionPlan__c() );
			apu.apTasks = apu.getTasks();
			
			System.assert( !apu.apTasks.isEmpty() );
		}		
				
		test.stopTest();		
	}
	
	private static testMethod void APUtestCancelNothing() {
		Test.startTest();
		ActionPlansUtilities apu = new ActionPlansUtilities();
		PageReference page = apu.cancel();
		System.assert( page!= null );
		Test.stopTest();
	}

	private static testMethod void APUtestCancelAccount() {
		Test.startTest();
		ActionPlansUtilities apu = new ActionPlansUtilities();
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'accounts', 0 );
		ApexPages.currentPage().getParameters().put( 'refType', 'Account' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Account__c + ',' + ge.createNewAccount().id);
		PageReference page = apu.cancel();
		System.assert( page!= null );
		Test.stopTest();
	}

	private static testMethod void APUtestCancelContact() {
		Test.startTest();
		ActionPlansUtilities apu = new ActionPlansUtilities();
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'contacts', 0 );
		ApexPages.currentPage().getParameters().put( 'refType', 'Contact' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Contact__c + ',' + ge.createNewContact().id);
		PageReference page = apu.cancel();
		System.assert( page!= null );
		Test.stopTest();
	}

	private static testMethod void APUtestCancelLead() {
		Test.startTest();
		ActionPlansUtilities apu = new ActionPlansUtilities();
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'leads', 0 );
		ApexPages.currentPage().getParameters().put( 'refType', 'Lead' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Lead__c + ',' + ge.createNewLead().id);
		PageReference page = apu.cancel();
		System.assert( page!= null );
		Test.stopTest();
	}

	private static testMethod void APUtestCancelOpportunity() {
		Test.startTest();
		ActionPlansUtilities apu = new ActionPlansUtilities();
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'opportunitys', 0 );
		ApexPages.currentPage().getParameters().put( 'refType', 'Opportunity' );
		ApexPages.currentPage().getParameters().put( 'refId' ,  ap.Opportunity__c + ',' + ge.createNewOpportunity().id);
		PageReference page = apu.cancel();
		System.assert( page!= null );
		Test.stopTest();
	}

	private static testMethod void APUtestCancelCase() {
		Test.startTest();
		ActionPlansUtilities apu = new ActionPlansUtilities();
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'cases', 0 );
		ApexPages.currentPage().getParameters().put( 'refType', 'Case' );
		ApexPages.currentPage().getParameters().put( 'refId' , ap.Case__c + ',' + ge.createNewCase().id);
		PageReference page = apu.cancel();
		System.assert( page!= null );
		Test.stopTest();
	}

	private static testMethod void APUtestCancelContract() {
		Test.startTest();
		ActionPlansUtilities apu = new ActionPlansUtilities();
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();

		ActionPlan__c ap = ge.createNewActionPlan( 'contracts', 0 );
		ApexPages.currentPage().getParameters().put( 'refType', 'Contract' );
		ApexPages.currentPage().getParameters().put( 'refId' , ap.Contract__c + ',' + ge.createNewContract().id);
		PageReference page = apu.cancel();
		System.assert( page!= null );
		Test.stopTest();
	}

	private static testMethod void APUtestCancelTemplate() {
		Test.startTest();
		ActionPlansUtilities apu = new ActionPlansUtilities();
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		
		ActionPlanTemplate__c apt = ge.createNewActionPlanTemplate( 0 );
		ApexPages.currentPage().getParameters().put( 'templateId', apt.Id );
		PageReference page = apu.cancel();
		System.assert( page!= null );
		Test.stopTest();
	}
	
	private static Map<String, ActionPlan__c> APUtestRelatedObjectId(String planType) {
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		
		ActionPlan__c ap = ge.createNewActionPlan( planType, 0 );
		ActionPlansUtilities apu = new ActionPlansUtilities(ap);
		String id = apu.relatedObjectId();

		Map<String, ActionPlan__c> m = new Map<String, ActionPlan__c>();
		m.put(id, ap);
		return m;
	}

	public static testMethod void APUtestRelatedObjectIdAccounts() {
		test.startTest();
		Map<String, ActionPlan__c> m = APUtestRelatedObjectId('accounts');
		for(String id : m.keySet()) {
			System.assertEquals( m.get(id).Account__c, id);
		}
		test.stopTest();
	}

	public static testMethod void APUtestRelatedObjectIdContacts() {
		test.startTest();
		Map<String, ActionPlan__c> m = APUtestRelatedObjectId('contacts');
		for(String id : m.keySet()) {
			System.assertEquals( m.get(id).Contact__c, id);
		}
		test.stopTest();
	}

	public static testMethod void APUtestRelatedObjectIdLeads() {
		test.startTest();
		Map<String, ActionPlan__c> m = APUtestRelatedObjectId('leads');
		for(String id : m.keySet()) {
			System.assertEquals( m.get(id).Lead__c, id);
		}
		test.stopTest();
	}

	public static testMethod void APUtestRelatedObjectIdOpportunitys() {
		test.startTest();
		Map<String, ActionPlan__c> m = APUtestRelatedObjectId('opportunitys');
		for(String id : m.keySet()) {
			System.assertEquals( m.get(id).Opportunity__c, id);
		}
		test.stopTest();
	}
	
	private static testMethod void APUtestHoursOption() {
		test.startTest();
			
		ActionPlansUtilities apu = new ActionPlansUtilities();
		List<selectOption>options = new List<selectOption>();
		options = apu.getHoursOption();
		
		System.assert( !options.isEmpty() );
		
		test.stopTest();
	}    

	private static testMethod void APUtestGetRecordOwnerIdAccounts() {
		
		test.startTest();
		
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		List<String> oIds = new List<String>();
		
		ActionPlan__c ap = ge.createNewActionPlan( 'accounts', 0 );
		ActionPlansUtilities apu = new ActionPlansUtilities(ap);
		Account a = [select Id, OwnerId from Account where id =:ap.Account__c]; 
		oIds.add(a.Id);
		apu.retrieveOwnersDataRelatedObject(oIds, 'Account');
		String owner = apu.getRecordOwnerId(ap);
		System.assertEquals(a.OwnerId, owner);
		test.stopTest();
	}


	private static testMethod void APUtestGetRecordOwnerIdCases() {

		test.startTest();
		
		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		List<String> oIds = new List<String>();

		ActionPlan__c ap = ge.createNewActionPlan( 'cases', 0 );
		ActionPlansUtilities apu = new ActionPlansUtilities(ap);
		Case c = [select Id, OwnerId from Case where id =:ap.Case__c];
		oIds.add(c.Id);
		apu.retrieveOwnersDataRelatedObject(oIds, 'Case');
		String owner = apu.getRecordOwnerId(ap);
		System.assertEquals(c.OwnerId, owner);
		test.stopTest();
	}

	private static testMethod void APUtestGetRecordOwnerIdContacts() {
		
		test.startTest();

		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		List<String> oIds = new List<String>();

		ActionPlan__c ap = ge.createNewActionPlan( 'contacts', 0 );
		ActionPlansUtilities apu = new ActionPlansUtilities(ap);
		Contact contact = [select Id, OwnerId from Contact where id =:ap.Contact__c];
		oIds.add(contact.Id);
		apu.retrieveOwnersDataRelatedObject(oIds, 'Contact');
		String owner = apu.getRecordOwnerId(ap);
		System.assertEquals(contact.OwnerId, owner);
		test.stopTest();
	}
		
	private static testMethod void APUtestGetRecordOwnerIdContracts() {

		test.startTest();

		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		List<String> oIds = new List<String>();

		ActionPlan__c ap = ge.createNewActionPlan( 'contracts', 0 );
		ActionPlansUtilities apu = new ActionPlansUtilities(ap);
		Contract contract = [select Id, OwnerId from Contract where id =:ap.Contract__c];
		oIds.add(contract.Id);
		apu.retrieveOwnersDataRelatedObject(oIds, 'Contract');
		String owner = apu.getRecordOwnerId(ap);
		System.assertEquals(contract.OwnerId, owner);
		test.stopTest();
	}

	private static testMethod void APUtestGetRecordOwnerIdLeads() {
		
		test.startTest();

		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		List<String> oIds = new List<String>();

		ActionPlan__c ap = ge.createNewActionPlan( 'leads', 0 );
		ActionPlansUtilities apu = new ActionPlansUtilities(ap);
		Lead l = [select Id, OwnerId from Lead where id =:ap.Lead__c];
		oIds.add(l.Id);
		apu.retrieveOwnersDataRelatedObject(oIds, 'Lead');
		String owner = apu.getRecordOwnerId(ap);
		System.assertEquals(l.OwnerId, owner);
		test.stopTest();
	}

	private static testMethod void APUtestGetRecordOwnerIdOpportunitys() {
		
		test.startTest();

		ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
		List<String> oIds = new List<String>();

		ActionPlan__c ap = ge.createNewActionPlan( 'opportunitys', 0 );
		ActionPlansUtilities apu = new ActionPlansUtilities(ap);
		Opportunity o = [select Id, OwnerId from Opportunity where id =:ap.Opportunity__c];
		oIds.add(o.Id);
		apu.retrieveOwnersDataRelatedObject(oIds, 'Opportunity');
		String owner = apu.getRecordOwnerId(ap);
		System.assertEquals(o.OwnerId, owner);
		
		test.stopTest();
	}
	private static void APUtestGenerateObjectFeed(String planType) {

		test.startTest();
				
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();

		ActionPlan__c ap = ge.createNewActionPlan( planType, 0 );
		ActionPlansUtilities apu = new ActionPlansUtilities(ap);
		apu.generateObjectFeed(ap.Id);
		Test.stopTest();
	}

	private static testMethod void APUtestGenerateObjectFeedAccounts() {
		APUtestGenerateObjectFeed( 'accounts' );
	}
	private static testMethod void APUtestGenerateObjectFeedCampaigns() {
		APUtestGenerateObjectFeed( 'campaigns' );
	}
	private static testMethod void APUtestGenerateObjectFeedCases() {
		APUtestGenerateObjectFeed( 'cases' );
	}
	private static testMethod void APUtestGenerateObjectFeedContacts() {
		APUtestGenerateObjectFeed( 'contacts' );
	}
	private static testMethod void APUtestGenerateObjectFeedContracts() {
		APUtestGenerateObjectFeed( 'contracts' );
	}
	private static testMethod void APUtestGenerateObjectFeedLeads() {
		APUtestGenerateObjectFeed( 'leads' );
	}
	private static testMethod void APUtestGenerateObjectFeedOpportunitys() {
		APUtestGenerateObjectFeed( 'opportunitys' );
	}
	
	public static testMethod void APUtestDeleteActionPlans() {
		
		ActionPlansTestUtilities ge =  new ActionPlansTestUtilities();
		ActionPlan__c ap 	= ge.createNewActionPlan( 'accounts', 0 );
		ActionPlan__c ap2 	= ge.createNewActionPlan( 'accounts', 0 );
		List<ActionPlan__c> lAp = new List<ActionPlan__c>();
		lAp.add(ap);
		lAp.add(ap2);
		String url = 'testURL';
		String records = ap.Id + ',' + ap2.id;
		
		ActionPlansUtilities apu = new ActionPlansUtilities(ap);
		ApexPages.currentPage().getParameters().put('retURL', url);
		ApexPages.currentPage().getParameters().put('records', records);
		test.startTest();
		Pagereference page = apu.deleteActionPlans();
		test.stopTest();
		
		List<ActionPlan__c> lAp2 = [select Id from ActionPlan__c where Id in : lAp];
		System.assert(lAp2.size() == 0);
		System.assertEquals(page.getUrl(), url);
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
   		upsert at;
   		return at;
	}
	
}