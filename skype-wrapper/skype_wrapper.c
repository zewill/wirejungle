/*
	Copyright 2010 Ami Chayun
	
	A wrapper to prevent loading 32-bit version of libpulse.so.0 in 64-bit Debian Squeeze. Used to allow Skype to work
	
	This file is free software; you can redistribute it and/or modify
	it under the terms of either the GNU General Public License version 2
	or the GNU Lesser General Public License version 2.1, both as
	published by the Free Software Foundation.
*/
#define _GNU_SOURCE
#include <dlfcn.h>

#include <stdio.h>
#include <string.h>

static void init (void) __attribute__ ((constructor));
void *(*next_dlopen)(const char *, int);

static void init (void)
{
    next_dlopen = dlsym(RTLD_NEXT, "dlopen");
}
void *dlopen(const char *filename, int flag)
{
    if (strcmp("libpulse.so.0", filename) == 0) {
        fprintf(stderr, "Preventing libpulse.so.0 from being loaded\n");
        return NULL;
    }
    return next_dlopen(filename, flag);
}
