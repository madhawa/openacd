<?php
session_start();
if($_SESSION['logged']=='admin') {
    include_once("db_connect.php");
    if($_POST["edid"]==-1){
	pg_exec("INSERT INTO public.destination (dst_id, dst_name, dst_ip) VALUES (nextval('destination_dst_id_seq'), '".$_POST["name"]."', '".$_POST["ip"]."')");
	header("Location: destination.php");
    } elseif (is_numeric($_POST["edid"])){
	pg_exec("UPDATE public.destination SET dst_name='".$_POST["name"]."', dst_ip='".$_POST["ip"]."' WHERE dst_id='".$_POST["edid"]."'");
	header("Location: destination.php");
    }
    if(is_numeric($_GET["delid"])){
	pg_exec("DELETE FROM public.destination WHERE dst_id = '".$_GET["delid"]."'");
	header("Location: destination.php");
    }
    if(is_numeric($_GET["editid"])){
	$to_edit = pg_exec("SELECT * FROM public.destination WHERE dst_id = '".$_GET["editid"]."'");
	$edit = pg_fetch_array($to_edit);
    }

    include_once("include.php");
    include_once("menu.php");
} else {
    header("Location: login.php");
}
?>
<h2>Где находится SIP телефон</h2>
<form method="post">
    SIP: <input type="text" size="15" maxlength="32" value="<?=$edit['dst_name']?>" name="name"><br />
    IP: <input type="text" size="15" maxlength="15" value="<?=$edit['dst_ip']?>" name="ip"><br />
    
    <input type="hidden" value="<?=(isset($edit['dst_id']))?$edit['dst_id']:-1?>" name="edid">
    <input type="submit" value="Добавить" name="submit"><br />
</form>

<?php
    $new = pg_exec('select * from public.destination');
?>

<table>

<?php    
    while($t = pg_fetch_array($new)){
        echo '<tr>';
//	echo '<td><a href=?delid='.$t[0].'>delete</a></td>';
	echo '<td><a href=?editid='.$t[0].'>edit</a></td>';
	echo '<td>'.$t['dst_id'].'</td>';
	echo '<td>'.$t['dst_name'].'</td>';
	echo '<td>'.$t['dst_ip'].'</td>';
        echo '</td>';
    }
?>

</table>

<?php    
    include_once("db_disconnect.php");
?>