import std.string;
import std.stdio;
import sqlite.database;

void main( string[] args ){
    writeln( "+++ create database" );
    Database db = new Database( "myDB.sqlite3.db" );
    writeln( "+++ create table" );
    db.createTable( "people", "name TEXT", "id INTEGER PRIMARY KEY NOT NULL" );
    writeln( "+++ insert table" );
    //~ db["people"].insert( cast(Variant[][])[["john"], ["smith"]], ["name"] );
    Variant name1   = "john";
    Variant name2   = "smith";
    Variant id      = 1;
    db["people"].insert( [id, name1], ["id", "name"] );
    db["people"].insert( [name2], ["name"] );
    writeln( "+++ select" );
    Row[] results1 = db["people"].select( ["name"], "id=1" );
    writeln( "+++ print" );
    writeln(results1.header);
    foreach( row; results1 )
        writeln( row );
    writeln( "+++ select whith binding value" );
    Row[] results2 = db["people"].select( ["name"], "id=?", id );
    writeln( "+++ print" );
    writeln(results2.header);
    foreach( row; results2 )
        writeln( row );
    writeln( "+++ select: manual" );
    Row[] results3 = db.command( "SELECT * FROM people;" );
    writeln( "+++ print" );
    writeln(results3.header);
    foreach( row; results3 )
        writeln( row );
}
