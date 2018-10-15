<html>
<head>
    <title>Schiffe versenken</title>
<body>

<table border=0 cellpadding=0 cellspacing=0 style="color:#00377c">
    <tr bgcolor=#ffcc00>
        <td class=tabhead style="font-size:1.8em"><img src=blank.gif width=750 height=6><br><b>Schiffe versenken anlegen
                - Spieler 2</b></td>
    </tr>
</table>

<?php

// dient zum Anlegen von enabled/disabled auf den Switchen 1-3
// port_update.pl darf nicht laufen!!!!!!!!!!!!!!

$switch = $_GET["switch"];
//$switch = "192.168.0.".$switch;

$port = $_GET["port"];
$enabled = $_GET["enabled"];

/*$switch=1;
$port=18;
$enabled=0;*/

// Datenbank öffnen
$db = new SQLite3('schiffe.db');

// Port in der SQLite-DB ändern
/*if ($enabled==1){$db->exec("UPDATE switche SET enabled='0' WHERE switch='$switch' AND port='$port';");}
else if ($enabled==0){$db->exec("UPDATE switche SET enabled='1' WHERE switch='$switch' AND port='$port';");}*/

// bei dem Port, der die php-Seite aufruft, Änderung in der SQLite-DB eintragen
if ($enabled == 1) {
    $db->exec("UPDATE switche SET enabled='0' WHERE switch='$switch' AND port='$port';");
}
if ($enabled == 0) {
    $db->exec("UPDATE switche SET enabled='1' WHERE switch='$switch' AND port='$port';");
}

// Daten der Switche aus der Datenbank abfragen
$result = $db->query('SELECT switch,port,enabled,up FROM switche;');


#echo "<br>"; echo $switch; echo "<br>"; echo $port; echo "<br>"; echo $enabled;

// Perl-Skript zum ändern des enabled-Status aufrufen
exec('perl /var/www/html/port_update.pl ' . $switch . ' ' . $port . ' ' . $enabled, $output);


echo "<br><br><br>";

/* Up/Down-Status der Ports abfragen */
$i = 1;
echo "eigene Schiffe: ";
echo "<br><br>";
echo "<table border='0'>";
echo "<tr><td>";
$even = [];
$odd = [];
while ($row = $result->fetchArray()) {
    if ($row['switch'] == 2){
	if ($row['port'] % 2 == 0) {
    	    $even[$row['port']] = $row;
	} else {
    	    $odd[$row['port']] = $row;
	}
    }
}
$run = true;
$evenIterator = new ArrayIterator($even);
$oddIterator = new ArrayIterator($odd);
$even = false;

while ($evenIterator->valid()) {
    if (!$even){
	draw($oddIterator->current(), $i);
	$oddIterator->next();
    } else {
	draw($evenIterator->current(), $i);
	$evenIterator->next();
    }
    if ( ($i %12) == 0 ){
	$even = !$even;
    }
    $i++;
}

function showArray($array)
{
    $iterator = new ArrayIterator($array);
    while($iterator->valid()) {
	echo $iterator->key() . ' => ' . $iterator->current() . "\n";

	$iterator->next();
    }
}

function draw($row, $i)
{
    //showArray($row);
    if ($row['switch'] == 2) {
        // bei dem Port, der die php-Seite aufruft, wird es genau andersrum angezeigt als in der Wirklichkeit
        $s = $row['switch'];
        $p = $row['port'];
        $e = $row['enabled'];
        // if ($s==$switch and $p==$port){
        //    if ($enabled==1){$e=0;} else if ($enabled==0){$e=1;}
        //}
        // Schiffe platzieren
        if ($e == 1) {
            echo "<a href='anlegen_02.php?switch=$s&port=$p&enabled=$e'><img src='schiff1.jpg' alt='up'></a>";
        } else {
            echo "<a href='anlegen_02.php?switch=$s&port=$p&enabled=$e'><img src='schiff3.jpg' alt='down'></a>";
        }
        echo " ";

        // Zeilenumbruch, wenn durch 12 teilbar
        //if (($i%6) == 0 ) {echo "<br>";}
        //if (($i%12) == 0 and ($i%24) != 0) {
        //    echo "</td><td>";
        //}
        if (($i % 12) == 0) {
            echo "</td></tr><tr><td>";
        }
    }
}

/*while( $row=$result->fetchArray() ) {
  // wertet nur Switche 1-3 aus
    if ($row['switch'] == 1){
	// bei dem Port, der die php-Seite aufruft, wird es genau andersrum angezeigt als in der Wirklichkeit
	$s=$row['switch']; $p=$row['port']; $e=$row['enabled'];
	// if ($s==$switch and $p==$port){
    //    if ($enabled==1){$e=0;} else if ($enabled==0){$e=1;}
	//}
	// Schiffe platzieren
	    if ($e == 1) {echo "<a href='anlegen_01.php?switch=$s&port=$p&enabled=$e'><img src='schiff1.jpg' alt='up'></a>";}
	    else {echo "<a href='anlegen_01.php?switch=$s&port=$p&enabled=$e'><img src='schiff3.jpg' alt='down'></a>";}
	echo " ";

	// Zeilenumbruch, wenn durch 12 teilbar
	//if (($i%6) == 0 ) {echo "<br>";}
	//if (($i%12) == 0 and ($i%24) != 0) {
	//    echo "</td><td>";
	//}
	if (($i%12) == 0) {
	    echo "</td></tr><tr><td>";
	}
    }
  $i++;
}*/
echo "</td></tr>";
echo "</table>";


echo "<br><br>";
echo "1 x 5er<br>";
echo "2 x 4er<br>";
echo "1 x 3er<br>";

echo "<br><br>";

?>

<a href="spielen_02.php">Spiel beginnen</a>

</body>
</html>

