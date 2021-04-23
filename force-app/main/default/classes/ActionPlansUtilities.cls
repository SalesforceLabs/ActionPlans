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
public inherited sharing class ActionPlansUtilities {

	/*************
	 * CONSTANTS *
	*************/

	public static final String FRIDAY = 'Friday';
	public static final String MONDAY = 'Monday';

	/**
	 * Section to describe ActionPlan object to make custom relationship fields dynamic
	 */

	private static List<String> apCustomRelationshipFields;

	public static List<String> getCustomRelationshipFields(){
		if(apCustomRelationshipFields == null){
			List<String> refrerenceFieldNames = new List<String>();

			//Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

			//Schema.DescribeSObjectResult d = ActionPlan__c.sObjectType.getDescribe();

			Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.ActionPlan__c.fields.getMap();

			for(String s : fieldMap.keyset()){
				if(s == 'Action_Plan_Template__c'){continue;}
				/* if(!gd.containsKey(s) && !gd.containsKey(s.replace('__c',''))){
					continue;
				} */
				if(s.containsIgnoreCase('.')){ continue; }
				Schema.DescribeFieldResult dfr = fieldMap.get(s).getDescribe();
				Schema.DisplayType dt = dfr.getType();
				if(dt.name().equalsIgnoreCase('Reference') && s.endsWithIgnoreCase('__c')){
					refrerenceFieldNames.add(s);
				}
			}
			apCustomRelationshipFields = refrerenceFieldNames;
		}
		System.debug('Related Fields: ' + apCustomRelationshipFields);
		return apCustomRelationshipFields;
	}

	public static final Boolean HAS_RECORD_TYPE = setHasRecordType();

	/**
	 * Allows us to force the environment variable checking if Task has a Record Type for testing. Increases code coverage.
	 */
	private static Boolean setHasRecordType(){
		if(ActionPlansTestUtilities.forceHasRecordType != null){
			//System.debug('forceHasRecordType was set to ' + ActionPlansTestUtilities.forceHasRecordType);
			return ActionPlansTestUtilities.forceHasRecordType;
		} else {
			//System.debug('forceHasRecordType is null');
			ActionPlansTestUtilities.forceHasRecordType = Task.sObjectType.getDescribe().fields.getMap().containsKey('recordtypeid');
		}
		return ActionPlansTestUtilities.forceHasRecordType;
	}

	/**
	* Get prefix of sObject
	* @param objName
	* @return obj.getKeyPrefix()
	*/
	public static String getObjectKeyPrefix( String objName ){
		Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get( objName ).getDescribe();
		return obj.getKeyPrefix();
	}

	/**
	 * Lazy load task record types to reduce queries
	 * @since 4
	 */
	private static List<SObject> getTaskRecordTypes(){
		if(taskRecordTypes == null){
			String taskRTQuery = 'SELECT Id, Name FROM RecordType WHERE SObjectType = \'Task\' and IsActive = true';
			taskRecordTypes = Database.query(taskRTQuery);
		}
		return taskRecordTypes;
	}
	private static List<SObject> taskRecordTypes;

	/**
	 * Generate Map of Record Type Id to default Task Status
	 * @since 4
	 */
	public static Map<Id, String> getTaskRecordTypeStatusDefaultValues(){
		if(taskRecordTypeStatusDefaultValues == null){
			taskRecordTypeStatusDefaultValues = new Map<Id, String>();
			if(ActionPlansUtilities.HAS_RECORD_TYPE){
				for( SObject rt : getTaskRecordTypes() ){
					Task t = (Task)Task.sObjectType.newSObject((Id)rt.get('Id'), true);
					taskRecordTypeStatusDefaultValues.put((Id)rt.get('Id'), t.Status);
					//System.debug(rt.Name + ' has default status ' + t.Status);
				}
			} else {
				//String firstStatus = [SELECT Id, ApiName FROM TaskStatus WHERE IsDefault = true LIMIT 1].MasterLabel;
				taskRecordTypeStatusDefaultValues.put(null, (String)Task.Status.getDescribe().getDefaultValue());
				//taskRecordTypeStatusDefaultValues.put('', firstStatus);
			}

		}
		return taskRecordTypeStatusDefaultValues;
	}
	private static Map<Id, String> taskRecordTypeStatusDefaultValues;

	/**
	 * Generate Map of Record Type Id to default Task Type
	 * @since 4
	 */
	public static Map<Id, String> getTaskRecordTypeTypeDefaultValues(){
		if(taskRecordTypeTypeDefaultValues == null){
			taskRecordTypeTypeDefaultValues = new Map<Id, String>();
			if(ActionPlansUtilities.HAS_RECORD_TYPE){
				for( SObject rt : getTaskRecordTypes() ){
					Task t = (Task)Task.sObjectType.newSObject((Id)rt.get('Id'), true);
					taskRecordTypeTypeDefaultValues.put((Id)rt.get('Id'), t.Type);
				}
			} else {
				Task t = (Task)Task.sObjectType.newSObject(null, true);
				taskRecordTypeTypeDefaultValues.put(null, t.Type);
			}
		}
		return taskRecordTypeTypeDefaultValues;
	}
	private static Map<Id, String> taskRecordTypeTypeDefaultValues;


	/**
	 * Generate Map of Record Type Id to default Task Priority
	 * @since 4
	 */
	public static Map<Id, String> getTaskRecordTypePriorityDefaultValues(){
		if(taskRecordTypePriorityDefaultValues == null){
			taskRecordTypePriorityDefaultValues = new Map<Id, String>();
			if(ActionPlansUtilities.HAS_RECORD_TYPE){
				for( SObject rt : getTaskRecordTypes() ){
					Task t = (Task)Task.sObjectType.newSObject((Id)rt.get('Id'), true);
					taskRecordTypePriorityDefaultValues.put((Id)rt.get('Id'), t.Priority);

				}
			} else {
				taskRecordTypePriorityDefaultValues.put(null, (String)Task.Priority.getDescribe().getDefaultValue());
			}
		}
		return taskRecordTypePriorityDefaultValues;
	}
	private static Map<Id, String> taskRecordTypePriorityDefaultValues;

	/**
	 * Find user default recordtype
	 * @since 4
	 */
	public static String getDefaultTaskRecordTypeId(){
		String toReturn = null;
		if(ActionPlansUtilities.HAS_RECORD_TYPE){
			List<Schema.RecordTypeInfo> recordTypeInfoList = Task.SObjectType.getDescribe().getRecordTypeInfos();
			for(RecordTypeInfo info : recordTypeInfoList) {
				//Check default record type
				if(info.isDefaultRecordTypeMapping()){
					toReturn = info.getRecordTypeId();
					break;
				}
			}
		}
		return toReturn;
	}

	/**
	 * Generate picklist of Task Record Types
	 * @since 4
	 */
	public static List<SelectOption> getTaskRTPicklistValues(){
		if(taskRTs == null){
			taskRTs = new List<SelectOption>();
			String taskRTQuery = 'SELECT Id, Name, IsActive FROM RecordType WHERE SObjectType = \'Task\' ORDER BY Name ASC';
			for( SObject rt : Database.query(taskRTQuery)){
				SelectOption so = new SelectOption((String)rt.get('Id'), (String)rt.get('Name'), !(Boolean)rt.get('IsActive'));
				//so.setValue(rt.Id);
				//so.setLabel(rt.Name);
				taskRTs.add(so);
			}
		}
		return taskRTs;
	}
	private static List<SelectOption> taskRTs;

	/**
	 * Lazy load open task statuses
	 * @since 4
	 */
	public static Set<String> getOpenTaskStatuses(){
		if(openTaskStatuses == null){
			openTaskStatuses = new Set<String>();
			for(TaskStatus ts : [SELECT IsClosed, MasterLabel FROM TaskStatus WHERE IsClosed = false]){
				openTaskStatuses.add(ts.MasterLabel);
			}
			//openTaskStatuses.remove([SELECT MasterLabel FROM TaskStatus WHERE IsDefault = true].MasterLabel);
		}
		//System.debug('Open Statuses: ' + openTaskStatuses);
		return openTaskStatuses;
	}
	private static Set<String> openTaskStatuses;

	/**
	 * Find all closed Task statuses
	 * @return List of completed statuses
	 */
	private static Set<String> closedTaskStatuses;
	public static Set<String> getClosedTaskStatuses(){
		if(closedTaskStatuses == null){
			closedTaskStatuses = new Set<String>();
			for(TaskStatus ts : [SELECT IsClosed, MasterLabel FROM TaskStatus WHERE IsClosed = true]){
				closedTaskStatuses.add(ts.MasterLabel);
			}
		}
		//System.debug('Closed Statuses: ' + closedTaskStatuses);
		return closedTaskStatuses;
	}

	/**
	 * Get a Visualforce picklist from any object and field
	 * @param objectname    the object name
	 * @param fieldname     the field name
	 * @return              List<SelectOption>
	 */
	public static List<SelectOption> getFieldOptions(String objectname, String fieldname, Boolean hasDefaultValue){
		List<SelectOption> toReturn = new List<SelectOption>();
		Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get( objectname ).getDescribe();
		Schema.SObjectField sof = obj.fields.getMap().get(fieldname);
		if(hasDefaultValue == null || !hasDefaultValue){
			toReturn.add( new SelectOption( '', '--' + System.Label.ap_None +'--' ) );
		}
		for(Schema.PicklistEntry spe : sof.getDescribe().getPicklistValues()){
			toReturn.add(new Selectoption(spe.getValue(), spe.getLabel()));
		}

		return toReturn;
	}

	/**
	* Set the Hours for select box of Remainder Hour
	* @return options
	*/
	public static List<SelectOption> getHoursOption() {

 	 	List<SelectOption> options = new List<SelectOption>();
 	 	options.add( new SelectOption( '0',  '12:00 AM' ) );
 	 	options.add( new SelectOption( '30', '12:30 AM' ) );
		options.add( new SelectOption( '60', '1:00 AM'  ) );
		options.add( new SelectOption( '90', '1:30 AM'  ) );
		options.add( new SelectOption( '120', '2:00 AM'  ) );
		options.add( new SelectOption( '150', '2:30 AM'  ) );
		options.add( new SelectOption( '180', '3:00 AM'  ) );
		options.add( new SelectOption( '210', '3:30 AM'  ) );
		options.add( new SelectOption( '240', '4:00 AM'  ) );
		options.add( new SelectOption( '270', '4:30 AM'  ) );
		options.add( new SelectOption( '300', '5:00 AM'  ) );
		options.add( new SelectOption( '330', '5:30 AM'  ) );
		options.add( new SelectOption( '360', '6:00 AM'  ) );
		options.add( new SelectOption( '390', '6:30 AM'  ) );
		options.add( new SelectOption( '420', '7:00 AM'  ) );
		options.add( new SelectOption( '450', '7:30 AM'  ) );
		options.add( new SelectOption( '480', '8:00 AM'  ) );
		options.add( new SelectOption( '510', '8:30 AM'  ) );
		options.add( new SelectOption( '540', '9:00 AM'  ) );
		options.add( new SelectOption( '570', '9:30 AM'  ) );
		options.add( new SelectOption( '600', '10:00 AM' ) );
		options.add( new SelectOption( '630', '10:30 AM' ) );
		options.add( new SelectOption( '660', '11:00 AM' ) );
		options.add( new SelectOption( '690', '11:30 AM' ) );
		options.add( new SelectOption( '720', '12:00 PM' ) );
		options.add( new SelectOption( '750', '12:30 PM' ) );
		options.add( new SelectOption( '780', '1:00 PM'  ) );
		options.add( new SelectOption( '810', '1:30 PM'  ) );
		options.add( new SelectOption( '840', '2:00 PM'  ) );
		options.add( new SelectOption( '870', '2:30 PM'  ) );
		options.add( new SelectOption( '900', '3:00 PM'  ) );
		options.add( new SelectOption( '930', '3:30 PM'  ) );
		options.add( new SelectOption( '960', '4:00 PM'  ) );
		options.add( new SelectOption( '990', '4:30 PM'  ) );
		options.add( new SelectOption( '1020', '5:00 PM' ) );
		options.add( new SelectOption( '1050', '5:30 PM' ) );
		options.add( new SelectOption( '1080', '6:00 PM' ) );
		options.add( new SelectOption( '1110', '6:30 PM' ) );
		options.add( new SelectOption( '1140', '7:00 PM' ) );
		options.add( new SelectOption( '1170', '7:30 PM' ) );
		options.add( new SelectOption( '1200', '8:00 PM' ) );
		options.add( new SelectOption( '1230', '8:30 PM' ) );
		options.add( new SelectOption( '1260', '9:00 PM' ) );
		options.add( new SelectOption( '1290', '9:30 PM' ) );
		options.add( new SelectOption( '1320', '10:00 PM' ) );
		options.add( new SelectOption( '1350', '10:30 PM' ) );
		options.add( new SelectOption( '1380', '11:00 PM' ) );
		options.add( new SelectOption( '1410', '11:30 PM' ) );

 	 	return options;
  	}

	/**
	* Verifies that the user is able to add reminders.
	* Checks the existence of a reminder setting field of the user object.
	* Mathod can be improved by asking for Reminder Options at Activity settings.
	* Does not query if the user wants reminders by default
	* @return if the user has access to reminders
	*/
	public static Boolean getCanDisplayReminder(){
		if(canDisplayReminder == null){
			System.debug('FIRST get for candisplayreminder');
			//Map<String, Schema.SObjectField> fieldsMap = Schema.sObjectType.User.fields.getMap();
			/* if( fieldsMap.containsKey('UserPreferencesTaskRemindersCheckboxDefault') ){
				canDisplayReminder = [SELECT UserPreferencesTaskRemindersCheckboxDefault FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].UserPreferencesTaskRemindersCheckboxDefault;
			} else {
				canDisplayReminder = false;
			} */
			canDisplayReminder = Schema.sObjectType.User.fields.getMap().containsKey('UserPreferencesTaskRemindersCheckboxDefault');
		}
		return canDisplayReminder;
	}
	private static Boolean canDisplayReminder;

	/**
	 * Check user preferences for whether to show task reminders by default
	 * @return Boolean if Task reminder checkbox should be checked by default (this will override default value)
	 * @since 4
	 */
	public static Boolean getCheckReminderByDefault(){
		if(checkReminderByDefault == null){
			System.debug('FIRST time looking for checkReminderByDefault');
			checkReminderByDefault = false;
			if(getCanDisplayReminder()){
				User u = [SELECT Name, UserPreferencesTaskRemindersCheckboxDefault FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
				checkReminderByDefault = u.UserPreferencesTaskRemindersCheckboxDefault;
			}
		}
		return checkReminderByDefault;
	}
	private static Boolean checkReminderByDefault;

	/**
	* Gets task reminder default time for current user
	* @return String picklist value
	*/
	public static String getDefaultReminderMinutes(){
		if(defaultMinutesForReminderTime == null){
			Map<String, Schema.SObjectField> fieldsMap = Schema.sObjectType.User.fields.getMap();
			defaultMinutesForReminderTime = '480';

			List<UserPreference> uP = [SELECT Value
										FROM UserPreference
										WHERE UserId = :Userinfo.getUserId() AND Preference = '58'];
			if ( !uP.isEmpty() ){
				defaultMinutesForReminderTime = uP[0].Value;
			}
		}
		return defaultMinutesForReminderTime;
	}
	private static String defaultMinutesForReminderTime;

	/**
	* Get the "Default" Custom Setting and return it.
	* @return cSetting
	*/
	public static Action_Plans_Settings__c getCustomSetting(){
		Action_Plans_Settings__c instance = Action_Plans_Settings__c.getInstance();
		if(instance == null){
			instance = new Action_Plans_Settings__c();
			instance.Action_Plans_Business_Hours_ID__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true].Id;
			upsert instance;
		}
		return instance;
	}

	/**
	 * Single method to shorten long strings to the hard-coded 80 character length of record name field
	 * @param the long string
	 * @return the full string or shortened if longer than 80 characters
	 */
	public static String actionPlanSubjectToName(String subject){
		return actionPlanSubjectToName(subject, 80);
	}

	/**
	 * Single method to shorten long strings to the dynamically described character length of record name field
	 * @param the long string
	 * @return the full string or shortened if longer than max characters
	 */
	public static String actionPlanSubjectToName(String subject, Integer maxChars){
		if(subject == null){System.debug('NULL SUBJECT'); return null;}
		if( subject.trim().length() > maxChars ){
			return subject.left(maxChars - 3).trim() + '...';
		}
		return subject;
	}


	//private static Boolean orgCanSendEmails;
	public static Boolean canSendEmails() {
		Boolean orgCanSendEmails;
		if (orgCanSendEmails == null){
			// An attempt to reserve some email capacity is the only means available for determining permissions
			// or limits issues. In the case of a lack of permissions, System.NoAccessException is thrown. If
			// limits are exhausted then System.HandledException is thrown
			try {
				Messaging.reserveSingleEmailCapacity(1);

				orgCanSendEmails = true;
			} catch (Exception e) {
				orgCanSendEmails = false;
			}
		}

		return orgCanSendEmails;
	}

	/**
	 * Returns Friday in the running user language
	 */
	public static String getFriday(){
		Datetime dt = DateTime.newInstance(1900, 1,5,1,1,1);
		String dayOfWeek = dt.format('EEEE'); //This returns - Monday, Tuesday, Wednesday, etc..
		System.debug(dayOfWeek);
		return dayOfWeek;
	}

	public static String getMonday(){
		Datetime dt = DateTime.newInstance(1900, 1,1,1,1,1);
		String dayOfWeek = dt.format('EEEE'); //This returns - Monday, Tuesday, Wednesday, etc..
		System.debug(dayOfWeek);
		return dayOfWeek;
	}

	public static String getDayOfWeek(Date d){

		Date monday = Date.newInstance(1900, 1, 1);
		Integer dayOfWeek = Math.mod(monday.daysBetween(d), 7);
		return dayOfWeekEnglish.get(dayOfWeek);

		/* Datetime dt = DateTime.newInstance( d.year(), d.month(), d.day(), 1, 1, 1 );
		String dayOfWeek = dt.format('EEEE'); //This returns - Monday, Tuesday, Wednesday, etc..
		System.debug(dayOfWeek);
		return dayOfWeek; */
	}

	public static Map<Integer, String> dayOfWeekEnglish = new Map<Integer, String>{
		0 => 'Monday', 1 => 'Tuesday', 2 => 'Wednesday', 3 => 'Thursday', 4 => 'Friday', 5 => 'Saturday', 6 => 'Sunday'
	};

	public static Weekend_Day__mdt getWeekendDay(String developerName){
		return getWeekendDay(developerName, 0, 0);
	}

	public static Weekend_Day__mdt getWeekendDay(String developerName, Integer daysBack, Integer daysForward){
		weekendDay = Weekend_Day__mdt.getInstance(developerName);
		if(weekendDay == null){
			weekendDay = new Weekend_Day__mdt(DeveloperName = developerName);
			weekendDay.Days_to_start_of_next_week__c = daysForward;
			weekendDay.Days_from_end_of_previous_week__c = daysBack;
		}
		return weekendDay;
	}
	private static Weekend_Day__mdt weekendDay;

}
