module sqlite.loader;

version (Posix){
    import core.sys.posix.dlfcn;
}
else version( Windows ){
    import core.sys.windows.windows;
}

import std.string;

struct DynamicLib{
    private void* _handle;

    this(string name){
        version (Posix){
            _handle = dlopen(toStringz(name ~ ".so"), 0x00002);
        }
        else version (Windows){
            _handle = LoadLibraryA(toStringz(FindModule(name ~ ".dll")));
        }

        if (_handle is null){
            throw new Exception("Couldn't load " ~ name ~ ".so");
        }
    }

    this(string name, string versionLib){
        version (Posix){
            _handle = dlopen(toStringz(name ~ ".so." ~ versionLib), 0x00002);
        }
        else version (Windows){
            _handle = LoadLibraryA(toStringz(FindModule(name ~ ".dll." ~ versionLib)));
        }

        if (_handle is null){
            throw new Exception("Couldn't load " ~ name ~ ".so");
        }
    }

    ~this(){
        version (Posix){
            dlclose(_handle);
        }
        else version (Windows){
            FreeLibrary(_handle);
        }
    }

    string FindModule(string libFile){
        return libFile;
    }

    void LoadSymbol(T)(string name, ref T func){
        version(Posix){
            func = cast(T) dlsym(_handle, toStringz(name));
        }
        else version(Windows){
            func = cast(T) GetProcAddress(_handle, toStringz(name));
        }
    }


}
