<?php

header ("content-type: text/xml");

$host="tcp://127.0.0.1";
$port = 4583;
$fp = fsockopen ($host, $port, $errno, $errstr, 5);
if (!$fp) {
    $result = "Error: could not open socket connection";
}
 else {
    while(strpos($t,'=cut=')==0) {
	$t .= fgets ($fp, 128);
    }
    $t='';
    fwrite ($fp, "xml op"."\r\n");
    while(strpos($t,'=cut=')==0) {
	$t .= fgets ($fp, 128);
    }
    $t = str_replace('=cut=','',$t);
    echo ($t);
    $t='';
    fwrite ($fp, "exit"."\r\n");
    $t = fgets ($fp, 128);
}

fclose($fp);
echo $result;

?>