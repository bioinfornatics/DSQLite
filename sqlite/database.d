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
private import std.conv;
public  import std.variant;

private import core.exception : RangeError;


public  import sqlite.c;
public  import sqlite.table;
public  import sqlite.statement;
public  import sqlite.exception;
private import sqlite.loader;

debug private import std.stdio;

/**
 * executeScript
 * This function allow to user read a sql script and execute the content to database
 * Params:
 *  databasePath:   Path to database whes script will ne executed
 *  lines:          One or more sql script line provides by example a file
 * Examples:
 * File sql = File( "script.sql", "r");
 * foreach (T line; lines(f))
 *     executeScript( "myDB.sqlite3.db", std.conv.to!(string) line );
 *
 */

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

/**
 * Database
 * It is an object for manipulate slaite Database easily
 */
class Database{
    private:
        DynamicLib      _loader;
        string          _databasePath;
        sqlite3*        _connection;
        Table[string]   _tables;
        Statement       _statement;

    public:
        /**
         * Constructor
         * Params:
         *    databasePath = a path to an existing or not slite database
         *    inMemory     = default false if you want load full databse in memory
         */
        this( string databasePath, bool inMemory = false ){
            // open dynamic lib
            _loader         = DynamicLib("libsqlite3", "0");
            // read / load symbols
            _loader.LoadSymbol("sqlite3_bind_double"         , sqlite3_bind_double);
            _loader.LoadSymbol("sqlite3_bind_int"            , sqlite3_bind_int);
            _loader.LoadSymbol("sqlite3_bind_int64"          , sqlite3_bind_int64);
            _loader.LoadSymbol("sqlite3_bind_text"           , sqlite3_bind_text);
            _loader.LoadSymbol("sqlite3_clear_bindings"      , sqlite3_clear_bindings);
            _loader.LoadSymbol("sqlite3_close"               , sqlite3_close);
            _loader.LoadSymbol("sqlite3_column_count"        , sqlite3_column_count);
            _loader.LoadSymbol("sqlite3_column_database_name", sqlite3_column_database_name);
            _loader.LoadSymbol("sqlite3_column_double"       , sqlite3_column_double);
            _loader.LoadSymbol("sqlite3_column_int"          , sqlite3_column_int);
            _loader.LoadSymbol("sqlite3_column_name"         , sqlite3_column_name);
            _loader.LoadSymbol("sqlite3_column_origin_name"  , sqlite3_column_origin_name);
            _loader.LoadSymbol("sqlite3_column_table_name"   , sqlite3_column_table_name);
            _loader.LoadSymbol("sqlite3_column_text"         , sqlite3_column_text);
            _loader.LoadSymbol("sqlite3_errmsg"              , sqlite3_errmsg);
            _loader.LoadSymbol("sqlite3_exec"                , sqlite3_exec);
            _loader.LoadSymbol("sqlite3_finalize"            , sqlite3_finalize);
            _loader.LoadSymbol("sqlite3_open"                , sqlite3_open);
            _loader.LoadSymbol("sqlite3_prepare_v2"          , sqlite3_prepare_v2);;
            _loader.LoadSymbol("sqlite3_reset"               , sqlite3_reset);
            _loader.LoadSymbol("sqlite3_step"                , sqlite3_step);
            // open database
            _databasePath   = databasePath.idup;
            debug writeln( "opening database" );
            int status      = sqlite3_open( _databasePath.toStringz, &_connection );
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

        /**
         * createTable
         * This method allow to user to create a table into current database
         *
         * Params:
         *    tableName =  name to give to table
         *    columns   =  each field fot this table by pair <Type> <Name>
         *
         * Examples:
         *    Database db = new Database( "myDB.sqlite3.db" );
         *    db.createTable( "people", "name TEXT", "id INTEGER PRIMARY KEY NOT NULL" );
         */
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

        /**
         * createTable
         * This method allow to user to create a table into current database
         *
         * Params:
         *    query =  SQL query for create a table
         *
         * Examples:
         *    Database db = new Database( "myDB.sqlite3.db" );
         *    db.createTable( "CREATE TABLE people ( name TEXT, id INTEGER PRIMARY KEY NOT NULL);" );
         */
        void createTable( string query ){
            debug writefln( "sql: %s", query );
            command( query );
            updateTablesList;
        }

        /**
         * dropTable
         * Remove given table from current database
         * Params:
         *     tableName = Name to table where will be dropped
         */
        void dropTable( string tableName ){
            string query = "DROP TABLE " ~ tableName;
            command( query );
            if(  tableName in _tables)
                _tables.remove( tableName );
        }

        /**
         * connection
         * In normal use you do not need use it
         */
        @property sqlite3* connection(){
            return _connection;
        }


        /**
         * tables
         * Returns:
         *     all tables in current database
         */
        @property Row[] tables(){
            return command( "SELECT name FROM sqlite_master WHERE type='table'" );
        }

        /**
         * updateTablesList
         * update tables used in current table. This it is usefull when you create a table with command and not with createTable method
         */
        @property void updateTablesList(){
            Row[] result = tables;
            foreach( table; result ){
                Column column   = table["name"];
                string tableName= to!(string)( column.getValue );
                debug writefln( "list table, %s: %s", column.name, tableName );
                if(  tableName !in _tables)
                    _tables[ tableName ] = new Table( this, tableName) ;
            }
        }

        /**
         * table_info
         * Returns:
         *     give table structure <FieldName> <Type>
         */
        Row[] table_info( string tableName ){
            return _statement.prepare( "PRAGMA table_info( " ~ tableName ~ " )" );
        }

        /**
         * command
         * This method is usefull for run one custom command
         * But prefer in first insert, select, udpdate method define in Table
         * Examples:
         *     b.command( "CREATE TABLE people ( name TEXT, id INTEGER PRIMARY KEY NOT NULL);" );
         */
        Row[] command( string query ){
           return _statement.prepare( query );
        }

        /**
         * command
         * This method is usefull for run muliple custom commands
         * But prefer in first insert, select, udpdate method define in Table
         * Examples:
         *     b.command( ["CREATE TABLE people ( name TEXT, id INTEGER PRIMARY KEY NOT NULL);", "CREATE TABLE car ( constructor TEXT, model TEXT, id INTEGER PRIMARY KEY NOT NULL)"] );
         */
        void command( string[] querys ){
            _statement.prepare( querys );
        }

        /**
         * command
         * This method is usefull for run one custom command
         * But prefer in first insert, select, udpdate method define in Table
         * Examples:
         *     b.command( "SELECT FROM people ( name ) WHERE id=?;", cast(Variant)1 );
         *     b.command( "SELECT FROM car ( name ) WHERE constructor=? and model)?;", cast(Variant) "citroën", cast(Variant) "C5" );
         */
        Row[] command( string query, Variant[] values... ){
            return _statement.prepare( query, values );
        }

        /**
         * command
         * This method is usefull for run multiple custom command
         * But prefer in first insert, select, udpdate method define in Table
         * Examples:
         *     b.command( ["SELECT FROM people ( name ) WHERE id=?;", "SELECT FROM car ( name ) WHERE constructor=? and model)?;"], [ [cast(Variant)1],  [cast(Variant)"citroën", cast(Variant)"C5" ] ] );
         */
        void command( string[] querys, Variant[][] values... ){
            _statement.prepare( querys, values );
        }

        /**
         * opApply
         * This method allow user to iterate through database for get table
         * foreach(Table t; db)
         *     t.select( ["name"], "id=?", cast(Variant) 5);
         */
        int opApply( int delegate(ref Table) dg ){
            int result = 0;
            foreach( name, table; _tables )
                result = dg( table );
            return result;
        }

        /**
         * opIndex
         * This method allow user to get table by his name
         * Example:
         *     Table people = db["people"];
         */
        Table opIndex( string name){
            if( name !in _tables )
                throw new RangeError("Table: %s does not exist!".format( name ) );
            return _tables[name];
        }

}
