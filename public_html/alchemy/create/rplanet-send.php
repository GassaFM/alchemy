<?php
// Inspired by: http://incarnate.github.io/curl-to-php/

header ('Access-Control-Allow-Origin: https://prospectors.online');
header ('Access-Control-Allow-Headers: Content-Type');
// header ('Access-Control-Allow-Origin: *');
// header ('Access-Control-Allow-Headers: *');

$ch = curl_init ();

$data = json_decode (file_get_contents ('php://input'), true);

curl_setopt ($ch, CURLOPT_URL, 'https://rplanet.io/api/send_transaction');
curl_setopt ($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt ($ch, CURLOPT_POST, 1);
curl_setopt ($ch, CURLOPT_POSTFIELDS, json_encode ($data));

$headers = array ();
$headers[] = 'Content-Type: application/json';
$headers[] = 'Origin: https://rplanet.io';
curl_setopt ($ch, CURLOPT_HTTPHEADER, $headers);

$result = curl_exec ($ch);
if (curl_errno ($ch)) {
    echo 'Error:' . curl_error ($ch);
}
curl_close ($ch);

print ($result);
?>
