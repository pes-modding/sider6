-- memory library for Win64

local ffi = require('ffi')
local C = ffi.C

ffi.cdef [[
bool VirtualProtect(void *p, size_t len, uint32_t newprot, uint32_t *oldprot);
int memcmp(void *dst, void *src, size_t len);
void sprintf(char *dst, char *fmt, ...);

typedef uint8_t BYTE;
typedef uint16_t WORD;
typedef uint32_t LONG;
typedef uint32_t DWORD;

typedef struct _IMAGE_DOS_HEADER
{
     WORD e_magic;
     WORD e_cblp;
     WORD e_cp;
     WORD e_crlc;
     WORD e_cparhdr;
     WORD e_minalloc;
     WORD e_maxalloc;
     WORD e_ss;
     WORD e_sp;
     WORD e_csum;
     WORD e_ip;
     WORD e_cs;
     WORD e_lfarlc;
     WORD e_ovno;
     WORD e_res[4];
     WORD e_oemid;
     WORD e_oeminfo;
     WORD e_res2[10];
     LONG e_lfanew;
} IMAGE_DOS_HEADER;

typedef struct _IMAGE_FILE_HEADER {
  WORD  Machine;
  WORD  NumberOfSections;
  DWORD TimeDateStamp;
  DWORD PointerToSymbolTable;
  DWORD NumberOfSymbols;
  WORD  SizeOfOptionalHeader;
  WORD  Characteristics;
} IMAGE_FILE_HEADER;

typedef struct _IMAGE_NT_HEADERS64 {
  DWORD                   Signature;
  IMAGE_FILE_HEADER       FileHeader;
  BYTE                    OptionalHeader;
} IMAGE_NT_HEADERS;

typedef struct _IMAGE_SECTION_HEADER {
  BYTE  Name[8];
  union {
    DWORD PhysicalAddress;
    DWORD VirtualSize;
  } Misc;
  DWORD VirtualAddress;
  DWORD SizeOfRawData;
  DWORD PointerToRawData;
  DWORD PointerToRelocations;
  DWORD PointerToLinenumbers;
  WORD  NumberOfRelocations;
  WORD  NumberOfLinenumbers;
  DWORD Characteristics;
} IMAGE_SECTION_HEADER;

IMAGE_DOS_HEADER *GetModuleHandleW(char *name);

]]

local m = {}

local PAGE_EXECUTE_READWRITE = 0x40
local PAGE_EXECUTE_WRITECOPY = 0x80

function m.search(s, from, to)
    local p = ffi.cast('char*', from)
    local q = ffi.cast('char*', to)
    local res = sider_kmp_search(s, p, q)
    if res then
        return ffi.cast('char*', res)
    end
end

function m.read(addr, len)
    local p = ffi.cast('char*', addr)
    return ffi.string(p, len)
end

function m.write(addr, s)
    local p = ffi.cast('char*', addr)
    local oldprot = ffi.new('uint32_t[1]',{});
    local len = #s
    if not C.VirtualProtect(p, len, PAGE_EXECUTE_READWRITE, oldprot) then
        return error(string.format('VirtualProtect failed for %s - %s memory range',
            m.hex(p), m.hex(p+len)))
    end
    ffi.copy(p, s, len)
end

local format_sizes = {
    i64 = 8, u64 = 8,
    i32 = 4, u32 = 4, i = 4, ui = 4,
    i16 = 2, u16 = 2, s = 2, us = 2,
    f = 4, d = 8,
}

function m.pack(fmt, value)
    local len = format_sizes[fmt]
    if len == nil then
        return error(string.format('Unsupported pack format: %s', fmt))
    end
    local arr
    if fmt == 'f' then
        arr = ffi.new('float[1]',{ffi.cast('float', value)})
    elseif fmt == 'd' then
        arr = ffi.new('double[1]',{ffi.cast('double', value)})
    else
        arr = ffi.new('char*[1]',{ffi.cast('char*', value)})
    end
    return ffi.string(ffi.cast('char*', arr), len)
end

function m.unpack(fmt, s)
    if fmt == 'i64' then
        return ffi.cast('int64_t*', s)[0]
    elseif fmt == 'u64' then
        return ffi.cast('uint64_t*', s)[0]
    elseif fmt == 'i32' or fmt == 'i' then
        return tonumber(ffi.cast('int32_t*', s)[0])
    elseif fmt == 'u32' or fmt == 'ui' then
        return tonumber(ffi.cast('uint32_t*', s)[0])
    elseif fmt == 'i16' or fmt == 's' then
        return tonumber(ffi.cast('int16_t*', s)[0])
    elseif fmt == 'u16' or fmt == 'us' then
        return tonumber(ffi.cast('uint16_t*', s)[0])
    elseif fmt == 'f' then
        return tonumber(ffi.cast('float*', s)[0])
    elseif fmt == 'd' then
        return tonumber(ffi.cast('double*', s)[0])
    end
    return error(string.format('Unsupported unpack format: %s', fmt))
end

function m.hex(value)
    if type(value) == 'string' then
        local s, count = string.gsub(value, '.', function(c)
            return string.format('%02x', string.byte(c))
        end)
        return s
    elseif type(value) == 'cdata' or type(value) == 'userdata' then
        local buf = ffi.new('char[32]',{});
        C.sprintf(buf, ffi.cast('char*', '0x%llx'), ffi.cast('uint64_t',value));
        return ffi.string(buf)
    else
        return string.format('0x%x', value)
    end
end

function m.get_process_info()
    local dos_header = C.GetModuleHandleW(nil)
    local p = ffi.cast('char*',dos_header) + dos_header.e_lfanew
    local nth = ffi.cast('IMAGE_NT_HEADERS*',p)
    local fh = ffi.cast('IMAGE_FILE_HEADER*',nth.FileHeader)
    local sec = ffi.cast('IMAGE_SECTION_HEADER*',
        ffi.cast('char*',fh) + ffi.sizeof(fh[0]) + fh.SizeOfOptionalHeader)
    local t = {}
    local base = ffi.cast('char*',dos_header)
    for i=0,fh.NumberOfSections-1 do
        local s = sec + i
        local name = ffi.string(s.Name, 8)
        name = string.match(name, '[%w._]+')
        local start = base + s.VirtualAddress
        local finish = start + s.Misc.VirtualSize
        t[#t+1] = {
            name = name,
            start = start,
            finish = finish,
            image_section_header = s,
        }
    end
    local pinfo = {}
    pinfo.base = base
    pinfo.sections = t
    return pinfo
end

function m.search_process(s)
    local pinfo = m.get_process_info()
    for i,section in ipairs(pinfo.sections) do
        local addr = m.search(s, section.start, section.finish)
        if addr then
            return addr, section
        end
    end
end

-- for backward compatibility
m.tohexstring = m.hex
        
return m

