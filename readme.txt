die HPSNMP.pm unter debianoiden Systemen in /usr/local/lib/site_perl/HPSNMP.pm 
ablegen (perl version entsprechend anpassen)

In dieser Datei sind auch die Community Strings hinterlegt (nach XXX suchen)

Perl-Lib  Net::SNMP wird benoetigt  -> sudo apt-get install libnet-snmp-perl


/usr/lib/perl/5.10.1

sudo apt-get install libdbi-perl
sudo apt-get install libdbd-sqlite3-perl


sudo apt-get install php5
sudo apt-get install dos2unix  -> php-Datei in Unix-Format wandeln
sudo apt-get install sqlite
sudo apt-get install php5-sqlite


sqlite3 schiffe.db "CREATE TABLE switche (key INTEGER PRIMARY KEY, switch INT, port INT, enabled INT, up INT);"

sqlite3 schiffe.db "insert into switche (switch,port,enabled,up) values ('1','1','2','3')"

	sqlite3 schiffe.db "SELECT * FROM switche";



./port_info_sqlite.pl l-switch-1 l-switch-2 l-switch-3 l-switch-4 l-switch-5 l-switch-6
./port_info_sqlite_spiel.pl l-switch-1 l-switch-2 l-switch-3 l-switch-4 l-switch-5 l-switch-6


-rwxr--r-- 1 fem  fem   2637 30. Sep 20:11 anlegen_01.php
-rwxr--r-- 1 fem  fem   2637 30. Sep 20:11 anlegen_02.php
-rw-r--r-- 1 fem  fem     43  4. Mai 18:03 blank.gif
-rw-r--r-- 1 root root   177 24. Sep 10:54 index1.html
-rwxr--r-- 1 fem  fem   2324 30. Sep 19:27 port_info.pl
-rwxr--r-- 1 fem  fem   1545 30. Sep 18:22 port_info_spiel.pl
-rwxr--r-- 1 fem  fem    325 30. Sep 19:21 port_update.pl
-rw-r--r-- 1 fem  fem   2550 30. Sep 20:18 readme.txt
-rw-r--r-- 1 fem  fem  22022 24. Sep 17:41 schiff1.jpg
-rw-r--r-- 1 fem  fem  22901 24. Sep 17:42 schiff2.jpg
-rw-r--r-- 1 fem  fem  20689 24. Sep 17:42 schiff3.jpg
-rw-rw-rw- 1 fem  fem   4096 30. Sep 20:30 schiffe.db
-rw-rw-rw- 1 fem  fem   2576 30. Sep 20:30 schiffe.db-journal
-rwxr--r-- 1 fem  fem   2359 30. Sep 20:09 spielen_01.php
-rw-r--r-- 1 fem  fem   2359 30. Sep 20:10 spielen_02.php


alle Rechte vergeben
-> Rechner neu starten


Manual:

192.168.1-6 Switche
192.168.1.7 26er Spieler 1 
192.168.1.8 26er Spieler 2
    ports 47 bis 50 können zum Anstecken von Notebooks verwendet werden
192.168.1.9 nupsi
192.168.1.10 Marketing-Notebook

nmap 192.168.1.* -sP

/var/www ./port_info.pl vor dem Spiel, um Datenbank auf den aktuellen Stand zu bringen
/var/www ./port_info_spiel.pl nach dem Eintragen, wenn das Spiel losgeht

anlegen_01.php und anlegen_02.php zum Anlegen der Schiffe
spielen_01.php und spielen_02.php zum Spielen

screen /dev/ttyUSB0 
ssh -c 3des-cbc admin@192.168.1.8 (altes swtichpasswort)


Spiel starten:
./restart_game.sh
Setzt alle Schiffe zurück und schreibt config auf ports
