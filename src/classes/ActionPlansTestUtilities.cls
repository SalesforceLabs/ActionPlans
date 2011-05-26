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
public with sharing class ActionPlansTestUtilities{
	
	/**
	* Attributes 
	*/ 
 	public ActionPlan__c 		 tAP		{ get; set; }
 	public APTaskTemplate__c	 tAPTask	{ get; set; }
 	public ActionPlanTemplate__c tAPT		{ get; set; }
 	public APTTaskTemplate__c	 tAPTTask	{ get; set; }
 	
 	//Lists
 	public List<APTaskTemplate__c>	tAPTList	{ get; set; }
 	public List<APTTaskTemplate__c>	tAPTTList	{ get; set; }
 	public List<Task>				tTaskList	{ get; set; }
 	
 	public User			tUser { get; set; }
 	public Account		tAcc  { get; set; }
 	public Lead			tLead { get; set; }
 	public Opportunity	tOpp  { get; set; }
 	public Contact		tCon  { get; set; }
 	public Task			tTask { get; set; }
 	
 	public String 		xmlImport				 { get; set; }
 	public String 		xmlImportWrongAPTemplate { get; set; }
 	public String 		xmlImportWrongAPTask	 { get; set; }
 	public String 		xmlImportWrongMetaData	 { get; set; }
 	public String 		xmlImportEmptyMetaData	 { get; set; }
 	
 	public ActionPlansTestUtilities(){
 		this.xmlImport 					= '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id>a025000000DGr9DAAT</id><name>Test+new+Import+Order</name><description>null</description><skipWeekend>true</skipWeekend><skipday>Friday</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject>task+1</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
 		this.xmlImportWrongAPTemplate 	= '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id></id><description>null</description><skipWeekend></skipWeekend><skipday>Friday</></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject>task+1</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
 		this.xmlImportWrongAPTask 		= '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id>a025000000DGr9DAAT</id><name>Test+new+Import+Order</name><description>null</description><skipWeekend>true</skipWeekend><skipday>Friday</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject></subject><dependent>null</dependent><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
 		this.xmlImportWrongMetaData 	= '<?xml version="1.0"?><export><meta><><></exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-07-30+13%3A12%3A52</exportCreateDate></meta><ActionPlanTemplate><id>a0250000';
 		this.xmlImportEmptyMetaData		= '<?xml version="1.0"?><export><meta><exportPackage></exportPackage><exportAuthor></exportAuthor><exportOrganization></exportOrganization><exportCreateDate></exportCreateDate></meta>';
 	}
 	
 	/**
    * Random words are required for testing 
    * as you will likely run into any word I can insert
    * during a test class and produce false test results.
    */
    public String createRandomWord() {
      
      String ret = 'word' + math.rint(math.random() * 100000);
      
      return ret;
    }
 
 	/*
    * A random user is useful for testing in order to be 
    * sure that you are able to see data across posts regardless
    * of follow status.
  	*/
  	public User createTestUser() {
    	for( Profile p : [ Select Id, PermissionsModifyAllData, Name from Profile limit 100 ] ){
    		if( p.PermissionsModifyAllData ){
    			return this.createTestUser( p );
    		}
    	}
    	return new User();
  	}
  
  	/**
 	* Creates a new User
 	* @return testUser
 	*/
  	public User createTestUser( Profile p ) {
    
    	String namePrefix = this.createRandomWord();
    
    	User testUser = new User();
    	testUser.Email 				= 'test@test.com';
    	testUser.Username 			= namePrefix + '@testuser.com';
    	testUser.LastName 			= 'test';
    	testUser.Alias 				= 'test';
    	testUser.ProfileId 			= p.Id;
    	testUser.LanguageLocaleKey 	= 'en_US';
    	testUser.LocaleSidKey 		= 'en_US';
    	testUser.TimeZoneSidKey 	= 'America/Chicago';
    	testUser.EmailEncodingKey 	= 'UTF-8';
    	
    	insert testUser;
    	
    	return testUser;
  	}
 	
 	/**
 	* Creates a new Account Object 
 	* @return newAccount
 	*/
 	public Account createNewAccount(){
 		
 		Account newAccount 	= new Account();
 		newAccount.Name 	= this.createRandomWord();
 		
 		try{
 			insert newAccount;
 		}
 		catch( Exception ex ){
 			System.assert( false ,'Pre deploy test failed, This may be because of custom validation rules in your Org. You '
 				+ 'can check ignore apex errors or temporarily deactivate your validation rules for Accounts and try again.');
 		}
 		
 		return newAccount;
 	}
 	
 	/**
 	* Creates a new Campaign Object 
 	* @return newCampaign
 	*/
 	public Campaign createNewCampaign(){
 		
 		Campaign newCampaign 	= new Campaign();
 		newCampaign.Name		= this.createRandomWord();
 		
 		try{
 			insert newCampaign;
 		}
 		catch( Exception ex ){
 			System.assert( false ,'Pre deploy test failed, This may be because of custom validation rules in your Org. You '
 				+ 'can check ignore apex errors or temporarily deactivate your validation rules for Campaigns and try again.');
 		}
 		
 		return newCampaign;
 	}
 	
 	/**
 	* Creates a new Case Object 
 	* @return newCase
 	*/
 	public Case createNewCase(){
 		
 		Case newCase 	= new Case();
 		newCase.Status	= 'New';
 		newCase.Origin	= 'Email'; 
 		
 		try{
 			insert newCase;
 		}
 		catch( Exception ex ){
 			System.assert( false ,'Pre deploy test failed, This may be because of custom validation rules in your Org. You '
 				+ 'can check ignore apex errors or temporarily deactivate your validation rules for Cases and try again.');
 		}
 		
 		return newCase;
 	}
 	
 	/**
 	* Creates a new Contact Object
 	* @return newContact
 	*/
 	public Contact createNewContact(){
 		
 		Contact newContact 	= new Contact();
 		newContact.LastName = this.createRandomWord();
 		
 		try{
 			insert newContact;
 		}
 		catch( Exception ex ){
 			System.assert( false ,'Pre deploy test failed, This may be because of custom validation rules in your Org. You '
 				+ 'can check ignore apex errors or temporarily deactivate your validation rules for Contacts and try again.');
 		}
 		
 		return newContact;
 	}
 	
 	/**
 	* Creates a new Contract Object
 	* @return newContract
 	*/
 	public Contract createNewContract(){
 		
 		Contract newContract 		= new Contract();
 		Account a 					= this.createNewAccount();
 		newContract.AccountId	 	= a.Id;
 		newContract.StartDate		= Date.today();
 		newContract.ContractTerm 	= 1;
 		
 		try{
 			insert newContract;
 		}
 		catch( Exception ex ){
 			System.assert( false ,'Pre deploy test failed, This may be because of custom validation rules in your Org. You '
 				+ 'can check ignore apex errors or temporarily deactivate your validation rules for Contracts and try again.');
 		}
 		
 		return newContract;
 	}
 	
 	/**
 	* Creates a new Lead Object 
 	* @return newLead
 	*/
 	public Lead createNewLead(){
 		
 		Lead newLead 		= new Lead();
 		newLead.LastName	= this.createRandomWord();
 		newLead.Company		= this.createRandomWord();
 		newLead.Status		= 'Open - Not Contacted';
 		
 		try{
 			insert newLead;
 		}
 		catch( Exception ex ){
 			System.assert( false ,'Pre deploy test failed, This may be because of custom validation rules in your Org. You '
 				+ 'can check ignore apex errors or temporarily deactivate your validation rules for Leads and try again.');
 		}
 		
 		return newLead;
 	}
 	
 	/**
 	* Creates a new Opportunity Object 
 	* @return newOpportunity
 	*/
 	public Opportunity createNewOpportunity(){
 		
 		Opportunity newOpportunity 	= new Opportunity();
 		newOpportunity.Name			= this.createRandomWord();
 		newOpportunity.CloseDate	= Date.today();
 		newOpportunity.StageName	= 'Prospecting';
 		
 		try{
 			insert newOpportunity;
 		}
 		catch( Exception ex ){
 			System.assert( false ,'Pre deploy test failed, This may be because of custom validation rules in your Org. You '
 				+ 'can check ignore apex errors or temporarily deactivate your validation rules for Opportunitys and try again.');
 		}
 		
 		return newOpportunity;
 	}
 	
 	/**
 	* Create Action Plan 
 	* @param relatedObject
 	* @return newActionPlan
 	*/
 	public ActionPlan__c createNewActionPlan( String relatedObject, Integer numTasks ){
 		
 		ActionPlan__c newActionPlan = new ActionPlan__c();
 		newActionPlan.Name			= this.createRandomWord();
 		newActionPlan.StartDate__c 	= Date.today();
 		newActionPlan.OwnerId		= Userinfo.getUserId();
 		
 		if( 'accounts'.equalsIgnoreCase( relatedObject ) ){
 			newActionPlan.Account__c = this.createNewAccount().Id;
 		}
 		if( 'campaigns'.equalsIgnoreCase( relatedObject ) ){
 			newActionPlan.Campaign__c = this.createNewCampaign().Id;
 		}
 		if( 'cases'.equalsIgnoreCase( relatedObject ) ){
 			newActionPlan.Case__c = this.createNewCase().Id;
 		}
 		if( 'contacts'.equalsIgnoreCase( relatedObject ) ){
 			newActionPlan.Contact__c = this.createNewContact().Id;
 		}
 		if( 'contracts'.equalsIgnoreCase( relatedObject ) ){
 			newActionPlan.Contract__c = this.createNewContract().Id;
 		}
 		if( 'leads'.equalsIgnoreCase( relatedObject ) ){
 			newActionPlan.Lead__c = this.createNewLead().Id;
 		}
 		if( 'opportunitys'.equalsIgnoreCase( relatedObject ) ){
 			newActionPlan.Opportunity__c = this.createNewOpportunity().Id;
 		}
 		
 		//ShouldBeRefactoerized
 		
 		try{
 			insert newActionPlan;
 		}
 		catch( Exception ex ){
 			System.assert( false ,' Inserting Action Plan failed,' + ex );
 		}
 		
 		APTaskTemplate__c auxTask = new APTaskTemplate__c();
 		User user = this.createTestUser();

 		//Creates default tasks for Action Plan
 		for( Integer i = 0; i < numTasks; i++ ){
 			auxTask = this.createNewActionPlanTask( newActionPlan, 1, user, 'Email', 'High' );
 		}
 		
 		
 		
 		return newActionPlan;
 	}
 	
 	/**
 	* Create Action Plan task Object
 	* @return newAPTask
 	*/
 	public APTaskTemplate__c createNewActionPlanTask( ActionPlan__c actionPlan , Integer days, User user, String category, String priority ){
 		
 		APTaskTemplate__c newAPTask = new APTaskTemplate__c();
 		newAPTask.Subject__c 		= this.createRandomWord();
 		newAPTask.DaysFromStart__c 	= days;
 		newAPTask.Action_Plan__c 	= actionPlan.Id;
 		newAPTask.User__c 			= user.Id;
 		newAPTask.Type__c 			= category;
 		newAPTask.Priority__c 		= priority;
 		newAPTask.Minutes_Reminder__c = '510';
 		
 		try{
 			insert newAPTask;
 		}
 		catch( Exception ex ){
 			System.assert( false ,' Inserting Action Plan task failed,' + ex );
 		}
 				
 		return newAPTask;
 	}
 	
 	/**
 	* Create Action Plan 
 	* @return apTemplate
 	*/
 	public ActionPlanTemplate__c createNewActionPlanTemplate( Integer numTasks ){
 		
 		ActionPlanTemplate__c apTemplate = new ActionPlanTemplate__c();
 		apTemplate.Name = this.createRandomWord();
 		
 		try{
 			insert apTemplate;
 		}
 		catch( Exception ex ){
 			System.assert( false ,' Inserting Action Plan Template failed,' + ex );
 		}
 		
 		APTTaskTemplate__c auxTask = new APTTaskTemplate__c();
 		//Creates default tasks for Action Plan
 		for( Integer i = 0; i < numTasks; i++ ){
 			auxTask = this.createNewActionPlanTemplateTask( apTemplate, 1, null, 'Email', 'High' );
 		}
 		
 		return apTemplate;
 	}
    
    /**
 	* Create Action Plan Template Task
 	* @return newAPTTask
 	*/
    public APTTaskTemplate__c createNewActionPlanTemplateTask( ActionPlanTemplate__c apTemplate, Integer days, User user, String category, String priority ){
 		
 		APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();
 		
 		newAPTTask.Action_Plan_Template__c 	= apTemplate.Id;
 		newAPTTask.Subject__c 				= this.createRandomWord();
 		newAPTTask.DaysFromStart__c 		= days;
 		newAPTTask.Dependent__c				= 'None';
 		if( user != null ){
 			newAPTTask.User__c = user.Id;
 		}
 		newAPTTask.Type__c 		= category;
 		newAPTTask.Priority__c 	= priority;
 		newAPTTask.Minutes_Reminder__c = '510';
 		
 		try{
 			insert newAPTTask;
 		}
 		catch( Exception ex ){
 			System.assert( false ,' Inserting Action Plan Template task failed,' + ex );
 		}
 				
 		return newAPTTask;
 	}
 	
 	/**
 	* Create Enviroment for BatchProcess
 	* return apTasksIds
 	*/
 	public List<String> batchIds( String ref ){
 		
	 		ActionPlan__c ap = this.createNewActionPlan( ref ,0);
			List<String> apTasksIds = new List<String>();
		
			APTaskTemplate__c at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = this.createTestUser().Id;
	   		at.SendEmail__c		 = false;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasksIds.add(at.Id);
	   		
	   		at = new APTaskTemplate__c();
	   		at.Action_Plan__c 	 = ap.Id;
	   		at.Dependent__c		 = 'None';
	   		at.DaysFromStart__c  = 2.0;
	   		at.User__c			 = this.createTestUser().Id;
	   		at.SendEmail__c		 = true;
	   		at.Subject__c		 = 'Test ';
	   		at.Type__c			 = 'Email';
	   		at.Priority__c		 = 'Low';
	   		at.Comments__c		 = 'Test';
	   		at.Reminder__c		 = true;
	   		at.Minutes_Reminder__c = '510';
	   		insert at;
	   		apTasksIds.add(at.Id);
	   		
	   		return apTasksIds;
 	}

    static TestMethod void testbatchIds(){
      
      ActionPlansTestUtilities apTestUtil = new ActionPlansTestUtilities();
      
      System.assert( apTestUtil.batchIds('accounts') != null );
    }
    
     static TestMethod void testRandomWord(){
      
      ActionPlansTestUtilities apTestUtil = new ActionPlansTestUtilities();
      
      System.assert( apTestUtil.createRandomWord() != apTestUtil.createRandomWord() );
    }
    /*
	static TestMethod void testcreateNewActionPlanTemplateTask(){
    
		test.startTest();
			ActionPlansTestUtilities apTestUtil = new ActionPlansTestUtilities();	      
			apTestUtil.createNewActionPlanTemplateTask( null,1,new User(),'EMAIL','LOW');
		test.stopTest();
    }   
    
	static TestMethod void testcreateNewActionPlanTask(){
    
		test.startTest();
			ActionPlansTestUtilities apTestUtil = new ActionPlansTestUtilities();	      
			apTestUtil.createNewActionPlanTask( null,1,new User(),'EMAIL','LOW');
		test.stopTest();
    }     

   	static TestMethod void testcreateNewActionPlan(){
    
		test.startTest();
			ActionPlansTestUtilities apTestUtil = new ActionPlansTestUtilities();	      
			apTestUtil.createNewActionPlan( 'REL_OBJECT',0);
		test.stopTest();
    }  */
}