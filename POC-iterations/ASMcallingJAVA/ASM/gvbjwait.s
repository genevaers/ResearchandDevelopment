         TITLE    'WAIT FOR REQUEST FROM GVBMR95 OR TERMINATION '
***********************************************************************
*
* (c) Copyright IBM Corporation 2023.
*     Copyright Contributors to the GenevaERS Project.
* SPDX-License-Identifier: Apache-2.0
*
***********************************************************************
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
*   or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
***********************************************************************
*
*   This module is called by the GvbJavaDaemon to wait on events
*   to communicate with assembler/3GL/etc code executing in separate
*   threads in the same address space, i.e. GVBMR95.
*
***********************************************************************
         IHASAVER DSECT=YES,SAVER=YES,SAVF4SA=YES,SAVF5SA=YES,TITLE=NO
*
         YREGS
*
*        COPY  GVBJDSCT
*
*        DYNAMIC WORK AREA
*
DYNAREA  DSECT
*
SAVEAREA DC    18F'0'
SAVER13  DS    D
*
         DS    0F
OUTDCB   DS    XL(OUTFILEL)    REENTRANT DCB AND DCBE AREAS
*
WKPRINT  DS    XL131           PRINT LINE
         DS    XL1
         DS   0F
WKREENT  DS    XL256           REENTRANT WORKAREA/PARMLIST
WKDBLWK  DS    XL08            DOUBLE WORK WORKAREA
WKDDNAME DS    CL8
WKRETC   DS    F
GVBMR95E DS    A
WKTOKNRC DS    A                  NAME/TOKEN  SERVICES RETURN CODE
WKTOKNAM DS    XL16               TOKEN NAME
WKTOKN   DS   0XL16               TOKEN VALUE
WKTOKNCTT DS   A                  A(CTT)
         DS    A
         DS    A
         DS    A
WKECBLST DS    A                  ADDRESS OF ECB LIST TO WAIT ON
WKECB1   DS    F
WKECB2   DS    F
WKECB3   DS    F
WKECB4   DS    F
WKECBNUM DS    H                  Number in list
WKECBLSZ DS    H
WKENTIDX DS    A
         DS    A
         DS    0F
DYNLEN   EQU   *-DYNAREA                 DYNAMIC AREA LENGTH
*
*        COMMUNICATIONS TENSOR TABLE DSECTS
*
CTTAREA  DSECT
CTTEYE   DS    CL8
CTTACTR  DS    A               ADDR CTRAREA
CTTNUME  DS    H               NUMBER OF ENTRIES
CTTACTIV DS    X
         DS    X
CTTTECB  DS    F               TERMINATION ECB
CTTGECB  DS    F               GO ECB
CTTGECB2 DS    F               Acknowledge GO
         DS    XL4
CTTLEN   EQU   *-CTTAREA
*
*
CTRAREA  DSECT
CTRECB1  DS    F               ECB JAVA WORKER WAITS ON
CTRECB2  DS    F               ECB ASM  WORKER WAITS ON
CTRCSWRD DS    F               CS CONTROL WORD
CTRREQ   DS    CL4             REQUEST FUNCTION
CTRACLSS DS    D               ADDRESS OF CLASS FIELD (A32) 
CTRAMETH DS    D               ADDRESS OF METHOD FIELD (A32)
CTRLENIN DS    D               LENGTH INPUT AREA
CTRLENOUT DS   D               LENGTH OUTPUT AREA
CTRMEMIN DS    D               ADDR INPUT AREA
CTRMEMOUT DS   D               ADDR OUTPUT AREA
CTRTHRDN DS    H
         DS    XL2
CTRUR70W DS    XL4             Pointer to GVBUR70 workarea
         DS    XL8
CTRLEN   EQU   *-CTRAREA
*
*
PARMSTR  DSECT
PAFUN    DS    CL8
PAOPT    DS    CL8
PACLASS  DS    CL32           
PAMETHOD DS    CL32
PALEN1   DS    D
PALEN2   DS    D
PAADDR1  DS    D
PAADDR2  DS    D
PARETC   DS    D
PAANCHR  DS    D
PARMLEN  EQU   *-PARMSTR
*
*
GVBJWAIT RMODE 24
GVBJWAIT AMODE 31
*
GVBJWAIT CSECT
*
*        ENTRY LINKAGE
*
         STMG  R14,R12,SAVF4SAG64RS14-SAVF4SA(R13)
         LLGTR R12,R15                   ESTABLISH ...
         USING GVBJWAIT,R12              ... ADDRESSABILITY
*
         sam64
         sysstate amode64=YES
         LGR   R9,R1                     => Parmstr
         USING PARMSTR,R9
         LGH   R2,PAOPT+4                Directions to ECB's for WAIT
         LG    R4,PAANCHR                Maybe we have this already ?
         sysstate amode64=NO
         sam31
*
         GETMAIN R,LV=DYNLEN             GET DYNAMIC STORAGE
         LR    R11,R1                    MOVE GETMAINED ADDRESS TO R11
         USING DYNAREA,11                ADDRESSABILITY TO DSECT
         STG   R13,SAVER13               SAVE CALLER SAVE AREA ADDRESS
         LAY   R15,SAVEAREA              GET ADDRESS OF OWN SAVE AREA
         STG   R15,SAVF4SANEXT-SAVF4SA(,R13) STORE IN CALLER SAVE AREA
         LLGTR R13,R15                   GET ADDRESS OF OWN SAVE AREA
         ST    R2,WKENTIDX               Directions for ECB(s)
*
*      OPEN MESSAGE FILE
         J     MAIN_096
         LA    R14,OUTFILE               COPY MODEL   DCB
D1       USING IHADCB,OUTDCB
         MVC   OUTDCB(OUTFILEL),0(R14)
         LAY   R0,OUTDCB                 SET  DCBE ADDRESS IN  DCB
         AGHI  R0,OUTFILE0
         STY   R0,D1.DCBDCBE
*
         LAY   R2,OUTDCB
         MVC   WKREENT(8),OPENPARM
         OPEN  ((R2),(EXTEND)),MODE=31,MF=(E,WKREENT)
         TM    48(R2),X'10'              SUCCESSFULLY OPENED  ??
         JO    MAIN_096                  YES - BYPASS ABEND
         WTO 'GVBJWAIT: DDPRINT OPEN FAILED'
         MVC   WKRETC,=F'16'
         J     DONEDONE
*
***********************************************************************
*  FIND GLOBAL NAME/TOKEN AREA                                        *
***********************************************************************
*
MAIN_096 EQU   *
         LTR   R4,R4
         JP    MAIN_142
         MVC   WKTOKNAM+0(8),GENEVA
         MVC   WKTOKNAM+8(8),TKNNAME
         CALL  IEANTRT,(TOKNLVL2,WKTOKNAM,WKTOKN,WKTOKNRC),            X
               MF=(E,WKREENT)
         LTGF  R15,WKTOKNRC       SUCCESSFUL  ???
         JZ    MAIN_140
         WTO 'GVBJWAIT: COMMUNICATIONS TENSOR TABLE NOT LOCATED'
         MVC   WKRETC,=F'8'
         J     DONE
*
MAIN_140 EQU   *
         LLGT  R4,WKTOKNCTT
*        wto 'gvbjwait: had to use token services'
MAIN_142 EQU   *
         USING CTTAREA,R4
         CLC   CTTEYE,CTTEYEB
         JE    MAIN_114
         WTO 'GVBJWAIT: COMMUNICATIONS TENSOR TABLE DOES NOT MATCH'
         MVC   WKRETC,=F'12'
         J     DONE
*
*        ALLOCATE TABLE for REQUEST communication: CTRAREA
*
MAIN_114 EQU   *
**       WTO 'GVBJWAIT: COMMUNICATIONS TENSOR TABLE LOCATED'
         LLGT  R5,CTTACTR * * *<
         USING CTRAREA,R5
*
* OBTAIN ECBLIST ARRAY
*
         LH    R0,CTTNUME        Number request entry ECB's
         AGHI  R0,2                plus TERM and GO ECB's
         STH   R0,WKECBNUM
*
         LA    R0,4              LENGTH OF ECB ADDRESS
         LLGTR R0,R0
         MH    R0,WKECBNUM       TIMES NUMBER LIST ELEMENTS NEEDED
         STH   R0,WKECBLSZ
         GETMAIN RU,LV=(0),LOC=(ANY)
         ST    R1,WKECBLST       CONNECT TO ECBLIST
*
         LR    R0,R1             CLEAR STORAGE
         LA    R1,4              ELEMENT SIZE IN LIST
         LLGTR R1,R1
         MH    R1,WKECBNUM       TIMES NUMBER LIST ELEMENTS NEEDED
         XR    R14,R14
         XR    R15,R15
         MVCL  R0,R14
*
* DETERMINE WHICH ECB's to WAIT ON
*
**       WTO 'GVBJWAIT: DETERMINE WHICH ECB'
*
         J     MAIN_116
         USING CTTAREA,R4
         MVC   WKPRINT,SPACES
         MVC   WKPRINT(10),=CL10'GVBJWAIT: '
         MVC   WKPRINT+10(28),=CL28'WAIT ON ECB with directions '
         LLGT  R1,WKENTIDX
         AHI   R1,1              Add one as index starts -1
         SLL   R1,2
         LAY   R15,OPTTABLE
         AR    R15,R1
         MVC   WKPRINT+38(4),0(R15)
         LA    R2,OUTDCB
         LA    R0,WKPRINT
         PUT   (R2),(R0)
*
MAIN_116 EQU   *
         ICM   R2,B'1111',WKENTIDX
         JM    A0130
         JZ    A0140
*
** *     WTO 'GVBJWAIT: WAITING FOR REQUEST OR TERMINATION'
**       CLI   CTTACTIV,X'FF'
**       JNE   A0160
         LTR   R5,R5
         JZ    A0170
         BCTR  R2,0              Minus 1 as index starts at 1
         MH    R2,=Y(CTRLEN)     Offset required
         AR    R5,R2
*
         L     R1,WKECBLST       ASSIGN ECBLIST
         LA    R0,CTRECB1
         ST    R0,0(,R1)
         OI    0(R1),X'80'
         J     A0180
*
A0130    EQU   *
         WTO 'GVBJWAIT: WAITING FOR TERM'
         L     R1,WKECBLST       ASSIGN ECBLIST
         LA    R0,CTTTECB
         ST    R0,0(,R1)
         OI    0(R1),X'80'
         J     A0180
*
A0140    EQU   *
         WTO 'GVBJWAIT: WAITING FOR GO95 OR TERM'
         L     R1,WKECBLST       ASSIGN ECBLIST
         LA    R0,CTTTECB
         ST    R0,0(,R1)
         LA    R0,CTTGECB
         ST    R0,4(,R1)
         OI    4(R1),X'80'
         J     A0180
*
A0160    EQU   *
         WTO 'GVBJWAIT: TABLE NO LONGER ACTIVE'
         MVC   WKRETC,=F'20'
         J     MAIN_200
*
A0170    EQU   *
         WTO 'GVBJWAIT: TABLE NOT YET ACTIVE'
         MVC   WKRETC,=F'20'
         J     MAIN_200
*
*        WAIT FOR SOMETHING TO DO OR END TO COME
*
A0180    EQU   *
*        WTO 'GVBJWAIT: ABOUT TO WAIT'
         LLGT  R1,WKECBLST
         WAIT  1,ECBLIST=(1)
*
*        WTO 'GVBJWAIT: BACK FROM WAIT'
*
* FIND OUT WHICH ECB POSTED US
*
         TM    CTTTECB,X'40'
         JO    A0022
         TM    CTTGECB,X'40'
         JO    A0020
         TM    CTRECB1,X'40'
         JO    A0024
         WTO 'GVBJWAIT: NOT POSTED BY ANY ECB'
         MVC   WKRETC,=F'20'
         J     DONE
*
A0020    EQU   *
         XC    CTTGECB,CTTGECB   Clear ECB
         sam64
         sysstate amode64=YES
         LGH   R0,CTTNUME         Return number threads here for now
         LG    R1,PAADDR2         Return buffer. Use first 8 bytes
         STG   R0,16(,R1)         Give number of threads to Java (FD)
         sysstate amode64=NO
         sam31
         WTO 'GVBJWAIT: POSTED BY GO ECB'
         MVC   WKRETC,=F'6'
         J     MAIN_200
*
A0022    EQU   *
         MVI   CTTACTIV,X'00'
         XC    CTTTECB,CTTTECB   Don't clear ECB ||||||||||||||||||||
         WTO 'GVBJWAIT: Posted by termination ECB and request table set+
                inactive'
         MVC   WKRETC,=F'2'
         J     MAIN_200
*
A0024    EQU   *
         XC    CTRECB1,CTRECB1    Clear ECB
         CLI   CTTACTIV,X'FF'     IS REQUEST TABLE STILL ACTIVE ?
         JE    A0025              YES, GO
         WTO 'GVBJWAIT: WAITING FOR REQUESTS BUT GOT TERMINATION'
         MVC   WKRETC,=F'2'
         J     MAIN_200
*
A0025    EQU   *
*        WTO 'GVBJWAIT: POSTED BY REQUEST ECB'
*        Put data into "return" buffer"
         sam64
         sysstate amode64=YES
         LG    R14,PAADDR2
         CLC   PALEN2,CTRLENOUT
         JNL   A0026
         MVC   8(8,R14),=CL8'TRUNC'      REASON CODE
         LG    R15,PALEN2                LENGTH
         J     A0027
A0026    EQU   *
         MVC   8(8,R14),=CL8'00000000'   REASON CODE
         LG    R15,CTRLENOUT             LENGTH
A0027    EQU   *
*
         LG    R1,CTRACLSS
         MVC   16(32,R14),0(R1)
         LG    R1,CTRAMETH
         MVC   48(32,R14),0(R1)
*
         LG    R1,CTRMEMOUT
         AGHI  R14,16+32+32
         AGHI  R15,-1
         EXRL  R15,MVCR14R1
         sysstate amode64=NO
         sam31
         MVC   WKRETC,=F'4'              == REQUEST FROM MR95
*
MAIN_200 EQU   *
         LH    R0,WKECBLSZ
         LLGT  R1,WKECBLST
         FREEMAIN RU,LV=(0),A=(1)
         DROP  R5 CTRAREA
         DROP  R4 CTTAREA
*
         J     DONE
         MVC   WKPRINT,SPACES
         MVC   WKPRINT(10),=CL10'GVBJWAIT: '
         MVC   WKPRINT+10(09),=CL9'COMPLETED'
*
         LA    R2,OUTDCB
         LA    R0,WKPRINT
         PUT   (R2),(R0)
*
*        RETURN TO CALLER
*
DONE     EQU   *                         RETURN TO CALLER
         J     DONEDONE
         LAY   R2,OUTDCB
         MVC   WKREENT(8),OPENPARM
         CLOSE ((R2)),MODE=31,MF=(E,WKREENT)
*
DONEDONE EQU   *                         RETURN TO CALLER
         LG    R13,SAVER13               CALLER'S SAVE AREA ADDRESS
         L     R15,WKRETC
         STG   R15,SAVF4SAG64RS15-SAVF4SA(,R13)
         FREEMAIN R,LV=DYNLEN,A=(11)     FREE DYNAMIC STORAGE
         LMG   R14,R12,SAVF4SAG64RS14-SAVF4SA(R13)
         BR    R14                       RETURN TO CALLER
*
         DS    0D
MVCR14R1 MVC   0(0,R14),0(R1)     * * * * E X E C U T E D * * * *
         DS    0D
CLCR1R14 CLC   0(0,R1),0(R14)     * * * * E X E C U T E D * * * *
*
*
*        STATICS
*
*
*        CONSTANTS
*
H1       DC    H'1'
H4       DC    H'4'
H255     DC    H'255'
F04      DC    F'04'
F40      DC    F'40'
F4096    DC    F'4096'
CTTEYEB  DC    CL8'GVBCTT'
TKNNAME  DC    CL8'GVBJMR95'
GENEVA   DC    CL8'GENEVA'
TOKNPERS DC    F'0'                    TOKEN PERSISTENCE
TOKNLVL1 DC    A(1)                    NAME/TOKEN  AVAILABILITY  LEVEL
TOKNLVL2 DC    A(2)                    NAME/TOKEN  AVAILABILITY  LEVEL
*
         DS   0D
MODE31   EQU   X'8000'
         DS   0D
OPENPARM DC    XL8'8000000000000000'
*
OUTFILE  DCB   DSORG=PS,DDNAME=DDPRINT,MACRF=(PM),DCBE=OUTFDCBE,       X
               RECFM=FB,LRECL=131
OUTFILE0 EQU   *-OUTFILE
OUTFDCBE DCBE  RMODE31=BUFF
OUTFILEL EQU   *-OUTFILE
*
SPACES   DC    CL256' '
XHEXFF   DC 1024X'FF'
*
*
         LTORG ,
*
NUMMSK   DC    XL12'402020202020202020202021'
*
*******************************************************
*                 UNPACKED NUMERIC TRANSLATION MATRIX
*******************************************************
*                    0 1 2 3 4 5 6 7 8 9 A B C D E F
*
TRTACLVL DC    XL16'00D500000000000000C5000000000000'  00-0F
         DC    XL16'D9000000000000000000000000000000'  10-1F
         DC    XL16'E4000000000000000000000000000000'  20-2F
         DC    XL16'00000000000000000000000000000000'  30-3F
         DC    XL16'C3000000000000000000000000000000'  40-4F
         DC    XL16'00000000000000000000000000000000'  50-5F
         DC    XL16'00000000000000000000000000000000'  60-6F
         DC    XL16'00000000000000000000000000000000'  70-7F
         DC    XL16'C1000000000000000000000000000000'  80-8F
         DC    XL16'00000000000000000000000000000000'  90-9F
         DC    XL16'00000000000000000000000000000000'  A0-AF
         DC    XL16'00000000000000000000000000000000'  B0-BF
         DC    XL16'00000000000000000000000000000000'  C0-CF
         DC    XL16'00000000000000000000000000000000'  D0-DF
         DC    XL16'00000000000000000000000000000000'  E0-EF
         DC    XL16'00000000000000000000000000000000'  F0-FF
*
TRTTBLU  DC    XL16'08080808080808080808080808080808'  00-0F
         DC    XL16'08080808080808080808080808080808'  10-1F
         DC    XL16'08080808080808080808080808080808'  20-2F
         DC    XL16'08080808080808080808080808080808'  30-3F
         DC    XL16'08080808080808080808080808080808'  40-4F
         DC    XL16'08080808080808080808080808080808'  50-5F
         DC    XL16'08080808080808080808080808080808'  60-6F
         DC    XL16'08080808080808080808080808080808'  70-7F
         DC    XL16'08080808080808080808080808080808'  80-8F
         DC    XL16'08080808080808080808080808080808'  90-9F
         DC    XL16'08080808080808080808080808080808'  A0-AF
         DC    XL16'08080808080808080808080808080808'  B0-BF
         DC    XL16'08080808080808080808080808080808'  C0-CF
         DC    XL16'08080808080808080808080808080808'  D0-DF
         DC    XL16'08080808080808080808080808080808'  E0-EF
         DC    XL16'00000000000000000000080808080808'  F0-FF
*
OPTTABLE DC    CL4'WRKT'
         DC    CL4'ACKG'
         DC    CL4'0001'
         DC    CL4'0002'
         DC    CL4'0003'
         DC    CL4'0004'
         DC    CL4'0005'
         DC    CL4'0006'
         DC    CL4'0007'
         DC    CL4'0008'
         DC    CL4'0009'
         DC    CL4'0010'
         DC    CL4'0011'
         DC    CL4'0012'
         DC    CL4'0013'
         DC    CL4'0014'
         DC    CL4'0015'
         DC    CL4'0016'
         DC    CL4'0017'
         DC    CL4'0018'
         DC    CL4'0019'
         DC    CL4'0020'
         DC    CL4'0021'
         DC    CL4'0022'
         DC    CL4'0023'
         DC    CL4'0024'
         DC    CL4'0025'
         DC    CL4'0026'
         DC    CL4'0027'
         DC    CL4'0028'
         DC    CL4'0029'
         DC    CL4'0030'
         DC    CL4'0031'
         DC    CL4'0032'
         DC    CL4'0033'
         DC    CL4'0034'
         DC    CL4'0035'
         DC    CL4'0036'
         DC    CL4'0037'
         DC    CL4'0038'
         DC    CL4'0038'
         DC    CL4'0040'
         DC    CL4'0041'
         DC    CL4'0042'
         DC    CL4'0043'
         DC    CL4'0044'
         DC    CL4'0045'
         DC    CL4'0046'
         DC    CL4'0047'
         DC    CL4'0048'
         DC    CL4'0049'
         DC    CL4'0050'
         DC    CL4'0051'
         DC    CL4'0052'
         DC    CL4'0053'
         DC    CL4'0054'
         DC    CL4'0055'
         DC    CL4'0056'
         DC    CL4'0057'
         DC    CL4'0058'
         DC    CL4'0059'
         DC    CL4'0060'
         DC    CL4'0061'
         DC    CL4'0062'
         DC    CL4'0063'
         DC    CL4'0064'
         DC    CL4'0065'
         DC    CL4'0066'
         DC    CL4'0067'
         DC    CL4'0068'
         DC    CL4'0069'
         DC    CL4'0070'
         DC    CL4'0071'
         DC    CL4'0072'
         DC    CL4'0073'
         DC    CL4'0074'
         DC    CL4'0075'
         DC    CL4'0076'
         DC    CL4'0077'
         DC    CL4'0078'
         DC    CL4'0079'
         DC    CL4'0080'
         DC    CL4'0081'
         DC    CL4'0082'
         DC    CL4'0083'
         DC    CL4'0084'
         DC    CL4'0085'
         DC    CL4'0086'
         DC    CL4'0087'
         DC    CL4'0088'
         DC    CL4'0089'
         DC    CL4'0090'
         DC    CL4'0091'
         DC    CL4'0092'
         DC    CL4'0093'
         DC    CL4'0094'
         DC    CL4'0095'
         DC    CL4'0096'
         DC    CL4'0097'
         DC    CL4'0098'
         DC    CL4'0099'
*
         DS   0F
         DCBD  DSORG=PS
*
         IHADCBE
*
JFCBAR   DSECT
         IEFJFCBN LIST=YES
*
         CVT   DSECT=YES
*
         IHAPSA
*
         END
