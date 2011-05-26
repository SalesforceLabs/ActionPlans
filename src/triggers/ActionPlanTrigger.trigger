trigger ActionPlanTrigger on ActionPlan__c ( before delete, after insert ){

    //Execution when a Action Plan is Deleted, delete all asociated Task
    if( trigger.isDelete ) {
        // if action plan is deleted, delete all tasks associated with it
        set<ID> apIds= new set<ID>();
        set<ID> apttIds= new set<ID>();
        List<Task> tasks = new List<Task>();
        
        for( ActionPlan__c ap : trigger.old ){
            apIds.add( ap.Id );
        }
        
        for( APTaskTemplate__c aptt : [ select Id from APTaskTemplate__c where Action_Plan__c in :apIds ] ){
            apttIds.add( aptt.Id );
        }
        
        delete [ select Id from Task where Status != 'Completed' and TaskTemplateId__c in :apttIds ];
    }
    //Execution When a Action Plan is Created, that check the Custom Setings in order to Post a new Feed ( Object )
    else if( trigger.isInsert ) {
        ActionPlansUtilities apUtil = new ActionPlansUtilities();
        Action_Plans_Settings__c mySettings = apUtil.getCustomSetting(); 
        
        //We need check first if the Related Object is Enabled to FeedPost
        //Just need the first Object of list to know the Related Object.
        Boolean isEnabledForFeed = apUtil.isObjectEnabledFeed( trigger.new.get(0) );
        
        if( isEnabledForFeed && mySettings != null && mySettings.Chatter_Object_Brag__c ) {
            List<FeedPost> feedsList = new List<FeedPost>(); 
            for( ActionPlan__c ap : trigger.new ) {
                feedsList.add( apUtil.generateObjectFeed( ap ) );
            }
            insert feedsList;
        }
        
    }
}