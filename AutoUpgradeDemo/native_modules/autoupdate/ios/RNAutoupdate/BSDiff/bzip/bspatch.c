/*-
 * Copyright 2003-2005 Colin Percival
 * Copyright 2012 Matthew Endsley
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted providing that the following conditions 
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
//
//#include "bspatch.h"
//#include <bzlib.h>
//#include <stdlib.h>
//#include <stdint.h>
//#include <stdio.h>
//#include <string.h>
//#include <err.h>
//#include <unistd.h>
//#include <fcntl.h>
//
//static int64_t offtin(uint8_t *buf)
//{
//    int64_t y;
//
//    y=buf[7]&0x7F;
//    y=y*256;y+=buf[6];
//    y=y*256;y+=buf[5];
//    y=y*256;y+=buf[4];
//    y=y*256;y+=buf[3];
//    y=y*256;y+=buf[2];
//    y=y*256;y+=buf[1];
//    y=y*256;y+=buf[0];
//
//    if(buf[7]&0x80) y=-y;
//
//    return y;
//}
//
//int bspatch(const uint8_t* old, int64_t oldsize, uint8_t* new, int64_t newsize, struct bspatch_stream* stream)
//{
//    uint8_t buf[8];
//    int64_t oldpos,newpos;
//    int64_t ctrl[3];
//    int64_t i;
//
//    oldpos=0;newpos=0;
//    while(newpos<newsize) {
//        /* Read control data */
//        for(i=0;i<=2;i++) {
//            if (stream->read(stream, buf, 8))
//                return -1;
//            ctrl[i]=offtin(buf);
//        };
//
//        /* Sanity-check */
//        if(newpos+ctrl[0]>newsize)
//            return -1;
//
//        /* Read diff string */
//        if (stream->read(stream, new + newpos, ctrl[0]))
//            return -1;
//
//        /* Add old data to diff string */
//        for(i=0;i<ctrl[0];i++)
//            if((oldpos+i>=0) && (oldpos+i<oldsize))
//                new[newpos+i]+=old[oldpos+i];
//
//        /* Adjust pointers */
//        newpos+=ctrl[0];
//        oldpos+=ctrl[0];
//
//        /* Sanity-check */
//        if(newpos+ctrl[1]>newsize)
//            return -1;
//
//        /* Read extra string */
//        if (stream->read(stream, new + newpos, ctrl[1]))
//            return -1;
//
//        /* Adjust pointers */
//        newpos+=ctrl[1];
//        oldpos+=ctrl[2];
//    };
//
//    return 0;
//}
//
//static int bz2_read(const struct bspatch_stream* stream, void* buffer, int length)
//{
//    int n;
//    int bz2err;
//    BZFILE* bz2;
//
//    bz2 = (BZFILE*)stream->opaque;
//    n = BZ2_bzRead(&bz2err, bz2, buffer, length);
//    if (n != length)
//        return -1;
//
//    return 0;
//}
//
//int beginPatch(const char* oldfile, const char* newfile, const char* patchfile)
//{
//    FILE * f;
//    int fd;
//    int bz2err;
//    uint8_t header[32];
//    uint8_t *old, *new;
//    int64_t oldsize, newsize;
//    BZFILE* bz2;
//    struct bspatch_stream stream;
//
//    //    if(argc!=4) errx(1,"usage: %s oldfile newfile patchfile\n",argv[0]);
//
//    /* Open patch file */
//    if ((f = fopen(patchfile, "r")) == NULL) {
//        //        err(1, "fopen(%s)", patchfile);
//        return -1;
//    }
//
//    /* Read header */
//    if (fread(header, 1, 32, f) != 32) {
//        if (feof(f)) {
//            //            errx(1, "Corrupt patch\n");
//        }
//        //        err(1, "fread(%s)", patchfile);
//        return -1;
//    }
//
//    /* Check for appropriate magic */
//    if (memcmp(header, "ENDSLEY/BSDIFF43", 16) != 0) {
//        //        errx(1, "Corrupt patch\n");
//        return -1;
//    }
//
//    /* Read lengths from header */
//    newsize=offtin(header+16);
//    if(newsize<0) {
//        //        errx(1,"Corrupt patch\n");
//        return -1;
//    }
//
//    /* Close patch file and re-open it via libbzip2 at the right places */
//    if(((fd=open(oldfile,O_RDONLY,0))<0) ||
//       ((oldsize=lseek(fd,0,SEEK_END))==-1) ||
//       ((old=malloc(oldsize+1))==NULL) ||
//       (lseek(fd,0,SEEK_SET)!=0) ||
//       (read(fd,old,oldsize)!=oldsize) ||
//       (close(fd)==-1)) err(1,"%s",oldfile);
//    if((new=malloc(newsize+1))==NULL) err(1,NULL);
//
//    if (NULL == (bz2 = BZ2_bzReadOpen(&bz2err, f, 0, 1, NULL, 0))) {
//        //        errx(1, "BZ2_bzReadOpen, bz2err=%d", bz2err);
//        return -1;
//    }
//
//    stream.read = bz2_read;
//    stream.opaque = bz2;
//    if (bspatch(old, oldsize, new, newsize, &stream)) {
//        //        errx(1, "bspatch");
//        return -1;
//    }
//
//    /* Clean up the bzip2 reads */
//    BZ2_bzReadClose(&bz2err, bz2);
//    fclose(f);
//
//    /* Write the new file */
//    if(((fd=open(newfile,O_CREAT|O_TRUNC|O_WRONLY,0666))<0) ||
//       (write(fd,new,newsize)!=newsize) || (close(fd)==-1)) {
//        err(1,"%s",newfile);
//        return -1;
//    }
//    free(new);
//    free(old);
//    return 0;
//}

#include "bspatch.h"
#include <sys/cdefs.h>

#include <bzlib.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <err.h>
#include <unistd.h>
#include <fcntl.h>

typedef unsigned char u_char;

static off_t offtin(u_char *buf)
{
    off_t y;
    
    y=buf[7]&0x7F;
    y=y*256;y+=buf[6];
    y=y*256;y+=buf[5];
    y=y*256;y+=buf[4];
    y=y*256;y+=buf[3];
    y=y*256;y+=buf[2];
    y=y*256;y+=buf[1];
    y=y*256;y+=buf[0];
    
    if(buf[7]&0x80) y=-y;
    
    return y;
}

int beginPatch(const char* oldfile, const char* newfile, const char* patchfile)
{
    FILE * f, * cpf, * dpf, * epf;
    BZFILE * cpfbz2, * dpfbz2, * epfbz2;
    int cbz2err, dbz2err, ebz2err;
    int fd;
    ssize_t oldsize,newsize;
    ssize_t bzctrllen,bzdatalen;
    u_char header[32],buf[8];
    u_char *old, *new;
    off_t oldpos,newpos;
    off_t ctrl[3];
    off_t lenread;
    off_t i;
    
    //if(argc!=4) errx(1,"usage: %s oldfile newfile patchfile\n",argv[0]);
    
    /* Open patch file */
    if ((f = fopen(patchfile, "r")) == NULL) {
        //        err(1, "fopen(%s)", patchfile);
        return -1;
    }
    
    /*
     File format:
     0    8    "BSDIFF40"
     8    8    X
     16    8    Y
     24    8    sizeof(newfile)
     32    X    bzip2(control block)
     32+X    Y    bzip2(diff block)
     32+X+Y    ???    bzip2(extra block)
     with control block a set of triples (x,y,z) meaning "add x bytes
     from oldfile to x bytes from the diff block; copy y bytes from the
     extra block; seek forwards in oldfile by z bytes".
     */
    
    /* Read header */
    if (fread(header, 1, 32, f) < 32) {
        if (feof(f))
            errx(1, "Corrupt patch\n");
        return -1;
    }
    
    /* Check for appropriate magic */
    if (memcmp(header, "BSDIFF40", 8) != 0)
        errx(1, "Corrupt patch\n");
    
    /* Read lengths from header */
    bzctrllen=offtin(header+8);
    bzdatalen=offtin(header+16);
    newsize=offtin(header+24);
    if((bzctrllen<0) || (bzdatalen<0) || (newsize<0))
        errx(1,"Corrupt patch\n");
    
    /* Close patch file and re-open it via libbzip2 at the right places */
    if (fclose(f))
        return -1;
    if ((cpf = fopen(patchfile, "r")) == NULL)
        return -1;
    if (fseeko(cpf, 32, SEEK_SET))
        return -1;
    if ((cpfbz2 = BZ2_bzReadOpen(&cbz2err, cpf, 0, 0, NULL, 0)) == NULL)
        return -1;
    if ((dpf = fopen(patchfile, "r")) == NULL)
        return -1;
    if (fseeko(dpf, 32 + bzctrllen, SEEK_SET))
        return -1;
    if ((dpfbz2 = BZ2_bzReadOpen(&dbz2err, dpf, 0, 0, NULL, 0)) == NULL)
        return -1;
    if ((epf = fopen(patchfile, "r")) == NULL)
        return -1;
    if (fseeko(epf, 32 + bzctrllen + bzdatalen, SEEK_SET))
        return -1;
    if ((epfbz2 = BZ2_bzReadOpen(&ebz2err, epf, 0, 0, NULL, 0)) == NULL)
        return -1;
    
    if(((fd=open(oldfile,O_RDONLY,0))<0) ||
       ((oldsize=lseek(fd,0,SEEK_END))==-1) ||
       ((old=malloc(oldsize+1))==NULL) ||
       (lseek(fd,0,SEEK_SET)!=0) ||
       (read(fd,old,oldsize)!=oldsize) ||
       (close(fd)==-1)) err(1,"%s",oldfile);
    if((new=malloc(newsize+1))==NULL) err(1,NULL);
    
    oldpos=0;newpos=0;
    while(newpos<newsize) {
        /* Read control data */
        for(i=0;i<=2;i++) {
            lenread = BZ2_bzRead(&cbz2err, cpfbz2, buf, 8);
            if ((lenread < 8) || ((cbz2err != BZ_OK) &&
                                  (cbz2err != BZ_STREAM_END)))
                errx(1, "Corrupt patch\n");
            ctrl[i]=offtin(buf);
        };
        
        /* Sanity-check */
        if(newpos+ctrl[0]>newsize)
            errx(1,"Corrupt patch\n");
        
        /* Read diff string */
        lenread = BZ2_bzRead(&dbz2err, dpfbz2, new + newpos, ctrl[0]);
        if ((lenread < ctrl[0]) ||
            ((dbz2err != BZ_OK) && (dbz2err != BZ_STREAM_END)))
            errx(1, "Corrupt patch\n");
        
        /* Add old data to diff string */
        for(i=0;i<ctrl[0];i++)
            if((oldpos+i>=0) && (oldpos+i<oldsize))
                new[newpos+i]+=old[oldpos+i];
        
        /* Adjust pointers */
        newpos+=ctrl[0];
        oldpos+=ctrl[0];
        
        /* Sanity-check */
        if(newpos+ctrl[1]>newsize)
            errx(1,"Corrupt patch\n");
        
        /* Read extra string */
        lenread = BZ2_bzRead(&ebz2err, epfbz2, new + newpos, ctrl[1]);
        if ((lenread < ctrl[1]) ||
            ((ebz2err != BZ_OK) && (ebz2err != BZ_STREAM_END)))
            errx(1, "Corrupt patch\n");
        
        /* Adjust pointers */
        newpos+=ctrl[1];
        oldpos+=ctrl[2];
    };
    
    /* Clean up the bzip2 reads */
    BZ2_bzReadClose(&cbz2err, cpfbz2);
    BZ2_bzReadClose(&dbz2err, dpfbz2);
    BZ2_bzReadClose(&ebz2err, epfbz2);
    if (fclose(cpf) || fclose(dpf) || fclose(epf)) {
        err(1, "fclose(%s)", patchfile);
        return -1;
    }
    
    /* Write the new file */
    if(((fd=open(newfile,O_CREAT|O_TRUNC|O_WRONLY,0666))<0) ||
       (write(fd,new,newsize)!=newsize) || (close(fd)==-1)) {
        err(1,"%s",newfile);
        return -1;
    }
    
    free(new);
    free(old);
    
    return 0;
}
