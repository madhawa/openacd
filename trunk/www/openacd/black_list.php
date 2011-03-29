<?php
    include_once("db_connect.php");

    if($_POST["edid"]==-1 && $_POST["number"]!=''){
	pg_exec("INSERT INTO public.black_list (bll_date, bll_number, bll_text, bll_service) VALUES (NOW(), '".$_POST["number"]."', '".$_POST["text"]."', '".$_POST["service"]."')");
	header("Location: black_list.php");
    } elseif (is_numeric($_POST["edid"])){
	pg_exec("UPDATE public.black_list SET bll_service='".$_POST["service"]."', bll_number='".$_POST["number"]."', bll_text='".$_POST["text"]."' WHERE bll_id='".$_POST["edid"]."'");
	header("Location: black_list.php");
    }

    if(is_numeric($_GET["delid"])){
	pg_exec("DELETE FROM public.black_list WHERE bll_id = '".$_GET["delid"]."'");
	header("Location: black_list.php");
    }
    if(is_numeric($_GET["editid"])){
	$to_edit = pg_exec("SELECT * FROM public.black_list WHERE bll_id = '".$_GET["editid"]."'");
	$edit = pg_fetch_array($to_edit);
    }

    include_once("include.php");
if($_SESSION['logged']=='admin') {

    include_once("menu.php");
?>
<h2>Черный список</h2>

<?if($_SESSION['logged']!='monitor'):?>
<form method="post">
    Номер: <input type="text" name="number" value="<?=$edit['bll_number']?>"><br />
    Сервис: <input type="text" name="service" value="<?=$edit['bll_service']?>"><br />
    Причина:<br>
    <textarea cols=70 rows=4 name="text"><?=$edit['bll_text']?></textarea><br>
    
    <input type="hidden" value="<?=(isset($edit['bll_id']))?$edit['bll_id']:-1?>" name="edid">
    <input type="submit" value="Добавить в черный список" name="submit"><br />
</form>
<?endif;?>
<?php
    $new = pg_exec('select * from public.black_list order by bll_date DESC');
?>

<table>

<?php    
    while($t = pg_fetch_array($new)){
        echo '<tr>';
	if($_SESSION['logged']=='admin') {
	    echo '<td><a href=?editid='.$t[0].'>edit</a></td>';
	    echo '<td><a href=?delid='.$t[0].'>del</a></td>';
	}
	echo '<td>'.substr($t['bll_date'],0,10).'</td>';
	echo '<td>-'.$t['bll_service'].'-</td>';
	echo '<td><b>'.$t['bll_number'].'</b></td>';
	echo '<td>('.$t['bll_count'].')</td>';
	echo '<td>'.$t['bll_text'].'</td>';
        echo '</td>';
    }
?>

</table>

<?php    
}
    include_once("db_disconnect.php");
?>