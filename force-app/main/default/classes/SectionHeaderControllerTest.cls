/**
 * Action Plans v4
 * Updated by David Schach 2021
 */
@IsTest
private class SectionHeaderControllerTest {

	@IsTest
	static void testObjectTabDescribe(){
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		User u = testUtil.createTestUser();

		Test.startTest();
		System.runAs(u){
			SectionHeaderController shc = new SectionHeaderController();
			shc.objectName = 'ActionPlan__c';
			shc.getIsCustom();
			shc.getObjectIconInfo();

			shc.objectName = 'APTaskTemplate__c';
			shc.getIsCustom();
			shc.getObjectIconInfo();

			shc.objectName = 'Account';
			shc.getIsCustom();
			shc.getObjectIconInfo();
		}
		Test.stopTest();

	}
}