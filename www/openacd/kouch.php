<?php
    include_once("db_connect.php");


    if($_POST["edid"]==-1){
	pg_exec("INSERT INTO public.kouch (kch_id, kch_name) VALUES (nextval('kouch_kch_id_seq'), '".$_POST["name"]."')");
	header("Location: kouch.php");
    } elseif (is_numeric($_POST["edid"])){
	pg_exec("UPDATE public.kouch SET kch_name='".$_POST["name"]."' WHERE kch_id='".$_POST["edid"]."'");
	header("Location: kouch.php");
    }
    if(is_numeric($_GET["delid"])){
	pg_exec("DELETE FROM public.kouch WHERE kch_id = '".$_GET["delid"]."'");
	header("Location: kouch.php");
    }
    if(is_numeric($_GET["editid"])){
	$to_edit = pg_exec("SELECT * FROM public.kouch WHERE kch_id = '".$_GET["editid"]."'");
	$edit = pg_fetch_array($to_edit);
    }

    include_once("include.php");
if($_SESSION['logged']=='admin') {

    include_once("menu.php");
?>
<h2>Коучи</h2>
<?if($_SESSION['logged']!='monitor'):?>
<form method="post">
    Фамилия Имя: <input type="text" size="64" maxlength="64" value="<?=$edit['kch_name']?>" name="name"><br />
    
    <input type="hidden" value="<?=(isset($edit['kch_id']))?$edit['kch_id']:-1?>" name="edid">
    <input type="submit" value="Добавить" name="submit"><br />
</form>
<?endif;?>
<?php
    $new = pg_exec('select * from public.kouch ORDER BY kch_name ASC');
?>

<table>
<tr>
<?if($_SESSION['logged']!='monitor'):?><td></td><td></td><?endif;?>
<td>Фамилия Имя</td>
</tr>
<?php    
    while($t = pg_fetch_array($new)){
        echo '<tr>';
if($_SESSION['logged']!='monitor'){
	echo '<td><a href=?delid='.$t[0].'>delete</a></td>';
	echo '<td><a href=?editid='.$t[0].'>edit</a></td>';
}
//	echo '<td>'.$t['kch_id'].' </td>';
	echo '<td> '.$t['kch_name'].'</td>';
        echo '</tr>';
    }
?>

</table>

<?php    
}
    include_once("db_disconnect.php");
?>