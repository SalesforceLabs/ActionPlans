/*
  ActionPlanTemplateCreationScripts
  version 1
  3th May 2010
  Oliver Cortinas
  
  Add <script src="ActionPlanTemplateCreationScripts.js"></script> to your HTML
*/
var taskSize = 75;
ActionPlanTemplateCreationScripts = {    	
    checkSkipWeekend : function (){
		if (document.getElementById("editPage:templateForm:editBlock:taskSection:skipWeekendCheckbox").checked == true){
			document.getElementById("editPage:templateForm:editBlock:taskSection:skipDayTable").style.display = "block";
        } else {
			document.getElementById("editPage:templateForm:editBlock:taskSection:skipDayTable").style.display = "none";
        }
    },
        
    checkDependent : function (dependent){
        var index = (dependent.split(":"));
        if (index[5] == document.getElementById(dependent).value){
			alert ( AP_ITSELF_TASK_DEPENDENCY );
            document.getElementById(dependent).value = 'None';
        }
    },
        
    checkReminder : function (type){
        if (type == "1"){
			for (i=0; i < taskSize; i++){
				if (document.getElementById("editPage:templateForm:editBlock:taskSection:taskTable:"+ i +":reminderSection:reminder")){
					document.getElementById("editPage:templateForm:editBlock:taskSection:taskTable:"+ i +":reminderSection:reminder").checked = 1;
	        	}
	        }
        } else {
			for (i=0; i < taskSize; i++){
				if (document.getElementById("editPage:templateForm:editBlock:taskSection:taskTable:"+ i +":reminderSection:reminder")){
					document.getElementById("editPage:templateForm:editBlock:taskSection:taskTable:"+ i +":reminderSection:reminder").checked = 0;
	        	}
	        }
        }
    },
        
    checkEmail : function (type){
        if (type == "1"){
			for (i=0; i < taskSize; i++){
				if (document.getElementById("editPage:templateForm:editBlock:taskSection:taskTable:"+ i +":emailSection:email")){
					document.getElementById("editPage:templateForm:editBlock:taskSection:taskTable:"+ i +":emailSection:email").checked = 1;
	        	}
	        }
        } else {
			for (i=0; i < taskSize; i++){
				if (document.getElementById("editPage:templateForm:editBlock:taskSection:taskTable:"+ i +":emailSection:email")){
					document.getElementById("editPage:templateForm:editBlock:taskSection:taskTable:"+ i +":emailSection:email").checked = 0;
	        	}
	        }
        }
    },
        
       
    showComments : function (row){
        for (i=0; i < taskSize; i++){
			if (document.getElementById("editPage:templateForm:editBlock:taskSection:taskTable:"+ i +":commentPanel")){
				document.getElementById('editPage:templateForm:editBlock:taskSection:taskTable:'+ i +':commentPanel').style.display = "none";
        	}
        }
 		var rowSplit = row.split(":");
 		row = rowSplit[5];      
        document.getElementById('editPage:templateForm:editBlock:taskSection:taskTable:'+row+':commentPanel').style.display = "block";
    },
        
    hideComments : function (row){
       	var rowSplit = row.split(":");
 		newRow = rowSplit[5];
 		document.getElementById('editPage:templateForm:editBlock:taskSection:taskTable:'+newRow+':commentPanel').style.display = "none";
 		if (document.getElementById('editPage:templateForm:editBlock:taskSection:taskTable:'+newRow+':Comments').value == null || document.getElementById('editPage:templateForm:editBlock:taskSection:taskTable:'+newRow+':Comments').value == ""){
 			document.getElementById(''+row+'-commentLink').innerHTML = "add";
 		}	
    }
}