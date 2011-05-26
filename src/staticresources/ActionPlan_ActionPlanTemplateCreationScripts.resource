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
        var cycle = false;
		var visitedTasks = new Array();
        if (index[5] == document.getElementById(dependent).value){
			alert ( AP_ITSELF_TASK_DEPENDENCY );
            document.getElementById(dependent).value = 'None';
        }
        // check dependency cycles
        else{
        	while( !cycle && document.getElementById( dependent ).value != 'None' ){
				row = ( dependent.split( ":" )[5] );
				if(!visitedTasks[row]){
					visitedTasks[row] = true;
					dependent = 'editPage:templateForm:editBlock:taskSection:taskTable:' + document.getElementById( dependent ).value + ':dependent';	
				}
				else{
					cycle = true;
					alert( AP_REMOVE_CYCLIC_DEPENDENCY );
					document.getElementById( dependent ).value = 'None';	
				}
        	}
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
    },
    
    showTasksListLoader : function(){
		var tableWidth 	= document.getElementById('editPage:templateForm:editBlock:taskSection:taskTable').offsetWidth;
		var tableHeight = document.getElementById('editPage:templateForm:editBlock:taskSection:taskTable').offsetHeight;
		document.getElementById('tasksListLoader').style.width 				= tableWidth  	+ 'px';
		document.getElementById('tasksListLoader').style.height 			= tableHeight 	+ 'px';
		document.getElementById('tasksListLoader').style.display 			= 'block';
		document.getElementById('tasksListLoaderMessage').style.marginTop	= tableHeight/2 + 'px';
	},
	
	hideTasksListLoader : function(){
		document.getElementById('tasksListLoader').style.display = 'none';
	},
	
	confirmTaskDeletion : function(dependent){
		var display_confirmation = false;
		var index = ( dependent.split( ":" ) );
		
		//check if this tasks has any other depending on it
		var allTasks = getElementsByClass('third',document,'td');
		    allTasks = allTasks.concat(getElementsByClass('third ',document,'td'));
		var i = 0; 
		var selObj= null;   
		while (i < allTasks.length && !display_confirmation ){
			if (allTasks[i] != undefined && allTasks[i].getElementsByTagName('select').length > 0){
				selObj = allTasks[i].getElementsByTagName('select')[0];
		        if ( index[5]== selObj.value )
		        	display_confirmation = true; 
		    }
		    i++;
		}    

		if( display_confirmation ){
			return !confirm(AP_TASKS_CONFIRM_MSG);
		}
		else{
			return false;
		}
	}
}