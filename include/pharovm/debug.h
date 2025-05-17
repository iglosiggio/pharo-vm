#pragma once

#include "exportDefinition.h"

#ifndef  DEBUG
# define DEBUG	0
#endif

#define LOG_NONE 		0
#define LOG_ERROR 		1
#define LOG_WARN 		2
#define LOG_INFO 		3
#define LOG_DEBUG		4
#define LOG_TRACE		5

EXPORT(void) logLevel(int level);
EXPORT(int) getLogLevel();

EXPORT(void) logMessage(int level, const char* fileName, const char* functionName, int line, ...);
EXPORT(void) logAssert(const char* fileName, const char* functionName, int line, char* msg);

EXPORT(void) registerCurrentThreadToHandleExceptions();
EXPORT(void) installErrorHandlers();
EXPORT(int) isLogDebug();

//This variable is set externally by CMAKE
#ifndef SOURCE_PATH_SIZE
# define SOURCE_PATH_SIZE 0
#endif

//FILENAME gives only the filename, as __FILE__ gives all the path
#define __FILENAME__ ((char*)__FILE__ + SOURCE_PATH_SIZE)

#define logTrace(...)	logMessage(LOG_TRACE, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logDebug(...)	logMessage(LOG_DEBUG, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logInfo(...)	logMessage(LOG_INFO, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logWarn(...)	logMessage(LOG_WARN, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logError(...)	logMessage(LOG_ERROR, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)

#define LOG_SIZEOF(expr) logDebug("sizeof("#expr"): %ld", sizeof(expr))

#define logErrorFromErrno(msg) 	logMessageFromErrno(LOG_ERROR, msg, __FILENAME__, __FUNCTION__, __LINE__);
#define logWarnFromErrno(msg) 	logMessageFromErrno(LOG_WARN, msg, __FILENAME__, __FUNCTION__, __LINE__);
#define logDebugFromErrno(msg) 	logMessageFromErrno(LOG_DEBUG, msg, __FILENAME__, __FUNCTION__, __LINE__);

EXPORT(void) logMessageFromErrno(int level, const char* msg, const char* fileName, const char* functionName, int line);

void error(char* aMessage);


#include <stdio.h>

int vm_printf(const char * format, ... );
void vm_setVMOutputStream(FILE * stream);

// Internal implementations of fprintf and vfprintf, so the different OS can reimplement if needed

EXPORT(int) fprintf_impl(FILE * stream, const char * format, ... );
EXPORT(int) vfprintf_impl(FILE * stream, const char * format, va_list arg);

EXPORT(void) printStatusAfterError();

#ifdef _WIN32

EXPORT(char*) formatMessageFromErrorCode(int errorCode);
EXPORT(void) logErrorFromGetLastError(char* msg);

EXPORT(char*) getErrorLogNameInto(char* nameBuffer, int maxSize);
EXPORT(FILE*) getErrorLogFile();

EXPORT(void) openDebugWindow(void* hwnd);
EXPORT(void) notifyDebugWindow();

#endif

// The event is a 64bit thing:
//   Inline Cache ID  | 40 bits
//   Current state    |  4 bits
//   Next state       |  4 bits
//   Data             | 16 bits
//
// States:
//   0 - NONEXISTENT
//   1 - UNLINKED
//   2 - POLYMORPHIC
//   3 - MEGAMORPHIC
//         Megamorphic ICs are executed immediately.
//         Next event indicates the new ID
// Data (for POLYMORPHIC):
//   Data represents the detailed new state for polymorphic inline caches.
//   When transitioning _to_ a polymorphic state it represents the initial
//   state. If you need the previous state you should look at the previous
//   event for the same ID. If has the following structure:
//     Two bits for each entry specifying its state (12 total):
//       0 - UNLINKED
//       1 - LINKED
//       2 - LINKED (Interpreted)
//       3 - LINKED (MNU)
//     Three bits specifying the where the table was hit:
//       0 - Cache miss
//       1 - First entry
//       2 - Second entry
//       3 - Third entry
//       4 - Fourth entry
//       5 - Fifth entry
//       6 - Sixth entry
//       7 - There is no method activation associated with this event
//     A final, reserved bit
void ics_event(unsigned long long event);
