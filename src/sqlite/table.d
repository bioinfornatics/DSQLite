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

module sqlite.table;
private import std.string;
private import std.array;
private import std.variant;
private import sqlite.statement;
private import sqlite.database;
debug private import std.stdio;

final class Table{

    private:
        Database    _database;
        string      _name;

        string _bindValues ( ref Variant[] values ){
            string bindValues   = "?, ".replicate( values.length );
            return bindValues[ 0 .. $ - 2 ];
        }

    public:
        this( ref Database database, string name ){
            _database   = database;
            _name       = name.idup;
        }

        // INSERT
        void insert(T)( T[] values, string[] columns = null ){
            string query        = "";
            string bindValues   = _bindValues( values );
            if( columns is null)
                query = "INSERT INTO `%s` VALUES ( %s )".format( _name, bindValues );
            else
                query = "INSERT INTO `%s` ( %s ) VALUES ( %s )".format( _name, columns.join( ", "), bindValues );
            _database.command( query, values );
        }

        void insert(T)( T[][] values, string[] columns = null ){
            foreach( value; values )
                insert( value, columns );
        }

        void insert(T)( T[][] values, string[][] columns = null ){
            if( values.length != columns.length )
                throw new TableException( " Array values and array columns need to be same length: %s != %s".format( values.length, columns.length ), __FILE__, __LINE__ );
            foreach( index; 0 .. values.length )
                insert( values[index], columns[index] );
        }

        // REPLACE
        void replace(T)( T[] values, string[] columns = null ){
            string query        = "";
            string bindValues   = _bindValues( values );
            if( columns is null )
                query = "REPLACE INTO `%s` VALUES ( %s )".format( _name, bindValues );
            else
                query = "REPLACE INTO `%s` ( %s ) VALUES ( %s )".format( _name, columns.join( ", "), bindValues );
            _database.command( query, values );
        }

        void replace(T)( T[][] values, string[] columns = null ){
            foreach( value; values )
                replace( value, columns);
        }

        void replace(T)( T[][] values, string[][] columns = null ){
            if( values.length != columns.length )
                throw new TableException( " Array values and array columns need to be same length: %s != %s".format( values.length, columns.length ), __FILE__, __LINE__ );
            foreach( index; 0 .. values.length )
                replace( values[index], columns[index]);
        }

        // UPDATE
        void update(T)( T[] values, string[] columns, string condition ){
            string query = "UPDATE `%s` ( %s ) SET ( %s ) WHERE %s".format( _name, columns.join( ", "), condition );
            _database.command( query, values );
        }

        void update(T)( T[][] values, string[] columns, string condition ){
            foreach( value; values )
                update( value, columns, condition );
        }

        void update(T)( T[][] values, string[][] columns, string[] conditions ){
            if( columns.length != conditions.length )
                throw new TableException( " Array columns and array condition need to be same length: %s != %s".format( columns.length, conditions.length ), __FILE__, __LINE__ );
            foreach( index; 0 .. columns.length )
                update( values[index], columns[index], conditions[index] );
        }

        // SELECT
        Row[] select( string[] column, string statement = null){
            string sql = "SELECT ( %s ) FROM `%s`".format( column.join(", "), _name );
            if( statement !is null )
                sql ~= " WHERE " ~ statement;
            debug writefln( "sql: %s", sql);
            return _database.command( sql );
        }

        Row[] select( string[] column, string statement, Variant[] values... ){
            string sql = "SELECT ( %s ) FROM `%s` WHERE %s".format( column.join(", "), _name, statement);
            debug writefln( "sql: %s", sql);
            return _database.command( sql, values );
        }
}
