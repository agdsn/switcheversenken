<html>
<head>
    <title>Schiffe versenken</title>
    <meta http-equiv="refresh" content="0.5;url=spielen_02.php">
<body style="color:#00377c">

<table border=0 cellpadding=0 cellspacing=0>
    <tr bgcolor=#ffcc00>
        <td class=tabhead style="font-size:1.8em"><img src=blank.gif width=1180 height=6><br><b>Schiffe versenken -
                Spieler 2</b></td>
    </tr>
</table>

<?php

// dient zum Spielen von up/down auf den Switchen 1-3

//#!/usr/bin/php

//phpinfo();

$db = new SQLite3('schiffe.db');

//$db->exec("CREATE TABLE switche (key INTEGER PRIMARY KEY, switch INT, port INT, enabled INT, up INT)");

//$db->exec("INSERT INTO switche (switch,port,enabled,up) VALUES (1,2,3,4)");

// Daten der Switche aus der Datenbank abfragen
$result = $db->query('SELECT switch,port,enabled,up FROM switche;');


echo "<br><br>";

// Daten ausgeben
/*$i=0;
while( $row=$result->fetchArray() ) {
  echo $row['switch']." ";
  echo $row['port']." ";
  echo $row['enabled']." ";
  echo $row['up']."<br><br>";
}*/

echo "<table border='0' cellspacing='50'>";
echo "<tr><td>";

$i = 1;
echo "<b>Treffer auf gegnerische Schiffe: </b>";
echo "<br><br>";
echo "<table border='0'>";
echo "<tr><td>";
$even=[];
$odd=[];
while ($row = $result->fetchArray()) {
    if ($row['switch'] == 1) {
        if ($row['port'] % 2 == 0) {
            $even[$row['port']] = $row;
        } else {
            $odd[$row['port']] = $row;
        }
    }
}

$evenIterator = new ArrayIterator($even);
$oddIterator = new ArrayIterator($odd);
$even = false;

while ($evenIterator->valid()) {
    if (!$even){
        drawThem($oddIterator->current(), $i);
        $oddIterator->next();
    } else {
        drawThem($evenIterator->current(), $i);
        $evenIterator->next();
    }
    if ( ($i %12) == 0 ){
        $even = !$even;
    }
    $i++;
}

function drawThem($row, $i){
        if ($row['up'] == 1) {
            echo "<img src='schiff2.jpg' alt='up'>";
        } else {
            echo "<img src='schiff3.jpg' alt='down'>";
        }
        echo " ";
        /*
        if (($i % 6) == 0) {
            echo "<br>";
        }
        if (($i % 12) == 0 and ($i % 24) != 0) {
            echo "</td><td>";
        }*/
        if (($i % 12) == 0) {
            echo "</td></tr><tr><td>";
        }
}
echo "</td></tr>";
echo "</table>";


echo "</td><td>";


$i = 1;
echo "<b>gegnerische Treffer auf eigene Schiffe: </b>";
echo "<br><br>";
echo "<table border='0'>";
echo "<tr><td>";
$even=[];
$odd=[];
while ($row = $result->fetchArray()) {
    if ($row['switch'] == 2) {
        if ($row['port'] % 2 == 0) {
            $even[$row['port']] = $row;
        } else {
            $odd[$row['port']] = $row;
        }
    }
}

$evenIterator = new ArrayIterator($even);
$oddIterator = new ArrayIterator($odd);
$even = false;

while ($evenIterator->valid()) {
    if (!$even){
        drawUs($oddIterator->current(), $i);
        $oddIterator->next();
    } else {
        drawUs($evenIterator->current(), $i);
        $evenIterator->next();
    }
    if ( ($i %12) == 0 ){
        $even = !$even;
    }
    $i++;
}

function drawUs($row, $i){
    if ($row['enabled'] == 1 and $row['up'] == 1) {
        echo "<img src='schiff2.jpg' alt='up'>";
    } else if ($row['enabled'] == 1 and $row['up'] == 0) {
        echo "<img src='schiff1.jpg' alt='down'>";
    } else {
        echo "<img src='schiff3.jpg' alt='down'>";
    }
    echo " ";
    /*
    if (($i % 6) == 0) {
        echo "<br>";
    }
    if (($i % 12) == 0 and ($i % 24) != 0) {
        echo "</td><td>";
    }*/
    if (($i % 12) == 0) {
        echo "</td></tr><tr><td>";
    }
}

echo "</td></tr>";
echo "</table>";

echo "</td></tr>";
echo "</table>";


//sqlite_close($db);

?>

</body>
</html>

