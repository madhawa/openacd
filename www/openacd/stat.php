<?php
    include_once("db_connect.php");

    $xls = trim ($_GET['xls']);
    $xlstype = trim ($_GET['type']);

    include_once("include.php");

if($_SESSION['logged']=='admin' || $_SESSION['logged']=='stat') {
    include_once("xls.php");

    if($xls!=1) include_once("menu.php");

    include_once("db_connect.php");

    if($xls==1) $_POST=$_GET;
    
    $search = trim ($_POST['search']);
    $kouch = trim ($_POST['kouch']);
    $service = trim ($_POST['service']);
    $call_type = trim ($_POST['call_type']);
    $number = trim ($_POST['number']);
    $date = trim ($_POST['to_date_from']);
    $datet = trim ($_POST['to_date_to']);
    $time = trim ($_POST['to_time_from']);
    $timet = trim ($_POST['to_time_to']);
    $random = trim ($_POST['random']);
    $random_count = (isset($_POST['random_count']))?trim($_POST['random_count']):50;

    $operators = pg_exec('select * from public.operators ORDER BY opr_name ASC');
    $services = pg_exec('SELECT * FROM public.services ORDER BY srv_order DESC');

if($xls==1) {
    if(!isset($xlstype)) $xlstype='';
// Send Header
    header("Pragma: public");
    header("Expires: 0");
    header("Cache-Control: must-revalidate, post-check=0, pre-check=0");
    header("Content-Type: application/force-download");
    header("Content-Type: application/octet-stream");
    header("Content-Type: application/download");;
    header("Content-Disposition: attachment;filename=operators-".date("Ymd-His").".xls");
    header("Content-Transfer-Encoding: binary ");

    xlsBOF();
    
    $i=0;
    foreach($_SESSION['xls_table'.$xlstype] as $str) {
	$j=0;
	foreach ($str as $cell){
	    if(is_numeric($cell)) xlsWriteNumber($i,$j++,$cell);
	    else xlsWriteLabel($i,$j++,  iconv('utf-8', 'cp1251', $cell));
	}
	$i++;
    }

    xlsEOF();
    exit();

?><?
} else {

$_SESSION['xls_table'.$xlstype] = "";

?>

<script type="text/javascript">
<!--

function dynamicSelect(id1, id2) {
 	if (document.getElementById && document.getElementsByTagName) {
  		var sel1 = document.getElementById(id1);
  		var sel2 = document.getElementById(id2);
  		var clone = sel2.cloneNode(true);
  		var clonedOptions = clone.getElementsByTagName("option");
  		refreshDynamicSelectOptions(sel1, sel2, clonedOptions);
  		sel1.onchange = function() {
   			refreshDynamicSelectOptions(sel1, sel2, clonedOptions);
  		};
 	}
}

function refreshDynamicSelectOptions(sel1, sel2, clonedOptions) {
 	while (sel2.options.length) {
  		sel2.remove(0);
 	}
 	var pattern1 = /( |^)(select)( |$)/;
	if(sel1.options[sel1.selectedIndex].value=='none') {
 		var pattern2 = new RegExp("( |^)(.*?)( |$)");
	} else {
 		var pattern2 = new RegExp("( |^)(" + sel1.options[sel1.selectedIndex].value + "|all)( |$)");
	}
 	for (var i = 0; i < clonedOptions.length; i++) {
  		if (clonedOptions[i].className.match(pattern1) || clonedOptions[i].className.match(pattern2)) {
  		 	sel2.appendChild(clonedOptions[i].cloneNode(true));
  		}
 	}
}

function addLoadEvent(func) {
  var oldonload = window.onload;
  if (typeof window.onload != 'function') {
    window.onload = func;
  } else {
    window.onload = function() {
      if (oldonload) {
        oldonload();
      }
      func();
    }
  }
}

addLoadEvent(function() {
dynamicSelect("kchs", "oprs");
});
//-->
</script>


<h2>Операторы</h2>

<form method="post" name="op">
    
    Коуч: 
    <select name="kouch" id="kchs">
	<option value="none">...</option>
<?
    $kouchdb = pg_exec('select * from public.kouch ORDER BY kch_name ASC');
    while($t3 = pg_fetch_array($kouchdb)){
	echo "<option value=".$t3['kch_id'];
	if($kouch==$t3['kch_id']) echo " selected";
	echo ">".$t3['kch_name']."</option>";
    }
?>	
    </select>
    <br />

    Оператор:<br> 
    <select name="search" id="oprs">
	<option class="all" value="all">все операторы</option>
    <?
	while($t = pg_fetch_array($operators)){
	    echo "<option class=\"".$t['kch_id']."\"";
	    if($t['opr_password']==$search) echo "selected ";
	    echo "value=".$t['opr_password'].">".$t['opr_password']." - ".$t['opr_name']."</option>";
	}
    ?>
    </select>
    <br />

<script type="text/javascript">
function showElement()
{ 
    if (document.forms.op.search.value == 'all') {
	document.getElementById("k").style.display="block"; 
    } else {
	document.getElementById("k").style.display="none"; 
    }
}
showElement();
</script>

<table><tr><td>    
    Дата с: <input name="to_date_from" id="to_date_from" type="text" size="11" maxlength="11" value="<?=(!empty($date))?$date:Date("Y-m-d");?>">
    <a href="javascript:void(null);" id="icon2"><img src="images/calendar.gif" width="16" height="16" border=0 alt="" /></a>
    <script type="text/javascript">
	new Component.Calendar('to_date_from', {lang: 'en'});
	new Component.Calendar('to_date_from', {lang: 'en', click: 'icon2'});
    </script>
    <br>
    Время с: <input name="to_time_from" type="text" size="11" maxlength="11" value="<?=(!empty($time))?$time:"07:00:00";?>">
</td><td>
    &nbsp;&nbsp;&nbsp;&nbsp;
</td><td>
    Дата по: <input name="to_date_to" id="to_date_to" type="text" size="11" maxlength="11" value="<?=(!empty($datet))?$datet:Date("Y-m-d", strtotime("+1 day"));?>">
    <a href="javascript:void(null);" id="icon3"><img src="images/calendar.gif" width="16" height="16" border=0 alt="" /></a>
    <script type="text/javascript">
	new Component.Calendar('to_date_to', {lang: 'en'});
	new Component.Calendar('to_date_to', {lang: 'en', click: 'icon3'});
    </script>
    <br>
    Время по: <input name="to_time_to" type="text" size="11" maxlength="11" value="<?=(!empty($timet))?$timet:"06:59:59";?>">
</td></tr></table>    
    Служба: 
    <select name="service">
	<option value="">все</option>
    <?
	while($t = pg_fetch_array($services)){
	    echo "<option ";
	    if($t['srv_name']==$service) echo "selected ";
	    echo "value=".$t['srv_name'].">".$t['srv_name']."</option>";
	}
    ?>
    </select>

    Тип звонка: 
    <select name="call_type">
	<option value="">все</option>
	<option <? if($call_type=="in") echo "selected "; ?> value="in">входящие</option>
	<option <? if($call_type=="out") echo "selected "; ?> value="out">исходящие</option>
    </select>
    <br />
    Номер абонента: <input type="text" name="number" size="11" maxlength="11" value="<?=$number;?>">
<br />

<input type="checkbox" onclick="show_n_hide('show_random');" id="label_random" name="random" value="on" <?if($random=='on') echo 'checked'?> >случайным образом
<span id="show_random" style="display:none;">
<br>
    Количество выводимых данных: <input type="text" name="random_count" size="5" maxlength="5" value="<?=$random_count;?>">
</span>

<script language="JavaScript">
function show_n_hide(what) {
    if(document.getElementById('label_random').checked){
	document.getElementById(what).style.display='';
    } else {
	document.getElementById(what).style.display='none';
    }
}

show_n_hide('show_random');
</script>

    <br /><br />
    <input type="submit" value="Найти" name="submit"><br />
</form>
<?php

function show_table($logs_new, $hide=array(0,0,0), $xlstype="") {
    $j=0;
    echo "<table border=1><tr>
	<td>ФИО</td>
	<td>пароль</td>
	<td>дата</td>";
    $tmp = array("ФИО", "пароль", "дата");
    if($hide[0]==0) {
	echo"
	<td>в системе</td>
	<td>прием</td>";
	$tmp = array_merge($tmp, array("в системе", "прием"));
    }
	echo "<td>завершение</td>";
	echo"<td>статус</td>";
	$tmp = array_merge($tmp, array("время", "статус"));
	if($hide[0]==0) echo '<td>номер</td>';
	if($hide[1]==0) echo '<td>разговор</td>';
	if($hide[0]==0) echo '<td>реакция</td>';
	if($hide[2]==0) echo '<td>интервал</td>';
	if($hide[0]==0) echo '<td>служба</td>';
	if($hide[0]==0) echo '<td>hangup</td>';

	if($hide[0]==0) $tmp = array_merge($tmp, array("номер"));
	if($hide[1]==0) $tmp = array_merge($tmp, array("разговор"));
	if($hide[0]==0) $tmp = array_merge($tmp, array("реакция"));
	if($hide[2]==0) $tmp = array_merge($tmp, array("интервал"));
	if($hide[0]==0) $tmp = array_merge($tmp, array("служба"));
	if($hide[0]==0) $tmp = array_merge($tmp, array("hangup"));
	echo"
	</tr>";
    $_SESSION['xls_table'.$xlstype][] = $tmp;
    while($t = pg_fetch_array($logs_new)){
	$tmp = array();
    	echo '<tr>';
	echo '<td>'.$t['opr_name'].'</td>';
	echo '<td>'.$t['opr_password'].'</td>';
	echo '<td>'.substr($t['dt'],0,10).'</td>';
	$tmp = array($t['opr_name'], $t['opr_password'], substr($t['dt'],0,10));
	if($hide[0]==0) {
	    echo '<td>'.substr($t['dt_begin'],11,8).'</td>';
	    echo '<td>'.date("H:i:s", strtotime(substr($t['dt'],11,8)." -".$t['timer']." seconds")).'</td>';
	    echo '<td>'.substr($t['dt'],11,8).'</td>';
	    $tmp = array_merge($tmp, array(substr($t['dt_begin'],11,8), date("H:i:s", strtotime(substr($t['dt'],11,8)." -".$t['timer']." seconds")), substr($t['dt'],11,8)));
	} else {
	    echo '<td>'.substr($t['dt'],11,8).'</td>';
	    $tmp = array_merge($tmp, array(substr($t['dt'],11,8)));
	}
	if($t['event']==21) echo '<td>вход</td>';
	elseif($t['event']==22) echo '<td>выход</td>';
	elseif($t['event']==10) {echo '<td>принятый</td>';$tmp = array_merge($tmp, array("принятый"));}
	elseif($t['event']==52) {echo '<td><b>без ответа</b></td>';$tmp = array_merge($tmp, array("без ответа"));}
	elseif($t['event']==53) {echo '<td><b>потерянный</b></td>';$tmp = array_merge($tmp, array("потерянный"));}
	elseif($t['event']==31) {echo '<td>исходящий</td>';$tmp = array_merge($tmp, array("исходящий"));}
	elseif($t['event']==36) {echo '<td>исх. без ответа</td>';$tmp = array_merge($tmp, array("исх. без ответа"));}
	elseif($t['event']==32) {echo '<td><i><b>локальный вх.</b></i></td>';$tmp = array_merge($tmp, array("локальный входящий"));}
	else echo '<td>'.$t['event'].'</td>';
	if($hide[0]==0) {echo '<td>'.$t['callid'].'</td>';$tmp = array_merge($tmp, array($t['callid']));}
	if($hide[1]==0) {echo '<td>'.$t['timer'].'</td>';$tmp = array_merge($tmp, array($t['timer']));}
	if($hide[0]==0) {echo '<td>'.$t['beforeanswertime'].'</td>';$tmp = array_merge($tmp, array($t['beforeanswertime']));}
	if($hide[2]==0) {
	    if($j==0) {
		$j=strtotime($t['dt']." -".$t['timer']." seconds")-$t['beforeanswertime'];
		echo '<td>0</td>';
		$tmp = array_merge($tmp, array(0));
	    } else {
		$m = $j-strtotime($t['dt']);
		if($hide[0]!=0) $m=round($m/60);
		echo '<td>'.($m).'</td>';
		$tmp = array_merge($tmp, array($m));
		$j=strtotime($t['dt']." -".$t['timer']." seconds")-$t['beforeanswertime'];
	    }
	    echo '</td>';
	}
	if($hide[0]==0){
	    echo '<td>'.$t['acdgroup'];
	    $tmp = array_merge($tmp, array($t['acdgroup']));
	    echo '</td>';
	}
//	if($hide[0]==0) echo '<td>'.$t['exten'].'</td>';
	if($t['dialstatus']==10) $t['dialstatus']="<b>оператор</b>";
	else $t['dialstatus']="";
	if($hide[0]==0) echo '<td>'.$t['dialstatus'].'</td>';
	$tmp = array_merge($tmp, array($t['dialstatus']));
	if($t['callid']==0) $t['callid'] = '';
	if( $t['record_file_name'] ) echo '<td><a href="sound.php?id='.$t['record_id'].'">аудио</a></td>';
    	echo '</tr>';
	$_SESSION['xls_table'.$xlstype][] = $tmp;
    }
    echo "</table>";
}

function op_info($search, $date, $time, $datet, $timet, $service, $call_type) {
//    $where="AND (op.opr_password like '%$search%' OR op.opr_name='$search')";
    $where="AND (op.opr_password = '$search')";
//    if($kouch!=0) $where.=" AND op.kouch='$kouch'";
    if($service!=0) $where.=" AND al.acdgroup='$service'";
    if( $call_type ) {
	$where.= ($call_type=='in')? " AND (al.event=10)" : " AND (al.event=31)";
    }
    if(!empty($date) && !empty($date)) $where.=" AND al.dt BETWEEN '$date $time' AND '$datet $timet'";
    else $where.=" AND al.dt BETWEEN '".Date("Y-m-d")." 00:00:00' AND '".Date("Y-m-d")." 23:59:59'";

//echo ('select COUNT(*), SUM(al.timer), SUM(al.beforeanswertime) from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) WHERE (al.event=10) '.$where.' GROUP by al.agent');
    $logs_new = pg_fetch_array(pg_exec('select COUNT(*), SUM(al.timer), SUM(al.beforeanswertime) from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) WHERE (al.event=10) '.$where.' GROUP by al.agent'));
    $recived = ($logs_new[0])?$logs_new[0]:0;
    $totaltime = round($logs_new[1]/60);
    if($logs_new[0]!=0) {
	$answertime = round($logs_new[1]/$logs_new[0]);
	$reaction = round($logs_new[2]/$logs_new[0]*100)/100;
    } else {
	$answertime = $reaction = 0;
    }

    $logs_new = pg_fetch_array(pg_exec('select COUNT(*) from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) WHERE (al.event=52) '.$where.' GROUP by al.agent'));
    $noanswer = ($logs_new[0])?$logs_new[0]:0;

    $logs_new = pg_fetch_array(pg_exec('select COUNT(*) from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) WHERE (al.event=53) '.$where.' GROUP by al.agent'));
    $lost = ($logs_new[0])?$logs_new[0]:0;

    $logs_new = pg_fetch_array(pg_exec('select COUNT(*) from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) WHERE (al.dialstatus=10) '.$where.' GROUP by al.agent'));
    $hangup = ($logs_new[0])?$logs_new[0]:0;

    $logs_new = pg_fetch_array(pg_exec('select COUNT(*) from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) WHERE (al.event=31 OR al.event=32) '.$where.' GROUP by al.agent'));
    $local_count = ($logs_new[0])?$logs_new[0]:0;

    $logs_new = pg_fetch_array(pg_exec('select SUM(al.timer) from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) WHERE (al.event=31 OR al.event=32) '.$where.' GROUP by al.agent'));
    $local_timer = ($logs_new[0])?round($logs_new[0]/60*100)/100:0;

    $total_time=$break_time=0;
    $tb=$tp='';
    $logs_new = pg_exec('select *, date_trunc(\'second\', al.Dt) as dt from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id)
			LEFT JOIN public.records r ON (al.record_id=r.record_id) 
			WHERE (al.event=21 OR al.event=22) '.$where.' order by date_trunc(\'second\', al.Dt) Asc, al.event Desc');
    while($t = pg_fetch_array($logs_new)){
	if($t['event']==21) {
	    $tb=$t['dt'];
	    if ($tp!='') {
		$break_time+=strtotime($tb)-strtotime($tp);
		$tp='';
	    }
	}
	if($t['event']==22 && $tb!='') {
	    $tp=$t['dt'];
	    if ($tb!='') {
		$total_time+=strtotime($tp)-strtotime($tb);
		$tb='';
    	    }
	}
    }
    $timeonline = round($total_time/60);
    $timeoffline = round($break_time/60);
    
    return (array($recived, $totaltime, $answertime, $reaction, $noanswer, $lost, $timeonline, $timeoffline, $local_count, $local_timer, $hangup));
}

$more_than_day = ((strtotime($datet." ".$timet)-strtotime($date." ".$time)) > (25*60*60));

if(empty($search) || $search!='all') {
    echo '<h3>События оператора</h3>';
//    if($search!='all') $where.="AND (op.opr_password like '%$search%' OR op.opr_name='$search')";
    if($search!='all') $where.="AND (op.opr_password='$search')";
    if(!empty($date) && !empty($date)) $where.=" AND al.dt BETWEEN '$date $time' AND '$datet $timet'";
    else $where.=" AND al.dt BETWEEN '".Date("Y-m-d")." 00:00:00' AND '".Date("Y-m-d")." 23:59:59'";
}

echo "<table><tr><td valign='top'>";


    $where = "";
if(!empty($search)) {
//    if($search!='all') $where.="AND (op.opr_password like '%$search%' OR op.opr_name='$search')";
    if($search!='all') $where.="AND (op.opr_password='$search')";
    if($kouch!=0 && $search=='all') $where.=" AND op.kch_id='$kouch'";
    if(!empty($date) && !empty($date)) $where.=" AND al.dt BETWEEN '$date $time' AND '$datet $timet'";
    else $where.=" AND al.dt BETWEEN '".Date("Y-m-d")." 00:00:00' AND '".Date("Y-m-d")." 23:59:59'";

  if(!empty($search) && $search!='all' && !$more_than_day && $random!='on') {
    list($recived, $totaltime, $answertime, $reaction, $noanswer, $lost, $timeonline, $timeoffline, $local_count, $local_timer, $hangup) = op_info($search, $date, $time, $datet, $timet, $service, $call_type);
    
    echo "<b>Принятые:</b> $recived<br>";
    echo "<b>Принятые(эфир), мин:</b> $totaltime<br>";
    echo "<b>Среднее время ответа, сек:</b> $answertime<br>";
    echo "<b>Среднее время реакции, сек:</b> $reaction<br>";
    if($timeonline!=0) echo "<b>Звонков, среднее за час:</b> ".round($recived/($timeonline/60))."<br>";
    echo "<b>Без ответа:</b> $noanswer<br>";
    echo "<b>Потерянные:</b> $lost<br>";
    echo "<b>hangup:</b> $hangup<br>";
    echo "<b>hangup от принятых:</b> ".round($hangup/$recived*100)."%<br>";
    echo "<b>Локальных звонков:</b> $local_count<br>";
    echo "<b>Время локальных звонков, мин:</b> $local_timer<br>";
    echo "<b>Время на линии, мин:</b> $timeonline<br>";
    echo "<b>Среднее время простоя, сек:</b> ".round((($timeonline-$totaltime)*60-5*$recived)/($recived+1))."<br>";
    echo "<b>Время перерывов, мин:</b> $timeoffline<br>";

	$logs_new = pg_exec('select * from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) 
			    LEFT JOIN public.records r ON (al.record_id=r.record_id) 
			    WHERE (al.event=21 OR al.event=22) '.$where.' order by date_trunc(\'second\', al.Dt_begin) Desc, al.event Asc LIMIT 100');
	echo '<h3>вход-выход</h3>';
	$_SESSION['xls_table2'] = "";
	echo '<a href="?xls=1&type=2"><img border=0 src="http://stat.isystems.com.ua/img/admin/xls.gif"> Экспорт в Excel</a>';
	show_table($logs_new, array(1,1), 2);



} elseif ( $more_than_day && (!empty($search)) && $random!='on' && empty($number)) {
    echo '<h3>Сводная по оператору</h3> <a href="?xls=1"><img border=0 src="http://stat.isystems.com.ua/img/admin/xls.gif"> Экспорт в Excel</a>';
    echo "<table border=1><tr>
	<td></td>
	<td>Пароль</td>
	<td>ФИО</td>
	<td>Дата</td>
	<td><small>Принятые</small></td>
	<td><small>эфир, мин</small></td>
	<td><small>среднее за час</small></td>
	<td><small>среднее t ответа, сек</small></td>
	<td><small>реакция. среднее, сек</small></td>
	<td><small>Без ответа</small></td>
	<td><small>Потери</small></td>
	<td><small>Hangup</small></td>
	<td><small>Hangup от принятых</small></td>
	<td><small>Локальных</small></td>
	<td><small>Локальных, мин</small></td>
	<td><small>На линии, мин</small></td>
	<td><small>Перерыв, мин</small></td>
	<td><small>Простой, среднее, сек</small></td></tr>
	";
    $_SESSION['xls_table'][] = array("","Пароль", "ФИО", "Дата", "Принятые", "эфир, мин", "среднее за час", "среднее время ответа, сек", "реакция. среднее, сек", "Без ответа", "Потери", "На линии, мин", "Перерыв, мин", "Простой, среднее, сек");
        $operators = pg_exec('select opr_password, opr_name from public.operators op INNER JOIN public.agents_logs al ON (al.agent=op.opr_id) WHERE 1=1 '.$where.' GROUP BY op.opr_password, op.opr_name ORDER BY op.opr_name ASC');
        $i=0;
	while($t = pg_fetch_array($operators)){
	$ij=0;
	do {
	    $now_date = date("Y-m-d", strtotime("$date + $ij day"));
	    $ij++;
	    $next_date = date("Y-m-d", strtotime("$date + $ij day"));
		$i++;
		$opr_password = $t['opr_password'];
		list($recived, $totaltime, $answertime, $reaction, $noanswer, $lost, $timeonline, $timeoffline, $local_count, $local_timer, $hangup) = op_info($t['opr_password'], $now_date, '07:00:00', $next_date, '06:59:59', $service, $call_type);
		//if($timeonline!=0)
		{
		    echo "<tr>
		    <td>$i</td>
		    <td>".$t['opr_password']."</td>
		    <td><nobr>".$t['opr_name']."</nobr></td>
		    <td><nobr>$now_date</nobr></td>
		    <td>$recived</td>
		    <td>$totaltime</td>
		    <td>";
		    echo ($timeonline)?round($recived/($timeonline/60)):0;
		    echo "</td>
		    <td>$answertime</td>
		    <td>$reaction</td>
		    <td>$noanswer</td>
		    <td>$lost</td>
		    <td>$hangup</td>";
		    if($recived!=0) echo"<td>".round($hangup/$recived*100)."%</td>";
		    else echo "<td>0%</td>";
		    echo"<td>$local_count</td>
		    <td>$local_timer</td>
		    <td>$timeonline</td>
		    <td>$timeoffline</td>
		    <td>".round((($timeonline-$totaltime)*60-5*$recived)/($recived+1))."</td></tr>
		    ";
		    $rto = ($timeonline)?round($recived/($timeonline/60)):0;
		    $_SESSION['xls_table'][] = array($i,$t['opr_password'], $t['opr_name'], $now_date, $recived, $totaltime, $rto, $answertime, $reaction, $noanswer, $lost, $timeonline, $timeoffline, round((($timeonline-$totaltime)*60-5*$recived)/($recived+1)));
		}
	} while ($now_date<$datet);
    }
    echo "</table>";

    if(pg_num_rows($operators)==1) {
	$ij=0;
	do {
	    $now_date = date("Y-m-d", strtotime("$date + $ij day"));
	    $ij++;
	    $next_date = date("Y-m-d", strtotime("$date + $ij day"));
	    $logs_new = pg_exec('select * from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) 
				LEFT JOIN public.records r ON (al.record_id=r.record_id) 
				WHERE (op.opr_password=\''.$opr_password.'\') ANd (al.event=21 OR al.event=22) AND al.dt BETWEEN \''.$now_date.' 06:45:00\' AND \''.$next_date.' 07:14:59\' order by date_trunc(\'second\', al.Dt_begin) Desc, al.event Asc LIMIT 100');
	    if(pg_num_rows($logs_new)) {
		echo '<h3>вход-выход '.$now_date.'</h3>';
		$_SESSION['xls_table2'] = "";
//	    	echo '<a href="?xls=1&type=2"><img border=0 src="http://stat.isystems.com.ua/img/admin/xls.gif"> Экспорт в Excel</a>';
		show_table($logs_new, array(1,1), 2);
	    }
	} while ($now_date<$datet);
    }

  } elseif(empty($number) && $random!='on') {
    echo '<h3>События операторов</h3> <a href="?xls=1"><img border=0 src="http://stat.isystems.com.ua/img/admin/xls.gif"> Экспорт в Excel</a>';
    echo "<table border=1><tr>
	<td></td>
	<td>Пароль</td>
	<td>ФИО</td>
	<td><small>Принятые</small></td>
	<td><small>эфир, мин</small></td>
	<td><small>среднее t ответа, сек</small></td>
	<td><small>реакция. среднее, сек</small></td>
	<td><small>Без ответа</small></td>
	<td><small>Потери</small></td>
	<td><small>Hangup</small></td>
	<td><small>Hangup от принятых</small></td>
	<td><small>Локальных</small></td>
	<td><small>Локальных, мин</small></td>
	<td><small>На линии, мин</small></td>
	<td><small>Перерыв, мин</small></td>
	<td><small>Простой, среднее, сек</small></td></tr>
	";
    $_SESSION['xls_table'][] = array("","Пароль", "ФИО", "Принятые", "эфир, мин", "среднее время ответа, сек", "реакция. среднее, сек", "Без ответа", "Потери", "На линии, мин", "Перерыв, мин", "Простой, среднее, сек");
    $operators = pg_exec('select opr_password, opr_name from public.operators op INNER JOIN public.agents_logs al ON (al.agent=op.opr_id) WHERE 1=1 '.$where.' GROUP BY op.opr_password, op.opr_name ORDER BY op.opr_name ASC');
    $i=0;
    while($t = pg_fetch_array($operators)){
      list($recived, $totaltime, $answertime, $reaction, $noanswer, $lost, $timeonline, $timeoffline, $local_count, $local_timer, $hangup) = op_info($t['opr_password'], $date, $time, $datet, $timet, $service, $call_type);
      if($totaltime) {
	$i++;
	echo "<tr>
	<td>$i</td>
	<td>".$t['opr_password']."</td>
	<td><nobr>".$t['opr_name']."</nobr></td>
	<td>$recived</td>
	<td>$totaltime</td>
	<td>$answertime</td>
	<td>$reaction</td>
	<td>$noanswer</td>
	<td>$lost</td>
	<td>$hangup</td>";
	if($recived!=0) echo"<td>".round($hangup/$recived*100)."%</td>";
	else echo "<td>0%</td>";
	echo"<td>$local_count</td>
	<td>$local_timer</td>
	<td>$timeonline</td>
	<td>$timeoffline</td>
	<td>".round((($timeonline-$totaltime)*60-5*$recived)/($recived+1))."</td></tr>
	";
	$_SESSION['xls_table'][] = array($i,$t['opr_password'], $t['opr_name'], $recived, $totaltime, $answertime, $reaction, $noanswer, $lost, $timeonline, $timeoffline, round((($timeonline-$totaltime)*60-(5*$recived))/($recived+1)));
      }
    }

    echo "</table>";
  }

//  if((empty($search) || $search!='all' || !empty($number) || !empty($service))) {
//  if((empty($search) || $search!='all' || !empty($number))) {
if(!$more_than_day || $random=='on' || !empty($number))
  if( empty($search) || $search!='all' || $random=='on' || !empty($number) ) {
    if(!empty($service)) $where.="AND (al.acdgroup = '$service')";
    if(!empty($number)) $where.="AND (al.callid = '$number')";
    if( $call_type ) {
	$where.= ($call_type=='in')? " AND (al.event=10)" : " AND (al.event=31)";
    }
    $limit = "";
    $order_by = "ORDER BY al.Dt_begin DESC, al.Dt Desc";
    if($random=="on"){
	if(is_numeric($random_count)) $limit = "LIMIT $random_count";
	$order_by = "ORDER BY RANDOM()";
    }
    $logs_new = pg_exec('select * from public.agents_logs al JOIN public.operators op ON (al.agent=op.opr_id) 
			LEFT JOIN public.records r ON (al.record_id=r.record_id) 
			WHERE (al.event=10 OR al.event=52 OR al.event=53 OR al.event=31 OR al.event=32) '.$where.' '.$order_by.' '.$limit);
    echo '<h3>принятые</h3>';
    $_SESSION['xls_table'] = "";
    echo '<a href="?xls=1"><img border=0 src="http://stat.isystems.com.ua/img/admin/xls.gif"> Экспорт в Excel</a>';
    if(!empty($number) || $search=='all') {
	show_table($logs_new, array(0,0,1));
    } else {
	show_table($logs_new);
    }
  }

}

include_once("db_disconnect.php");

echo "</td></tr></table>";

}

}
?>