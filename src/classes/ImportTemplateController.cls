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