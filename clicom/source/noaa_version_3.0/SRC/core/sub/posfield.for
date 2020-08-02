$STORAGE:2

      SUBROUTINE POSFIELD(STRTELEM,NUMLINE,STRTLINE,IELEM,ILINE,
     +       RECTYPE,HOURLBL,CENTER,MAXY)
C
C   ROUTINE TO POSITION THE CURSOR TO THE FIRST CHARACTER OF A DATA
C       FIELD
C         THE NUMBER OF ELEMENTS, STARTING ELEMENT, NUMBER OF LINES, AND
C         STARTING LINE IS PASSED TO THE ROUTINE.
C         THE ELEMENT NUMBER AND LINE NUMBERS ARE PASSED TO THE ROUTINE
C         AND ARE RETURNED - THEY MAY BE RECOMPUTED.
C         IF CENTER = 1, THE FIELD IS CENTERED ON THE SCREEN, OTHERWISE
C         NO SPECIAL EFFORT IS MADE TO CENTER THE FIELD
C
      PARAMETER (MAXX = 10)  
C
      CHARACTER*2 HOURLBL
      CHARACTER*3 RECTYPE
      INTEGER*2 STRTELEM, NUMLINE, STRTLINE,IELEM,ILINE,
     +          CENTER, ESTRT, LSTRT
      LOGICAL NEWPAGE
C
      NEWPAGE = .FALSE.
C
C   CHECK IF THE REQUESTED FIELD IS AVAILABLE ON THE PRESENT FORM
C        
      IF (IELEM.LT.STRTELEM.OR.IELEM.GT.(STRTELEM+MAXX-1)) THEN
         STRTELEM = 5 * (((IELEM - 1) / 5) - 1) + 1
         IF (STRTELEM.LT.1) THEN
            STRTELEM = 1
         END IF 
         NEWPAGE = .TRUE.
      END IF
      IF (ILINE.LT.STRTLINE-1.OR.ILINE.GT.STRTLINE+MAXY)THEN
         NEWPAGE = .TRUE.
      END IF
C
C   CENTER THE FIELD IF THAT IS REQUESTED
C
      IF (CENTER.EQ.1) THEN
         ESTRT = IELEM - (MAXX/2)
         LSTRT = ILINE - (MAXY/2)
         IF (ESTRT.LT.1) THEN
            ESTRT = 1
         END IF
         IF (LSTRT.LT.1) THEN
            LSTRT = 1
         ELSE IF (LSTRT.GT.NUMLINE-MAXY+1) THEN
            LSTRT = NUMLINE-MAXY+1
         END IF
         IF (ESTRT.LT.STRTELEM-1.OR.ESTRT.GT.STRTELEM+1) THEN
            STRTELEM = ESTRT
            NEWPAGE = .TRUE.
         END IF
         IF (LSTRT.LT.STRTLINE-1.OR.LSTRT.GT.STRTLINE+1) THEN
            STRTLINE = LSTRT
            NEWPAGE = .TRUE.
         END IF
      END IF
C 
      IF (NEWPAGE) THEN
         IF (ILINE.LT.STRTLINE) THEN
            STRTLINE = ILINE
         ELSE IF (ILINE.GT.(STRTLINE+MAXY-1)) THEN
            STRTLINE = ILINE - MAXY + 1
         END IF  
         CALL WRTPAGE(RECTYPE,HOURLBL,STRTELEM,STRTLINE)
      ELSE
         IF (ILINE.LT.STRTLINE) THEN
C             .. SCROLL DOWN
            CALL CLTEXT(0,0,IERR)
            CALL SCROLL(0,1,5,0,MAXY+4,79)
            STRTLINE = STRTLINE - 1
            CALL WRTLINE(RECTYPE,HOURLBL,STRTELEM,STRTLINE,5)
         ELSE IF (ILINE.GT.(STRTLINE+MAXY-1)) THEN
C             .. SCROLL UP
            CALL CLTEXT(0,0,IERR)
            CALL SCROLL(1,1,5,0,MAXY+4,79)
            STRTLINE = STRTLINE + 1
            CALL WRTLINE(RECTYPE,HOURLBL,STRTELEM,ILINE,MAXY+4)
         END IF
      END IF  
      IROW = (ILINE - STRTLINE) + 5
      ICOL = (IELEM - STRTELEM)*7 + 7
      CALL LOCATE (IROW,ICOL,IERR)
      RETURN
      END
