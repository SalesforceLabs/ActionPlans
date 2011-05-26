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
public with sharing class ExportActionPlanTemplate{
	
	private String templateId;
	
	/**
	* Constructor
	* @param templateId
	*/
	public ExportActionPlanTemplate( String templateId ){
		
		this.templateId = templateId;
	}
	
	/**
	* Method in charge of handling the export task related to a Action Plan Template
	* @return doc
	*/
	public Document export(){
		
		ActionPlanTemplate__c apTemplate = [ Select a.SkipWeekends__c, a.SkipDay__c, a.Name, a.Id, a.Description__c,
												( Select Id, Name, Action_Plan_Template__c, APTTaskTemplate__c, Comments__c, DaysFromStart__c, Dependent__c, 
													Priority__c, Reminder__c, SendEmail__c, Subject__c, Type__c, Minutes_Reminder__c , taskIndex__c From apTasks__r )
												From ActionPlanTemplate__c a where a.Id =: this.templateId ];
		
		String xml 		= buildXmlString( apTemplate );
		Document doc 	= saveToDocument( apTemplate.name, xml );
		
		return doc;
	}
	
	/**
	* Method in charge of saving document in personal folder for later retrievel
	* @param name
	* @param xml
	* @return doc
	*/
	private Document saveToDocument( String name, String xml ){
		
		Document doc = new Document();
		doc.body 			= Blob.valueOf( xml );
		doc.ContentType 	= 'application/force-download';
		doc.name 			= 'Export - ' + name + ' - ' + System.now()+'.xml';
		doc.FolderId 		= UserInfo.getUserId();
		
		insert doc;
		
		return doc;
	}
	
	/**
	* Method in charge of compiling XML document for a given Action Plan Template and child tasks
	* @param target
	* @return ret
	*/
	private String buildXmlString( ActionPlanTemplate__c target ){

		Xmlstreamwriter out = new Xmlstreamwriter();
		
		out.writeStartDocument( null, '1.0' );
		
		out.writeStartElement( null, 'export', null );
		out.writeStartElement( null, 'meta', null );
		
		writeElement( out, 'exportPackage', 'Action Plan Template' );
		writeElement( out, 'exportAuthor', UserInfo.getName() );
		writeElement( out, 'exportOrganization', UserInfo.getOrganizationName() );		
		writeElement( out, 'exportCreateDate', '' + System.now() );	
		
		out.writeEndElement();
		
		out.writeStartElement( null, 'ActionPlanTemplate', null );
		
		writeElement( out, 'id', target.id );
		writeElement( out, 'name', target.name );
		writeElement( out, 'description', '' + target.Description__c );
		writeElement( out, 'skipWeekend', '' + String.valueOf( target.SkipWeekends__c ) );
		writeElement( out, 'skipday', '' + target.SkipDay__c );
		
		out.writeEndElement();
		out.writeStartElement( null, 'ActionPlanTemplateTasks', null );

		for( APTTaskTemplate__c currentTask : target.apTasks__r ){
			out.writeStartElement( null, 'TaskTemplate', null );
			writeElement( out, 'id', '' + currentTask.Id );
			writeElement( out, 'templateId', '' + currentTask.Action_Plan_Template__c );
			writeElement( out, 'subject', '' + currentTask.Subject__c );
			if(target.apTasks__r.size() == 1){
				writeElement( out, 'dependent', '' + Label.ap_None );
				writeElement( out, 'taskIndex', '0' );
			}
			else{
				writeElement( out, 'dependent', '' + currentTask.Dependent__c );
				writeElement( out, 'taskIndex', '' + String.valueOf( currentTask.TaskIndex__c ) );
			}
			writeElement( out, 'apttemplate', '' + currentTask.APTTaskTemplate__c );
			writeElement( out, 'daysFromStart', '' + String.valueOf( currentTask.DaysFromStart__c ) );
			writeElement( out, 'category', '' + currentTask.Type__c );
			writeElement( out, 'priority', '' + currentTask.Priority__c );
			writeElement( out, 'sendEmail', '' + String.valueOf( currentTask.SendEmail__c ) );
			writeElement( out, 'reminder', '' + String.valueOf( currentTask.Reminder__c ) );
			//removed Minutes_Reminder__c field 
			//writeElement( out, 'reminderTime', currentTask.Minutes_Reminder__c );
			writeElement( out, 'comments', '' + currentTask.Comments__c );
			
			out.writeEndElement();
		}

		out.writeEndElement();
		out.writeEndElement();
		out.writeEndDocument();
		
		String ret = out.getXmlString();
		
		out.close();

		return ret;
	}
	
	/**
	* Method used for sanatizing input for XML document 
	* @param out
	* @param tag
	* @param content
	*/
	private void writeElement( Xmlstreamwriter out, String tag, String content ){
		
		out.writeStartElement( null, tag, null );
		out.writeCharacters( EncodingUtil.urlEncode( content, 'UTF-8' ) );
		out.writeEndElement();	
	}
	
	public static testmethod void exportTest(){
	
		Test.StartTest();
		
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate( 3 );
		
		ExportActionPlanTemplate exportTemplate = new ExportActionPlanTemplate( actionPlanTemplate.Id );
		Document doc = exportTemplate.export();		
		
		System.assert( doc != null );
		
		Test.StopTest();
	}
}