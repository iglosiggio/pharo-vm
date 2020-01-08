#pragma once

#ifndef __imageAccess_h__
#define __imageAccess_h__

#include <stdlib.h>

#ifndef EXPORT
#define EXPORT(type) type
#endif

#define sqImageFile void*
#define squeakFileOffsetType size_t

typedef struct {
	sqInt (*imageFileClose)(sqImageFile f);

	sqImageFile (*imageFileOpen)(char* fileName, char *mode);
	long int (*imageFilePosition)(sqImageFile f);
	size_t (*imageFileRead)(void * ptr, size_t sz, size_t count, sqImageFile f);

	int (*imageFileSeek)(sqImageFile f, long int pos);
	int (*imageFileSeekEnd)(sqImageFile f, long int pos);
	size_t (*imageFileWrite)(void* ptr, size_t sz, size_t count, sqImageFile f);

} _FileAccessHandler;

typedef _FileAccessHandler FileAccessHandler;

EXPORT(FileAccessHandler*) currentFileAccessHandler();
void setFileAccessHandler(FileAccessHandler* aFileAccessHandler);

#define sqImageFileClose(f) 				currentFileAccessHandler()->imageFileClose(f)
#define sqImageFileOpen(fileName, mode)		currentFileAccessHandler()->imageFileOpen(fileName, mode)
#define sqImageFilePosition(f)				currentFileAccessHandler()->imageFilePosition(f)

#define sqImageFileRead(ptr, sz, count, f)  currentFileAccessHandler()->imageFileRead(ptr, sz, count, f)

#define sqImageFileSeek(f, pos)				currentFileAccessHandler()->imageFileSeek(f, pos)
#define sqImageFileSeekEnd(f, pos)			currentFileAccessHandler()->imageFileSeekEnd(f, pos)
#define sqImageFileWrite(ptr, sz, count, f)	currentFileAccessHandler()->imageFileWrite(ptr, sz, count, f)

#define sqImageFileStartLocation(fileRef, fileName, size)  0

#endif
