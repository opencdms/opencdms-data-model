$STORAGE:2
C
C     PROGRAM RVSNDE  
C
C     ** OBJECTIVE:  PROGRAM CONSTRUCTS THE KEYSTROKE TABLE THAT USE TO REVISE
C                    FORMS AND REPORTS THAT HAVE BEEN MODIFIED:
C                              FORMS                   REPORTS
C                          様様様様様様�          様様様様様様様様�
C                          STN ELEMENT            COPY-ELEM-EXTREMES
C                          STN GEOGRAPHY          EXPORT-DLY-ASCII
C                          NORMAL                 EXPORT-SYN-ASCII
C                          STN GEOG UP            EXPORT-HLY-ASCII
C                          STN ELEM UP            EXPORT-15M-ASCII
C                                                 EXPORT-U-A-ASCII
C                    THE PROGRAM READS THE COMMAND PARAMETER AND WRITES THE 
C                    APPROPRIATE KEYSTROKE TABLE THAT IS BASED ON THE VERSION 
C                    OF DATAEASE CURRENTLY IN USE
C
C     ** PASSED PARAMETER IS:
C           %1    = DATEASE VERSION
C
C ---------------------------------------------------------------------
      INTERFACE TO SUBROUTINE CMDLIN2(ADDRES,LENGTH,RESULT)
      INTEGER*4   ADDRES[VALUE],LENGTH[VALUE]
      CHARACTER*1 RESULT
      END
C ---------------------------------------------------------------------
      PROGRAM RVSNDE
C
      CHARACTER*1  CHARCODE(200)
      CHARACTER*40 RESULT
      INTEGER*1    ICHRCODE(200)
      CHARACTER*5  DETYPE,DATATYPE
      CHARACTER*3  DEVERS
      CHARACTER*22 FILENAME
      CHARACTER*30 MSGTXT
      INTEGER*2    NUMCHAR
      INTEGER*4    PSP, PSPNCHR, OFFSET
C
C  LOCATE SEGMENTED ADDRESS OF THE BEGINNING OF THIS PROGRAM
C
      OFFSET = #00100000
      PSP = LOCFAR(RVSNDE)
C
C  COMPUTE THE BEGINNING OF THE PROGRAM SEGMENT PREFIX (PSP)
C
      PSP = (PSP - MOD(PSP,#1000)) - OFFSET
C
C  LOCATE THE POSITION OF COMMAND PARAMETERS WITHIN PSP
C
      PSPNCHR = PSP + #80
      PSP = PSP + #81
C
C  PASS THE ADDRESS OF THE COMMAND PARAMETERS TO CMDLIN2 WHICH DECODES
C  THE COMMAND AND RETURNS IT AS RESULT.
C
      CALL CMDLIN2(PSP,PSPNCHR,RESULT)
C
C  PULL THE COMMANDS OUT OF THE RESULT :
C     DEVERS   --   DATAEASE VERSION
C
      DEVERS  = '     '
      DO 20 L=1,40
         IF (RESULT(L:L) .NE. ' ') THEN
            DEVERS = RESULT(L:40)
            GO TO 30
         ENDIF
   20 CONTINUE
C
C     *** DETERMINE WHICH VERSION OF DATAEASE IS IN USE
C
   30 CONTINUE
      IF (DEVERS.EQ.'4.0'.OR.DEVERS.EQ.'4.2') THEN
          DETYPE = 'DE4.0'
      ELSE IF (DEVERS.EQ.'4.5') THEN
          DETYPE = 'DE4.5'
      ELSE IF (DEVERS.EQ.'2.5') THEN
          DETYPE = 'DE2.5'
      ELSE
          STOP 2
      END IF    
C 
C     *** OPEN THE KEY STROKES FILE
C
  40     CONTINUE
         FILENAME='A:\RVSNDE24.KEY'
         OPEN (67,FILE=FILENAME,STATUS='OLD',FORM='FORMATTED',
     +         IOSTAT=IOCHK)
         IF (IOCHK.NE.0) THEN
            CALL CLS
            CALL OPENMSG('A:\RVSNDE24.KEY    ','RVSNDE     ',IOCHK)
            GO TO 40
         END IF
C
C     *** FIND THE KEYSTROKES TABLE FOR THE DEASE VERSION SPECIFIED
C
      DO 70 I = 1,3
      READ(67,*,ERR=300)DATATYPE,NUMCHAR  
      IF (DATATYPE(1:5).EQ.DETYPE(1:5)) THEN
          GO TO 80
      END IF  
C
C     *** DETERMINE THE NUMBER OF LINES NEED TO SKIP
C
      IF (MOD(NUMCHAR,20).NE.0) THEN
          NLINE = (NUMCHAR/20) + 1
      ELSE
          NLINE = NUMCHAR/20
      END IF
      DO 75 K = 1,NLINE
         READ(67,'(A60)',ERR=300)
  75  CONTINUE
  70  CONTINUE
  80  CONTINUE
      READ(67,'(20(Z2,1X))',ERR=300)(ICHRCODE(J),J=1,NUMCHAR)
c      CALL DELAY (150)
C
C     *** OPEN THE TEMPORARY OUTPUT FILE AND WRITE NECESSARY KEY STROKES TO
C         REPLACE FORMS AND REPORTS.
C
      FILENAME='C:\RVDEKEYS.DAT'
      OPEN (68,FILE=FILENAME,STATUS='UNKNOWN',ACCESS='DIRECT',
     +      FORM='UNFORMATTED',RECL=NUMCHAR,IOSTAT=IOCHK) 
      IF(IOCHK.NE.0) THEN
         CALL CLS
         WRITE(MSGTXT,'(A20,2X,I4)') FILENAME,IOCHK
         CALL WRTMSG(4,157,12,1,1,MSGTXT,26)
         CALL LOCATE(24,0,IERR)
         STOP 2            
      END IF
      DO 150 K=1,NUMCHAR
         CHARCODE(K)=CHAR(ICHRCODE(K))
  150 CONTINUE
      WRITE(68)(CHARCODE(J),J=1,NUMCHAR)
      CLOSE(68)
      CLOSE(67)
      STOP ' '
C
C     *** ERROR READING FILE ***
C  
  300 CONTINUE
      CALL CLS
      CALL WRTMSG(4,191,12,1,1,FILENAME,22)
      CALL LOCATE(24,0,IERR)
      STOP 2            
      END
