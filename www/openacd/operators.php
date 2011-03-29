<?php
session_start();
if($_SESSION['logged']=='admin') {

    include_once("db_connect.php");

    if($_POST["edid"]==-1){
	if(empty($_POST["date_begin"])) $_POST["date_begin"]='NULL'; else $_POST["date_begin"] = "'".$_POST["date_begin"]."'";
	if(empty($_POST["date_end"])) $_POST["date_end"]='NULL'; else $_POST["date_end"] = "'".$_POST["date_end"]."'";
	if($_POST["outgoing_calls"]!=1) $_POST["outgoing_calls"]=0;
	pg_exec("INSERT INTO public.operators (opr_id, opr_name, opr_city, opr_password, opr_date_begin, opr_date_end, opr_graid, kch_id, opr_outgoing_call) 
		    VALUES (nextval('operators_opr_id_seq'), '".$_POST["name"]."', 1, '".$_POST["password"]."', ".$_POST["date_begin"].", ".
						$_POST["date_end"].", '".$_POST["graid"]."', '".$_POST["kouch"]."',".$_POST["outgoing_calls"].")");
	$new_id = pg_exec("SELECT opr_id FROM public.operators WHERE opr_name='".$_POST["name"]."' AND opr_password='".$_POST["password"]."'");
	$id = pg_fetch_array($new_id);
	if(is_array($_POST['lang'])) 
	  foreach($_POST['lang'] as $t){
	    pg_exec("INSERT INTO public.operators_languages (opl_id, opr_id, lng_id) VALUES (nextval('operators_languages_opl_id_seq'), ".$id['opr_id'].", $t)");
	  }
	header("Location: operators.php");
    } elseif (is_numeric($_POST["edid"])){
	if(empty($_POST["date_begin"])) $_POST["date_begin"]='NULL'; else $_POST["date_begin"] = "'".$_POST["date_begin"]."'";
	if(empty($_POST["date_end"])) $_POST["date_end"]='NULL'; else $_POST["date_end"] = "'".$_POST["date_end"]."'";
	if(empty($_POST["graid"])) $_POST["graid"]=0;
	if($_POST["outgoing_calls"]!=1) $_POST["outgoing_calls"]=0;
	pg_exec("UPDATE public.operators SET opr_name='".$_POST["name"]."', 
			    opr_password='".$_POST["password"]."', 
			    kch_id=".$_POST["kouch"].", 
			    opr_city = 1,
			    opr_date_begin=".$_POST["date_begin"].", 
			    opr_date_end=".$_POST["date_end"].",
			    opr_outgoing_call=".$_POST["outgoing_calls"].", 
			    opr_graid='".$_POST["graid"]."' WHERE opr_id='".$_POST["edid"]."'");
	pg_exec("DELETE FROM public.operators_languages WHERE opr_id='".$_POST["edid"]."'");
	if(is_array($_POST['lang'])) 
	  foreach($_POST['lang'] as $t){
	    pg_exec("INSERT INTO public.operators_languages (opl_id, opr_id, lng_id) VALUES (nextval('operators_languages_opl_id_seq'), '".$_POST["edid"]."', $t)");
	  }
	header("Location: operators.php");
    }
    if(is_numeric($_GET["delid"])){
	pg_exec("DELETE FROM public.operators WHERE opr_id = '".$_GET["delid"]."'");
	header("Location: operators.php");
    }
    if(is_numeric($_GET["editid"])){
	$to_edit = pg_exec("SELECT * FROM public.operators WHERE opr_id = '".$_GET["editid"]."'");
	$edit = pg_fetch_array($to_edit);
	$new2 = pg_exec("select * from public.operators_languages o JOIN public.languages l ON (o.lng_id=l.lng_id) WHERE o.opr_id = '".$_GET["editid"]."'");
	$lng2 = array();
	while($t2 = pg_fetch_array($new2)){
	    $lng2[$t2['lng_id']] = 1;
	}
    }

    $lang = pg_exec('select * from public.languages order by lng_id ASC');

    include_once("include.php");

    include_once("menu.php");

} else {
    header("Location: login.php");
}

?>
<h2>Операторы</h2>
<?if($_SESSION['logged']!='monitor'):?>
<?/*<a href="operators-import.php">clear and import</a>*/?>
<form method="post">
    Фамилия Имя: <input type="text" size="64" maxlength="64" value="<?=$edit['opr_name']?>" name="name"><br />
    Пароль: <input type="text" size="5" maxlength="5" value="<?=$edit['opr_password']?>" name="password"> 
    Грейд: <input type="text" size="2" maxlength="2" value="<?=$edit['opr_graid']?>" name="graid">
    Исходящие звонки: <input type="checkbox" size="10" value="1" name="outgoing_calls" <?if($edit['opr_outgoing_call']) echo "checked"?>>
<br />
    Дата начала работы: <input type="text" size="10" maxlength="10" value="<?=$edit['opr_date_begin']?>" name="date_begin">
    Дата увольнения: <input type="text" size="10" maxlength="10" value="<?=$edit['opr_date_end']?>" name="date_end"><br />
    Языки:
<?
    while($t = pg_fetch_array($lang)){
	echo '<input id="'.$t['lng_name'].'" type="checkbox" name="lang[]"';
	if (isset($lng2[$t['lng_id']])) echo ' checked';
	echo ' value="'.$t['lng_id'].'"><label for="'.$t['lng_name'].'">'.$t['lng_name'].'</label> &nbsp;';
    }
?><br />
    Коуч: 
    <select name="kouch">
	<option value=0>...</option>
<?
    $kouchdb = pg_exec('select * from public.kouch ORDER BY kch_name ASC');
    $kouch = array();
    while($t3 = pg_fetch_array($kouchdb)){
	echo "<option value=".$t3['kch_id'];
	if($edit['kch_id']==$t3['kch_id']) echo " selected";
	echo ">".$t3['kch_name']."</option>";
	$kouch[$t3['kch_id']] = $t3['kch_name'];
    }
?>	
    </select>
    <br />
    
    <input type="hidden" value="<?=(isset($edit['opr_id']))?$edit['opr_id']:-1?>" name="edid">
    <input type="submit" value="Добавить" name="submit"><br />
</form>
<?endif;?>
<?php
    $new = pg_exec('select * from public.operators ORDER BY opr_name ASC');
    $new2 = pg_exec('select * from public.operators_languages o JOIN public.languages l ON (o.lng_id=l.lng_id)');
    $lng = array();
    while($t2 = pg_fetch_array($new2)){
	$lng[$t2['opr_id']][] = $t2['lng_name_short'];
    }
?>

<table>
<tr>
<?if($_SESSION['logged']!='monitor'):?><td></td><?endif;?>
<td>Фамилия Имя</td>
<td>Пароль</td>
<td>Грейд</td>
<td>Языки</td>
<td>Исходящие</td>
<td>Дата приема</td>
<td>Дата увольнения</td>
<td>Коуч</td>
<td></td>
</tr>
<?php    
    while($t = pg_fetch_array($new)){
        echo '<tr>';
//	echo '<td><a href=?delid='.$t[0].'>delete</a></td>';
if($_SESSION['logged']!='monitor')	echo '<td><a href=?editid='.$t[0].'>edit</a></td>';
//	echo '<td>'.$t['opr_id'].' </td>';
	echo '<td> '.$t['opr_name'].'</td>';
	echo '<td>'.$t['opr_password'].'</td>';
	echo '<td>'.$t['opr_graid'].'</td>';
	echo '<td>';
	if (is_array($lng[$t['opr_id']])) echo implode(',',$lng[$t['opr_id']]);
	echo '</td>';
	echo '<td><center>'.$t['opr_outgoing_call'].'</center></td>';
	echo '<td>'.$t['opr_date_begin'].'</td>';
	echo '<td>'.$t['opr_date_end'].'</td>';
	echo '<td>';
	if (isset($kouch[$t['kch_id']])) echo $kouch[$t['kch_id']];
	echo '</td>';
        echo '</tr>';
    }
?>

</table>

<?php    
    include_once("db_disconnect.php");
?>