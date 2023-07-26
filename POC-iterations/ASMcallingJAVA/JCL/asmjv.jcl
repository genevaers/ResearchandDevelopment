//NCBMR95 JOB (ACCT),'BUILD MR95 JAVA BITS',                            JOB22327
//            NOTIFY=&SYSUID.,
//            CLASS=A,
//            MSGLEVEL=(1,1),
//            TIME=(0,45),
//            MSGCLASS=X
//*
//*        SET HLQ=<YOUR-TSO-PREFIX>
//*        SET MLQ=GVBDEMO
//*
//****************************************************************
//*  ASSEMBLE GVBGO95 AND GVBJ2ENV MODULES
//****************************************************************
//ASMP1    PROC
//ASM      EXEC PGM=ASMA90,
// PARM=(NODECK,OBJECT,ADATA,'SYSPARM(RELEASE)','OPTABLE(ZS7)',
// 'PC(GEN),FLAG(NOALIGN),SECTALGN(256),GOFF,LIST(133)')
//*
//SYSIN    DD DISP=SHR,DSN=&LVL1..RTC&RTC..ASM(&MEMBER)
//*
//SYSLIB   DD DISP=SHR,DSN=&LVL1..RTC&RTC..MAC
//         DD DISP=SHR,DSN=SYS1.MACLIB
//         DD DISP=SHR,DSN=SYS1.MODGEN
//         DD DISP=SHR,DSN=CEE.SCEEMAC
//*
//SYSLIN   DD DSN=&LVL1..RTC&RTC..BTCHOBJ(&MEMBER),
//            DISP=SHR
//*
//SYSUT1   DD DSN=&&SYSUT1,
//            UNIT=SYSDA,
//            SPACE=(1024,(300,300),,,ROUND),
//            BUFNO=1
//*
//SYSADATA DD DISP=SHR,DSN=&LVL1..RTC&RTC..SYSADATA(&MEMBER)
//*
//SYSPRINT DD SYSOUT=*
//*YSPRINT DD DSN=&LVL1..RTC&RTC..LISTASM(&MEMBER),
//*           DISP=SHR
//*
//*       E X T R A C T   S T E P
//*
//EXTRACT  EXEC PGM=ASMLANGX,PARM='&MEMBER (ASM LOUD ERROR'
//* ARM='GVBXLEU (ASM LOUD ERROR'
//STEPLIB  DD   DISP=SHR,DSN=ASM.SASMMOD2
//SYSADATA DD   DISP=SHR,DSN=&LVL1..RTC&RTC..SYSADATA(&MEMBER)
//ASMLANGX DD   DISP=SHR,DSN=&LVL1..RTC&RTC..ASMLANGX
//*
//         PEND
//*
//ASMJGO95 EXEC ASMP1,MEMBER=GVBJGO95
//ASMJLENV EXEC ASMP1,MEMBER=GVBJ2ENV
//