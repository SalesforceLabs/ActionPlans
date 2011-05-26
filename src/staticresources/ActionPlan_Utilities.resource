function gup( name ){
	var regexS = "[?&]"+name+"=([^&#]*)";
	var regex = new RegExp ( regexS );
	var tmpURL = window.location.href;
	var results = regex.exec( tmpURL );
	if( results == null ){
		return "";
	}else{
		return results[1];
	}
}

/*
OLD VERSION 
function getElementsByClass(searchClass,node,tag) {
	var classElements = new Array();
	if ( node == null )
		node = document;
	if ( tag == null )
		tag = '*';
	var els = node.getElementsByTagName(tag);
	var elsLen = els.length;
	var pattern = new RegExp('(^|\\\\s)'+searchClass+'(\\\\s|$)');
	for (i = 0, j = 0; i < elsLen; i++) {
		if ( pattern.test(els[i].className) ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}

*/

function getElementsByClass(searchClass,node,tag) {
	var classElements = new Array();
	if ( node == null )
		node = document;
	if ( tag == null )
		tag = '*';
	var els = node.getElementsByTagName(tag);
	var elsLen = els.length;
	var pattern = new RegExp('(^|\\\\s)'+searchClass+'(\\\\s|$)');
	var match = false;
	var h = 0;
	var class_list = null;
	for (i = 0, j = 0; i < elsLen; i++) {
		class_list = els[i].className.split(' ');
		match = false;
		h = 0;
		while (!match && h< class_list.length){
			match = pattern.test(class_list[h]);
			h++;
		}
	
		if ( match ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}


/* This method is invoked when clicking over a button*/
function disableActions() {

	//disable top buttons
	var btns = getElementsByClass('btn',document.getElementById('editPage:apForm:editBlock:buttons'),'input');
	for(var i in btns){
		btns[i].setAttribute('disabled', "disabled"); 
		btns[i].setAttribute('className', "btnDisabled"); 
		btns[i].setAttribute('class', "btnDisabled"); 
	}

	//disable bottom buttons
	var btns_bottom = getElementsByClass('btn',document.getElementById('editPage:apForm:editBlock:buttons:bottom'),'input');
	for(var j in btns_bottom){
		btns_bottom[j].setAttribute('disabled', "disabled"); 
		btns_bottom[j].setAttribute('className', "btnDisabled"); 
		btns_bottom[j].setAttribute('class', "btnDisabled"); 
	}

   return true;
   
}


function enableActions() {

	//disable top buttons
	var btns = getElementsByClass('btnDisabled',document.getElementById('editPage:apForm:editBlock:buttons'),'input');
	for(var i in btns){
		btns[i].removeAttribute('disabled'); 
		btns[i].setAttribute('className', "btn"); 
		btns[i].setAttribute('class', "btn"); 
	}

	//disable bottom buttons
	var btns_bottom = getElementsByClass('btnDisabled',document.getElementById('editPage:apForm:editBlock:buttons:bottom'),'input');
	for(var j in btns_bottom){
		btns_bottom[j].removeAttribute('disabled'); 
		btns_bottom[j].setAttribute('className', "btn"); 
		btns_bottom[j].setAttribute('class', "btn"); 
	}

   return true;
   
}

function addDays(myDate,days) {
   return new Date(myDate.getTime() + days*24*60*60*1000);
}

//if the text contains words with a length greater than t_length
// this function will add a space character in the t_length position
// for cases when horizontal scroll must not be shown and text escapes from containter
function fitToWidth(text, t_length){

	var parts = text.split(' ');
    var s = '';
    var s_tmp = '';
    var s_final = '';

    for (var i = 0; i < parts.length; i++) {
        s = parts[i];
        s_remain = s;
        while (s.length > t_length) {
            s_tmp = s.substring(0, t_length);
            s = s.substring(t_length, s.length);
    		s_final += s_tmp + ' ';
        }
        s_final += s + ' ';
    }
    return s_final;
}


function applyTooltip(className,msg){
	var obj = getElementsByClass(className,document,'th');
	if (obj != null){
		var div = obj[0].getElementsByTagName('div')
		div[0].title= msg;//"This value determines the due date of the task. For tasks with no dependency, the task's due date will be offset from the plan start date. For tasks with a dependency, the due date will be offset from the expected due date of the task on which it depends on.";
	}
}

function showErrors(){
	if(getElementsByClass('errorMsg',document,'div').length > 0){
		document.getElementById('error').style.display = 'block';
	}
	else{
		document.getElementById('error').style.display = 'none';	
	}
	
	
	var all_cols= getElementsByClass('fifth',document,'td');
	for (var h = 0; h < all_cols.length; h++) {	
		var aux_divs = getElementsByClass('ownerLookUpPanel',all_cols[h],'div');
		for (var i = 0; i < aux_divs.length; i++) {
					
			if(getElementsByClass('errorMsg',aux_divs[0],'div').length > 0){
				all_cols[h].childNodes[0].style.display = 'block';
				all_cols[h].childNodes[1].style.display = 'none';
			}
			else{
				all_cols[h].childNodes[0].style.display = 'none';
				all_cols[h].childNodes[1].style.display = 'block';	
			}
		}	
	}
}