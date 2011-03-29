<?php
    include_once("db_connect.php");


    if($_POST["edid"]==-1){
	pg_exec("INSERT INTO public.services (srv_id, srv_name, srv_weight, srv_message, srv_order, srv_access_type ) VALUES (nextval('services_srv_id_seq'), '".$_POST["name"]."', '".$_POST["weight"]."', '".$_POST["message"]."', ".$_POST["order"].", ".$_POST["access_type"].")");
	header("Location: services.php");
    } elseif (is_numeric($_POST["edid"])){
	pg_exec("UPDATE public.services SET srv_name='".$_POST["name"]."', srv_weight='".$_POST["weight"]."', srv_order='".$_POST["order"]."', srv_access_type='".$_POST["access_type"]."', srv_message='".$_POST["message"]."' WHERE srv_id='".$_POST["edid"]."'");
	header("Location: services.php");
    }
    if(is_numeric($_GET["delid"])){
	pg_exec("DELETE FROM public.services WHERE srv_id = '".$_GET["delid"]."'");
	header("Location: services.php");
    }
    if(is_numeric($_GET["editid"])){
	$to_edit = pg_exec("SELECT * FROM public.services WHERE srv_id = '".$_GET["editid"]."'");
	$edit = pg_fetch_array($to_edit);
    }

    include_once("include.php");
if($_SESSION['logged']=='admin') {
    include_once("menu.php");
?>
<h2>Службы</h2>
<?if($_SESSION['logged']!='monitor'):?>
<form method="post">
    Группа: <input type="text" size="12" maxlength="12" value="<?=$edit['srv_name']?>" name="name">
    Вес: <input type="text" size="3" maxlength="3" value="<?=$edit['srv_weight']?>" name="weight">
    Порядок следования: <input type="text" size="3" maxlength="3" value="<?=$edit['srv_order']?>" name="order"><br />
    Порядок опроса серверов: <select name="access_type">
	<option <?=($edit['srv_access_type']==0)?'selected':''?> value="0">локальный-удаленный</option>
	<option <?=($edit['srv_access_type']==1)?'selected':''?> value="1">только локальный</option>
	<option <?=($edit['srv_access_type']==2)?'selected':''?> value="2">удаленный-локальный</option>
<!--	<option <?=($edit['srv_access_type']==3)?'selected':''?> value="3">только удаленный</option>-->
    </select>
    <br />
    Сообщение: <input type="text" size="100" value="<?=$edit['srv_message']?>" name="message"><br />
    <input type="hidden" value="<?=(isset($edit['srv_id']))?$edit['srv_id']:-1?>" name="edid">
    <input type="submit" value="Добавить" name="submit"><br />
</form>
<?endif;?>

<?php
    $new = pg_exec('select * from public.services order by srv_order DESC');
?>

<table>

<?php    
    while($t = pg_fetch_array($new)){
        echo '<tr>';
if($_SESSION['logged']!='monitor'){
//	echo '<td><a href=?delid='.$t[0].'>delete</a></td>';
	echo '<td><a href=?editid='.$t[0].'>edit</a></td>';
	echo '<td>'.$t['srv_id'].'&nbsp;&nbsp;</td>';
	echo '<td>';
	switch ($t['srv_access_type']) {
	    case 0: echo "л-у"; break;
	    case 1: echo "л"; break;
	    case 2: echo "у-л"; break;
	    case 3: echo "у"; break;
	}
	echo '&nbsp;&nbsp;</td>';
}
	echo '<td>'.$t['srv_name'].'&nbsp;&nbsp;</td>';
	echo '<td>'.$t['srv_weight'].'&nbsp;&nbsp;</td>';
	echo '<td>'.$t['srv_message'].'</td>';
        echo '</td>';
    }
?>

</table>

<?php    
}
    include_once("db_disconnect.php");
?>