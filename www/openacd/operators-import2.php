<?php
    include_once("db_connect.php");

    if($_FILES['file']['size']>0){
	pg_exec("DELETE FROM public.operators_services");
	pg_exec("DELETE FROM public.operators");
	$content = file($_FILES['file']['tmp_name']);
	foreach ($content as $line) {
	    preg_match_all("|(.*);[\"]?(.*?)[\"]?;[\"]?(.*?)[\"]?;[\"]?(.*?)[\"]?;(.*)\n|", $line, $out, PREG_PATTERN_ORDER);
	    $res1 = pg_exec("INSERT INTO public.operators (opr_id, opr_name, opr_password, opr_city) VALUES (nextval('operators_opr_id_seq'), '".$out[2][0]."', '".$out[5][0]."', '1') RETURNING opr_id");
	    $id_op = pg_fetch_array($res1);
	    $id_op = $id_op['opr_id'];
	    if(trim($out[3][0])!="все службы") {
		preg_match_all("|(\d*)|", $out[3][0], $services, PREG_PATTERN_ORDER);
		foreach($services[0] as $service){
		    if(is_numeric($service)){
			$services_sql = pg_exec("select * from public.services WHERE srv_name='$service'");
			while($t = pg_fetch_array($services_sql)){
			    pg_exec("INSERT INTO public.operators_services (ops_id, srv_id, opr_id, ops_value) VALUES (nextval('services_srv_id_seq'), ".$t['srv_id'].", $id_op, 100)");
			}
		    }
		}
	    } else {
		$services_sql = pg_exec('select * from public.services');
		while($t = pg_fetch_array($services_sql)){
		    pg_exec("INSERT INTO public.operators_services (ops_id, srv_id, opr_id, ops_value) VALUES (nextval('services_srv_id_seq'), ".$t['srv_id'].", $id_op, 50)");
		}
	    }
	}
    }
    
    if($_POST["edid"]==-1){
	pg_exec("INSERT INTO public.operators (opr_id, opr_name, opr_password, opr_city) VALUES (nextval('operators_opr_id_seq'), '".$_POST["name"]."', '".$_POST["password"]."', '".$_POST["city"]."')");
	header("Location: /openacd/operators.php");
    } elseif (is_numeric($_POST["edid"])){
	pg_exec("UPDATE public.operators SET opr_name='".$_POST["name"]."', opr_password='".$_POST["password"]."', opr_city='".$_POST["city"]."' WHERE opr_id='".$_POST["edid"]."'");
	header("Location: /openacd/operators.php");
    }
    if(is_numeric($_GET["delid"])){
	pg_exec("DELETE FROM public.operators WHERE opr_id = '".$_GET["delid"]."'");
	header("Location: /openacd/operators.php");
    }
    if(is_numeric($_GET["editid"])){
	$to_edit = pg_exec("SELECT * FROM public.operators WHERE opr_id = '".$_GET["editid"]."'");
	$edit = pg_fetch_array($to_edit);
    }

    include_once("include.php");
    include_once("menu.php");
?>
<h2>Operators</h2>
<form method="post" enctype="multipart/form-data">
    CSV-file: <input type="file" name="file"><br />
    <br />
    
    <input type="submit" value="submit" name="submit"><br />
</form>

<?php
    $new = pg_exec('select * from public.operators');
?>

<table>

<?php    
    while($t = pg_fetch_array($new)){
        echo '<tr>';
	echo '<td><a href=?delid='.$t[0].'>delete</a></td>';
	echo '<td><a href=?editid='.$t[0].'>edit</a></td>';
	echo '<td>'.$t['opr_id'].'</td>';
	echo '<td>'.$t['opr_name'].'</td>';
	echo '<td>'.$t['opr_password'].'</td>';
	echo '<td>'.$t['opr_city'].'</td>';
        echo '</td>';
    }
?>

</table>

<?php    
    include_once("db_disconnect.php");
?>