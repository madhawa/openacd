<?php
    
    session_start();
//echo md5($_POST["password"]);
    if(isset($_POST["name"])){
	if (
	    ($_POST["name"]=='monitor' &&
	    md5($_POST["password"])=='08b5411f848a2581a41672a759c87380') 
	) {
	    $logged = $_POST["name"];
	    session_register("logged");
	    header("Location: online.php");
	}
	if (
	    ($_POST["name"]=='admin' &&
	    md5($_POST["password"])=='21232f297a57a5a743894a0e4a801fc3') 
	) {
	    $logged = $_POST["name"];
	    session_register("logged");
	    header("Location: operators.php");
	}
    }
    
    include_once("menu.php");
?>

<h2>Login request</h2>
<form method="post" enctype="multipart/form-data">

Login : <input type="text" name="name"><br />
Password : <input type="password" name="password"><br />

<input type="submit" value="submit" name="submit"><br />

</form>

