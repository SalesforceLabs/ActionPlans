/*
  ActionPlanCreationScripts

  version 1
  22 Nov 2010
  Francisco Pereira

  version 2
  March 2021
  David Schach
*/

var maxDays  = 1000;

function checkSkipWeekend(checkboxId, skipDayTableId) {
	var skipbox = document.getElementById(checkboxId);
	var daypicklist = document.getElementById(skipDayTableId);

	if( j$( skipbox ).is(":checked") ){
		j$(daypicklist).show().removeAttr('disabled');
	}
	else{
		j$(daypicklist).attr('disabled','disabled').val("");
	}
}

function checkDependent (dependent, dependentErrorText, cyclicErrorText){
	//var index = ( dependent.split( ":" ) );
	var currentDependentPicklist = document.getElementById( dependent );
	var cycle = false;
	var visitedTasks = new Array();

	var rowNum = getRowFromVisualforceId(dependent);
	if(Number.isNaN(rowNum)){
		return;
	}

	// check itself dependency
	if( rowNum == currentDependentPicklist.value ){
		alert( dependentErrorText );
		currentDependentPicklist.value = 'None';
	}

	// check dependency cycles
	else{
		while( !cycle && document.getElementById( dependent ).value != 'None' ){
			row = getRowFromVisualforceId(dependent);
			if(!visitedTasks[row]){
				visitedTasks[row] = true;
				var nextRowNum = document.getElementById( dependent ).value;
				dependent = j$("select[id$=" + nextRowNum + "\\:dependent]").attr('id');
			}
			else{
				cycle = true;
				alert( cyclicErrorText );
				document.getElementById( dependent ).value = 'None';
			}
		}
	}
}

function getRowFromVisualforceId( elementId ){
	var index = ( elementId.split( ":" ) );
	var rowNum;
	for(var i = 0; i < index.length; i++ ){
		if(Number.isInteger( parseInt(index[i]) ) ) {
			rowNum = parseInt(index[i]);
			return rowNum;
		}
	}
	if(Number.isNaN(rowNum)){
		return null;
	}
}

function checkReminder (type){
	if(type == "1"){
		j$("[id$=\\:reminder]").prop( "checked", true );
	} else {
		j$("[id$=\\:reminder]").prop( "checked", false );
	}
	this.checkReminderPicklists();
}

function checkEmail (type){
	if(type == "1"){
		j$("[id$=sendEmailCheckbox]").prop( "checked", true );
	} else {
		j$("[id$=sendEmailCheckbox]").prop( "checked", false );
	}
}

function enableDisableReminderPicklist ( reminder, reminderPicklistId ){
	var reminderCheckbox = reminder;
	var reminderPicklist = document.getElementById( reminderPicklistId );

	if( reminderCheckbox.checked ){
		reminderPicklist.disabled = false;
	}
	else{
		reminderPicklist.disabled = true;
	}
}

function checkReminderPicklists () {
	j$(".reminderColumn").each( function () {
		if(j$("[id$=reminder]").is(":checked")){
			j$("[id$=reminderPickList]").prop("disabled", false);
		} else {
			j$("[id$=reminderPickList]").prop("disabled", true);
		}
	});
}

function reloadActionPlan(templateId, selectedTemplateId) {
	var new_location    = window.location.href;
	var reload          = 0;
	var refObjType = j$(".hidden_refOBjtype").val(); //getElementsByClassAP('hidden_refOBjtype', null, 'input');
	var objIds = j$('.hidden_refID').val(); //getElementsByClassAP('hidden_refID', null, 'input');


	// There is a template selected and different from previous one
	if ( selectedTemplateId != '000000000000000' && templateId.match(selectedTemplateId ) == null){
		if( templateId != "" ){
			// Replaces current selected template id into the URL
			if (new_location.match('templateId')){
				//new_location = new_location.replace(templateId, selectedTemplateId);

				new_location = '/apex/ActionPlanCreation?templateId=' + selectedTemplateId;

				reload = 1;
			// Adds current selected template id into the URL
			} else {

				var patt1 = /\?/gi;
				var txt = new String(location);
				var concat_with = "&";

				if (txt.match(patt1) == null){
					concat_with = "?";
				}

				new_location += concat_with + "templateId=" + selectedTemplateId;

				reload = 1;
			}

		} else {

			var patt1 = /\?/gi;
			var txt = new String(location);
			var concat_with = "&";
			//var obj_ids_str = "";

			if (txt.match(patt1) == null){
				concat_with = "?";
			}

			new_location += concat_with + "templateId=" + selectedTemplateId;

			if (refObjType.length > 0 ){
				new_location = new_location + '&refType=' + refObjType;

				// add objects list
				if (objIds.length > 0 ){
					new_location = new_location + '&refId=' + objIds;
				}
			}
			reload = 1;
		}

		if (reload) {
			if (refObjType.length > 0 && refObjType != ''){
				new_location = new_location + '&refType=' + refObjType;

				// add objects list

				if (objIds.length > 0 && objIds != ''){
					new_location = new_location + '&refId=' + objIds;
				}
			}

			if (UITheme.getUITheme() === 'Theme4d' || UITheme.getUITheme() === 'Theme4u'){
				sforce.one.navigateToURL(new_location);
			} else {
				window.location.href = new_location;
			}

		}

	} else {
		//manage invalid template ID
	}
}

function getURLParameter(sParam){
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split('&');
    for (var i = 0; i < sURLVariables.length; i++)
    {
        var sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] == sParam)
        {
            return sParameterName[1];
        }
	}
}

function checkAllDependent (dependentErrorText, cyclicErrorText){
	var allTasks = getElementsByClassAP('third',document,'td');
		//allTasks = allTasks.concat(getElementsByClassAP('third',document,'td'));

	allTasks.each(function (i) {
		var n = j$( this ).j$("select");
		if(n.length > 0 && n.hasClass("selectDepending")){
			checkDependent(n.attr('id'), dependentErrorText, cyclicErrorText);
		}
	});
}

function confirmTaskDeletion (dependent, confirmMessage ){
	var display_confirmation = false;
	//var index = ( dependent.split( ":" ) );

	//check if this tasks has any other depending on it
	var allTasks = getElementsByClassAP('third',document,'td');
		//allTasks = allTasks.concat(getElementsByClassAP('third',document,'td'));
	var i = 0;
	var selObj= null;
	while (i < allTasks.length && !display_confirmation ){
		if (allTasks[i] != undefined && allTasks[i].getElementsByTagName('select').length > 0 &&
			allTasks[i].getElementsByTagName('select')[0].className =='selectDepending'){
			selObj = allTasks[i].getElementsByTagName('select')[0];
			if ( getRowFromVisualforceId(dependent) == Number.parseInt(selObj.value )){
				display_confirmation = true;
			}
		}
		i++ ;
	}

	if( display_confirmation ){
		return !confirm(confirmMessage);
	}
	else{
		return false;
	}
}