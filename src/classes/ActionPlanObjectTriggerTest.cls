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
public with sharing class ActionPlanObjectTriggerTest {

    public static Boolean isTest = false;
    
    public static testmethod void testAccountTrigger(){
    
        ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
        ActionPlan__c ap = ge.createNewActionPlan( 'accounts', 1 );
        Account a = [select id from Account where id =:ap.Account__c]; 
        
        // Verifies that action plans are deleted when removing related object
        test.startTest();
        delete a;
        test.stopTest();
        List<ActionPlan__c> lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 0);
        
        // Verifies catch is working fine
        isTest = true;
        try{
            undelete a;
        }catch(Dmlexception e){
            System.assert(e.getMessage().contains('You can not undelete an action plan whose related object is deleted.'));
        }
        isTest = false;
        
        // Verifies that action plans are undeleted when restoring related object
        List <String> ids = new List <String>();
        ids.add(a.Id);
        ids.add(ap.Id);
        undelete a;
        lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 1);
        
        // Verifies that action plans that are in recycle bin are removed when deleting the related object
        delete ap;
        delete a;
        lAp = [ select Id, Name , LastModifiedDate from ActionPlan__c where Account__c =: a.Id and isDeleted = true ALL ROWS ];
        System.assert(lAp.size() == 0);
    }
    
    public static testmethod void testCampaignTrigger(){
    
        ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
        ActionPlan__c ap = ge.createNewActionPlan( 'campaigns', 1 );
        Campaign c = [select id from Campaign where id =:ap.Campaign__c];
        
        // Verifies that action plans are deleted when removing related object
        test.startTest();
        delete c;
        test.stopTest();
        List<ActionPlan__c> lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 0);

        // Verifies catch is working fine
        isTest = true;
        try{
            undelete c;
        }catch(Dmlexception e){
            System.assert(e.getMessage().contains('You can not undelete an action plan whose related object is deleted.'));
        }
        isTest = false;
        
        // Verifies that action plans are undeleted when restoring related object
        List <String> ids = new List <String>();
        ids.add(c.Id);
        ids.add(ap.Id);
        undelete(c);
        lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 1); 
        
        // Verifies that action plans that are in recycle bin are removed when deleting the related object
        delete ap;
        delete c;
        lAp = [ select Id, Name , LastModifiedDate from ActionPlan__c where Campaign__c =: c.Id and isDeleted = true ALL ROWS ];
        System.assert(lAp.size() == 0);
    }
    
    public static testmethod void testCaseTrigger(){
    
        ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
        ActionPlan__c ap = ge.createNewActionPlan( 'cases', 1 );
        Case c = [select id from Case where id =:ap.Case__c];
        
        // Verifies that action plans are undeleted when restoring related object
        test.startTest();
        delete c;
        test.stopTest();
        List<ActionPlan__c> lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 0);
        
        // Verifies catch is working fine
        isTest = true;
        try{
            undelete c;
        }catch(Dmlexception e){
            System.assert(e.getMessage().contains('You can not undelete an action plan whose related object is deleted.'));
        }
        isTest = false;
        
        // Verifies that action plans are undeleted when restoring related object
        List <String> ids = new List <String>();
        ids.add(c.Id);
        ids.add(ap.Id);
        undelete c;
        lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 1);
        
        // Verifies that action plans that are in recycle bin are removed when deleting the related object
        delete ap;
        delete c;
        lAp = [ select Id, Name , LastModifiedDate from ActionPlan__c where Case__c =: c.Id and isDeleted = true ALL ROWS ];
        System.assert(lAp.size() == 0);
    }
    
    public static testmethod void testContactTrigger(){
    
        ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
        ActionPlan__c ap = ge.createNewActionPlan( 'contacts', 1 );
        Contact c = [select id from Contact where id =:ap.Contact__c];
        
        // Verifies that action plans are undeleted when restoring related object
        test.startTest();
        delete c;
        test.stopTest();
        List<ActionPlan__c> lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 0);
        
        // Verifies catch is working fine
        isTest = true;
        try{
            undelete c;
        }catch(Dmlexception e){
            System.assert(e.getMessage().contains('You can not undelete an action plan whose related object is deleted.'));
        }
        isTest = false;
        
        // Verifies that action plans are undeleted when restoring related object
        List <String> ids = new List <String>();
        ids.add(c.Id);
        ids.add(ap.Id);
        undelete c;
        lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 1);
        
        // Verifies that action plans that are in recycle bin are removed when deleting the related object
        delete ap;
        delete c;
        lAp = [ select Id, Name , LastModifiedDate from ActionPlan__c where Contact__c =: c.Id and isDeleted = true ALL ROWS ];
        System.assert(lAp.size() == 0);
    }
    
    public static testmethod void testContractTrigger(){
    
        ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
        ActionPlan__c ap = ge.createNewActionPlan( 'contracts', 1 );
        Contract c = [select id from Contract where id =:ap.Contract__c];
        
        // Verifies that action plans are undeleted when restoring related object
        test.startTest();
        delete c;
        test.stopTest();
        List<ActionPlan__c> lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 0);
        
        // Verifies catch is working fine
        isTest = true;
        try{
            undelete c;
        }catch(Dmlexception e){
            System.assert(e.getMessage().contains('You can not undelete an action plan whose related object is deleted.'));
        }
        isTest = false;
        
        // Verifies that action plans are undeleted when restoring related object
        List <String> ids = new List <String>();
        ids.add(c.Id);
        ids.add(ap.Id);
        undelete c;
        lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 1);
        
        // Verifies that action plans that are in recycle bin are removed when deleting the related object
        delete ap;
        delete c;
        lAp = [ select Id, Name , LastModifiedDate from ActionPlan__c where Contract__c =: c.Id and isDeleted = true ALL ROWS ];
        System.assert(lAp.size() == 0);
    }

    public static testmethod void testLeadTrigger(){
    
        ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
        ActionPlan__c ap = ge.createNewActionPlan( 'leads', 1 );
        Lead l = [select id from Lead where id =:ap.Lead__c];
        
        // Verifies that action plans are undeleted when restoring related object
        test.startTest();
        delete l;
        test.stopTest();
        List<ActionPlan__c> lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 0);
        
        // Verifies catch is working fine
        isTest = true;
        try{
            undelete l;
        }catch(Dmlexception e){
            System.assert(e.getMessage().contains('You can not undelete an action plan whose related object is deleted.'));
        }
        isTest = false;
        
        // Verifies that action plans are undeleted when restoring related object
        List <String> ids = new List <String>();
        ids.add(l.Id);
        ids.add(ap.Id);
        undelete l;
        lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 1);
        
        // Verifies that action plans that are in recycle bin are removed when deleting the related object
        delete ap;
        delete l;
        lAp = [ select Id, Name , LastModifiedDate from ActionPlan__c where Lead__c =: l.Id and isDeleted = true ALL ROWS ];
        System.assert(lAp.size() == 0);
    }
    
    public static testmethod void testOpportunityTrigger(){
    
        ActionPlansTestUtilities ge = new ActionPlansTestUtilities();
        ActionPlan__c ap = ge.createNewActionPlan( 'opportunitys', 1 );
        Opportunity o = [select id from Opportunity where id =:ap.Opportunity__c];
        
        // Verifies that action plans are undeleted when restoring related object
        test.startTest();
        delete o;
        test.stopTest();
        List<ActionPlan__c> lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 0);
        
        // Verifies catch is working fine
        isTest = true;
        try{
            undelete o;
        }catch(Dmlexception e){
            System.assert(e.getMessage().contains('You can not undelete an action plan whose related object is deleted.'));
        }
        isTest = false;
        
        // Verifies that action plans are undeleted when restoring related object
        List <String> ids = new List <String>();
        ids.add(o.Id);
        ids.add(ap.Id);
        undelete o;
        lAp = [select id from ActionPlan__c where id =: ap.Id];
        System.assert(lAp.size() == 1);
        
        // Verifies that action plans that are in recycle bin are removed when deleting the related object
        delete ap;
        delete o;
        lAp = [ select Id, Name , LastModifiedDate from ActionPlan__c where Opportunity__c =: o.Id and isDeleted = true ALL ROWS ];
        System.assert(lAp.size() == 0);
    }

}