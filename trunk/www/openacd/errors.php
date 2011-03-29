<?php
    include_once("db_connect.php");

    if($_POST["operator"]!=''){
	$text = "Оператор: <b>".$_POST["operator"]."</b>
<br>
Время: <b>".$_POST["date"]."</b><br>
IP: <b>".$_SERVER['REMOTE_ADDR']."</b><br>
Тема: <b>".$_POST["header"]."</b><br>
Сообщение: <b>".$_POST["body"]."</b>
	";
	pg_exec("INSERT INTO public.errors (err_text) VALUES ('$text')");
	header("Location: errors.php");
    }
    if(is_numeric($_GET["delid"])){
	pg_exec("DELETE FROM public.errors WHERE err_id = '".$_GET["delid"]."'");
	header("Location: errors.php");
    }

    include_once("include.php");

    include_once("menu.php");
?>
<h2>Обратная связь</h2>
<form method="post">
    Оператор: <b><?=$_SESSION['logged']?></b><input type="hidden" value="<?=$_SESSION['logged']?>" name="operator"><br />
    Дата/время: <b><?=date("Y-m-d H:i:s")?></b><input type="hidden" value="<?=date("Y-m-d H:i:s")?>" name="date"><br />
    Тема сообщения:<br>
    <select name="header">
	<option>...</option>
	<option value="Залипание">Залипание - оператор свободен, но в системе занят</option>
	<option value="Двойные звонки">Двойные звонки - оператор получает звонок, когда занят</option>
	<option value="Неравномерная нагрузка">Неравномерная нагрузка - оператор получает больше звонков, чем другие</option>
	<option value="Разлогинивание">Разлогинивание - через определенное время оператор разлогинивается</option>
	<option value="Другое">Другое</option>
    </select>
    <br />
    Дополнительный текст (если нужно):<br>
    <textarea cols=50 name="body"></textarea><br>
    
    <input type="submit" value="Отправить" name="submit"><br />
</form>

<?php
    $new = pg_exec('select * from public.errors order by err_date ASC');
?>

<table>

<?php    
    while($t = pg_fetch_array($new)){
        echo '<tr>';
	if($_SESSION['logged']=='admin') echo '<td><a href=?delid='.$t[0].'>delete</a></td>';
	echo '<td>'.$t['err_id'].'</td>';
	echo '<td>'.$t['err_date'].'</td>';
	echo '<td>'.$t['err_text'].'</td>';
        echo '</td>';
    }
?>

</table>

<?php    
    include_once("db_disconnect.php");
?>