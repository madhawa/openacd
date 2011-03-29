<?php

    include_once("db_connect.php");
    $r = pg_exec('select record_file_name from public.records where record_id='.( trim ($_GET['id']) ) );
    $f = ( $t = pg_fetch_array($r) )? $t : 0;
    include_once("db_disconnect.php");
    $nameourfile = end ( explode ('/', $f[0]) );

    if($f) {

	header("Pragma: public");
	header("Expires: 0");
	header("Cache-Control: must-revalidate, post-check=0, pre-check=0");
	header("Content-Type: application/force-download");
	header("Content-Type: application/octet-stream");
	header("Content-Type: application/audio");
	header("Content-Disposition: attachment;filename=$nameourfile");
	header("Content-Transfer-Encoding: binary ");

	readfile($f[0]);
    }

?>