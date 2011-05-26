.taskTable { 
	width:100% 
}
.taskTable td { 
	width:0%; 
	padding:3px 3px 2px 3px; 
}
.taskTable th { 
	padding: 0px 2px 3px 0px !important; 
	border-bottom: 2px solid #ccc !important; 
	margin-bottom:2px !important;
}
a { 
	cursor: pointer; 
}
.errorMessage { 
	margin: 15px 0px 0px 0px !important; 
	color:#cc0000; 
	border-left:2px solid #cc0000 !important;
}
a.all-none { 
	font-weight: normal; 
	cursor: pointer; 
	color: #000000; 
	text-decoration:underline;
}
#commentContainer { 
	width:270px; 
	right:20px; 
	position:absolute; 
	border: 3px solid #77B900; 
	padding:0px;  
	z-index:9999;
}
#commentContainer .hd { 
	width:100%; 
	background-color:#77B900; 
	height:23px;
}
#commentContainer .hd-left { 
	float:left; 
	color:#fff; 
	font-weight:bold; 
	padding:3px 0px 0px 5px;
}
#commentContainer .hd-right { 
	float:right; 
}
#commentContainer .bd { 
	background-color:#f3f3ec; 
	clear:both; 
}
#commentContainer textarea { 
	margin:5px; 
	width:250px;
}
#templateForm select { 
	z-index:1; 
}
#daysAfterTtip_help.helpButton, #daysAfterTtip_help.helpButtonOn {
    position: absolute;
}
#tasksListLoader {
	background-color:white;
	opacity:0.9;
	position:absolute;
	z-index:500;
}