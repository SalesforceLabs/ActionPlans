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
		Id xmlId = exportTemplate.export();

		Test.StopTest();

		System.assert( xmlId != null );
	}

	@IsTest
	private static void exportDocTest(){

		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );

		ExportActionPlanTemplate exportTemplate = new ExportActionPlanTemplate( actionPlanTemplate.Id );
		String xml = exportTemplate.buildXmlString( actionPlanTemplate );

		Id xmlId = exportTemplate.saveToDocument('templateName', xml);

		Test.StopTest();

		System.assert( xmlId != null );
	}

	@IsTest
	private static void exportFileTest(){

		Test.StartTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );

		ExportActionPlanTemplate exportTemplate = new ExportActionPlanTemplate( actionPlanTemplate.Id );
		String xml = exportTemplate.buildXmlString( actionPlanTemplate );

		Id xmlId = exportTemplate.saveToContent('templateName', xml);

		Test.StopTest();

		System.assert( xmlId != null );
	}
}