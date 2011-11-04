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

module sqlite.statement;
private import std.variant;
private import std.ascii : newline;
private import std.conv;
private import std.string;
private import etc.c.sqlite3;
private import sqlite.exception;

private import sqlite.database;

debug private import std.stdio;

struct Statement{
    private:
        sqlite3_stmt*   _statement;
        char*           _lineError;
        bool            _isPrepared;
        int             _columnCount; // returns the number of columns
        Database        _database;


        /**
         * Return: type of selected column
         * SQLITE_INTEGER  = 1
         * SQLITE_FLOAT    = 2
         * SQLITE3_TEXT    = 3
         * SQLITE_BLOB     = 4
         * SQLITE_NULL     = 5
         */
        size_t _columnType( int column ){
            if( ! _isPrepared )
                throw new StatementException( "Error: you can not perform this method if statement is not already prepared.", __FILE__, __LINE__ );
            return sqlite3_column_type( _statement, column );
        }

        void _bind( Variant[] values... ){
            foreach( int index, value; values ){
                int position = index + 1;
                if( value.type == typeid(int) || value.type == typeid(uint) )
                    sqlite3_bind_int( _statement, position, value.get!(int) );
                else if( value.type  == typeid(long) || value.type == typeid(ulong) )
                    sqlite3_bind_int64( _statement, position, value.get!(long) );
                else if( value.type == typeid(float) || value.type == typeid(double) )
                    sqlite3_bind_double( _statement, position, value.get!(double) );
                else if( value.type == typeid(immutable(char)[]) || value.type == typeid(char[]) )
                    sqlite3_bind_text( _statement, position, value.get!(string).toStringz, cast(int)value.get!(string).length, null );
                else
                    throw new StatementException( "Not supported type: %s".format( value.type ), __FILE__, __LINE__ );
            }
        }

    public:
        bool autoExecute;

        this( Database db ){
            _database   = db;
            autoExecute = true;
        }

        ~this(){
            finalyze;
        }

        Row[] prepare( string query ){
            Row[] result    = null;
            _isPrepared     = true;
            if( query[ $ - 1] != ';' )
                query ~= ";";
            debug writefln( "prepare sql: %s", query );
            int status  = sqlite3_prepare_v2( _database.connection, query.toStringz, cast(int)query.length, &_statement, &_lineError );
            if( status != SQLITE_OK )
                throw new StatementException( to!string( sqlite3_errmsg( _database.connection ) ), __FILE__, __LINE__ );
            if( _statement is null )
                 throw new StatementException( "Error: _statement is null.", __FILE__, __LINE__);
            _columnCount = sqlite3_column_count( _statement );
            if( autoExecute )
               result = execute;
            debug writefln( "Count: %s", _columnCount );
            return result;
        }

        void prepare( string[] querys ){
            Row result          = null;
            bool tmpAutoExecute = autoExecute;          // If user have set this var store it for restore the user value at the end
            if( autoExecute )
                autoExecute = false;
            prepare( "BEGIN TRANSACTION" );
                foreach( index, query; querys )
                    prepare( query );
            prepare( "COMMIT TRANSACTION" );
            if( tmpAutoExecute )
                autoExecute = true;                     // restore the user value
        }

        Row[] prepare( string query, Variant[] values... ){
            Row[] result    = null;
            _isPrepared     = true;
            if( query[ $ - 1] != ';' )
                query ~= ";";
            debug writefln( "prepare sql: %s", query );
            int status  = sqlite3_prepare_v2( _database.connection, query.toStringz, cast(int)query.length, &_statement, &_lineError );
            if( status != SQLITE_OK )
                throw new StatementException( to!string( sqlite3_errmsg( _database.connection ) ), __FILE__, __LINE__ );
            if( _statement is null )
                 throw new StatementException( "Error: _statement is null.", __FILE__, __LINE__);
            if( values !is null && values.length > 0 )
                _bind( values );
            _columnCount = sqlite3_column_count( _statement );
            if( autoExecute )
                result = execute;
            return result;
        }

        void prepare( string[] querys, Variant[][] values... ){
            if( querys.length != values.length )
                throw new StatementException( "Error: querys.lenght != values.length: %s != %s".format( querys.length, values.length ), __FILE__, __LINE__ );
            bool tmpAutoExecute = autoExecute;          // If user have set this var store it for restore the user value at the end
            if( autoExecute )
                autoExecute = false;
            prepare( "BEGIN TRANSACTION" );
                foreach( index, query; querys )
                    prepare( query, values[index] );
            prepare( "COMMIT TRANSACTION", );
            if( tmpAutoExecute )
                autoExecute = true;                     // restore the user value
        }

        @property Row[] execute(){
            void add(T)( ref T[] array, ref T item, ref size_t counter ){
                if( counter >= array.length ){
                    array.length = array.length + 10;
                }
                array[counter] = item;
                counter++;
            }
            debug writeln( "execute" );
            if( ! _isPrepared )
                throw new StatementException( "Error: you can not perform this method if statement is not already prepared.", __FILE__, __LINE__ );
            bool isFetching     = true;
            size_t rowCounter   = 0;
            Row[] result        = new Row[]( 10 );
            while( isFetching ){
                Row         currentRow  = null;
                Column[]    columns     = new Column[]( _columnCount );
                size_t      colCounter  = 0;
                int         status      = sqlite3_step( _statement );
                debug writefln( "execute n° %s", rowCounter );

                debug writefln( "status %s | SQLITE_ROW %s | SQLITE_DONE %s", status, SQLITE_ROW, SQLITE_DONE );
                if( status == SQLITE_ROW){
                    foreach( int columnNumber; 0 .. _columnCount ){
                        Column column   = Column( columnName( columnNumber ) );
                        column.value    = columnValue( columnNumber );
                        add!Column( columns, column, colCounter );
                        debug writefln( "column n° %s, %s", columnNumber, column );
                    }
                    currentRow = Row( columns );
                    add!Row( result, currentRow, rowCounter );
                }
                else if( status == SQLITE_DONE )
                    isFetching = false;
                else
                    throw new StatementException( "Error: when executing a statement: %s".format( to!string( sqlite3_errmsg( _database.connection ) ) ), __FILE__, __LINE__ );
            }
            result.length = rowCounter;
            sqlite3_reset( _statement );
            sqlite3_clear_bindings( _statement );
            return result;
        }

        @property size_t length(){
            return _columnCount;
        }

        @property void finalyze(){
            sqlite3_finalize( _statement );
        }

        string databaseName(int column){
            if( ! _isPrepared )
                throw new StatementException( "Error: you can not perform this method if statement is not already prepared.", __FILE__, __LINE__);
            if( column >= _columnCount )
                throw new StatementException( "Column number %s greather than %s".format( column, _columnCount ), __FILE__, __LINE__ );
            return to!string(sqlite3_column_database_name( _statement, column ) );
        }

        string tableName(int column){
            if( ! _isPrepared )
                throw new StatementException( "Error: you can not perform this method if statement is not already prepared.", __FILE__, __LINE__);
            if( column >= _columnCount )
                throw new StatementException( "Column number %s greather than %s".format( column, _columnCount ), __FILE__, __LINE__ );
            return to!string( sqlite3_column_table_name( _statement, column ) );
        }

        string originName(int column){
            if( ! _isPrepared )
                throw new StatementException( "Error: you can not perform this method if statement is not already prepared.", __FILE__, __LINE__);
            if( column >= _columnCount )
                throw new StatementException( "Column number %s greather than %s".format( column, _columnCount ), __FILE__, __LINE__ );
            return to!string( sqlite3_column_origin_name( _statement, column ) );
        }

        string columnName(int column){
            if( ! _isPrepared )
                throw new StatementException( "Error: you can not perform this method if statement is not already prepared.", __FILE__, __LINE__);
            if( column >= _columnCount )
                throw new StatementException( "Column number %s greather than %s".format( column, _columnCount ), __FILE__, __LINE__ );
            return to!string( sqlite3_column_name( _statement, column ) );
        }

        Variant columnValue( int column ){
            size_t type = _columnType( column );
            Variant value;
            switch( type ){
                case SQLITE_INTEGER :
                    value = sqlite3_column_int( _statement, column );
                    break;
                case SQLITE_FLOAT :
                    value = sqlite3_column_double( _statement, column );
                    break;
                case SQLITE3_TEXT :
                    value = to!string( sqlite3_column_text( _statement, column ) );
                    break;
                case SQLITE_NULL :
                    value = null;
                    break;
                default:
                    throw new StatementException( "Type number %s in column %s was not recongnized".format( type, column ), __FILE__, __LINE__ );
            }
            return value;
        }

        /**
         * Enable foreach given index from 0 to _columnCount
         * Return result of dg 0 == SUCCESS
         */
        int opApply( int delegate(ref int) dg ){
            if( ! _isPrepared )
                throw new StatementException( "Error: you can not perform this method if statement is not already prepared.", __FILE__, __LINE__ );
            int result = 0;
            foreach( col; 0 .. _columnCount )
                result = dg( col );
            return result;
        }
}


struct Row{
    private:
        Column[] _columns;

    public:
        this( Column[] columns ){
            _columns = columns.dup;
        }

        /**
         * Enable foreach given index from 0 to _columns.length
         * Return result of dg 0 == SUCCESS
         */
        int opApply( int delegate(ref Column) dg ){
            int result = 0;
            foreach( col; _columns )
                result = dg( col );
            return result;
        }

        /**
         * Enable foreach given index from 0 to _columns.length
         * Return result of dg 0 == SUCCESS
         */
        int opApply( int delegate(ref size_t index, ref Column) dg ){
            int result = 0;
            foreach( index, col; _columns )
                result = dg( index, col );
            return result;
        }

        string toString(){
            string line = "";
            foreach( column; _columns)
                line ~= to!(string)(column.getValue) ~ "\t";
            if( line.length > 0 )
                line = line[ 0 .. $ -1 ];
            return line;
        }

        Column opIndex( size_t index ){
            return _columns[index];
        }

        Column opIndex( string name ){
            bool    isSearching = true;
            size_t  index       = 0;
            Column  result      = null;
            while( isSearching ){
                if( _columns.length >= index )
                    isSearching = false;
                else if( _columns[index].name == name ){
                    isSearching = false;
                    result      = _columns[index];
                }
                else
                    index++;
            }
            return result;
        }
}


struct Column{
    private:
        Variant _value;
        string  _name;
    public:
        this( string  name ){
            _name   = name;
        }

        this( Variant value, string  name ){
            _value = value;
            _name  = name;
        }

        @property string name(){
            return _name;
        }

        @property void value( T )( T item ){
            _value = item;
        }

        @property Variant getValue(){
            return _value;
        }

        Variant opCall(){
            return _value;
        }

        string toString(){
            return  "%s: %s".format( name, _value );
        }

        @property T to(T)(){
                return _value.get!(T);
        }
}

@property string header(Row[] rows){
    string result;
    if( rows.length > 0 ){
        Row row = rows[0];
        foreach( column; row )
            result ~= column.name ~ "\t" ;
        result = result[0 .. $ - 1];
    }
    return result;
}
