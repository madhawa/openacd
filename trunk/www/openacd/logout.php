<?php
    session_start();
    $_SESSION['logged']!='';
    session_unregister("logged");
    header("Location: login.php");
?>