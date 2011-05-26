/*
  ActionPlanCreationScripts
  version 1
  3th May 2010
  Oliver Cortinas
  
  Add <script src="ActionPlanCreationScripts.js"></script> to your HTML
*/
var taskSize = 75;
ActionPlanCreationScripts = {
	checkSkipWeekend : function (){
		if( document.getElementById( "editPage:apForm:editBlock:taskSection:skipWeekendCheckbox" ).checked == true ){
			document.getElementById( "editPage:apForm:editBlock:taskSection:skipDayTable" ).style.display = "block";
        }
        else{
			document.getElementById( "editPage:apForm:editBlock:taskSection:skipDayTable" ).style.display = "none";
        }
    },

	checkDependent : function (dependent){
		var index = ( dependent.split( ":" ) );
        if( index[5] == document.getElementById( dependent ).value ){
			alert( AP_ITSELF_TASK_DEPENDENCY );
            document.getElementById( dependent ).value = 'None';
        }
    },

	checkReminder : function (type){
		var taskSize = 75;
        if( type == "1" ){
			for( i = 0; i < taskSize; i++ ){
				if( document.getElementById( "editPage:apForm:editBlock:taskSection:taskTable:" + i + ":reminderSection:reminder" ) ){
					document.getElementById( "editPage:apForm:editBlock:taskSection:taskTable:" + i + ":reminderSection:reminder" ).checked = 1;
                }
            }
        }
        else{
			for( i = 0; i < taskSize; i++ ){
				if (document.getElementById( "editPage:apForm:editBlock:taskSection:taskTable:" + i + ":reminderSection:reminder" ) ){
					document.getElementById( "editPage:apForm:editBlock:taskSection:taskTable:" + i + ":reminderSection:reminder" ).checked = 0;
                }
            }
        }
    },

	checkEmail : function (type){
		var taskSize = 75;
		if( type == "1" ){
			for( i = 0; i < taskSize; i++ ){
				if( document.getElementById( "editPage:apForm:editBlock:taskSection:taskTable:" + i + ":emailSection:email")){
					document.getElementById( "editPage:apForm:editBlock:taskSection:taskTable:" + i + ":emailSection:email").checked = 1;
                }
            }
        }
        else{
			for( i = 0; i < taskSize; i++ ){
				if( document.getElementById( "editPage:apForm:editBlock:taskSection:taskTable:" + i + ":emailSection:email" ) ){
					document.getElementById( "editPage:apForm:editBlock:taskSection:taskTable:" + i + ":emailSection:email" ).checked = 0;
                }
            }
        }
    },

	showComments : function ( row ){
		for( i = 0; i < taskSize; i++ ){
			if (document.getElementById( "editPage:apForm:editBlock:taskSection:taskTable:" + i + ":commentPanel" ) ){
				document.getElementById( 'editPage:apForm:editBlock:taskSection:taskTable:' + i + ':commentPanel' ).style.display = "none";
            }
        }
        var rowSplit = row.split( ":" );
        row = rowSplit[5];      
        document.getElementById( 'editPage:apForm:editBlock:taskSection:taskTable:' + row + ':commentPanel' ).style.display = "block";
    },

	hideComments : function ( row ){
		var rowSplit = row.split( ":" );
        newRow = rowSplit[5];
        document.getElementById( 'editPage:apForm:editBlock:taskSection:taskTable:' + newRow + ':commentPanel' ).style.display = "none";
        if( document.getElementById( 'editPage:apForm:editBlock:taskSection:taskTable:' + newRow + ':Comments' ).value == null || document.getElementById( 'editPage:apForm:editBlock:taskSection:taskTable:' + newRow + ':Comments' ).value == "" ){
			document.getElementById( '' + row + ':commentLink' ).innerHTML = "add";
        }   
    }
}
