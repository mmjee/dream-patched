<?php
  header("Content-type: text/html");
$fp = stream_socket_client("tcp://localhost:8085", $errno, $errstr, 30);
if (!$fp) {
    echo "$errstr ($errno)<br />\n";
} else {
    while (!feof($fp)) {
        echo fgets($fp, 1024);
    }
    fclose($fp);
}
?>
