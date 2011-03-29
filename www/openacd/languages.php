<?php
    include_once("db_connect.php");


    if($_POST["edid"]==-1){
	pg_exec("INSERT INTO public.languages (lng_id, lng_name, lng_name_short) VALUES (nextval('languages_lng_id_seq'), '".$_POST["name"]."', '".$_POST["name_short"]."')");
	header("Location: languages.php");
    } elseif (is_numeric($_POST["edid"])){
	pg_exec("UPDATE public.languages SET lng_name='".$_POST["name"]."', lng_name_short='".$_POST["name_short"]."' WHERE lng_id='".$_POST["edid"]."'");
	header("Location: languages.php");
    }
    if(is_numeric($_GET["delid"])){
	pg_exec("DELETE FROM public.languages WHERE lng_id = '".$_GET["delid"]."'");
	header("Location: languages.php");
    }
    if(is_numeric($_GET["editid"])){
	$to_edit = pg_exec("SELECT * FROM public.languages WHERE lng_id = '".$_GET["editid"]."'");
	$edit = pg_fetch_array($to_edit);
    }

    include_once("include.php");
if($_SESSION['logged']=='admin') {

    include_once("menu.php");
?>
<h2>Языки</h2>
<form method="post">
    Название: <input type="text" size="64" maxlength="64" value="<?=$edit['lng_name']?>" name="name"><br />
    Сокращенное название: <input type="text" size="4" maxlength="4" value="<?=$edit['lng_name_short']?>" name="name_short"><br />
    
    <input type="hidden" value="<?=(isset($edit['lng_id']))?$edit['lng_id']:-1?>" name="edid">
    <input type="submit" value="Добавить" name="submit"><br />
</form>

<?php
    $new = pg_exec('select * from public.languages order by lng_id ASC');
?>

<table>

<?php    
    while($t = pg_fetch_array($new)){
        echo '<tr>';
//	echo '<td><a href=?delid='.$t[0].'>delete</a></td>';
	echo '<td><a href=?editid='.$t[0].'>edit</a></td>';
	echo '<td>'.$t['lng_id'].'</td>';
	echo '<td>'.$t['lng_name'].'</td>';
	echo '<td>'.$t['lng_name_short'].'</td>';
        echo '</td>';
    }
?>

</table>

<?php    
}
    include_once("db_disconnect.php");
?>