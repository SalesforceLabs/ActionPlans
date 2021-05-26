public inherited sharing class ActionPlansRedirect {

	private APTaskTemplate__c actionPlanTask;
	private APTTaskTemplate__c actionPlanTemplateTask;
	private Id parentId;

	public ActionPlansRedirect(ApexPages.StandardController controller) {
		Id recordId = controller.getId();

		String objName = recordId.getSObjectType().getDescribe().getName();
		if(objName.equalsIgnoreCase('APTaskTemplate__c')){
			actionPlanTask = (APTaskTemplate__c)controller.getRecord();
			parentId = actionPlanTask.Action_Plan__c;
		}
		else if(objName.equalsIgnoreCase('APTTaskTemplate__c')){
			actionPlanTemplateTask = (APTTaskTemplate__c)controller.getRecord();
			parentId = actionPlanTemplateTask.Action_Plan_Template__c;
		}
    }

	public Pagereference redirect(){
		Pagereference pr = new Pagereference('/' + parentId);
		pr.setRedirect(true);
		return pr;
	}
}
