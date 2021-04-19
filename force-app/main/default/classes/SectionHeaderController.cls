/**
 * Action Plans v4
 * Updated by David Schach 2021
 */
global inherited sharing class SectionHeaderController {

	//public Map<String, String> iconAttributeMap {get; set; }
	global String objectName { get; set; }

	global Map<String,String> getObjectIconInfo(){
		return retrieveIconForObject(objectName);
	}

	global Boolean getIsCustom(){
		return isCustom(objectName);
	}

	/**
	 * Given an object name, return if it is a custom object
	 */
	private Boolean isCustom(String sObjectName){
		return Schema.getGlobalDescribe().get( sObjectName.toLowerCase() ).getDescribe().isCustom();
	}

	/***
	 * Explores the schema of the soject passed in and finds lightning icon style and image url for sObject
	 * If nothing is found, defaults to the custom icon
	 *
	 * @param   sObjectTypeName       the sObject to find the icon for
	 * @return  Map<String,String>    Map of properties about the icon to be consumed by the front end.
	 *                                Right now, returns values for keys: iconStyle,iconURL
	 */
	private Map<String,String> retrieveIconForObject(String sObjectName) {
		String iconStyle;
		String iconURL;
		String iconTag;
		Map<String,String>                iconPropertyMap = new Map<String,String>();
		List<Schema.DescribeTabSetResult> tabSetDesc      = Schema.describeTabs();
		List<Schema.DescribeTabResult>    tabDesc         = new List<Schema.DescribeTabResult>();
		List<Schema.DescribeIconResult>   iconDesc        = new List<Schema.DescribeIconResult>();

		if(!sObjectName.endsWithIgnoreCase('__c')){
			iconStyle = 'slds-icon-standard-' + sObjectName.toLowerCase();
			iconURL   = '/img/icon/t4v35/standard/' + sObjectName.toLowerCase() + '_120.png';
			iconTag   = sObjectName.toLowerCase();

			iconPropertyMap.put('iconStyle', iconStyle);
			iconPropertyMap.put('iconURL',  iconURL);
			iconPropertyMap.put('iconTag', iconTag);

			return iconPropertyMap;
		}

		for(Schema.DescribeTabSetResult tsr : tabSetDesc){
			tabDesc.addAll(tsr.getTabs());
		}
		for(Schema.DescribeTabResult tr : tabDesc) {
			if( sObjectName == tr.getSobjectName() ) {
				//System.debug(tr.getIcons());
				if(!tr.getIcons().isEmpty()){
					iconDesc.addAll(tr.getIcons());
				} else {
					if( tr.isCustom() == true ) {
						iconStyle = 'slds-icon-standard-record';
						iconURL   = '/img/icon/t4v35/standard/record_120.png';
					} else {
						iconStyle = 'slds-icon-standard-' + sObjectName.toLowerCase();
						iconURL   = '/img/icon/t4v35/standard/' + sObjectName.toLowerCase() + '_120.png';
					}
				}
			}
		}
		for (Schema.DescribeIconResult ir : iconDesc) {
			if(ir.getTheme() =='custom' && !ir.getContentType().startsWith('image/svg')){//custom icon thats not an svg
				iconTag   = 'custom';
				iconURL   = ir.getURL();
				iconStyle = 'slds-icon-standard-record';
				break;
			} else if(ir.getWidth() == 120 && ir.getTheme() =='theme4' && ir.getContentType() == 'image/png'){//large lightning icon image
				if(ir.getURL().contains('/custom/')){ //Icon is from the Custom Sprite
					iconTag    = ir.getURL().substringBetween('custom/','.png').substringBefore('_');
					iconURL    = '/img/icon/t4v35/custom/' + iconTag + '_120.png';
					iconStyle  = 'slds-icon-custom-'+ iconTag;
					break;
				} else if(ir.getURL().contains('/standard/')){//Icon is from the Standard Sprite
					iconTag    = ir.getURL().substringBetween('standard/','.png').substringBefore('_');
					iconURL    = '/img/icon/t4v35/standard/' + iconTag + '_120.png';
					iconStyle  = 'slds-icon-standard-'+ iconTag;
					break;
				}
			}
		}
		//if no icons are found, just default to the Custom lightning icon
		if(iconStyle == null){
			iconStyle = 'slds-icon-standard-record';
			iconURL   = '/img/icon/t4v35/standard/record_120.png';
			iconTag   = 'No Lightning Icon Found';
		}
		//return a map with our properties for the front end
		iconPropertyMap.put('iconStyle', iconStyle);
		iconPropertyMap.put('iconURL',  iconURL);
		iconPropertyMap.put('iconTag', iconTag);

		return iconPropertyMap;
	}
}