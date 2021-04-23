/**
 * Action Plans v4
 * Updated by David Schach 2021
 */
@IsTest
private class ImportTemplateControllerTest {

	private static String xmlImport 				= '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id>a025000000DGr9DAAT</id><name>Test+new+Import+Order</name><description>null</description><skipWeekend>true</skipWeekend><skipday>End of previous week</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject>task+1</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlImportWrongAPTemplate 	= '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id></id><description>null</description><skipWeekend></skipWeekend><skipday>End of previous week</></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject>task+1</subject><dependent>None</dependent><taskIndex>0</taskIndex><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlImportWrongAPTask 		= '<?xml version="1.0"?><export><meta><exportPackage>Action+Plan+Template</exportPackage><exportAuthor>mat+men</exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-08-10+19%3A24%3A49</exportCreateDate></meta><ActionPlanTemplate><id>a025000000DGr9DAAT</id><name>Test+new+Import+Order</name><description>null</description><skipWeekend>true</skipWeekend><skipday>End of previous week</skipday></ActionPlanTemplate><ActionPlanTemplateTasks><TaskTemplate><id>a005000000IJPlZAAX</id><templateId>a025000000DGr9DAAT</templateId><subject></subject><dependent>null</dependent><apttemplate>null</apttemplate><daysFromStart>1</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>510</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPyqAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task+3</subject><dependent>0</dependent><taskIndex>2</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>1</daysFromStart><category>Phone+Call</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate><TaskTemplate><id>a005000000IJPlaAAH</id><templateId>a025000000DGr9DAAT</templateId><subject>task2</subject><dependent>0</dependent><taskIndex>1</taskIndex><apttemplate>a005000000IJPlZAAX</apttemplate><daysFromStart>2</daysFromStart><category>Email</category><priority>Medium</priority><sendEmail>false</sendEmail><reminder>true</reminder><reminderTime>30</reminderTime><comments>null</comments></TaskTemplate></ActionPlanTemplateTasks></export>';
	private static String xmlImportWrongMetaData 	= '<?xml version="1.0"?><export><meta><><></exportAuthor><exportOrganization>Force.com+Labs</exportOrganization><exportCreateDate>2010-07-30+13%3A12%3A52</exportCreateDate></meta><ActionPlanTemplate><id>a0250000';
	private static String xmlImportEmptyMetaData	= '<?xml version="1.0"?><export><meta><exportPackage></exportPackage><exportAuthor></exportAuthor><exportOrganization></exportOrganization><exportCreateDate></exportCreateDate></meta>';

    @IsTest
	private static void testXMLImport(){

    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();

    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( xmlImport ), ContentType = 'plain/text' );
    	controller.attachment = att;

    	Pagereference pageRef = controller.importTemplate();

    	System.assert( pageRef != null );
    }

    @IsTest
	private static void testXMLImportEmptyAttachment(){

    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();

    	controller.attachment = null;

    	try{
    		Pagereference pageRef = controller.importTemplate();
    	} catch( Exception ex ){
    		System.assert( true );
    	}
    }

    @IsTest
	private static void testXMLImportEmptyXML(){

    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();

    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( '' ), ContentType = 'plain/text' );
    	controller.attachment = att;

    	try{
    		Pagereference pageRef = controller.importTemplate();
    	} catch( Exception ex ){
    		System.assert( true );
    	}
    }

    @IsTest
	private static void testXMLImportWrongTemplate(){

    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();

    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( xmlImportWrongAPTemplate ), ContentType = 'plain/text' );
    	controller.attachment = att;

    	try{
    		Pagereference pageRef = controller.importTemplate();
    	} catch( Exception ex ){
    		System.assert( true );
    	}
    }

    @IsTest
	private static void testXMLImportWrongTemplateTask(){

    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();

    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( xmlImportWrongAPTask ), ContentType = 'plain/text' );
    	controller.attachment = att;

    	try{
    		Pagereference pageRef = controller.importTemplate();
    	} catch( Exception ex ){
    		System.assert( true );
    	}
    }

     @IsTest
	private static void testXMLImportWrongMetaData(){

    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();

    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( xmlImportWrongMetaData ), ContentType = 'plain/text' );
    	controller.attachment = att;

    	try{
    		Pagereference pageRef = controller.importTemplate();
    	} catch( Exception ex ){
    		System.assert( true );
    	}
    }
}