$STORAGE:2

      SUBROUTINE GETMLIM(STARTSTN,ENDSTN,YEARMON,FILNAME,RTNCODE)
C
C   SUBROUTINE TO SOLICIT A RANGE OF STATIONS AND YEARS TO BE PROCESSED
C       THE ROUTINE ASKS THE USER TO SUPPLY THE INFORMATION AND READS IT
C       FROM THE KEYBOARD BY CALLING ROUTINE GETFRM. 
C
      CHARACTER*8 STARTSTN,ENDSTN
      INTEGER*4 YEARMON
      CHARACTER*1 RTNCODE
      CHARACTER*2 RTNFLAG
      CHARACTER*64 FILNAME
      CHARACTER*20 FIELD(4)
      FIELD(1) = '       '
      FIELD(2) = '       '
      FIELD(3) = '    '
      FIELD(4) = '  ' 
      RTNCODE = '0'
      CALL POSLIN(IROW,ICOL)
C
C   BUILD AND READ THE DATA ENTRY FORM 
C
   40 CONTINUE
      CALL LOCATE(IROW,ICOL,IERR)
      RTNFLAG = 'SS'
      CALL GETFRM('GETMLIM ',FILNAME,FIELD,20,RTNFLAG)
      CALL POSLIN(IROW,IERR)
      IF (RTNFLAG.EQ.'4F') THEN
         RTNCODE = '1'
         RETURN
      END IF
C
C   CHECK THE INPUT DATA 
C
      STARTSTN = FIELD(1)
      ENDSTN = FIELD(2)
      READ(FIELD(3),'(I4)') IYEAR
      READ(FIELD(4),'(I2)') IMON
      RYEAR = IYEAR
      RMON = IMON
      RYRMON = RYEAR*100. + RMON
      YEARMON = INT4(RYRMON)
C
      IROW = IROW + 7 
      CALL LOCATE(IROW,1,IERR) 
C
      RETURN
      END
