/*
  ActionPlanPrintScripts
  version 1
  22 Nov 2010
  Francisco Pereira
  
  Add <script src="ActionPlanPrintScripts.js"></script> to your HTML
*/
var taskSize = 75;
ActionPlanPrintScripts = {

	formatFields : function ( ){
		this.formatSubject();
		this.formatDependency();
		this.formatComments();
	},
	
	formatSubject : function ( ){
		var subject;
		
		for( i = 0; i < taskSize; i++ ){
			subject = document.getElementById( "printPage:apForm:detailBlock:taskSection:theTable:" + i + ":columnOne" );
			if( subject ){
				subject.innerHTML = fitToWidth( subject.innerHTML, 20 );
        	}
        }
	},
	
	formatDependency : function ( ){
		var dependency;
		
		for( i = 0; i < taskSize; i++ ){
			dependency = document.getElementById( "printPage:apForm:detailBlock:taskSection:theTable:" + i + ":dependency" );
			if( dependency ){
				dependency.innerHTML = fitToWidth( dependency.innerHTML, 20 );
        	}
        }
	},
	
	formatComments : function ( ){
		var comment;
		var text;
		for( i = 0; i < taskSize; i++ ){
			dependency = document.getElementById( "printPage:apForm:detailBlock:taskSection:theTable:" + i + ":comment" );
			if( dependency ){
				text = fitToWidth( dependency.innerHTML, 20 );
				dependency.innerHTML = (text.length > 80) ?text.substring(0, 77) + '...' : text;  
        	}
        }
	}

}