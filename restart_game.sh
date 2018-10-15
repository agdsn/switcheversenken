#!/bin/bash
sqlite3 schiffe.db "DROP TABLE switche;"
sqlite3 schiffe.db "CREATE TABLE switche (key INTEGER PRIMARY KEY, switch INT, port INT, enabled INT, up INT);"
./port_info.pl