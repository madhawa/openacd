<?php

function xlsBOF() {
    echo pack("ssssss", 0x809, 0x8, 0x0, 0x10, 0x0, 0x0);
    return;
}

function xlsEOF() {
    echo pack("ss", 0x0A, 0x00);
    return;
}

function xlsWriteNumber($Row, $Col, $Value) {
    echo pack("sssss", 0x203, 14, $Row, $Col, 0x0);
    echo pack("d", $Value);
    return;
}

function xlsWriteLabel($Row, $Col, $Value ) {
    $L = strlen($Value);
    echo pack("ssssss", 0x204, 8 + $L, $Row, $Col, 0x0, $L);
    echo $Value;
    return;
}

function win2uni($s)
{
    $s = convert_cyr_string($s,'w','i'); // преобразование win1251 -> iso8859-5
    // преобразование iso8859-5 -> unicode:
    for ($result='', $i=0; $i<strlen($s); $i++) {
	$charcode = ord($s[$i]);
	$result .= ($charcode>175)?"&#".(1040+($charcode-176)).";":$s[$i];
    }
    return $result;
}

?>
