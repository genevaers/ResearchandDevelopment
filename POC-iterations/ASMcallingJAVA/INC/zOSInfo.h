/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class zOSInfo */

#ifndef _Included_zOSInfo
#define _Included_zOSInfo
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     zOSInfo
 * Method:    showZos
 * Signature: (Ljava/lang/Int;Ljava/lang/String;Ljava/lang/String;Ljava/lang/jbyteArray;Ljava/lang/Int;)Ljava/lang/jbyteArray;
 */

typedef struct Genparm
{
    void* gpenva;
    void* gpfilea;
    void* gpstarta;
    void* gpeventa;
    void* gpextra;
    void* gpkeya;
    void* gpworka;
    void* gprtnca;
    void* gpblocka;
    long* gpblksiz;
 } Genparm;

typedef struct Genenv
{
    char thrdno[2];
    char phase[2];
    char view[4];
    char envva[4];
    char jstpct[4];
    char jstka[4];
    char prdatetime[16];
    char errorstuff[12];
    char pfcount[4];
    char thrdwa[4];
} Genenv;

typedef struct PassStruct
{
    char       func[8];
    char       opt[8];
    char       thread[10];
    char       flag1;
    char       flag2;
    char       spare[52];
    long       length1;
    long       length2;
    void*      addr1;
    void*      addr2;
    long       retcd;
    char       anchor[8];
    void*      thrdmem;
    struct Genparm genparms;
} PassStruct;

typedef struct Pass1Struct
{
    char*      message;
} Pass1Struct;

typedef struct Pass2Struct
{
    char       returnCD[8];
    char       reasonCD[8];
    union {
        char       classmethod[64];
        long       additions1;
        char       resultant[1];
    } u;
    char       gpphase[2];
    char       gpdatetime[16];
    char       gpstartupdata[32];
} Pass2Struct;

JNIEXPORT jbyteArray JNICALL Java_zOSInfo_showZos
  (JNIEnv *, jobject, jint, jstring, jstring, jbyteArray, jint);

#ifdef __cplusplus
}
#endif
#endif