<?

ini_set('session.gc_maxlifetime',28800);
ini_set('session.gc_probability',1);
ini_set('session.gc_divisor',1); 

    session_start();
    
    if(!session_is_registered("logged")) {
	header("Location: login.php");
    }

if($xls!=1) include_once("include-header.php"); 

?>