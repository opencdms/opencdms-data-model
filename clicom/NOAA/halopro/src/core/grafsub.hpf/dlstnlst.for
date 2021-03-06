$STORAGE:2
      SUBROUTINE DLSTNLST (LSTNAM)
C
C       ** ROUTINE TO DELETE A STATION SELECTION LIST FILE AND REMOVE ITS 
C          ENTRY FROM THE MPSTNLST INDEX FILE.
C
C       ** FILE STRUCTURE:
C          -- STATION SELECTION LIST FILE (O:\DATA\xxxxxxxx.LST)
C                RECORD LENGTH = 36
C                FILE TYPE     = DIRECT, UNFORMATTED
C                STNGEOG RECORD # + STATION ID + STATION ABBREVIATION
C          -- STATION LIST INDEX FILE (P:\DATA\MPSTNLST.IDX)
C                RECORD LENGTH = 43
C                FILE TYPE     = DIRECT, BINARY
C                LIST NAME+BLANK+DESCRIPTION+CR+LF
C                   8     +  1       32     +1 +1 =43
C
      CHARACTER*8 LSTNAM
C
      CHARACTER*78 MSGTXT
      CHARACTER*43 INREC
      CHARACTER*20 LSTFIL
      CHARACTER*2  YESUP,NOUP,IDUM
      LOGICAL      FIRSTCALL
      DATA FIRSTCALL/.TRUE./
C      
      IF (FIRSTCALL) THEN
         FIRSTCALL = .FALSE.
         CALL GETYN(1,2,YESUP,IDUM)
         CALL GETYN(2,2, NOUP,IDUM)
      ENDIF   
C      
C  BUILD STATION LIST FILE NAME,  OPEN IT, AND DELETE IT
C
      LSTFIL = 'O:\DATA\'//LSTNAM
      I1 = LNG(LSTFIL)
      LSTFIL(I1+1:) = '.LST'         
C      
      CALL GETMSG(372,MSGTXT)
      CALL GETMSG(999,MSGTXT)
      MSGLEN = LNG(MSGTXT)
      CALL LOCATE(22,5,IERR)
      CALL WRTSTR(MSGTXT,MSGLEN,12,0)
   20 CONTINUE
      CALL BEEP
      CALL GETCHAR(0,INCHAR)
      IF (INCHAR.EQ.NOUP) THEN
         CALL CLRMSG(3)
         GO TO 120
      ELSE IF (INCHAR.NE.YESUP) THEN
         GO TO 20
      END IF
      CALL CLRMSG(3)
C      
      OPEN (51,FILE=LSTFIL,STATUS='OLD',ACCESS='DIRECT'
     +     ,MODE='WRITE',IOSTAT=ICHK,RECL=36)
      IF (ICHK.NE.6416.AND.ICHK.NE.0) THEN
         CALL OPENMSG(LSTFIL,'DLSTNLST    ',ICHK)
      END IF
      CLOSE(51,STATUS='DELETE')
      I1=LNG(LSTFIL)
      CALL WRTMSG(3,594,12,0,0,LSTFIL,I1)
C
C   FIND AND REMOVE THE ENTRY FROM THE MPSTNLST INDEX FILE
C      
      OPEN (51,FILE='O:\DATA\MPSTNLST.IDX',STATUS='OLD',FORM='BINARY'
     +     ,ACCESS='DIRECT',RECL=43)
      DO 100 I = 1,9999
         READ(51,REC=I,ERR=110) INREC
         IF (INREC(1:8).EQ.LSTNAM) THEN
            INREC(1:8) = '********'              
            INREC(10:41) = 'THIS RECORD DELETED'
            WRITE(51,REC=I) INREC
            GO TO 110
         END IF
100   CONTINUE
110   CONTINUE
      LSTNAM=' '
120   CONTINUE
      CLOSE(51)
      RETURN
      END
      