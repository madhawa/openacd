<script type="text/javascript">
</script>

<?if(isset($_SESSION['logged']) && !is_numeric($_SESSION['logged'])):?>

<h2>КИЕВ</h2>

<?if(($_SESSION['logged']!='stat') && ($_SESSION['logged']!='monitor')):?>
<a href="operators.php">Операторы</a> | 
<a href="kouch.php">Коучи</a> | 
<a href="languages.php">Языки</a> | 
<a href="services.php">Службы</a> | 
<a href="access.php">Доступ</a> | 
<a href="destination.php">SIP/IP</a> | 
<a href="black_list.php">Черный список</a> | 
<a href="white_list.php">Белый список</a> | 
<?endif;?>

<?if($_SESSION['logged']!='monitor'):?>
<a href="stat.php">Статистика</a> | 
<?endif;?>


<a href="online.php">Онлайн</a> | 
<?endif;?>

<?if(isset($_SESSION['logged'])):?>
<a href="errors.php">Обратная связь</a> | 
<a href="logout.php">Выход</a>

<hr>

<?endif;?>
