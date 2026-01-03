#include "pharovm/pharo.h"
#include <stdarg.h>

#ifdef _WIN32

#else
#include <sys/time.h>
#endif

#ifndef PATH_MAX
#define PATH_MAX MAX_PATH
#endif

char * GetAttributeString(sqInt id);

#if defined(DEBUG) && DEBUG
static int max_error_level = 4;
#else
static int max_error_level = 1;
#endif
/*
 * This function set the logLevel to use in the VM
 *
 * LOG_NONE 		0
 * LOG_ERROR 		1
 * LOG_WARN 		2
 * LOG_INFO 		3
 * LOG_DEBUG		4
 * LOG_TRACE		5
 *
 */
EXPORT(void) logLevel(int value){
	max_error_level = value;
}

EXPORT(int) getLogLevel(){
	return max_error_level;
}

EXPORT(int) isLogDebug(){
	return getLogLevel() >= LOG_DEBUG;
}

void error(char *errorMessage){
    logError(errorMessage);
	logError("Aborting the execution of the VM");
	printStatusAfterError();
    abort();
}

static const char* severityName[5] = {"ERROR", "WARN", "INFO", "DEBUG", "TRACE"};

EXPORT(void) logAssert(const char* fileName, const char* functionName, int line, char* msg){
	logMessage(LOG_WARN, fileName, functionName, line, msg);
}

void logMessageFromErrno(int level, const char* msg, const char* fileName, const char* functionName, int line){
	char buffer[1024+1];

#ifdef WIN32
	strerror_s(buffer, 1024, errno);
#else
	strerror_r(errno, buffer, 1024);
#endif

	logMessage(level, fileName, functionName, line, "%s: %s", msg, buffer);
}

FILE* getStreamForLevel(int level){
	if(level <= LOG_ERROR){
		return stderr;
	}else{
		return stdout;
	}
}


EXPORT(void) logMessage(int level, const char* fileName, const char* functionName, int line, ...){
	char * format;
	char timestamp[20];

	FILE* outputStream;

	outputStream = getStreamForLevel(level);


	if(level > max_error_level){
		return;
	}

	time_t now = time(NULL);

#if defined(_WIN32)
	struct tm ltime_struct;
	localtime_s(&ltime_struct, &now);
	struct tm* ltime = &ltime_struct;
#else
	struct tm* ltime = localtime(&now);
#endif

	strftime(timestamp, 20, "%Y-%m-%d %H:%M:%S", ltime);

	//Printing the header.
	// Ex: [DEBUG] 2017-11-14 21:57:53,661 functionName (filename:line) - This is a debug log message.

	fprintf_impl(outputStream, "[%-5s] %s.%03d %s (%s:%d):", severityName[level - 1], timestamp, 0 /* milliseconds */ , functionName, fileName, line);

	//Printint the message from the var_args.
	va_list list;
	va_start(list, line);

	format = va_arg(list, char*);
	vfprintf_impl(outputStream, format, list);

	va_end(list);

	int formatLength = strlen(format);

	if(formatLength == 0 || format[formatLength - 1] != '\n'){
		fprintf_impl(outputStream,"\n");
	}

	fflush(outputStream);
}

void getCrashDumpFilenameInto(char *buf)
{
#ifdef _WIN32
	/*
	* Unsafe version of deprecated strcpy for compatibility
	* - does not check error code
	* - does use count as the size of the destination buffer
	*/
	strcat_s(buf, PATH_MAX + 1, "crash.dmp");
#else
	strcat(buf, "crash.dmp");
#endif
}

char *getVersionInfo()
{
#if STACKVM
  extern char *__interpBuildInfo;
# define INTERP_BUILD __interpBuildInfo
# if COGVM
  extern char *__cogitBuildInfo;
# endif
#else
# define INTERP_BUILD interpreterVersion
#endif
  extern char *revisionAsString();

#define BUFFER_SIZE 4096

  char *info= (char *)malloc(BUFFER_SIZE);
  info[0]= '\0';

#if defined(NDEBUG)
# define BuildVariant "Production"
#elif DEBUGVM
# define BuildVariant "Debug"
# else
# define BuildVariant "Assert"
#endif

#if ITIMER_HEARTBEAT
# define HBID " ITHB"
#else
# define HBID
#endif

  snprintf(info, BUFFER_SIZE, VM_BUILD_STRING " " COMPILER_VERSION " [" BuildVariant HBID " VM]\nBuilt from: %s\n With:%s\n Revision: " VM_BUILD_SOURCE_STRING, INTERP_BUILD, GetAttributeString(1008));
  return info;
}

/***
 *  This SHOULD be rewritten passing the FILE* as a parameter.
 */

static FILE* outputStream = NULL;

void
vm_setVMOutputStream(FILE * stream){
	fflush(outputStream);
	outputStream = stream;
}

int
vm_printf(const char * format, ... ){

	va_list list;
	va_start(list, format);

	if(outputStream == NULL){
		outputStream = stdout;
	}

	int returnValue = vfprintf_impl(outputStream, format, list);

	va_end(list);

	return returnValue;
}

// https://sourceware.org/gdb/current/onlinedocs/gdb.html/Declarations.html#Declarations
typedef enum
{
  JIT_NOACTION = 0,
  JIT_REGISTER_FN,
  JIT_UNREGISTER_FN
} jit_actions_t;

struct jit_code_entry
{
  struct jit_code_entry *next_entry;
  struct jit_code_entry *prev_entry;
  const char *symfile_addr;
  uint64_t symfile_size;
};

struct jit_descriptor
{
  uint32_t version;
  /* This type should be jit_actions_t, but we use uint32_t
     to be explicit about the bitwidth.  */
  uint32_t action_flag;
  struct jit_code_entry *relevant_entry;
  struct jit_code_entry *first_entry;
};

/* GDB puts a breakpoint in this function.  */
void __attribute__((noinline)) __jit_debug_register_code() { };

struct pharo_jit_entry {
  char magic[8];
  uintptr_t code_zone_start;
  uintptr_t code_zone_end;
};

struct pharo_jit_entry pharo_entry = {
  .magic = "PHAROOOP",
  .code_zone_start = 0,
  .code_zone_end = 0,
};

struct jit_code_entry gdb_entry = {
  .next_entry = NULL,
  .prev_entry = NULL,
  .symfile_addr = (void*)&pharo_entry,
  .symfile_size = sizeof(pharo_entry),
};

/* Make sure to specify the version statically, because the
   debugger may check the version before we can set it.  */
struct jit_descriptor __jit_debug_descriptor = {
  .version = 1,
  .action_flag = JIT_NOACTION,
  .relevant_entry = &gdb_entry,
  .first_entry = &gdb_entry,
};

void notifyCodeChanges(void* code_zone_start, void* code_zone_end) {
  // FIXME! Run some simple hash to rule out unneeded notifications!
  //static int times = 0;
  //printf("CODE_CHANGES! (%p, %p, %ld) %d\n", code_zone_start, code_zone_end, code_zone_end - code_zone_start, times++);

  if (__jit_debug_descriptor.action_flag == JIT_REGISTER_FN) {
    __jit_debug_descriptor.action_flag = JIT_UNREGISTER_FN;
    __jit_debug_register_code();
  }
  __jit_debug_descriptor.action_flag = JIT_REGISTER_FN;
  pharo_entry.code_zone_start = code_zone_start;
  pharo_entry.code_zone_end = code_zone_end;
  __jit_debug_register_code();
}
