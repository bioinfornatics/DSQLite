import std.string;
import std.stdio;
import sqlite.database;

void main( string[] args ){
    writeln( "+++ create database" );
    Database db = new Database( "myDB.sqlite3.db" );
    writeln( "+++ create table" );
    db.createTable( "people", "name TEXT", "id INTEGER PRIMARY KEY NOT NULL" );
    Variant name1   = "john";
    Variant name2   = "smith";
    Variant id      = 1;
    writeln( "+++ INSERT INTO people (id, name) VALUES(?, ?), john, 1" );
    db["people"].insert( [id, name1], ["id", "name"] );
    writeln( "+++ INSERT INTO people (id, name) VALUES(?), smith" );
    db["people"].insert( [name2], ["name"] );
    writeln( "+++ SELECT name FROM people WHERE id=1" );
    Row[] results1 = db["people"].select( ["name"], "id=1" );
    writeln( "+++ print" );
    writeln(results1.header);
    foreach( row; results1 )
        writeln( row );
    writeln( "+++ SELECT name FROM people WHERE id=?, 1" );
    Row[] results2 = db["people"].select( ["name"], "id=?", id );
    writeln( "+++ print" );
    writeln(results2.header);
    foreach( row; results2 )
        writeln( row );
    writeln( "+++ SELECT * FROM people" );
    Row[] results3 = db.command( "SELECT * FROM people;" );
    writeln( "+++ print" );
    writeln(results3.header);
    foreach( row; results3 )
        writeln( row );
    writeln( "+++ CREATE TABLE car ( constructor TEXT, model TEXT, id INTEGER PRIMARY KEY NOT NULL);" );
    db.command( "CREATE TABLE car ( constructor TEXT, model TEXT, id INTEGER PRIMARY KEY NOT NULL)" );
    writeln( "+++ UPDATE table name stored" );
    db.updateTablesList;
    assert( db["car"] !is null);
}
