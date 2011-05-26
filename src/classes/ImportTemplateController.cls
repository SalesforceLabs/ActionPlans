/**
* @author Matias Menafra
* @createdate 07/28/2010
*/
public with sharing class ImportTemplateController{
	
	public Attachment attachment { get; set; }

	/**
	* Constructor
	*/
    public ImportTemplateController(){
    	this.attachment = new Attachment();
    }
    
    /**
	* Action that initiates the Import process
	* @return PageReference
	*/
    public PageReference importTemplate(){
		
		ImportActionPlanTemplate importUtil = new ImportActionPlanTemplate();
		
		try{
			String templateId = importUtil.processImportedDocument( this.attachment );
    		
    		return new Pagereference( '/apex/ActionPlanTemplateDetail?id=' + templateId );
    	}catch( Exception ex ){
    		//we initialize again the attachment when an error ocurres to prevent viewstate size errors
    		this.attachment = new Attachment();
    		ApexPages.addMessages( ex );
    	}
    	
    	return null;
    }
    
    public static testMethod void testXMLImport(){
    
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();
    	
    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( testUtil.xmlImport ), ContentType = 'plain/text' );
    	controller.attachment = att;
    	
    	Pagereference pageRef = controller.importTemplate();
    	
    	System.assert( pageRef != null );
    }
    
    public static testMethod void testXMLImportEmptyAttachment(){
    
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();
    	
    	controller.attachment = null;
    	
    	try{
    		Pagereference pageRef = controller.importTemplate();
    	}catch( Exception ex ){
    		System.assert( true );
    	}
    }
    
    public static testMethod void testXMLImportEmptyXML(){
    
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();
    	
    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( '' ), ContentType = 'plain/text' );
    	controller.attachment = att;
    	
    	try{
    		Pagereference pageRef = controller.importTemplate();
    	}catch( Exception ex ){
    		System.assert( true );
    	}
    }
    
    public static testMethod void testXMLImportWrongTemplate(){
    
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();
    	
    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( testUtil.xmlImportWrongAPTemplate ), ContentType = 'plain/text' );
    	controller.attachment = att;
    	
    	try{
    		Pagereference pageRef = controller.importTemplate();
    	}catch( Exception ex ){
    		System.assert( true );
    	}
    }
    
    public static testMethod void testXMLImportWrongTemplateTask(){
    
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();
    	
    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( testUtil.xmlImportWrongAPTask ), ContentType = 'plain/text' );
    	controller.attachment = att;
    	
    	try{
    		Pagereference pageRef = controller.importTemplate();
    	}catch( Exception ex ){
    		System.assert( true );
    	}
    }
    
     public static testMethod void testXMLImportWrongMetaData(){
    
    	ActionPlansTestUtilities testUtil 	= new ActionPlansTestUtilities();
    	ImportTemplateController controller = new ImportTemplateController();
    	
    	Attachment att = new Attachment( Name = 'Test Xml', Body = Blob.valueOf( testUtil.xmlImportWrongMetaData ), ContentType = 'plain/text' );
    	controller.attachment = att;
    	
    	try{
    		Pagereference pageRef = controller.importTemplate();
    	}catch( Exception ex ){
    		System.assert( true );
    	}
    }
}