/*
This file is part of DSQLite.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
*/

module sqlite.database;

private import std.string;
private import etc.c.sqlite3;
public  import std.variant;
private import std.conv;

public  import sqlite.table;
public  import sqlite.statement;
public  import sqlite.exception;

debug private import std.stdio;

Database executeScript( string databasePath, string[] lines ...){

    void add( ref string[] statements, ref string query, ref size_t stmtCounter){
        stmtCounter++;
        if( stmtCounter >= statements.length )
            statements.length = statements.length + 10;
        statements[stmtCounter] = query.idup ;
        query = "";
    }

    Database    db          = new Database( databasePath );
    string[]    statements  = new string[](10);
    size_t      stmtCounter = 0;
    sizediff_t  index       = 0;
    string      tmpLine     = "";
    foreach( line; lines ){
        index = line.indexOf(";");
        if( index != -1 ){
            tmpLine ~= line[ 0 .. index ];
            add( statements, tmpLine, stmtCounter );
        }
        else{
            tmpLine ~= line;
        }
    }
    statements.length = stmtCounter;
    db.command( statements );
    return db;
}


class Database{
    private:
        string          _databasePath;
        sqlite3*        _connection;
        Table[string]   _tables;
        Statement       _statement;

    public:
        this( string databasePath, bool inMemory = false ){
            _databasePath= databasePath.idup;
            debug writeln( "opening database" );
            int status   = sqlite3_open( _databasePath.toStringz, &_connection );
            if( status != SQLITE_OK )
                throw new SQLiteException( to!string(sqlite3_errmsg( _connection )), __FILE__, __LINE__ );
            debug writeln( "init statement" );
            _statement = Statement( this );
            debug writeln( "optimize sqlite perf" );
            // Optimization
            command("PRAGMA cache_size   = 4000" );
            command("PRAGMA foreign_keys = OFF" );
            command("PRAGMA synchronous  = OFF" );
            debug writeln( "optimize done" );
            if( inMemory )
                command("PRAGMA synchronous = MEMORY" );
                // TODO create table object
        }

        ~this(){
            sqlite3_exec( _connection, "END", null, null, null );
            sqlite3_close( _connection );
        }

        void createTable( string tableName, string[] columns ... ){
            string query = "CREATE TABLE " ~ tableName ~ " ( ";
            foreach( index, column; columns ){
                query ~= column;
                if( index == columns.length -1 )
                    query ~= " )";
                else
                    query ~= ", ";
            }
            command( query );
            _tables[tableName] = new Table( this, tableName);
        }

        void createTable( string query ){
            debug writefln( "sql: %s", query );
            command( query );
            updateTablesList;
        }

        @property sqlite3* connection(){
            return _connection;
        }

        @property Row[] tables(){
            return command( "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name" );
        }

        @property void updateTablesList(){
            Row[] result = tables;
            foreach( table; tables ){
                Column name     = table["name"];
                string tableName= name.to!(string)();
                if(  tableName !in _tables)
                    _tables[ tableName ] = new Table( this, tableName) ;
            }
        }

        Row[] table_info( string tableName ){
            return _statement.prepare( "PRAGMA table_info( " ~ tableName ~ " )" );
        }

        Row[] command( string query ){
           return _statement.prepare( query );
        }

        void command( string[] querys ){
            _statement.prepare( querys );
        }

        Row[] command( string query, Variant[] values... ){
            return _statement.prepare( query, values );
        }

        void command( string[] querys, Variant[][] values... ){
            _statement.prepare( querys, values );
        }

        int opApply( int delegate(ref Table) dg ){
            int result = 0;
            foreach( name, table; _tables )
                result = dg( table );
            return result;
        }

        Table opIndex( string name){
            return _tables[name];
        }
}

