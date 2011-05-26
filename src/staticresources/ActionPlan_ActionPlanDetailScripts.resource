/*
  ActionPlanDetailScripts
  version 1
  3th May 2010
  Oliver Cortinas
  
  Add <script src="ActionPlanDetailScripts.js"></script> to your HTML
*/
var taskSize = 75;
ActionPlanDetailScripts = {
    showComments : function ( row ){
		for( i = 0; i < taskSize; i++ ){
			if( document.getElementById( "detailPage:apForm:detailBlock:taskSection:theTable:" + i + ":commentPanel" ) ){
				document.getElementById( 'detailPage:apForm:detailBlock:taskSection:theTable:' + i + ':commentPanel' ).style.display = "none";
        	}
        }
 		var rowSplit = row.split( ":" );
 		row = rowSplit[5];
        document.getElementById( 'detailPage:apForm:detailBlock:taskSection:theTable:' + row + ':commentPanel' ).style.display = "block";
    },
        
    hideComments : function ( row ){
		var rowSplit = row.split( ":" );
		row = rowSplit[5];
 		document.getElementById( 'detailPage:apForm:detailBlock:taskSection:theTable:' + row + ':commentPanel' ).style.display = "none";
    }

}