<?php
$operators_ol = array(); 
$currentOp = null;
$cOp = null;
$index = null;

function readXML($file) 
{
if(!file_exists($file) || (filemtime($file)+2)<time()) {
    include_once("client.php");
    $xml = client("xml op");
    $f = fopen($file, "w");
    fwrite ($f, $xml);
    fclose($f);
} else {
    $xml = join('',file($file));
}
return $xml;
}

function saxStartElement($parser,$name,$attrs)
{
    global $currentOp,$cOp,$index;
    switch($name)
    {
        case 'operators':
            $operators_ol = array();
            break;
        case 'op_ol':
            $currentOp = array();
            if (in_array('date',array_keys($attrs)))
                $currentOp['date'] = $attrs['date'];
            break;
        case 'op':
            $cOp = array();
            break;
        default:
            $index = $name;
            break;
    };
}

function saxEndElement($parser,$name)
{
    global $operators_ol,$currentOp,$operators,$cOp,$index;
    if ((is_array($currentOp)) && ($name=='op_ol'))
    {
        $operators_ol[] = $currentOp;
        $currentOp = null;
    };
    if ((is_array($cOp)) && ($name=='op'))
    {
        $operators[] = $cOp;
        $cOp = null;
    };
    $index = null;
}

function saxCharacterData($parser,$data)
{
    global $cOp,$currentOp,$index;
    if ((is_array($currentOp)) && ($index))
        $currentOp[$index] = $data;
    if ((is_array($cOp)) && ($index))
        $cOp[$index] = $data;
}

$parser = xml_parser_create();

xml_set_element_handler($parser,'saxStartElement','saxEndElement');
xml_set_character_data_handler($parser,'saxCharacterData');
xml_parser_set_option($parser,XML_OPTION_CASE_FOLDING,false);

$xml = readXML('operators.xml');

if (!xml_parse($parser,$xml,true))
    die(sprintf('Ошибка XML: %s в строке %d',
        xml_error_string(xml_get_error_code($parser)),
        xml_get_current_line_number($parser)));

print_r ($operators_ol);
echo "<hr>";
print_r ($operators);

xml_parser_free($parser);
?>