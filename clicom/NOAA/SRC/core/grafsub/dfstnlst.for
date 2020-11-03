$STORAGE:2
      SUBROUTINE DFSTNLST(NSELECT,STNSTAT,J4REC,MXSTAT,MAXREC,MAXLST
     +                   ,RTNCODE)
C
C       ** INPUT:
C             NSELECT
C             STNSTAT
C             J4REC
C             MXSTAT.....MAXIMUM NUMBER OF STATIONS THAT CAN BE PROCESSED.  
C                        EACH STATION MUST BE FLAGGED AS SELECTED OR 
C                        NON-SELECTED.  THIS FLAG IS STORED IN STNSTAT.  
C                        MXSTAT DETERMINES THE NUMBER OF STATIONS THAT CAN 
C                        BE CONSIDERED.  ANY ADDITIONAL STATIONS IN 
C                        STNGEOG.INF WILL BE IGNORED
C             MAXREC
C             MAXLST
C       ** OUTPUT:
C             RTNCODE
C
C       .. ARGUMENTS
      INTEGER*2    MXSTAT,MAXREC,NSELECT
      INTEGER*4    STNSTAT(MXSTAT),J4REC(MAXREC),NUMSTN
      CHARACTER*1  RTNCODE
C
C       .. LOCAL VARIABLES
C            J.......RECORD NUMBER FOR LAST RECORD READ FROM FILE
C            I.......NUMBER OF LINES DISPLAYED IN CURRENT PAGE -- HLDREC
C            I1......LINE NUMBER OF CURSOR ON CURRENT PAGE
C            JPAGE...RECORD NUMBER IN FILE FOR FIRST RECORD IN CURRENT PAGE 
C
      INTEGER*2 MAXLIN
      PARAMETER (MAXLIN=22)
      INTEGER*2 RECLEN,SRTBEG, SRTLEN,WINWIDTH
      INTEGER*4 HLDNBR(24)
      CHARACTER*2 INCHAR
      CHARACTER*3 DEVERS
      CHARACTER*5 CMAXLST
      CHARACTER*64 HELPFILE
      CHARACTER*80 INID,PREVID,HLDREC(24),INREC,PREVREC
      CHARACTER*80 MSGLN1,MSGLN2,MSGLN3
      LOGICAL FOUND,FIRSTCALL
C
      INTEGER*2 BUFFER(1300,2)
      COMMON /WINDOW/ BUFFER
C      
      DATA FIRSTCALL /.TRUE./, HELPFILE /'P:\HELP\VALWIN.HLP'/
      DATA IWINDOW /1/
C
C       ** J4REC IS A REAL ARRAY OUTSIDE THIS ROUTINE.  IT IS USED AS
C          INTEGER*4 ONLY TO SAVE SPACE.  INITIAL TO INTEGER VALUES.
C 
      DO 10 I=1,MAXREC
         J4REC(I)=0
   10 CONTINUE         
C
C   ON FIRST CALL TO THIS ROUTINE - READ MESSAGE TEXT
C
      IF (FIRSTCALL) THEN
         FIRSTCALL = .FALSE.
         CALL GETMSG(100,MSGLN1)
         MSGLEN=LNG(MSGLN1)
         CALL GETDEASE(DEVERS)
         IF (DEVERS.EQ.'4.0') THEN
            NMSG=592
         ELSE
            NMSG=591
         ENDIF
         CALL GETMSG(NMSG,MSGLN2)
         CALL GETMSG(583,MSGLN3)
         CALL GETMSG(999,MSGLN3)
         DO 15 I=1,80
          IF (MSGLN3(I:I).EQ.'=') GO TO 16
   15    CONTINUE          
         I=4 
   16    CONTINUE
         INDX1=I+1
         INDX2=LNG(MSGLN3)+1
         MSG3LEN=INDX2+3
      END IF    
C
      WRITE(CMAXLST,'(I5)') MAXLST
      RTNCODE = '0'        
      IDBEG = 1
      IDLEN = 8
      SRTBEG = 17
      SRTLEN = 24
      RECLEN = 40
      WINWIDTH = 50
      JMIN = 1
      J = JMIN
      IWIDTH = IDLEN + SRTLEN + 1
C
C     DETERMINE WHERE THE WINDOW SHOULD BE OPENED
C
      CALL POSLIN(JROW,JCOL)
      IF (JCOL.LT.40) THEN
         ISTRT = 80 - WINWIDTH
      ELSE
         ISTRT = 0
      END IF
C
C   OPEN AND CLEAR THE SCREEN WINDOW
C
      IEND = ISTRT + WINWIDTH - 1
      CALL OPENWIN(IWINDOW,BUFFER(1,IWINDOW),0,ISTRT,24,IEND)
C
C  INITIALIZE
C
      PREVID = '        '
      I1 = 1
      IPAGE = 0
C
C  OPEN THE STNGEOG.INF FILE AND INITIALIZE
C
   20  OPEN (35,FILE='P:\DATA\STNGEOG.INF',STATUS='OLD',
     +      ACCESS='DIRECT',RECL=80,SHARE='DENYWR',MODE='READ'
     +      ,IOSTAT=IOCHK)
      IF (IOCHK.NE.0) THEN
         CALL OPENMSG('P:\DATA\STNGEOG.INF   ','GRAFINIT    ',IOCHK)
         GO TO 20
      END IF
      READ(35,REC=1) NUMSTN
C
C   READ ONE SCREEN OF INPUT RECORDS (MAXLIN ENTRIES)
C
100   CONTINUE
      DO 105 I2 = 1,MAXLIN
         HLDREC(I2) = ' '
         HLDNBR(I2) = 0
105   CONTINUE
      I = 0
      IPAGE = IPAGE + 1
      J4REC(IPAGE) = J + 1
110   CONTINUE
      FOUND = .TRUE.
      J = J + 1
      IF (J.GT.MXSTAT) THEN
         GO TO 120
      ENDIF           
      READ(35,REC=J,ERR=120) (INREC(I3:I3),I3=1,RECLEN)
      INID = INREC(IDBEG:IDBEG+IDLEN-1)
      INJ = J
C      
C       .. IF MULTIPLE ENTRIES FOR THE ID SAVE THE LAST ONE
      IF (INID.NE.PREVID) THEN
         IF (PREVID.NE.'      ') THEN
            I = I + 1
            HLDREC(I) = PREVREC
            HLDNBR(I) = JPREV
         END IF
      END IF
C
      PREVID = INID
      PREVREC = INID
      PREVREC(IDLEN+2:IDLEN+SRTLEN+1)=INREC(SRTBEG:SRTBEG+SRTLEN-1)
      JPREV=INJ
      IF (I.LT.MAXLIN) THEN
         GO TO 110
      END IF
      GO TO 130
C
C   GET HERE IF EOF ENCOUNTERED IN STNGEOG.INF OR IF THE MAXIMUM NUMBER OF
C   STATIONS HAVE BEEN PROCESSED.  EACH STATION MUST BE FLAGGED AS SELECTED
C   OR NON SELECTED.  THIS FLAG IS STORED IN STNSTAT.  MXSTAT DETERMINES
C   THE NUMBER OF STATIONS THAT CAN BE CONSIDERED.  ANY ADDITIONAL STATIONS
C   IN STNGEOG.INF WILL BE IGNORED
C
120   CONTINUE
      I = I + 1
      IF (PREVID.EQ.'        ') THEN
         HLDREC(I) = '       '
         HLDNBR(I) = 0
         FOUND = .FALSE.
      ELSE
         HLDREC(I) = PREVREC
         HLDNBR(I) = JPREV
      END IF
C
C   DISPLAY THE SCREEN OF DATA
C
130   CONTINUE
      IROW = 0
      ICOL = 0
      CALL CLRWIN(IWINDOW)
      IF (FOUND) THEN
         DO 150 I2 = 1,I
            INDX=HLDNBR(I2)
            ICOLOR=STNSTAT(INDX)
            CALL DSPREC(I2,ISTRT+1,ICOLOR,HLDREC(I2),IWIDTH)
150      CONTINUE
         WRITE(MSGLN3(INDX1:INDX1+3),'(I4)') NSELECT
         WRITE(MSGLN3(INDX2:INDX2+3),'(I4)') MAXLST-NSELECT
         CALL LOCATE(23,ISTRT+1,IERR)
         CALL WRTSTR(MSGLN3,MSG3LEN,4,3)
      END IF
C   
C       .. WRITE FUNCTION LINE      
      CALL LOCATE(24,ISTRT+1,IERR)
      CALL WRTSTR(MSGLN2,48,0,3)
C
C   HIGHLIGHT THE CURRENT LINE AND READ THE USER INPUT
C
180   CONTINUE
      IF (FOUND) THEN
         ICOLOR=1
         ILEN=8
         CALL DSPREC(I1,ISTRT+1,ICOLOR,HLDREC(I1),ILEN)
         CALL GETCHAR(0,INCHAR)
      ELSE
         CALL CLRWIN(IWINDOW)
         CALL LOCATE(2,ISTRT+2,IERR)
         CALL WRTSTR(MSGLN1,38,15,3)
         CALL GETCHAR(0,INCHAR)
      END IF
C
C   IF HELP WANTED, DISPLAY IT AND ASK FOR NEXT USER INPUT.
C   OTHERWISE, REMOVE HIGHLIGHT ON THIS LINE IN ANTICIPATION OF MOVING
C   TO ANOTHER LINE.
C      
      IF (INCHAR.EQ.'1F') THEN
         CALL DSPWIN(HELPFILE)
         GO TO 180
      ELSE IF (FOUND) THEN
         INDX=HLDNBR(I1)
         ICOLOR=STNSTAT(INDX)
         CALL DSPREC(I1,ISTRT+1,ICOLOR,HLDREC(I1),IWIDTH)
      END IF
C
C   OTHERWISE, CHECK FOR PAGE, CURSOR, OR OTHER FUNCTION KEYS AND
C   TAKE THE APPROPRIATE ACTION.
C 
      IF (INCHAR.EQ.'DP') THEN
         I1 = I + 1
      ELSE IF (INCHAR.EQ.'UP') THEN
         I1 = 0
      ELSE IF (INCHAR.EQ.'HO') THEN
         I1 = 1
      ELSE IF (INCHAR.EQ.'EN') THEN
         I1 = I
      ELSE IF (INCHAR.EQ.'DA') THEN
         I1 = I1 + 1
      ELSE IF (INCHAR.EQ.'UA') THEN
         I1 = I1 - 1
      ELSE IF (INCHAR.EQ.'RE') THEN
         INDX=HLDNBR(I1)
         IF (STNSTAT(INDX).EQ.0) THEN
            IF (NSELECT.EQ.MAXLST) THEN
               CALL WRTMSG(2,593,12,1,0,CMAXLST,5)
            ELSE   
               STNSTAT(INDX) = -1
               NSELECT=NSELECT+1
            ENDIF
         ELSE
            STNSTAT(INDX) = 0   
            NSELECT=NSELECT-1
         ENDIF   
         IF (FOUND) THEN
            WRITE(MSGLN3(INDX1:INDX1+3),'(I4)') NSELECT
            WRITE(MSGLN3(INDX2:INDX2+3),'(I4)') MAXLST-NSELECT
            CALL LOCATE(23,ISTRT+1,IERR)
            CALL WRTSTR(MSGLN3,MSG3LEN,4,3)
            INDX=HLDNBR(I1)
            ICOLOR=STNSTAT(INDX)
            CALL DSPREC(I1,ISTRT+1,ICOLOR,HLDREC(I1),IWIDTH)
         END IF
      ELSE IF (INCHAR.EQ.'2F') THEN
         RTNCODE='0'
         GO TO 300
      ELSE IF (INCHAR.EQ.'4F') THEN
         RTNCODE='1'
         GO TO 300
      ELSE
         CALL BEEP
         GO TO 180   
      END IF
C
C  IF SELECTED LINE IS OFF THE PAGE, SCROLL PAGE
C
      IF (I1.GT.I) THEN
         IF (I.EQ.MAXLIN) THEN
            I1 = 1
            GO TO 100
         ELSE
            I1 = I
            CALL BEEP
         END IF
      ELSE IF (I1.LT.1) THEN
         IF (IPAGE.GT.1) THEN
            IPAGE = IPAGE - 2
            I1 = MAXLIN
            J = J4REC(IPAGE+1) - 1
            PREVID = '        '
            GO TO 100
         ELSE
            I1 = 1
            CALL BEEP
         END IF
      END IF
      GO TO 180  

300   CONTINUE
C
C   CLOSE WINDOW, RESTORE SCREEN AND RETURN
C
      CALL CLOSWIN(IWINDOW,BUFFER(1,IWINDOW))
C
      RETURN
      END      
