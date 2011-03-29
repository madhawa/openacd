<html>
<head>
<title>ACD Monitor</title>
<?if($op==1):?>
<meta http-equiv="Refresh" content="1; URL=op.php">
<?endif;?>
<?if($online2==12):?>
<meta http-equiv="Refresh" content="1; URL=online2.php">
<?endif;?>
<META HTTP-EQUIV="Content-type" CONTENT="text/html; charset=UTF-8">
<script language="javascript" src="jquery-1.2.1.js" type="text/javascript"></script>
<script language="javascript" src="acd-query.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="css/calendar.css" />
<style>
body	{margin:5px; padding:5px; background-color:#ffffff; color:#333333; font-size:80%; font-family: Verdana, Arial, Geneva CY, Sans-Serif;}
a       {color:#0033ff}
a:hover {color:#0000ff}
h2      {font-size:150%; color:#666666;}
table   {border-collapse:collapse;}
td      {margin:0; padding:1; vertical-align:top; color:#333333; font-size:80%; font-family: Verdana, Arial, Geneva CY, Sans-Serif;}

#ACDQueues td		{vertical-align:middle;	padding: 0.1em 0.3em 0.1em 0.3em; border-bottom: 1px solid #505050; }
#ACDQueues td.zero	{color:#999999;}
#ACDQueues td.normal	{color:#333333;}
#ACDQueues td.red	{color:#993333;}
#ACDQueues #h td	{background-color:#f9f9f9; color:#333366; vertical-align:top;}

#ACDCalls td		{vertical-align:middle;	padding: 0.1em 0.3em 0.1em 0.3em; border-bottom: 1px solid #e0e0e0; }
#ACDCalls td.zero	{color:#999999;}
#ACDCalls td.normal	{color:#333333;}
#ACDCalls td.red	{color:#993333;}
#ACDCalls #h td		{background-color:#f9f9f9; color:#333366; vertical-align:top;}

#ACDPhones td		{vertical-align:middle;	padding: 0.1em 0.3em 0.1em 0.3em; border-bottom: 1px solid #e0e0e0; }
#ACDPhones td.lock	{color:#cccccc;}
#ACDPhones td.zero	{color:#999999;}
#ACDPhones td.half	{color:#666666;}
#ACDPhones td.free	{color:#330000;}
#ACDPhones td.normal	{color:#333333;}
#ACDPhones td.red	{color:#993333;}
#ACDPhones #h td	{background-color:#f9f9f9; color:#333366; vertical-align:top;}

#Logs td	{vertical-align:middle;	padding: 0.1em 0.3em 0.1em 0.3em; border-bottom: 1px solid #e0e0e0; }
#Logs td.lock	{color:#cccccc;}
#Logs td.zero	{color:#999999;}
#Logs td.half	{color:#666666;}
#Logs td.free	{color:#330000;}
#Logs td.normal	{color:#333333;}
#Logs td.red	{color:#993333;}
#Logs #h td	{background-color:#f9f9f9; color:#333366; vertical-align:top;}

ï».list {
    border-collapse:	collapse;
    border-top:			solid 1px #A2A2A2;
}

.list .left {
    border-left: 		solid 1px #A2A2A2;
}

.list .once {
    border-left: 		solid 1px #A2A2A2;
    border-right: 		solid 1px #A2A2A2;
}

.list .right {
    border-right: 		solid 1px #A2A2A2;
}

.list td {
    font-size:				12px;
    padding:					5px;
    background-color:	#F5F5F5;
    border-bottom: 		dashed 1px #CCCCCC;
}

.list .light {
    background-color:	#FFE;
}

.p0 td {padding: 0px; font-size: 10px; white-space:nowrap;}
.p1 td {padding: 2px; font-size: 12px; white-space:nowrap; border-right: dashed 1px #CCCCCC;}

</style>

<script src="js/calendar/prototype.js" type="text/javascript"></script>
<script src="js/calendar/scriptaculous.js" type="text/javascript"></script>
<script src="js/calendar/calendar.js" type="text/javascript"></script>

</head>
<body>
