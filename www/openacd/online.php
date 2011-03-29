<?php

    if(is_numeric($_GET["opr_off"])){
//	include_once("client.php");
//	$xml = client("op delete ".$_GET["opr_off"]);
	header("Location: /openACD/online.php");
    }
    if($_GET["opr_off"]=='restart'){
//	include_once("client.php");
//	$xml = client("restart");
	header("Location: /openACD/online.php");
    }

include_once("include.php");
    include_once("menu.php");

//	var online=serverGetRequest(url1);
?>
<h2>Онлайн</h2>
<span id='operators'></span>

<script src="ajax.js?v=02" type="text/javascript" charset="windows-1251"></script>

<script type="text/javascript">

function TimerQuery() {
    var url1='online_check.php';
    var online=serverGetRequest(url1);
    document.getElementById('operators').innerHTML = online;
}

var timerRef = window.setInterval("TimerQuery();", 1100);
window.onunload = new Function("clearTimeout(timerRef);");

</script>