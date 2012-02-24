module sqlite.c;


shared extern (C){
    struct      sqlite3;
    struct      sqlite3_stmt;
    struct      sqlite3_value;
    alias long  sqlite3_int64;
    alias ulong sqlite3_uint64;

    //sqlite3_openType sqlite3_open;
    int function (const(char)*, sqlite3**)  sqlite3_open;
    int function (sqlite3 *) sqlite3_close;

    int function (sqlite3*, const(char)*, size_t, sqlite3_stmt**, char**) sqlite3_prepare_v2;
    //sqlite3_prepare_v2Type sqlite3_prepare_v2;

    immutable(char)*    function (sqlite3*)                                                         sqlite3_errmsg;
    immutable(void)*    function (sqlite3*)                                                         sqlite3_errmsg16;
    immutable(char)*    function (const(char)*,...)                                                 sqlite3_mprintf;
    int                 function (sqlite3_stmt*)                                                    sqlite3_step;
    int                 function (sqlite3_stmt*)                                                    sqlite3_finalize;
    int                 function (sqlite3_stmt*)                                                    sqlite3_reset;
    int                 function (sqlite3*, const(char)*, int function (void*,int, const(char*)*,const(char*)*), void*, const(char*)* ) sqlite3_exec;
    int                 function (sqlite3*)                                                         sqlite3_changes;
    int                 function (sqlite3_stmt*)                                                    sqlite3_column_count;
    immutable(char)*    function (sqlite3_stmt*, int)                                               sqlite3_column_text;
    immutable(void)*    function (sqlite3_stmt*, int)                                               sqlite3_column_text16;
    immutable(char)*    function (sqlite3_stmt*, int)                                               sqlite3_column_name;
    immutable(void)*    function (sqlite3_stmt*, int)                                               sqlite3_column_blob;
    int                 function (sqlite3_stmt*, int)                                               sqlite3_column_bytes;
    int                 function (sqlite3_stmt*, int)                                               sqlite3_column_bytes16;
    double              function (sqlite3_stmt*, int)                                               sqlite3_column_double;
    int                 function (sqlite3_stmt*, int)                                               sqlite3_column_int;
    sqlite3_int64       function (sqlite3_stmt*, int)                                               sqlite3_column_int64;
    int                 function (sqlite3_stmt*, int)                                               sqlite3_column_type;
    sqlite3_value*      function (sqlite3_stmt*, int)                                               sqlite3_column_value;
    int                 function (sqlite3_stmt*, int, const void*, int, void function (void*) )     sqlite3_bind_blob;
    int                 function (sqlite3_stmt*, int, double)                                       sqlite3_bind_double;
    int                 function (sqlite3_stmt*, int, int)                                          sqlite3_bind_int;
    int                 function (sqlite3_stmt*, int, sqlite3_int64)                                sqlite3_bind_int64;
    int                 function (sqlite3_stmt*, int)                                               sqlite3_bind_null;
    int                 function (sqlite3_stmt*, int, const char*, int, void function (void*))      sqlite3_bind_text;
    int                 function (sqlite3_stmt*, int, const void*, int, void function (void*))      sqlite3_bind_text16;
    int                 function (sqlite3_stmt*, int, const sqlite3_value*)                         sqlite3_bind_value;
    int                 function (sqlite3_stmt*, int, int)                                          sqlite3_bind_zeroblob;
    int                 function (sqlite3_stmt*)                                                    sqlite3_clear_bindings;
    const(char)*        function (sqlite3_stmt*,int)                                                sqlite3_column_database_name;
    const(void)*        function (sqlite3_stmt*,int)                                                sqlite3_column_database_name16;
    const(char)*        function (sqlite3_stmt*,int)                                                sqlite3_column_table_name;
    const (void)*       function (sqlite3_stmt*,int)                                                sqlite3_column_table_name16;
    const (char)*       function (sqlite3_stmt*,int)                                                sqlite3_column_origin_name;
    const (void)*       function (sqlite3_stmt*,int)                                                sqlite3_column_origin_name16;
}

enum
    SQLITE_OK           = 0;   /** Successful result */
/* beginning-of-error-codes */
/// Ditto
enum
    SQLITE_ERROR        = 1,   /** SQL error or missing database */
    SQLITE_INTERNAL     = 2,   /** Internal logic error in SQLite */
    SQLITE_PERM         = 3,   /** Access permission denied */
    SQLITE_ABORT        = 4,   /** Callback routine requested an abort */
    SQLITE_BUSY         = 5,   /** The database file is locked */
    SQLITE_LOCKED       = 6,   /** A table in the database is locked */
    SQLITE_NOMEM        = 7,   /** A malloc() failed */
    SQLITE_READONLY     = 8,   /** Attempt to write a readonly database */
    SQLITE_INTERRUPT    = 9,   /** Operation terminated by sqlite3_interrupt()*/
    SQLITE_IOERR       = 10,   /** Some kind of disk I/O error occurred */
    SQLITE_CORRUPT     = 11,   /** The database disk image is malformed */
    SQLITE_NOTFOUND    = 12,   /** Unknown opcode in sqlite3_file_control() */
    SQLITE_FULL        = 13,   /** Insertion failed because database is full */
    SQLITE_CANTOPEN    = 14,   /** Unable to open the database file */
    SQLITE_PROTOCOL    = 15,   /** Database lock protocol error */
    SQLITE_EMPTY       = 16,   /** Database is empty */
    SQLITE_SCHEMA      = 17,   /** The database schema changed */
    SQLITE_TOOBIG      = 18,   /** String or BLOB exceeds size limit */
    SQLITE_CONSTRAINT  = 19,   /** Abort due to constraint violation */
    SQLITE_MISMATCH    = 20,   /** Data type mismatch */
    SQLITE_MISUSE      = 21,   /** Library used incorrectly */
    SQLITE_NOLFS       = 22,   /** Uses OS features not supported on host */
    SQLITE_AUTH        = 23,   /** Authorization denied */
    SQLITE_FORMAT      = 24,   /** Auxiliary database format error */
    SQLITE_RANGE       = 25,   /** 2nd parameter to sqlite3_bind out of range */
    SQLITE_NOTADB      = 26,   /** File opened that is not a database file */
    SQLITE_ROW         = 100,  /** sqlite3_step() has another row ready */
    SQLITE_DONE        = 101;  /** sqlite3_step() has finished executing */
/* end-of-error-codes */

/**
** CAPI3REF: Extended Result Codes
*/
enum
    SQLITE_IOERR_READ              = (SQLITE_IOERR | (1<<8)),
    SQLITE_IOERR_SHORT_READ        = (SQLITE_IOERR | (2<<8)),
    SQLITE_IOERR_WRITE             = (SQLITE_IOERR | (3<<8)),
    SQLITE_IOERR_FSYNC             = (SQLITE_IOERR | (4<<8)),
    SQLITE_IOERR_DIR_FSYNC         = (SQLITE_IOERR | (5<<8)),
    SQLITE_IOERR_TRUNCATE          = (SQLITE_IOERR | (6<<8)),
    SQLITE_IOERR_FSTAT             = (SQLITE_IOERR | (7<<8)),
    SQLITE_IOERR_UNLOCK            = (SQLITE_IOERR | (8<<8)),
    SQLITE_IOERR_RDLOCK            = (SQLITE_IOERR | (9<<8)),
    SQLITE_IOERR_DELETE            = (SQLITE_IOERR | (10<<8)),
    SQLITE_IOERR_BLOCKED           = (SQLITE_IOERR | (11<<8)),
    SQLITE_IOERR_NOMEM             = (SQLITE_IOERR | (12<<8)),
    SQLITE_IOERR_ACCESS            = (SQLITE_IOERR | (13<<8)),
    SQLITE_IOERR_CHECKRESERVEDLOCK = (SQLITE_IOERR | (14<<8)),
    SQLITE_IOERR_LOCK              = (SQLITE_IOERR | (15<<8)),
    SQLITE_IOERR_CLOSE             = (SQLITE_IOERR | (16<<8)),
    SQLITE_IOERR_DIR_CLOSE         = (SQLITE_IOERR | (17<<8)),
    SQLITE_IOERR_SHMOPEN           = (SQLITE_IOERR | (18<<8)),
    SQLITE_IOERR_SHMSIZE           = (SQLITE_IOERR | (19<<8)),
    SQLITE_IOERR_SHMLOCK           = (SQLITE_IOERR | (20<<8)),
    SQLITE_LOCKED_SHAREDCACHE      = (SQLITE_LOCKED |  (1<<8)),
    SQLITE_BUSY_RECOVERY           = (SQLITE_BUSY   |  (1<<8)),
    SQLITE_CANTOPEN_NOTEMPDIR      = (SQLITE_CANTOPEN | (1<<8));

/**
** CAPI3REF: Flags For File Open Operations
*/
enum
    SQLITE_OPEN_READONLY         = 0x00000001,  /** Ok for sqlite3_open_v2() */
    SQLITE_OPEN_READWRITE        = 0x00000002,  /** Ok for sqlite3_open_v2() */
    SQLITE_OPEN_CREATE           = 0x00000004,  /** Ok for sqlite3_open_v2() */
    SQLITE_OPEN_DELETEONCLOSE    = 0x00000008,  /** VFS only */
    SQLITE_OPEN_EXCLUSIVE        = 0x00000010,  /** VFS only */
    SQLITE_OPEN_AUTOPROXY        = 0x00000020,  /** VFS only */
    SQLITE_OPEN_MAIN_DB          = 0x00000100,  /** VFS only */
    SQLITE_OPEN_TEMP_DB          = 0x00000200,  /** VFS only */
    SQLITE_OPEN_TRANSIENT_DB     = 0x00000400,  /** VFS only */
    SQLITE_OPEN_MAIN_JOURNAL     = 0x00000800,  /** VFS only */
    SQLITE_OPEN_TEMP_JOURNAL     = 0x00001000,  /** VFS only */
    SQLITE_OPEN_SUBJOURNAL       = 0x00002000,  /** VFS only */
    SQLITE_OPEN_MASTER_JOURNAL   = 0x00004000,  /** VFS only */
    SQLITE_OPEN_NOMUTEX          = 0x00008000,  /** Ok for sqlite3_open_v2() */
    SQLITE_OPEN_FULLMUTEX        = 0x00010000,  /** Ok for sqlite3_open_v2() */
    SQLITE_OPEN_SHAREDCACHE      = 0x00020000,  /** Ok for sqlite3_open_v2() */
    SQLITE_OPEN_PRIVATECACHE     = 0x00040000,  /** Ok for sqlite3_open_v2() */
    SQLITE_OPEN_WAL              = 0x00080000;  /** VFS only */

/**
** CAPI3REF: Device Characteristics
*/
enum
    SQLITE_IOCAP_ATOMIC                 = 0x00000001,
    SQLITE_IOCAP_ATOMIC512              = 0x00000002,
    SQLITE_IOCAP_ATOMIC1K               = 0x00000004,
    SQLITE_IOCAP_ATOMIC2K               = 0x00000008,
    SQLITE_IOCAP_ATOMIC4K               = 0x00000010,
    SQLITE_IOCAP_ATOMIC8K               = 0x00000020,
    SQLITE_IOCAP_ATOMIC16K              = 0x00000040,
    SQLITE_IOCAP_ATOMIC32K              = 0x00000080,
    SQLITE_IOCAP_ATOMIC64K              = 0x00000100,
    SQLITE_IOCAP_SAFE_APPEND            = 0x00000200,
    SQLITE_IOCAP_SEQUENTIAL             = 0x00000400,
    SQLITE_IOCAP_UNDELETABLE_WHEN_OPEN  = 0x00000800;

/**
** CAPI3REF: File Locking Levels
*/
enum
    SQLITE_LOCK_NONE          = 0,
    SQLITE_LOCK_SHARED        = 1,
    SQLITE_LOCK_RESERVED      = 2,
    SQLITE_LOCK_PENDING       = 3,
    SQLITE_LOCK_EXCLUSIVE     = 4;

/**
** CAPI3REF: Synchronization Type Flags
*/
enum
    SQLITE_SYNC_NORMAL        = 0x00002,
    SQLITE_SYNC_FULL          = 0x00003,
    SQLITE_SYNC_DATAONLY      = 0x00010;

/**
** CAPI3REF: Fundamental Datatypes
*/
enum
    SQLITE_INTEGER  = 1,
    SQLITE_FLOAT    = 2,
    SQLITE_BLOB     = 4,
    SQLITE_NULL     = 5,
    SQLITE3_TEXT    = 3;
