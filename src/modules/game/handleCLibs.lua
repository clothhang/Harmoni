local sep = package.config:sub(1,1)
package.cpath = package.cpath .. string.format(";.%sclibs%s?.dll", sep, sep)
local os = love.system.getOS()
local ext = ({
    Windows = ".dll",
    Linux   = ".so",
    OSX     = ".dylib"
})[os] or ".dll"

local ffi = require("ffi")

local WIN_LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = 0x00001000
local WIN_LOAD_LIBRARY_SEARCH_USER_DIRS    = 0x00000400

if os == "Windows" then
    ffi.cdef[[
        int _putenv(const char *envstring);
        const char *getenv(const char *name);
        int SetDllDirectoryW(const wchar_t *lpPathName);
        void* AddDllDirectory(const wchar_t* NewDirectory);
        int SetDefaultDllDirectories(unsigned long DirectoryFlags);
    ]]
else
    ffi.cdef[[
        int setenv(const char *name, const char *value, int overwrite);
        const char *getenv(const char *name);
    ]]
end

local function toWide(str)
    local w = ffi.new("wchar_t[?]", #str + 1)
    for i = 1, #str do w[i - 1] = str:byte(i) end
    w[#str] = 0
    return w
end

local function getenv(name)
    local res = ffi.C.getenv(name)
    if res == nil then return nil end
    return ffi.string(res)
end

local save = love.filesystem.getSaveDirectory()
local clibs = save .. sep .. "clibs"

local CURRENT_DLL_LAYOUT_VERSION = "1.4"

local function copyToSave(src, dst)
    local data, err = love.filesystem.read("data", src)
    if not data then error("Failed to read " .. src .. ": " .. err) end
    assert(love.filesystem.write(dst, data))
end

local function setupCLibs()
    love.filesystem.createDirectory("clibs")

    local needUpdate = true
    if love.filesystem.getInfo("videoversion.txt") then
        local ver = love.filesystem.read("videoversion.txt")
        if ver:match("^(%S+)") == CURRENT_DLL_LAYOUT_VERSION then
            needUpdate = false
        end
    end

    if needUpdate then
        local arch = jit and jit.arch or (love.system.getProcessorCount() > 4 and "x64" or "x86")
        for _, file in ipairs(love.filesystem.getDirectoryItems("clibs/" .. os .. arch)) do
            copyToSave("clibs/" .. os .. arch .. "/" .. file, "clibs/" .. file)
        end
        love.filesystem.write("videoversion.txt", CURRENT_DLL_LAYOUT_VERSION .. "\n")
    end

    if not package.cpath:find(clibs, 1, true) then
        package.cpath = package.cpath .. ";" .. clibs .. sep .. "?.dll"
    end

    if os == "Windows" then
        ffi.C.SetDefaultDllDirectories(
            WIN_LOAD_LIBRARY_SEARCH_DEFAULT_DIRS + WIN_LOAD_LIBRARY_SEARCH_USER_DIRS
        )
        local cookie = ffi.C.AddDllDirectory(toWide(clibs))
        assert(cookie ~= nil, "AddDllDirectory failed")
        print("Updated PATH environment variable for DLLs.")
    end

    local base = love.filesystem.getCRequirePath()
    local newPaths = base .. ";clibs/??" .. ";" .. save .. "/clibs/??"
    love.filesystem.setCRequirePath(newPaths)
    print("Updated love.filesystem C require path.")

    local libname = "video"
    if os == "Linux" then libname = "libvideo" end
    local success, _DLL_Video = pcall(require, libname)
    if success then
        print("Successfully loaded video DLL.")
    else
        print("Warning: Could not load video DLL. Video playback disabled.")
        --print("Error message: " .. DLL_Video)
        DLL_Video = nil
    end
    DLL_Video = _DLL_Video
    if not DLL_Video or not DLL_Video.open then DLL_Video = nil end

    local ok, _video = pcall(require, "objects.game.shared.video")
    if ok then
        print("Video module loaded successfully.")
    else
        print("Warning: Failed to require video module: " .. video)
    end

    video = _video

    print("C Libraries setup complete.")
end

return {
    setupIfNeeded = setupCLibs
}
