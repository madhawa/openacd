<?php 

session_start();
if($_SESSION['logged']=='admin') {

    include_once("db_connect.php");

    if(!empty($_POST["access"])){
	$access = $_POST["access"];
	pg_exec("DELETE FROM public.operators_services");
	foreach ($access as $key_op=>$acc_op){
	    foreach ($acc_op as $key_qu=>$acc_value){
		if(!empty($acc_value)) pg_exec("INSERT INTO public.operators_services (ops_id, srv_id, opr_id, ops_value) VALUES (nextval('operators_services_ops_id_seq'), $key_qu, $key_op, $acc_value)");
	    }
	}
	header("Location: access.php");
    }

    include_once("include.php");
    include_once("menu.php");

} else {
    header("Location: login.php");
}

?>
<h2>Доступ к службам</h2>
<?if($_SESSION['logged']!='monitor'):?>
<form method="post">
<?endif;?>
<?php
    $services_sql = pg_exec('select * from public.services ORDER BY srv_order DESC');
    while($t = pg_fetch_array($services_sql)){
	$services[$t['srv_id']] = $t['srv_name'];
    }
    $operators_sql = pg_exec('select * from public.operators WHERE opr_date_end>NOW() OR opr_date_end is NULL order by opr_name');
    while($t = pg_fetch_array($operators_sql)){
	$operators[$t['opr_id']] = $t['opr_name'];
	$passwords[$t['opr_id']] = $t['opr_password'];
    }
    $access_sql = pg_exec('select * from public.operators_services');
    while($t = pg_fetch_array($access_sql)){
	$access[$t['opr_id']][$t['srv_id']] = $t['ops_value'];
    }
?>

<table>

<?php
    $j=0;
    echo "</tr>";
    foreach($operators as $key_op=>$operator){
	if($j==0) {
	    $j=15;
	    echo "<tr><td></td><td></td>";
	    foreach($services as $key=>$queue){
		echo "<td><b>$queue</b></td>";
	    }
	}
	$j--;
	echo "<tr><td><b>".$passwords[$key_op]."</b></td><td>$operator</td>";
	foreach($services as $key=>$queue){
	    if($_SESSION['logged']!='monitor'){
		echo "<td><input value='".$access[$key_op][$key]."' size='3' maxlength='3' name='access[$key_op][$key]'></td>";
	    } else {
		echo "<td align=center>&nbsp;&nbsp;".$access[$key_op][$key]."&nbsp;&nbsp;</td>";
	    }
//	    echo "<td>".$access[$key_op][$key]."</td>";
	}
	echo "</tr>";
    }
?>

</table>
<?if($_SESSION['logged']!='monitor'):?>
<input type="submit" value="submit" name="submit"><br />
<?endif;?>
</form>

<?php    
    include_once("db_disconnect.php");
?>