@IsTest
public inherited sharing class ActionPlansRedirectTest {

	@TestSetup
	static void makeData(){

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 2 );
		ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'contact', 2 );

	}

	@IsTest
	static void aPTaskRedirect(){

		Test.startTest();
		APTaskTemplate__c aptt = [SELECT Id, Action_Plan__c FROM APTaskTemplate__c LIMIT 1];

		Test.setCurrentPage(Page.ActionPlanTaskOverride);
		ActionPlansRedirect apr = new ActionPlansRedirect(new ApexPages.StandardController(aptt));

		PageReference pr = apr.redirect();
		Test.stopTest();

		Pagereference cp = pr;
		System.assert(!cp.getURL().containsIgnoreCase(aptt.Id));
		System.debug('CurrentPage ' + cp.getURL());
		System.assert(cp.getURL().containsIgnoreCase(aptt.Action_Plan__c));

	}

	@IsTest
	static void aPTTaskRedirect(){

		Test.startTest();
		APTTaskTemplate__c apttt = [SELECT Id, Action_Plan_Template__c FROM APTTaskTemplate__c LIMIT 1];

		Test.setCurrentPage(Page.ActionPlanTemplateTaskOverride);
		ActionPlansRedirect apr = new ActionPlansRedirect(new ApexPages.StandardController(apttt));

		PageReference pr = apr.redirect();
		Test.stopTest();

		Pagereference cp = pr;
		System.assert(!cp.getURL().containsIgnoreCase(apttt.Id));
		System.debug('CurrentPage ' + cp.getURL());
		System.assert(cp.getURL().containsIgnoreCase(apttt.Action_Plan_Template__c));

	}
}
