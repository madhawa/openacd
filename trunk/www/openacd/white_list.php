<?php
    include_once("db_connect.php");

    if($_POST["edid"]==-1 && $_POST["number"]!=''){
	foreach (explode("\r\n",$_POST["number"]) as $number) {
	    pg_exec("INSERT INTO public.white_list (wll_date, wll_number, wll_text, wll_service) VALUES (NOW(), '$number', '', '".$_POST["service"]."')");
	}
	header("Location: white_list.php");
    } elseif (is_numeric($_POST["edid"])){
	pg_exec("UPDATE public.white_list SET wll_service='".$_POST["service"]."', wll_number='".$_POST["number"]."', wll_text='".$_POST["text"]."' WHERE wll_id='".$_POST["edid"]."'");
	header("Location: white_list.php");
    }

    if(is_numeric($_GET["delid"])){
	pg_exec("DELETE FROM public.white_list WHERE wll_id = '".$_GET["delid"]."'");
	header("Location: white_list.php");
    }
    if(is_numeric($_GET["editid"])){
	$to_edit = pg_exec("SELECT * FROM public.white_list WHERE wll_id = '".$_GET["editid"]."'");
	$edit = pg_fetch_array($to_edit);
    }

    include_once("include.php");
if($_SESSION['logged']=='admin') {

    include_once("menu.php");
?>
<h2>Белый список</h2>

<?if($_SESSION['logged']!='monitor'):?>
<form method="post">
    Служба: 
    <select name="service">
	<option value="">все</option>
    <?
	$services = pg_exec('SELECT * FROM public.services ORDER BY srv_order DESC');
	while($t = pg_fetch_array($services)){
	    echo "<option ";
	    if($t['srv_name']==$edit['wll_service']) echo "selected ";
	    echo "value=".$t['srv_name'].">".$t['srv_name']."</option>";
	}
    ?>
    </select>
    <br />
<?
    if(is_numeric($_GET["editid"])){
?>
    Номер: <input type="text" name="number" value="<?=$edit['wll_number']?>"><br />
<?} else {?>
    Список телефонов, разделенные переводом строки:<br>
    <textarea cols=70 rows=4 name="number"><?=$edit['wll_text']?></textarea><br>
<?}?>
    
    <input type="hidden" value="<?=(isset($edit['wll_id']))?$edit['wll_id']:-1?>" name="edid">
    <input type="submit" value="Добавить в Белый список" name="submit"><br />
</form>
<?endif;?>
<?php
    $new = pg_exec('select * from public.white_list order by wll_date DESC');
?>

<table>

<?php    
    while($t = pg_fetch_array($new)){
        echo '<tr>';
	if($_SESSION['logged']=='admin') {
	    echo '<td><a href=?editid='.$t[0].'>edit</a></td>';
	    echo '<td><a href=?delid='.$t[0].'>del</a></td>';
	}
	echo '<td>'.substr($t['wll_date'],0,10).'</td>';
	echo '<td>-'.$t['wll_service'].'-</td>';
	echo '<td><b>'.$t['wll_number'].'</b></td>';
	echo '<td>('.$t['wll_count'].')</td>';
	echo '<td>'.$t['wll_text'].'</td>';
        echo '</td>';
    }
?>

</table>

<?php    
}
    include_once("db_disconnect.php");
?>