<?php
$file = 'online_check.html';
#$file2 = 'online_check_2.html';

if(!file_exists($file) || (filemtime($file))<time()) {

    touch($file,time()+2);
    ob_start();

include_once("db_connect.php");

//    $new = pg_exec('select * from public.operators_login ol LEFT JOIN public.operators op ON (ol.opr_id=op.opr_id) ORDER BY op.opr_password');
    $new = pg_exec('SELECT op.opr_id, SUM(os.ops_value) as val, MIN(opl_status) as opl_status, MIN(opr_password) as opr_password, 
			MIN(opl_destination) as opl_destination, MIN(opr_name) as opr_name, MIN(opl_time) as opl_time, 
			MIN(ol.opl_number) as opl_number, MIN(ol.srv_id) as srv_id
		    FROM public.operators_login ol  
                    LEFT JOIN public.operators op ON (ol.opr_id=op.opr_id)  
                    LEFT JOIN public.operators_services os ON (os.opr_id=op.opr_id)  
                    GROUP BY op.opr_id 
                    ORDER BY val DESC, opr_password ASC');
    $stat_operators_free = 0;
    while($t = pg_fetch_array($new)){
	$table_operators[$t['opr_id']]['status'] = $t['opl_status'];
	if ($t['opl_status']==1 && (substr($t['opl_time'], 0, 19)<date("Y-m-d H:i:s"))) $stat_operators_free++;
	$table_operators[$t['opr_id']]['password'] = $t['opr_password'];
	$table_operators[$t['opr_id']]['val'] = $t['val'];
	$table_operators[$t['opr_id']]['channel'] = $t['opl_destination'];
	$oname = split (" ",$t['opr_name']);
	$table_operators[$t['opr_id']]['name'] = $oname[0]." ".$oname[1];
	$table_operators[$t['opr_id']]['time'] = $t['opl_time'];
	$table_operators[$t['opr_id']]['number'] = $t['opl_number'];
	$table_operators[$t['opr_id']]['srv_id'] = $t['srv_id'];
    }

    $new = pg_exec('select * from public.operators');
    while($t = pg_fetch_array($new)){
	$table_passwords[$t['opr_id']] = $t['opr_password'];
    }

    $new = pg_exec('select * from public.services ORDER BY srv_order DESC');
    while($t = pg_fetch_array($new)){
	$table_services[$t['srv_id']]['name'] = $t['srv_name'];
	$table_services[$t['srv_id']]['weight'] = $t['srv_weight'];
    }

    $new = pg_exec('select os.srv_id, os.opr_id, os.ops_value from public.operators_services os JOIN public.operators_login op ON (os.opr_id=op.opr_id)');
    while($t = pg_fetch_array($new)){
	$table_access[$t['opr_id']][$t['srv_id']] = $t['ops_value'];
    }

//    $new = pg_exec('select * from public.queues WHERE que_bussy=0 AND que_time_from<NOW()-INTERVAL \'3 seconds\'');
    $stat_operators_queues = 0;
    $new = pg_exec('select * from public.queues WHERE que_bussy=0 order by que_time_from ASC');
    while($t = pg_fetch_array($new)){
	if (substr($t['que_time_from'], 0, 19)<=date("Y-m-d H:i:s")) $stat_operators_queues++;
	$queues[$t['srv_id']]['number'][] = $t['que_number'];
	$queues[$t['srv_id']]['time'][] = $t['que_time_from'];
	$stat_operators_queues_services[$t['srv_id']]++;
    }

    $new = pg_exec('select os.srv_id,COUNT(*) as cnt from public.operators_services os JOIN public.operators_login ol ON (os.opr_id=ol.opr_id) GROUP BY os.srv_id');
    while($t = pg_fetch_array($new)){
	$queues_count_all[$t['srv_id']] = $t['cnt'];
    }

    $new = pg_exec('select os.srv_id,COUNT(*) as cnt from public.operators_services os JOIN public.operators_login ol ON (os.opr_id=ol.opr_id) WHERE ol.opl_status=1 GROUP BY os.srv_id');
    while($t = pg_fetch_array($new)){
	$queues_count_free[$t['srv_id']] = $t['cnt'];
    }

    $logs_new = pg_exec('select * from public.agents_logs WHERE (event!=22 AND event!=21) ORDER BY dt DESC LIMIT 15');
//    $logs_new = pg_exec('select * from public.agents_logs al RIGHT JOIN public.operators op ON(op.opr_id=al.agent) WHERE (event!=22 AND event!=21) ORDER BY dt DESC LIMIT 15');

    $lng_new = pg_exec('select * from public.operators_languages o JOIN public.languages l ON (o.lng_id=l.lng_id)');
    $lng = array();
    while($t2 = pg_fetch_array($lng_new)){
	$lng[$t2['opr_id']][] = $t2['lng_name_short'];
    }


echo "<table><tr><td valign='top'>";

if(is_array($table_operators)){
echo '<h3>Операторы - Киев</h3>';
echo "<table border=1>
	<tr><td>№</td><td></td><td></td><td></td><td></td><td><small>языки</small></td>";
 foreach($table_services as $key=>$t){
    echo "<td>";
    if($t['weight']!=0) echo "<b>";
    echo $t['name']."</b></td>";
 }
 echo "<td><b>номер</b></td>";
 echo "<td><small>время</small></td>";
 echo "</tr>";
 $jj=0;
 foreach($table_operators as $key=>$t){
    $jj++;
    switch ($t['status']){
	case '0' : $color='black'; break;
	case '1' : $color='green'; break;

	case '3' : $color='blue'; break;
	case '4' : $color='red'; break;

	case '9' : $color='olive'; break;
	case '8' : $color='orange'; break;

	case '' : $color='black'; break;
	default : $color='black'; break;
      }
    echo "<tr><td>$jj</td><td style='color:$color'><small>".$t['val']."</small></td><td style='color:$color'><b>".$t['password']."</b></td>";
    echo "<td style='color:$color'><nobr><small>".$t['name']."</small></nobr></td>";
    echo "<td style='color:$color'>".$t['channel']."</td>";
    echo "<td style='color:$color'><small>";
    if (is_array($lng[$key])) echo implode(',',$lng[$key]);
    echo "</small></td>";
    foreach($table_services as $keys=>$ts){
	if(isset($table_access[$key][$keys])){
	    $c = str_pad(dechex(round($table_access[$key][$keys]*1.3+50)),2,"0", STR_PAD_LEFT);
	    if($t['status']==1) {$color2="#00".$c."00";}
	    if($t['status']==4) {$color2="#".$c."0000";}
	    if($t['status']==4 && $table_operators[$key]['srv_id']==$keys) {$color2="#0000".$c;}
	    if($t['status']==9) {$color2="#66".$c."26";}
	    if($t['status']==8) {$color2="#".$c."8040";}
	    echo "<td align=center style='color:$color2'><b>".$t['status'];
	    if($table_operators[$key]['srv_id']==$keys) {
		echo "&#664;";
		$stat_operators_calls_services[$keys]++;
	    }
	    else echo "&#149;";
    	    echo "</b></td>";
    	    $stat_operators_count_services[$keys]++;
    	    if ($t['status']==1 && (substr($t['time'], 0, 19)<date("Y-m-d H:i:s"))) $stat_operators_free_services[$keys]++;
    	} else {
    	    echo "<td></td>";
    	}
    }
    echo "<td>";
    if($t['status']==9) {echo "<b>&uarr;</b>";};
    if($t['status']==4 || $t['status']==8) {echo "<b>&darr;</b>";}
    echo "<small>".$t['number']."</small></td>";
    echo "<td style='color:$color'>".(time()-strtotime($t['time']))."</td></tr>";
 }

echo "<tr><td></td><td></td><td></td><td></td><td></td><td></td>";
 foreach($table_services as $key=>$t){
    echo "<td>";
    if($t['weight']!=0) echo "<b>";
    echo $t['name']."</b></td>";
 }
 echo "<td></td><td></td>";
 echo "</tr>";

echo "</table>";
}

echo '<br><font color=green><b>&#149; свободный</b></font> ';
echo '<font color=red><b>&#149; входящий</b></font> ';
echo '<font color=olive><b>&#149; исходящий</b></font> ';
echo '<font color=orange><b>&#149; локальный in</b></font> ';
echo '<font color=black><b>&#149;</b> выход</font>';


echo "</td><td width='40' valign='top'>";


echo "</td><td width='40' valign='top'>";
echo "</td><td valign='top'>";

echo '<h3>Очередь<br>Киев</h3>';
echo "<table>";

 foreach($table_services as $key=>$t){
    echo "<tr><td><b>".$t['name']."</b><br>";

    	if($queues_count_all[$key]==0) {
    	    $percent_line = 0;
    	} else {
    	    $percent_line = ($queues_count_free[$key]/$queues_count_all[$key])*100;
    	}

	echo '
	<table height="10" width="120"><tr>
	    <td bgcolor="red" width="'.(100-$percent_line).'">
	    </td>
	    <td bgcolor="green" width="'.$percent_line.'">
	    </td>
	    <td width="25">
	    <font style="font-size:8px;">'.round(100-$percent_line).'%</font>
	    </td>
	</tr></table>';

    if(is_array($queues[$key]['number'])){
    foreach ($queues[$key]['number'] as $kq=>$num) {
	echo "&nbsp;&#149;$num(".(time()-strtotime($queues[$key]['time'][$kq])).")<br>";
    }
    }
    echo "</td></tr>";
 }

echo "</table>";


echo "</td><td width='40' valign='top'>";
echo "</td><td valign='top'>";

echo '<h3>Звонки - Киев</h3>';
echo "<table border=1>";
    while($t = pg_fetch_array($logs_new)){
    	if( $t['event']==53 || $t['event']==36 ) echo '<tr style="background:#FF9090">';
    	elseif($t['event']==52) echo '<tr style="background:#9090FF">';
    	elseif($t['event']==31 || $t['event']==32) echo '<tr style="background:#FFFF00">';
    	else echo '<tr>';
	echo '<td><b>';
	if( $t['event']==31 || $t['event']==36 ) {echo "&uarr;";} else {echo "&darr;";}
	echo $t['callid'].'</b></td>';
	echo '<td>'.$t['acdgroup'].'</td>';
	echo '<td><b>'.$table_passwords[$t['agent']].'</b></td>';
	echo '<td>'.$t['timer'].'</td>';
	echo '<td>'.substr($t['dt_begin'],-8).'</td>';
    	echo '</tr>';
    }
    
echo "</table>";

echo "</table>";

echo "</td></tr></table>";

echo "</td></tr></table> <br>";

include_once("db_disconnect.php");


//if(!$REMOTE_DB) echo "<h1>Потеря связи с Одессой</h1>";

    $content = ob_get_contents();
    $f = fopen($file, 'w');
    fwrite($f, $content);
    fclose($f);
    ob_end_clean();
    ob_end_flush();

}

readfile($file);
#readfile($file2);


?>
