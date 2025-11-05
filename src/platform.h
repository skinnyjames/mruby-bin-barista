#pragma once 

/* 
 * includes detection of the OS, compiler, architecture, language std and
 * creates appropriate #defines for those platforms + some runtime detection
 * functions. Here are the most important #defines:
 *
 * - PLATFORM_{WIN32|LINUX|MACOS}
 * - COMPILER_{GCC|CLANG|MINGW|MSVC|TCC}
 * - LANGUAGE_{C|CPP}
 * - STANDARD_{C89|C99|C11|C17|Cxx98|Cxx03|Cxx11|Cxx14|Cxx17|Cxx20}
 * - STANDARD_VERSION: Integer between 1989 and 2020
 *
 * - EXPORT: for export declaration, syntax: EXPORT void func()
 * - CDECL:  c calling convention, syntax: void CDECL func()
 * - EXT_C:   extern "C" to prevent C++ name mangling
 *
 * - thread_local: crossplatform thread_local specifier
 *
 * - BUILD_{DEBUG|RELEASE|CUSTOM}: detected build type
 *
 * - DO_PRAGMA: cross-platform #pragma's
 * - WARNING_TO_{ENABLE|ERROR|IGNORE}(flag,code): What to do with a warning
 * - {PUSH|POP}_WARNINGS(): Open/close a scope in which to enable/ignore/error warnings
 * - WARNING(msg) : Macro form of #warning "msg", can be used in other macros
 * - {PUSH|POP}_STRUCT_PACK(n): Open/close a scope in which all structs have alignment n
 *
 * - DEBUG_BREAK(): portable debug_break()
 * - ASSERT(expr): portable assert
 * - UNREACHABLE(msg, ...): for unreachable code
 * - UNIMPLEMENTED: for unimplemented code
 * - DEPRECATED: for declaring functions deprecated (TODO)
 * - STATIC_ASSERT(expr,msg): portable static_assert
 * - debug_running_under_debugger(): runtime debugger detection
 *
 * - OFFSET_OF(type,member): portable offsetof()
 * - TYPE_OF(e): portable typeof()/decltype() (except MSVC in C-mode)
 * - SAME_TYPE(a,b): checks if two variables are the same type (ignoring qualifiers)
 * - container_of(ptr, type, member): portable linux kernel-style container_of().
 *   Gets a pointer to the struct containing ptr as a member.
 * - ARRAY_COUNT(arr) : returns count of elements in array and 0 for pointers (decayed arrays)
 *
 * - u8,u32,u64,f32,f64,... typedefs. Can be turned off with PLATFORM_NO_TYPEDEFS
 * - numericals limits like U32_MAX, F32_MIN, etc. Can be turned off with PLATFORM_NO_TYPEDEFS
 */

/* os detection */
#if defined(_WIN32)
    #define PLATFORM_WIN32
#elif defined(__linux__) // || defined(__gnu_linux__)
    #define PLATFORM_LINUX
#elif defined(__APPLE__) && defined(__MACH__)
    #define PLATFORM_MACOS // NOTE: untested
#else
    #error "No supported platform (OS) detected."
# endif

#if defined(__EMSCRIPTEN__)
    #define PLATFORM_WEB // NOTE: untested
#endif

/* compiler detection */
#if defined(__GNUC__)
    #define COMPILER_GCC
    #ifdef __clang__ // NOTE clang also defines __GNUC__ since it implements the gcc extensions
        #define COMPILER_CLANG
        #undef COMPILER_GCC
    #endif
    #ifdef __MINGW32__ // NOTE mingw also defines __GNUC__
        #define COMPILER_MINGW
        #undef COMPILER_GCC
    #endif

#elif defined(__clang__) // NOTE for clang++ on windows
    #define COMPILER_CLANG
#elif defined(__TINYC__)
    #define COMPILER_TCC
#elif defined(_MSC_VER)
    #define COMPILER_MSVC
#else
    #error "No supported compiler detected."
#endif

/* architecture detection */
#if defined(_M_X64) || defined(__amd64__)
    #define ARCH_X64
#elif defined(__i386__) || defined(_M_IX86) || defined(__x86_64__)
    #define ARCH_X86
#elif defined(__arm__) || defined(_M_ARM)
    #define ARCH_ARM   // NOTE: untested  
#elif defined(__aarch64__)
    #define ARCH_ARM64 // NOTE: untested
#else
    #warning "Architecture not detected"
#endif

/* define export declarations for .dll & .so files */
#if defined(COMPILER_GCC)
    // NOTE GCC exports every symbol to the ELF by default, unless -fvisibility=hidden is specified
    #if __GNUC__ >= 4 // NOTE: taken from SDL
        #define EXPORT __attribute__((visibility("default")))
    #else
        #define EXPORT
    #endif
#elif defined(COMPILER_CLANG)
    #define EXPORT __attribute__((visibility("default")))
#elif defined(COMPILER_MSVC)
    #define EXPORT __declspec(dllexport)
#elif defined(COMPILER_MINGW)
    // NOTE apparently you can use both __attribute__() & __declspec() with mingw
    #define EXPORT __declspec(dllexport)
#elif defined(COMPILER_TCC) && defined(PLATFORM_WIN32)
    #define EXPORT __attribute__(dllexport)
#endif

/* define c calling convention macro */
// NOTE: untested
#if defined(COMPILER_MSVC)
    #define CDECL  __cdecl
#elif defined(COMPILER_GCC)
    //#define CDECL __attribute__((__cdecl__)) // NOTE this define can cause warnings
    #define CDECL
#elif defined(COMPILER_MINGW)
    // NOTE mingw doesn't seem to care if this is defined or not
    #define CDECL  __cdecl
#elif defined(COMPILER_CLANG)
    // TODO define CDECL for COMPILER_CLANG, break compilation in the meantime
    #define CDECL  not_defined
#elif defined(COMPILER_TCC)
    #define CDECL __attribute__(cdecl) // TODO untested
#endif

#if defined(__cplusplus)
    #define LANGUAGE_CPP

    #if defined(_MSVC_LANG)
        #define STANDARD_VERSION (_MSVC_LANG/100)
    #else
        #define STANDARD_VERSION (__cplusplus/100)
    #endif

    // NOTE: maybe we don't need this...
    #if   STANDARD_VERSION >= 1997 && STANDARD_VERSION < 2004
        // NOTE: __cplusplus == 199711 for -std=c++98/c++03 for both clang & gcc
        #define STANDARD_Cxx98
        #define STANDARD_Cxx03
    #elif STANDARD_VERSION >= 2011 && STANDARD_VERSION < 2012
        #define STANDARD_Cxx11
    #elif STANDARD_VERSION >= 2014 && STANDARD_VERSION < 2015
        #define STANDARD_Cxx14
    #elif STANDARD_VERSION >= 2017 && STANDARD_VERSION < 2018
        #define STANDARD_Cxx17
    #elif STANDARD_VERSION >= 2020 && STANDARD_VERSION < 2021
        #define STANDARD_Cxx20
    #else
        #warning "C++ standard not detected"
    #endif
#elif defined(__STDC_VERSION__)
    #define LANGUAGE_C

    #define STANDARD_VERSION (__STDC_VERSION__/100)

    #if   __STDC_VERSION__ >= 198901L && __STDC_VERSION__ < 199000L
        #define STANDARD_C89 // NOTE: not supported
    #elif __STDC_VERSION__ >= 199901L && __STDC_VERSION__ < 200000L
        #define STANDARD_C99
    #elif __STDC_VERSION__ >= 201101L && __STDC_VERSION__ < 201200L
        #define STANDARD_C11
    #elif __STDC_VERSION__ >= 201701L && __STDC_VERSION__ < 201800L
        #define STANDARD_C17
    //#elif __STDC_VERSION__ >= 2013... && __STDC_VERSION__ < 201800L // TODO
    //    #define STANDARD_C23
    #else
        #warning "C standard not detected"
    #endif
#else
    #warning "Language not detected (C or C++)"
#endif

#ifdef LANGUAGE_CPP
    #define EXT_C extern "C"  /* NOTE: untested */
#endif

/* thread local storage macro */
#if defined(LANGUAGE_CPP)
  #if STANDARD_VERSION < 2011 /* keyword in C++11 */
    #if defined(COMPILER_MSVC)
        #define thread_local __declspec(thread)
    #else
        #define thread_local __thread
    #endif
  #endif
#endif
#if defined(LANGUAGE_C)
  #if STANDARD_VERSION < 2023 /* keyword in C23 */
    #if defined(COMPILER_MSVC)
        #define thread_local __declspec(thread)
    #else
        #define thread_local __thread
    #endif
  #endif
#endif

/* functions / strings for runtime detection */
#define PLATFORMS(X)        \
    X(UNKNOWN, "Unknown")   \
    X(LINUX,   "Linux")     \
    X(WIN32,   "Windows")   \
    X(MACOS,   "MacOS")     \
    X(COUNT,   "Invalid")

#define OPERATING_SYSTEM_ENUM(e, ...) OPERATING_SYSTEM_##e,
typedef enum operating_system_e
{
    PLATFORMS(OPERATING_SYSTEM_ENUM)
} operating_system_e;

#define COMPILERS(X)      \
    X(UNKNOWN, "Unknown") \
    X(CLANG,   "Clang")   \
    X(GCC,     "GCC")     \
    X(MINGW,   "MinGW")   \
    X(MSVC,    "MSVC")    \
    X(TCC,     "TCC")     \
    X(COUNT,   "Invalid")

#define COMPILER_ENUM(e, ...) COMPILER_TYPE_##e, // NOTE: _TYPE_ to not clash with the (more important) macro
typedef enum compiler_e
{
    COMPILERS(COMPILER_ENUM)
} compiler_e;

inline static operating_system_e platform_detect_os()
{
    operating_system_e os = OPERATING_SYSTEM_UNKNOWN;
#if   defined(PLATFORM_WIN32)
    os = OPERATING_SYSTEM_WIN32;
#elif defined(PLATFORM_LINUX)
    os = OPERATING_SYSTEM_LINUX;
#elif defined(PLATFORM_MACOS)
    os = OPERATING_SYSTEM_MACOS;
#endif
    return os;
}

#define OPERATING_SYSTEM_STRING(e, str, ...) case OPERATING_SYSTEM_##e: { string = str; } break;
inline static const char* platform_os_string(operating_system_e os)
{
    const char* string = "Unknown";
    switch (os)
    {
        PLATFORMS(OPERATING_SYSTEM_STRING);
        default: { string = "Invalid"; } break; // UNREACHABLE
    }
    return string;
}

inline static compiler_e platform_detect_compiler()
{
    compiler_e compiler = COMPILER_TYPE_UNKNOWN;
#if   defined(COMPILER_CLANG)
    compiler = COMPILER_TYPE_CLANG;
#elif defined(COMPILER_GCC)
    compiler = COMPILER_TYPE_GCC;
#elif defined(COMPILER_MINGW)
    compiler = COMPILER_TYPE_MINGW;
#elif defined(COMPILER_MSVC)
    compiler = COMPILER_TYPE_MSVC;
#elif defined(COMPILER_TCC)
    compiler = COMPILER_TYPE_TCC;
#endif
    return compiler;
}

#define COMPILER_STRING(e, str, ...) case COMPILER_TYPE_##e: { string = str; } break;
inline static const char* platform_compiler_string(compiler_e compiler)
{
    const char* string = "Unknown";
    switch (compiler)
    {
        COMPILERS(COMPILER_STRING);
        default: { string = "Invalid"; } break; // UNREACHABLE
    }
    return string;
}

#if defined(ARCH_X64)
  #define ARCHITECTURE_STRING "x64"
#elif defined(ARCH_X86)
  #define ARCHITECTURE_STRING "x86"
#elif defined(ARCH_ARM)
  #define ARCHITECTURE_STRING "ARM"
#endif

#if   defined(STANDARD_C89)
  #define C_STANDARD_STRING "C89"
#elif defined(STANDARD_C99)
  #define C_STANDARD_STRING "C99"
#elif defined(STANDARD_C11)
  #define C_STANDARD_STRING "C11"
#elif defined(STANDARD_C17)
  #define C_STANDARD_STRING "C17"
#elif defined(STANDARD_Cxx98)
  #define C_STANDARD_STRING "C++98"
#elif defined(STANDARD_Cxx03)
  #define C_STANDARD_STRING "C++03"
#elif defined(STANDARD_Cxx11)
  #define C_STANDARD_STRING "C++11"
#elif defined(STANDARD_Cxx14)
  #define C_STANDARD_STRING "C++14"
#elif defined(STANDARD_Cxx17)
  #define C_STANDARD_STRING "C++17"
#elif defined(STANDARD_Cxx20)
  #define C_STANDARD_STRING "C++20"
#endif

/* determine build type */
#if !defined(BUILD_DEBUG) && !defined(BUILD_RELEASE) && !defined(BUILD_CUSTOM)
    // if not set by -DBUILD_*, we try to figure out whether to build DEBUG/RELEASE
    // via conventional macros set by IDEs/compilers/etc.
    #if defined(NDEBUG) || defined(__OPTIMIZE__)
        #define BUILD_RELEASE
    #elif defined(DEBUG) || defined(_DEBUG)
        #define BUILD_DEBUG
    #else
        #define BUILD_DEBUG // default to debug if all else fails
    #endif
#endif

#if defined(BUILD_DEBUG)
  #define BUILD_TYPE_STRING "DEBUG"
#elif defined(BUILD_RELEASE)
  #define BUILD_TYPE_STRING "RELEASE"
#elif defined(BUILD_CUSTOM)
  #define BUILD_TYPE_STRING "CUSTOM"
#else
  #error "No build type set or detected."
#endif

/* cross-platform #pragma's */
// MSVC syntax: #pragma warning( disable : 4507 34; once : 4385; error : 164 )
// MSVC keywords:
//   default
//   disable
//   error
//   once
//   suppress (disables warning only for next line)
// GCC syntax: #pragma GCC diagnostic warning "-Wname"
// GCC keywords:
//   warning
//   error
//   ignored

/* Example usage: */
//      PUSH_WARNINGS()
//      WARNING_TO_IGNORE("-Wshadow", 6244)
//      WARNING_TO_IGNORE("-Wshadow", 6246)
//      int a = 0;
//      {
//              int a = 0;
//      }
//      POP_WARNINGS()
//
//      PUSH_STRUCT_PACK(1)
//      struct tightly_packed {
//         int   a; //    4B
//         char  b; // +  1B
//      }
//      ASSERT(sizeof(tightly_packed) == 5);
//      POP_STRUCT_PACK()
#if defined(COMPILER_MSVC) && !defined(COMPILER_CLANG)
    #define DO_PRAGMA(x) __pragma(x)

    #define WARNING_TO_ENABLE(flag,code) DO_PRAGMA(warning(default : code))
    #define WARNING_TO_ERROR(flag,code)  DO_PRAGMA(warning(error   : code))
    #define WARNING_TO_IGNORE(flag,code) DO_PRAGMA(warning(disable : code))
    #define PUSH_WARNINGS() DO_PRAGMA(warning(push))
    #define POP_WARNINGS()  DO_PRAGMA(warning(pop))

    #define WARNING(msg)    DO_PRAGMA(message(msg))

    #define PUSH_STRUCT_PACK(n) DO_PRAGMA(pack(push,n))
    #define POP_STRUCT_PACK()   DO_PRAGMA(pack(pop))
#elif !defined(COMPILER_TCC)
    #define DO_PRAGMA(x) _Pragma (#x)
    #define WARNING_TO_ENABLE(flag,code) DO_PRAGMA(GCC diagnostic warning flag)
    #define WARNING_TO_ERROR(flag,code)  DO_PRAGMA(GCC diagnostic error   flag)
    #define WARNING_TO_IGNORE(flag,code) DO_PRAGMA(GCC diagnostic ignored flag)

    #define PUSH_WARNINGS() DO_PRAGMA(GCC diagnostic push)
    #define POP_WARNINGS()  DO_PRAGMA(GCC diagnostic pop)

    // NOTE: to not show "expanded from macro.." in gcc: -ftrack-macro-expansion=0 -fno-diagnostics-show-caret
    #define WARNING(msg) DO_PRAGMA(GCC warning msg)

    #define PUSH_STRUCT_PACK(n) DO_PRAGMA(pack(push,n))
    #define POP_STRUCT_PACK()   DO_PRAGMA(pack(pop))
#else
    #define DO_PRAGMA(x)
    #define WARNING_TO_ENABLE(flag,code)
    #define WARNING_TO_ERROR(flag,code)
    #define WARNING_TO_IGNORE(flag,code)

    #define PUSH_WARNINGS()
    #define POP_WARNINGS()

    #define WARNING(msg)

    #define PUSH_STRUCT_PACK(n)
    #define POP_STRUCT_PACK()
#endif

/* asserts */
#ifdef COMPILER_MINGW
    #define _POSIX // needed for mingw to include SIGTRAP
#endif

#include <stdio.h>  // for fprintf, stderr TODO maybe let user provide a PRINT macro

// NOTE way to check for builtins: __has_builtin(__builtin_debugtrap)

// here a list of ways to implement a DEBUG_BREAK macro and on what OS+compiler they work
// see https://github.com/scottt/debugbreak for more info
//   __builtin_debugtrap();              linux: clang(++)                   windows: clang-cl.exe clang(++)
//   __builtin_trap();                   linux: clang(++) gcc(++) mingw(++) windows: clang(++) clang-cl.exe
//   #include <signal.h> raise(SIGTRAP); linux: clang(++) gcc(++) mingw(++) windows: none
//   DebugBreak()                        linux: none                        windows: cl.exe clang-cl.exe
//   __debugbreak()                      linux: none                        windows: cl.exe clang-cl.exe clang(++)
//   __asm__ volatile("int $0x03");      trap instruction, x86 specific
#ifdef COMPILER_MSVC
    #define DEBUG_BREAK() __debugbreak()
#else
    #if defined(ARCH_X86) || defined(ARCH_X64)
        #define DEBUG_BREAK() __asm__ volatile("int $0x03")
    #else
        #warning "No DEBUG_BREAK() defined for this architecture."
    #endif
#endif

// NOTE: __func__ seems to be supported everywhere (alternative in case: __FUNCTION__)
#define _ASSERT_STRING "Assert failed for '%s' in file '%s', function: '%s' at line '%d'\n"
#define ASSERT(expr)                                                      \
if (expr) { }                                                             \
else                                                                      \
{                                                                         \
    fprintf(stderr, _ASSERT_STRING, #expr, __FILE__, __func__, __LINE__); \
    DEBUG_BREAK();                                                        \
}

// TODO try to use __builtin_unreachable
#define UNREACHABLE(msg, ...) do { fprintf(stderr,msg,##__VA_ARGS__); ASSERT(0); } while (0)

#define UNIMPLEMENTED UNREACHABLE("Call to unimplemented function %s", __FUNCTION__)

/* TODO compile-time warning for deprecated functions. Usage: DEPRECATED int my_func() { } */
#if defined(LANGUAGE_CPP)
  /* works with GCC, G++, CLANG++, MSVC++, CLANG++.exe */
  #define DEPRECATED(msg) [[deprecated(msg)]]
#elif defined(LANGUAGE_C) && !defined(COMPILER_MSVC)
  /* works with GCC, G++, CLANG++, CLANG, CLANG.exe, CLANG++.exe */
  #define DEPRECATED(msg) __attribute__((error(msg)))
#else
  /* no equivalent when compiling ".c" files with msvc */
  #define DEPRECATED WARNING("no DEPRECATED macro available")
#endif

/* static_assert */
#if defined(LANGUAGE_CPP) && STANDARD_VERSION >= 2011
    #define STATIC_ASSERT(expr, msg) static_assert(expr, msg) /* C++11 built-in static_assert */
#elif defined(LANGUAGE_C) && STANDARD_VERSION >= 2011
    #define STATIC_ASSERT(expr, msg) _Static_assert(expr, msg)
#else
    // portable static_assert, but message string is lost
    #define STATIC_ASSERT(expr, msg) typedef char static_assertion[(expr)?1:-1]
#endif

/* debugger runtime detection */
#if defined(BUILD_DEBUG)
    #if defined(PLATFORM_WIN32)
        //#include <debugapi.h>
        #include <windows.h>
        static int debug_running_under_debugger()
        {
            return IsDebuggerPresent();
        }
    #else
        #include <sys/ptrace.h>
        static int debug_running_under_debugger()
        {
            static int debugger_detected;
            static int debugger_present = 0;
            if (!debugger_detected)
            {
                debugger_detected = 1;
                debugger_present = 0;//(ptrace(PTRACE_TRACEME, 0, 0, 0) == -1);
            }
            return debugger_present;
        }
    #endif
#else
    /* NOTE we assume we don't run under a debugger when not built with debug information */
    static int debug_running_under_debugger() { return 0; }
#endif

/* memory macros */

/* OFFSET_OF for struct members */
#if !defined(COMPILER_MSVC) && !defined(COMPILER_TCC)
    #define OFFSET_OF(type, member) __builtin_offsetof(type, member)
#else
    #define OFFSET_OF(s,m) ((size_t)&(((s*)0)->m))
#endif

/* TYPE_OF macro for all compilers except MSVC in C-mode */
#if defined(LANGUAGE_CPP)
  #define TYPE_OF(e) decltype(e)
#elif !defined(COMPILER_MSVC)
  /* NOTE: non standard gcc extension, but works everywhere except MSVC w/ C */
  #define TYPE_OF(e) __typeof__(e)
#else
  #undef TYPE_OF
  #define TYPE_OF(e) STATIC_ASSERT(0, "TYPE_OF macro doesn't work w/ MSVC in C-mode");
#endif

/* SAME_TYPE and container_of macro for all compilers (except MSVC in C-mode) */
#if defined(LANGUAGE_CPP)
  #if STANDARD_VERSION > 2011 /* NOTE: actually works with C++11 but error with clang-cl: deduced return types are a C++14 extension... */
    #include <type_traits>
    #define SAME_TYPE(a, b) std::is_same<TYPE_OF((a)),TYPE_OF((b))>::value
    /* NOTE: static assert is not identical to the C version */
    #define container_of(ptr, type, member)  \
          ((type *)(((char*) ptr) - OFFSET_OF(type, member)));  \
          STATIC_ASSERT(SAME_TYPE(*(ptr), ((type *)0)->member), "Pointer type mismatch in container_of macro")
  #endif
#elif !defined(COMPILER_MSVC) /* no SAME_TYPE under msvc in C-mode */
  /* Are two types/vars the same type (ignoring qualifiers)? */
  #define SAME_TYPE(a, b) __builtin_types_compatible_p(TYPE_OF(a), TYPE_OF(b))

  #define container_of(ptr, type, member)  \
        ((type *)(((char*) ptr) - OFFSET_OF(type, member))); \
        STATIC_ASSERT(SAME_TYPE(*(ptr), ((type *)0)->member) || SAME_TYPE(*(ptr), void), "pointer type mismatch")
#else
  #define container_of(ptr, type, member)  \
        ((type *)(((char*) ptr) - OFFSET_OF(type, member)));
#endif

/* macros to check if array is real array (and not just a pointer, i.e. decayed array) */
#define IS_INDEXABLE(arg) (sizeof(arg[0]))
#define IS_ARRAY(arg) (IS_INDEXABLE(arg) && (((void *) &arg) == ((void *) arg)))

/* shouldn't work for decayed arrays */
#define ARRAY_COUNT(arr) (IS_ARRAY(arr) ? (sizeof(arr)/sizeof(arr[0])) : 0)

#ifndef PLATFORM_NO_TYPEDEFS
    /* u32, f32, ... types */
    #include <stdint.h>
    typedef int8_t    i8;
    typedef int16_t   i16;
    typedef int32_t   i32;
    typedef int64_t   i64;

    typedef int8_t    s8;
    typedef int16_t   s16;
    typedef int32_t   s32;
    typedef int64_t   s64;

    typedef uint8_t   u8;
    typedef uint16_t  u16;
    typedef uint32_t  u32;
    typedef uint64_t  u64;

    typedef int8_t    b8;
    typedef int16_t   b16;
    typedef int32_t   b32;
    typedef int64_t   b64;

    typedef float     f32;
    typedef double    f64;

    // typedef uintptr_t umm; /* stand-in for void* */

    /* numerical limits */
    #include <float.h>  // for FLT_MAX/MIN
    #define U8_MIN  0
    #define U8_MAX  255
    #define U16_MIN 0
    #define U16_MAX 65535
    #define U32_MIN 0
    #define U32_MAX 4294967295
    #define U64_MIN 0
    #define U64_MAX 18446744073709551615
    #define I32_MIN ((i32) 0x80000000)
    #define I32_MAX ((i32) 0x7FFFFFFF)
    #define S32_MIN ((s32) 0x80000000)
    #define S32_MAX ((s32) 0x7FFFFFFF)
    #define F32_MIN -FLT_MAX
    #define F32_MAX FLT_MAX
#endif
