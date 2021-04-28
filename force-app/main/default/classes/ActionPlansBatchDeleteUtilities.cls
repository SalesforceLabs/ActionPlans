/*
Action Plans v4
Updated by David Schach 2021

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

BSD 3-Clause License

Copyright (c) 2021, salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
public inherited sharing class ActionPlansBatchDeleteUtilities {

 	private Set<Id> 			    relActionPlansIds;

	//constructor
	public ActionPlansBatchDeleteUtilities(Set<Id> oIDsSet){

		relActionPlansIds = oIDsSet;

	}

	public Database.QueryLocator getObjects( Database.BatchableContext bc ){

		String soql = 'SELECT Id FROM ActionPlan__c WHERE Id IN :relActionPlansIds';
		return Database.getQueryLocator( soql );
	}

	public void deleteActionPlans() {

		List<ActionPlan__c> relActionPlans = [SELECT Id FROM ActionPlan__c WHERE Id IN :this.relActionPlansIds LIMIT :ActionPlansConstants.MAX_APTODELETE];

		// 	task templates probably don't need to be deleted as they are the detail part of the relationship
		Map<Id, APTaskTemplate__c> relTaskTemplateMap = new Map<Id, APTaskTemplate__c>([SELECT Id FROM APTaskTemplate__c WHERE Action_Plan__c IN :this.relActionPlansIds]);

		delete relActionPlans;

		List<Task> relTaskList = [SELECT Id FROM Task WHERE IsClosed = false AND TaskAPTaskTemplate__c IN :relTaskTemplateMap.keySet()];

		// Tasks should have been deleted by the trigger handler, but we will be sure here
		delete relTaskList;

	 }

}