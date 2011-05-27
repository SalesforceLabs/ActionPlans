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
public with sharing class ActionPlanCreationController{
    
    public Double                   taskIndex               { get; set; }    
    public ActionPlan__c            actionPlan              { get; set; }
    public ActionPlansUtilities     actionPlans             { get; set; }
    public String                   actionPlanId            { get; set; }
    public String                   templateId              { get; set; }
    public List<String>             relatedObjIds           { get; set; }
    public String                   relatedObjName          { get; set; }
    public List<String>             relatedObjNameList      { get; set; }
    public Boolean                  hasRelated              { get; set; }
    public Boolean                  hasRelatedObject        { get; set; }
    public String                   relatedObjectSelected   { get; set; }
    public Action_Plans_Settings__c defaultSettings         { get; set; }
    public String                   throwError              { get; set; }
    public Boolean                  addedTask               { get; set; }
    public Boolean                  displayReminder         { get; set; }
    private Map<String,ApTaskWrapper>   mapTasksListBkp;
    
    /**
    * Constructor
    */
    public ActionPlanCreationController( ApexPages.StandardController stdController ){
        
        this.taskIndex          = 0;
        this.addedTask          = false;
        this.hasRelated         = false;
        this.hasRelatedObject   = false;
        this.relatedObjNameList = new List<String>();
        this.relatedObjIds      = new List<String>();
        this.mapTasksListBkp    = new Map<String,ApTaskWrapper>();
        this.actionPlan         = ( ActionPlan__c ) stdController.getRecord();
        
        this.actionPlanId       = System.currentPageReference().getParameters().get( 'id' );
        String clone            = System.currentPageReference().getParameters().get( 'clone' );
        
        this.templateId         = ApexPages.currentPage().getParameters().get( 'templateId' );
        this.refId              = ApexPages.currentPage().getParameters().get( 'refId' );
        
        if      ( this.actionPlanId != null )   initEditActionPlan();
        else if ( clone == '1' )                initCloneActionPlan();
        else if ( this.templateId != null )     initNewActionPlanFromTemplate();
        else                                    initNewActionPlan();
        
        this.defaultSettings    = this.actionPlans.getCustomSetting();
        this.displayReminder    = this.actionPlans.getDisplayReminder();
    }    

    /**
    * Initalize controller for editing an Action Plan
    */
    public void initEditActionPlan(){

        //Add your Custom object in the SOQL Query
        List<ActionPlan__c> listAP = [ select a.Id, a.Name, a.CreatedById, a.StartDate__c, a.Action_Plan_Template__r.Name, 
                                a.Action_Plan_Template__r.Id, a.Action_Plan_Template__c, a.Account__c, a.Contact__c, 
                                a.Lead__c, a.Opportunity__c, a.Contract__c, a.Case__c, a.Campaign__c ,
                                a.SkipWeekends__c, a.SkipDay__c
                                from ActionPlan__c a  
                                Where a.Id =: this.actionPLanId limit 1 ];

        if (listAP.size() > 0) this.actionPlan = listAP.get(0);
        
        this.actionPlans                = new ActionPlansUtilities( this.actionPlan );
        this.hasRelatedObject           = this.actionPlans.hasRelatedObject();
        this.taskIndex                  = this.calculateAPTaskIndexValue();
    }

    /**
    * Initalize controller for cloning an Action Plan
    */
    public void initCloneActionPlan(){
        
        this.actionPlan.StartDate__c    = Date.today();
        this.actionPlans = new ActionPlansUtilities( this.actionPlan );
        
        List<APTaskTemplate__c> tcAux   = this.actionPlans.getTasks();
        List<APTaskTemplate__c> tC      = this.actionPlans.apTasks.deepClone( false );
        
        this.actionPlans.apTasks.clear();
        this.actionPlans.apTasks = tC;
        
        // clear task relations
        for( APTaskTemplate__c t : this.actionPlans.apTasks ){
            t.Action_Plan__c = null;
        }
    }
    
    /**
    * Initalize controller for creating a new Action Plan from a template
    */
    public void initNewActionPlanFromTemplate(){
        
        this.InitNewActionPlan();
        
        List<ActionPlanTemplate__c> listAPT = [ select a.Id, a.Name, a.Description__c, a.LastModifiedDate,  
                                                        a.SkipWeekends__c, a.SkipDay__c from ActionPlanTemplate__c a 
                                                        where a.Id = : this.templateId ];
        
        if (listAPT.size() > 0) {
            ActionPlanTemplate__c actionPlanTemplate = listAPT.get(0);                              
            this.actionPlan.Name                     = this.actionPlans.retrieveAPNameFromTemplate(actionPlanTemplate);
            this.actionPlan.Description__c           = actionPlanTemplate.Description__c;
            this.actionPlan.SkipWeekends__c          = actionPlanTemplate.SkipWeekends__c;
            this.actionPlan.SkipDay__c               = actionPlanTemplate.SkipDay__c; 
            this.actionPlan.Action_Plan_Template__c  = actionPlanTemplate.Id;
        }
        this.taskIndex  = this.calculateAPTTaskIndexValue();

    }
    
    /**
    * Initalize controller for creating a new Action Plan
    */
    public void initNewActionPlan(){
        
        this.actionPlan.StartDate__c    = Date.today();
        this.actionPlans                = new ActionPlansUtilities( this.actionPlan );   
        if( refId != null ){    
            this.hasRelated = true;
            this.referedObjectInit();
        } 
        this.relatedObjectSelected = this.actionPlans.getDefaultRelatedObjectOption().getValue();
    }
    
    /**
    * Getter and Setter for refId
    */
    public String refId{ 
        get{
            if( refId == null ){
                refId = ApexPages.currentPage().getParameters().get( 'refId' );
            }
            return refId;
        }
        set;
    }
    
    /**
    * Getter and Setter for RefType
    */
    public String refType{ 
        get{
            if( refType == null ){
                refType = ApexPages.currentPage().getParameters().get( 'refType' );
            }
            return refType;
        }
        set;
    }
    
    /**
    * Getter and Setter for ExistTemplate
    */
    public Boolean aPTemplateExists{
        get{
            if( aPTemplateExists == null ){
                String objectType   = ApexPages.currentPage().getParameters().get( 'refType' );
                String objectIds    = ApexPages.currentPage().getParameters().get( 'refId' );
                Integer count       = [select count() from ActionPlanTemplate__c limit 1];
                
                if( objectType != null && objectIds != null && count == 0){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.ap_NoTemplatesError));
                    aPTemplateExists = false;
                }
                else{
                    aPTemplateExists = true;
                } 
            }
            return aPTemplateExists;
        }
        set;
    }
    
    /**
    * Action which saves a new Action Plan
    * @return PageReference
    */
    public PageReference save(){
        
        this.throwError         = null;
        PageReference pageRef   = null;
        
        try{
            if( !this.actionPlans.checkCycleDependent() ){
                referedObjectOwnerInit();
                pageRef = this.actionPlans.saveHandler();   
            }
        }
        catch( FieldCustomValidationException e ){
            this.throwError = e.getCustomMessage(); 
        }
        catch( DmlException e ){
            Apexpages.addMessages( e );
        }
        
        return pageRef;
    }
    
    /**
    * Action which saves a new Action Plan
    * @return PageReference
    */
    public PageReference saveAndNew(){
        return this.actionPlans.saveAndNew( );
    }
    
    /**
    * Action that forwards to previous page
    * @return PageReference
    */
    public PageReference cancel(){
        return this.actionPlans.cancel();
    }
    
    /**
    * Retrieves number of completed tasks
    * @return Integer
    */
    public Integer getCompleted(){
        Integer i = 0;
        if( this.actionPlans != null ){
            i = this.actionPlans.getCompleted();
        }
        return i;
    }
    
    /**
    * Creates a blank Task object and adds it to List<Task>
    */
    public void addTask(){
        this.taskIndex++;
        this.actionPlans.taskIndexOrder = this.taskIndex;
        this.addedTask = this.actionPlans.addTask();
    }
    
    /**
    * Action for removing a existing task
    */
    public void removeTask(){
        addedTask = !actionPlans.removeTask();
    }
    
    /**
    * Method which retrieves all tasks for a Action Plan
    * @return List<APTaskTemplate__c>
    */
    public List<ApTaskWrapper> getTasks(){
        
        ApTaskWrapper apTaskWrapper;
        List<ApTaskWrapper> tasksList = new List<ApTaskWrapper>();
        Boolean userRequired    = false;
        Boolean displayLookUp = false;
        ApTaskWrapper tmpAptask;
        
        if( this.actionPlans != null ){
            Integer i = 0;
            
            
            for( APTaskTemplate__c aptTaskTemplate : actionPlans.getTasks( )){
                //check if the lookUp has to be shown
                if (aptTaskTemplate.Name != null && aptTaskTemplate.Name !=''){
                    tmpAptask = this.mapTasksListBkp.get(aptTaskTemplate.Name);
                }
                
                /*
                RSC //TODO trouble spot here on "user Required"
                getUnassignedDefaultsToRecordOwner
                */
                /*
                if (tmpAptask == null){
                    displayLookUp   = aptTaskTemplate.User__c != null || (aptTaskTemplate.Name == null && aptTaskTemplate.Name !='');
                    userRequired    = aptTaskTemplate.Name == null || (aptTaskTemplate.Name != null && aptTaskTemplate.Name !='' && aptTaskTemplate.User__c != null);
                }else{
                    displayLookUp   = tmpAptask.displayLookUp;
                    userRequired    = tmpAptask.userRequired;
                }
				*/
                if (tmpAptask == null){
                    displayLookUp   = aptTaskTemplate.User__c != null || (aptTaskTemplate.User__c == null && !getUnassignedDefaultsToRecordOwner());
                    userRequired    = !getUnassignedDefaultsToRecordOwner();
                }else{
                    displayLookUp   = tmpAptask.displayLookUp;
                    userRequired    = tmpAptask.userRequired;
                }
                
                apTaskWrapper = new ApTaskWrapper( aptTaskTemplate, i , displayLookup,userRequired);
                tasksList.add( apTaskWrapper );
                if (aptTaskTemplate.Name != null  && aptTaskTemplate.Name !=''){
                    this.mapTasksListBkp.put(aptTaskTemplate.Name,apTaskWrapper);
                }
                
                i++;
            }
            if( addedTask ){
                tasksList.get( i - 1 ).isLast = true;   
            }   
        }

        return tasksList;
    }
    
    /**
    * Get Settings 
    * @return mySetings
    * 2011-05-27 was getShowUserLookup() - now getUnassignedDefaultsToRecordOwner()
    */
    public Boolean getUnassignedDefaultsToRecordOwner(){
        Action_Plans_Settings__c settings = new Action_Plans_Settings__c();
        settings = this.actionPlans.getCustomSetting();
        return settings.Unassigned_Task_Default__c;
    } 
    
    /**
    * Retrieves if template lookup must be displayed
    * @return Boolean
    */
    public Boolean getDisplayTemplateLookup(){
        return (this.hasRelated || this.templateId != null);
    }
    
    /**
    * Retrieves size of APT Template Tasks List.
    * @return apTasks
    */
    public Integer getTaskSize(){
        return ( this.actionPlans != null ) ? this.actionPlans.getTaskSize() : 0; 
    }
    
    /**
    * Returns list of Dependet tasks to fill drop down 
    * @return List<SelectOption>
    */
    public List<SelectOption> getSubjectItems(){
        return this.actionPlans.getSubjectItems();
    }
    
    /**
    * Set the Refered object to Create New Action Plan 
    */
    public void referedObjectInit(){
        
        String nameParam = '';
        String idsParam;
        
        if( ApexPages.currentPage().getParameters().get( 'refType' ) != null ){
            nameParam        = String.escapeSingleQuotes( ApexPages.currentPage().getParameters().get( 'refType' ) );
            idsParam         = String.escapeSingleQuotes( ApexPages.currentPage().getParameters().get( 'refId' ) );
            
            if( idsParam != null && idsParam != '' ){
                this.relatedObjIds = idsParam.split(',');       
            }
        }
        
        retrieveNameRelatedObject(relatedObjIds,nameParam);
    }
    
    /**
    * Sets the owner list for each object that will be related to an Action Plan
    */
    public void referedObjectOwnerInit(){
        
        String nameParam = '';
        String idsParam;
        
        if( ApexPages.currentPage().getParameters().get( 'templateId' ) != null ){
            if( ApexPages.currentPage().getParameters().get( 'refType' ) != null ){
                
                nameParam        = String.escapeSingleQuotes( ApexPages.currentPage().getParameters().get( 'refType' ) );
                idsParam         = String.escapeSingleQuotes( ApexPages.currentPage().getParameters().get( 'refId' ) );
                
                if( idsParam != null && idsParam != '' ){
                    this.relatedObjIds = idsParam.split(',');       
                }
            }else{
                relatedObjIds = new List<String>();
                if( this.actionPlans.relatedObjectId() != null ){
                    relatedObjIds.add( String.escapeSingleQuotes( this.actionPlans.relatedObjectId() ) );   
                }
                nameParam = String.escapeSingleQuotes( relatedObjectSelected );
            }
            
            this.actionPlans.retrieveOwnersDataRelatedObject( relatedObjIds, nameParam );
        }
    }
    
    /**
    * 
    * @param relatedObjIds
    * @param relatedObjectName
    */
    private void retrieveNameRelatedObject( List<String> relatedObjIds, String relatedObjectName ){
        
        if( 'Account'.equalsIgnoreCase( relatedObjectName ) ){
            this.relatedObjName = 'Accounts';
            for( Account acc : [ Select Name from Account where Id IN : relatedObjIds ] ){
                this.relatedObjNameList.add( acc.Name );
            }
        } 
        else if( 'Lead'.equalsIgnoreCase( relatedObjectName ) ){
            this.relatedObjName = 'Leads';
            for( Lead lead : [ Select FirstName, LastName from Lead where Id IN : relatedObjIds ] ){
                this.relatedObjNameList.add( (lead.FirstName != null) ? lead.FirstName + ' ' + lead.LastName : lead.LastName );
            }
        } 
        else if( 'Contact'.equalsIgnoreCase( relatedObjectName ) ){
            this.relatedObjName = 'Contacts';
            for( Contact cont : [ Select LastName, FirstName from Contact where Id IN : relatedObjIds ] ){
                this.relatedObjNameList.add( (cont.FirstName != null) ? cont.FirstName + ' ' + cont.LastName : cont.LastName );
            }
        } 
        else if( 'Opportunity'.equalsIgnoreCase( relatedObjectName ) ){
            this.relatedObjName = 'Opportunities';
            for( Opportunity opp : [ Select Name from Opportunity where Id IN : relatedObjIds ] ){
                this.relatedObjNameList.add( opp.Name );
            }
        }
        //Add new version Support to Cases , Contracts ans Campaigns
        else if( 'Case'.equalsIgnoreCase( relatedObjectName ) ){
            this.relatedObjName = 'Cases';
            for( Case cases : [ Select Subject, CaseNumber from Case where Id IN : relatedObjIds ] ){
                this.relatedObjNameList.add( (cases.Subject != null) ?  cases.CaseNumber + ': ' + cases.Subject : cases.CaseNumber );
            }
        }
        
        else if( 'Campaign'.equalsIgnoreCase( relatedObjectName ) ){
            this.relatedObjName = 'Campaigns';
            for( Campaign camp : [ Select Name from Campaign where Id IN : relatedObjIds ] ){
                this.relatedObjNameList.add( camp.Name );
            }
        }
        
        else if( 'Contract'.equalsIgnoreCase( relatedObjectName ) ){
            this.relatedObjName = 'Contracts';
            for( Contract contr : [ Select ContractNumber from Contract where Id IN : relatedObjIds ] ){
                this.relatedObjNameList.add( 'Contract Number :'+ contr.ContractNumber );
            }
        }
        //Add custom object code Segment here.
        /*else if( 'CustomObject'.equalsIgnoreCase( relatedObjectName ) ){
            this.relatedObjName = 'CustomObject';
            for( CustomObject custObj : [ Select Name from CustomObject where Id IN : relatedObjIds ] ){
                this.relatedObjNameList.add( custObj.Name );
            }
        }*/
    }
    
    /**
    * Getter method to return the error message from
    * action plans utilities
    */
    public String getErrorMsg(){
        return actionPlans.errorMsg;
    }
    
    /**
    * Calculates the highest task index value for Action Plan Tasks
    * @return maxIndex
    */
    public Double calculateAPTaskIndexValue(){
        
        List<APTaskTemplate__c> apTasks = [ select Id, taskIndex__c from APTaskTemplate__c 
                                                where Action_Plan__c =: this.actionPlanId ];
        
        Double maxIndex = 0;
        for( APTaskTemplate__c tsk : apTasks ){
            if( tsk.taskIndex__c > maxIndex ){
                maxIndex = tsk.taskIndex__c;
            }
        }
        
        return maxIndex;
    }
    
    /**
    * Calculates the highest task index value for Action Plan Template Tasks
    * @return maxIndex
    */
    public Double calculateAPTTaskIndexValue(){
        
        List<APTTaskTemplate__c> aptTasks = [ select id, taskIndex__c from APTTaskTemplate__c 
                                                where Action_Plan_Template__c =: this.templateId ];
        
        Double maxIndex = 0;
        for( APTTaskTemplate__c tsk : aptTasks ){
            if( tsk.taskIndex__c > maxIndex ){
                maxIndex = tsk.taskIndex__c;
            }
        }
        
        return maxIndex;
    }
    
    /**
    * Getter method with the related object options by default.
    */
    public List<SelectOption> getRelatedObjectOptions(){
        return actionPlans.getRelatedObjectOptions();
    }
    
    /**
    * Refresh the related object lookup field.
    */
    public PageReference refreshRelatedObjectsLookUp(){
        relatedObjectSelected = Apexpages.currentPage().getParameters().get( 'relatedObjectSelected' );
        return null;
    }
    
    /**
    * Wrapper Class for AP task Object
    * @author Rodrigo Birriel
    * @createddate 08/01/2010
    */
    public class ApTaskWrapper{
        
        public APTaskTemplate__c task       { get; set; }
        public  Integer     position        { get; set; }
        public  Boolean     isLast          { get; set; }
        public  Boolean     displayLookUp   { get; set; }
        public  Boolean     userRequired    { get; set; }
        
        public ApTaskWrapper( APTaskTemplate__c apTask, Integer pos, Boolean looKp, Boolean userReq ){
            task            = apTask;
            position        = pos;
            isLast          = false;
            displayLookUp   = looKp;
            userRequired    = userReq;
        }
    }
    
    public static testMethod void constructorTests(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
        ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'contacts', 2 );
        
        System.currentPageReference().getParameters().put( 'id', null );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        
        System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
        apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'clone', '1' );
        apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        
        ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate( 3 );
        
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'clone', null );
        System.currentPageReference().getParameters().put( 'templateId', apTemplate.Id );
        apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        
        Contact contact = testUtil.createNewContact();
        
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'refId', contact.Id );
        System.currentPageReference().getParameters().put( 'refType', 'Contact' );
        apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        String refid    = apCreateController.refId;
        String reftype  = apCreateController.refType;
        apCreateController.refreshRelatedObjectsLookUp();
        
        Test.StopTest();
    }
    
    public static testMethod void testActionPlanSave(){
        
        //Erase all Action Plans before begining test
        List<ActionPlan__c> apList = [ select Id from ActionPlan__c limit 10000];
        delete apList;
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlan__c actionPlan            = new ActionPlan__c();
        
        Contact contact = testUtil.createNewContact();
        
        actionPlan.Name         = testUtil.createRandomWord();
        actionPlan.Contact__c   = contact.Id;
        actionPlan.StartDate__c = Date.today();
        
        APTaskTemplate__c apTask = new APTaskTemplate__c();
        
        apTask.Subject__c           = testUtil.createRandomWord();
        apTask.User__c              = testUtil.createTestUser().Id;
        apTask.DaysFromStart__c     = 2;
        apTask.Type__c              = 'Email';
        apTask.Priority__c          = 'Hight';
                
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'refId', contact.Id );
        System.currentPageReference().getParameters().put( 'refType', 'Contact' );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        
        apCreateController.actionPlans.apTasks = new List<APTaskTemplate__c>();
        apCreateController.actionPlans.apTasks.add( apTask );
        apCreateController.save();
        
        Test.StopTest();
        
        List<ActionPlan__c> results = [ select Id from ActionPlan__c limit 10000];
        
        
        System.assert( !results.isEmpty(), 'Action Plan not created' );
        System.assert( results.size() == 1, 'Action Plan not created' );
        
        apCreateController.cancel();
    }
    
    public static testMethod void testActionPlanSaveAndNew(){
        
        //Erase all Action Plans before begining test
        List<ActionPlan__c> apList = [ select Id from ActionPlan__c limit 10000];
        delete apList;
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlan__c actionPlan            = new ActionPlan__c();
        
        Contact contact = testUtil.createNewContact();
        
        actionPlan.Name         = testUtil.createRandomWord();
        actionPlan.Contact__c   = contact.Id;
        actionPlan.StartDate__c = Date.today();
        
        APTaskTemplate__c apTask = new APTaskTemplate__c();
        
        apTask.Subject__c           = testUtil.createRandomWord();
        apTask.User__c              = testUtil.createTestUser().Id;
        apTask.DaysFromStart__c     = 2;
        apTask.Type__c              = 'Email';
        apTask.Priority__c          = 'Hight';
                
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'refId', contact.Id );
        System.currentPageReference().getParameters().put( 'refType', 'Contact' );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        
        apCreateController.actionPlans.apTasks = new List<APTaskTemplate__c>();
        apCreateController.actionPlans.apTasks.add( apTask );
        apCreateController.saveAndNew();
        Test.StopTest();
        List<ActionPlan__c> results = [ select Id from ActionPlan__c limit 10000];
        
        System.assert( !results.isEmpty(), 'Action Plan not created' );
        System.assert( results.size() == 1, 'Action Plan not created' );
        
        
    }
    
    public static testMethod void checkCompletedTasks(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'accounts', 2 );
        
        System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        
        Integer numTasksComplete = apCreateController.getCompleted();
        
        System.assert( numTasksComplete == 0 , 'Action plan task completed is incorrect' );
        
        Test.StopTest();
    }
    
    public static testMethod void testAddNewTask(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'accounts', 2 );
        
        APTaskTemplate__c apTask = new APTaskTemplate__c();
        
        apTask.Action_Plan__c       = actionPlan.Id;
        apTask.Subject__c           = testUtil.createRandomWord();
        apTask.User__c              = testUtil.createTestUser().Id;
        apTask.DaysFromStart__c     = 2;
        apTask.Type__c              = 'Email';
        apTask.Priority__c          = 'Hight';
                
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'add', '1' );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        apCreateController.actionPlans.apTasks = new List<APTaskTemplate__c>();
        apCreateController.actionPlans.apTasks.add( apTask );
        apCreateController.addTask();
        
        Test.StopTest();
    }
    
    public static testMethod void testRemoveActionPlanTask(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'accounts', 3 );
                
        System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
        System.currentPageReference().getParameters().put( 'remove', '1' );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        apCreateController.actionPlans.apTasks = [ select a.Type__c, a.Subject__c, a.ActivityDate__c, a.Priority__c, a.Status__c, a.Dependent__c, 
                                                        a.Name, a.User__c, a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.APTaskTemplate__r.Name, 
                                                        a.APTaskTemplate__r.Subject__c, a.APTaskTemplate__c, a.Action_Plan__c, a.Reminder__c, 
                                                        a.SendEmail__c, a.Comments__c 
                                                        from APTaskTemplate__c a 
                                                        where a.Action_Plan__c =: actionPlan.Id order by a.createdDate asc ];
                                    
        apCreateController.removeTask();
        
        Test.StopTest();
    }
    
    public static testMethod void checkActionPlanTaskList(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'accounts', 2 );
        
        System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        
        List<ApTaskWrapper> apTaskList = apCreateController.getTasks();
        
        System.assert( !apTaskList.isEmpty(), 'Action plan task list is empty' );
                
        Test.StopTest();
    }
    
    public static testMethod void checkActionPlanTaskListSize(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'accounts', 2 );
        
        System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        
        List<ApTaskWrapper> apTaskList  = apCreateController.getTasks();
        Integer numTasks                    = apCreateController.getTaskSize();
        
        System.assert( !apTaskList.isEmpty(), 'Action plan task list is empty' );
                
        System.assert( numTasks == apTaskList.size(), 'Action Plan task size incorrect');
                        
        Test.StopTest();
    }
    
    public static testMethod void checkSubjectItems(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil   = new ActionPlansTestUtilities();
        ActionPlan__c actionPlan            = testUtil.createNewActionPlan( 'accounts', 2 );
        
        System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        apCreateController.actionPlans.apTasks = [ select a.Type__c, a.Subject__c, a.ActivityDate__c, a.Priority__c, a.Status__c, a.Dependent__c, 
                                                        a.Name, a.User__c, a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.APTaskTemplate__r.Name, 
                                                        a.APTaskTemplate__r.Subject__c, a.APTaskTemplate__c, a.Action_Plan__c, a.Reminder__c, 
                                                        a.SendEmail__c, a.Comments__c 
                                                        from APTaskTemplate__c a 
                                                        where a.Action_Plan__c =: actionPlan.Id order by a.createdDate asc ];
                                                        
        List<Selectoption> options = apCreateController.getSubjectItems();
        
        System.assert( !options.isEmpty(), 'select options is empty' );
        System.assert( options.size() == 3, 'incorrect number of select options' );
                        
        Test.StopTest();
    }
    
    public static testMethod void testCyclicDependencyTaskSuccess(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
        
        ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'accounts', 0 );
        
        APTaskTemplate__c newAPTask1 = new APTaskTemplate__c();
        APTaskTemplate__c newAPTask2 = new APTaskTemplate__c();
        APTaskTemplate__c newAPTask3 = new APTaskTemplate__c();
        
        newAPTask1.Subject__c           = testUtil.createRandomWord();
        newAPTask1.DaysFromStart__c     = 2;
        newAPTask1.Dependent__c         = '2';
        newAPTask1.Type__c              = 'Email';
        newAPTask1.Priority__c          = 'High';
        newAPTask1.Action_Plan__c       = actionPlan.Id;
        upsert newAPTask1;
        
        newAPTask2.Subject__c           = testUtil.createRandomWord();
        newAPTask2.DaysFromStart__c     = 2;
        newAPTask2.Dependent__c         = 'None';
        newAPTask2.Type__c              = 'Email';
        newAPTask2.Priority__c          = 'High';
        newAPTask2.Action_Plan__c       = actionPlan.Id;
        upsert newAPTask2;
        
        newAPTask3.Subject__c           = testUtil.createRandomWord();
        newAPTask3.DaysFromStart__c     = 2;
        newAPTask3.Dependent__c         = '1';
        newAPTask3.Type__c              = 'Email';
        newAPTask3.Priority__c          = 'High';
        newAPTask3.Action_Plan__c       = actionPlan.Id;
        upsert newAPTask3;
        
        System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        
        apCreateController.actionPlans.apTasks = new List<APTaskTemplate__c>();
        apCreateController.actionPlans.apTasks.add( newAPTask1 );
        apCreateController.actionPlans.apTasks.add( newAPTask2 );
        apCreateController.actionPlans.apTasks.add( newAPTask3 );
        
        apCreateController.save();
        
        System.assert( apCreateController.getErrorMsg() == '' );
        
        Test.StopTest();
    }
    
    public static testMethod void testCyclicDependencyTasksFail(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
        
        ActionPlan__c actionPlan = testUtil.createNewActionPlan( 'accounts', 0 );
        
        APTaskTemplate__c newAPTask1 = new APTaskTemplate__c();
        APTaskTemplate__c newAPTask2 = new APTaskTemplate__c();
        APTaskTemplate__c newAPTask3 = new APTaskTemplate__c();
        
        newAPTask1.Subject__c           = testUtil.createRandomWord();
        newAPTask1.DaysFromStart__c     = 2;
        newAPTask1.Dependent__c         = '2';
        newAPTask1.Type__c              = 'Email';
        newAPTask1.Priority__c          = 'Hight';
        
        newAPTask2.Subject__c           = testUtil.createRandomWord();
        newAPTask2.DaysFromStart__c     = 2;
        newAPTask2.Dependent__c         = '0';
        newAPTask2.Type__c              = 'Email';
        newAPTask2.Priority__c          = 'Hight';
        
        newAPTask3.Subject__c           = testUtil.createRandomWord();
        newAPTask3.DaysFromStart__c     = 2;
        newAPTask3.Dependent__c         = '1';
        newAPTask3.Type__c              = 'Email';
        newAPTask3.Priority__c          = 'Hight';
        
        System.currentPageReference().getParameters().put( 'id', actionPlan.Id );
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( actionPlan ) );
        
        apCreateController.actionPlans.apTasks = new List<APTaskTemplate__c>();
        apCreateController.actionPlans.apTasks.add( newAPTask1 );
        apCreateController.actionPlans.apTasks.add( newAPTask2 );
        apCreateController.actionPlans.apTasks.add( newAPTask3 );
        
        apCreateController.save();
        
        System.assert( apCreateController.getErrorMsg() != null );
        
        Test.StopTest();
    }
    
    public static testMethod void checkReferedObject(){
        
        Test.StartTest();
        
        ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
        
        Contact contact         = testUtil.createNewContact();
        Account account         = testUtil.createNewAccount();
        Lead lead               = testUtil.createNewLead();
        Opportunity opportunity = testUtil.createNewOpportunity();  
        
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'refId', contact.id );
        System.currentPageReference().getParameters().put( 'refType', 'Contact' );
        
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        apCreateController.referedObjectInit();
        apCreateController.referedObjectOwnerInit();
        
        System.assert( apCreateController.relatedObjNameList.size() == 2 );
        
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'refId', account.Id );
        System.currentPageReference().getParameters().put( 'refType', 'Account' );
        
        apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        apCreateController.referedObjectInit();
        apCreateController.referedObjectOwnerInit();
        
        System.assert( apCreateController.relatedObjNameList.size() == 2 );
        
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'refId', lead.Id );
        System.currentPageReference().getParameters().put( 'refType', 'Lead' );
        
        apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        apCreateController.referedObjectInit();
        apCreateController.referedObjectOwnerInit();
        
        System.assert( apCreateController.relatedObjNameList.size() == 2 );
        
        System.currentPageReference().getParameters().put( 'id', null );
        System.currentPageReference().getParameters().put( 'refId', opportunity.Id );
        System.currentPageReference().getParameters().put( 'refType', 'Opportunity' );
        
        apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        apCreateController.referedObjectInit();
        apCreateController.referedObjectOwnerInit();
        
        System.assert( apCreateController.relatedObjNameList.size() == 2 );
        System.assert( apCreateController.getRelatedObjectOptions().size() == apCreateController.actionPlans.getRelatedObjectOptions().size() );
        
        Test.StopTest();
    }
    
    
    //aPTemplateExists
    public static testMethod void test_aPTemplateExists(){
        
        Test.StartTest();
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
        
        ApexPages.currentPage().getParameters().put( 'refType','FOO' );
        ApexPages.currentPage().getParameters().put( 'refId','FOO' );
        delete [select Id from ActionPlanTemplate__c];
        
        System.assertEquals(apCreateController.aPTemplateExists,false);
        
        Test.StopTest();
    }    
    
    /*
    public static testMethod void test_getShowUserLookup(){
        
        Test.StartTest();
        //delete custom settings
        ActionPlanCreationController apCreateController = new ActionPlanCreationController( new Apexpages.StandardController( new ActionPlan__c() ) );
       
       	System.assert(apCreateController.getShowUserLookup());
       	
        System.assert(!apCreateController.getDisplayTemplateLookup());
        
        
        Test.StopTest();
    }   
    */
}