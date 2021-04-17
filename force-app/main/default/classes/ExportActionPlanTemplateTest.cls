/**
 * Action Plans v4
 * Updated by David Schach 2021
 */
@IsTest
private class ExportActionPlanTemplateTest {
    @IsTest
	private static void exportTest(){

		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );

		ExportActionPlanTemplate exportTemplate = new ExportActionPlanTemplate( actionPlanTemplate.Id );
		Document doc = exportTemplate.export();

		System.assert( doc != null );

		Test.StopTest();
	}
}