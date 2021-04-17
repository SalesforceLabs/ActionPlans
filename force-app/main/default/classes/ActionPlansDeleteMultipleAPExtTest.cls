/*
Action Plans v4
Updated by David Schach 2021

Action Plans v3
Force.com Labs
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2011, salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, inc. nor the names of its contributors
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
@IsTest
private class ActionPlansDeleteMultipleAPExtTest {

    private static final Integer APS_TO_CREATE = 100;

    @testSetup
    public static void setupdata(){
            ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

            List<ActionPlan__c> apToInsert = new List<ActionPlan__c>();
            List<APTaskTemplate__c> apttToInsert = new List<APTaskTemplate__c>();

            Account a = testUtil.createNewAccount();

            for(Integer i = 0; i < 100; i++){
                ActionPlan__c newActionPlan = new ActionPlan__c();
                newActionPlan.Name          = testUtil.createRandomWord();
                newActionPlan.StartDate__c  = Date.today();
                newActionPlan.OwnerId       = Userinfo.getUserId();
                newActionPlan.Account__c    = a.Id;
                apToInsert.add(newActionPlan);

            }
            insert apToInsert;

            for(ActionPlan__c newActionPlan : apToInsert){
                for(Integer j = 0; j < 5; j++){
                    APTaskTemplate__c newAPTask = new APTaskTemplate__c();
                    newAPTask.Subject__c        = testUtil.createRandomWord();
                    newAPTask.DaysFromStart__c  = j+1;
                    newAPTask.Action_Plan__c    = newActionPlan.Id;
                    newAPTask.User__c           = UserInfo.getUserId();
                    newAPTask.Type__c           = 'Call';
                    newAPTask.Priority__c       = (String)Task.Priority.getDescribe().getDefaultValue();
                    newAPTask.Minutes_Reminder__c = '510';
                    apttToInsert.add(newAPTask);
                }
            }

            insert apttToInsert;
    }

    @IsTest
    public static void givenRecordsToDeleteThenDeleted() {

        List<ActionPlan__c> listActionPlan = [SELECT Id, Name FROM ActionPlan__c];
        System.assertEquals(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
        ApexPages.StandardSetController std = new ApexPages.StandardSetController(listActionPlan );
        std.setSelected(new List<ActionPlan__c> { listActionPlan[0], listActionPlan[1] });
        ActionPlansDeleteMultipleAPExtension ctrl = new ActionPlansDeleteMultipleAPExtension(std);

        Test.startTest();
        // When
        ctrl.deleteRecords();
        Test.stopTest();
        // Then
        System.assertEquals(APS_TO_CREATE - 2, [SELECT Count() FROM ActionPlan__c]);
    }

    @IsTest
    public static void givenNoRecordsToDeleteThenNotDeleted() {

        List<ActionPlan__c> listActionPlan = [SELECT Id, Name FROM ActionPlan__c];
        System.assertEquals(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
        ApexPages.StandardSetController std = new ApexPages.StandardSetController(listActionPlan );
        std.setSelected(new List<ActionPlan__c> {  });
        ActionPlansDeleteMultipleAPExtension ctrl = new ActionPlansDeleteMultipleAPExtension(std);

        Test.startTest();
        // When
        ctrl.deleteRecords();
        Test.stopTest();

        // Then
        System.assertEquals(APS_TO_CREATE, [SELECT Count() FROM ActionPlan__c]);
    }
}