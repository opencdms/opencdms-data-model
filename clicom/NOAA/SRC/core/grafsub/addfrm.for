$STORAGE:2
      SUBROUTINE ADDFRM(RTNCODE)
C      
C       ** OBJECTIVE:  ADD A FRAME TO DATASET
C
C       ** OUTPUT:
C             RTNCODE....      
C
      CHARACTER *1 RTNCODE
C
$INCLUDE: 'GRFPARM.INC'
$INCLUDE: 'GRAFVAR.INC'
$INCLUDE: 'DATAVAL.INC'
$INCLUDE: 'FRMPOS.INC'
$INCLUDE: 'MODTMP.INC'
C
C       ** GRFPARM.INC REQUIRED FOR PARAMETER LENTXTD
      CHARACTER *(LENTXTD) FRMTITLE,FRMSUB
      CHARACTER *1 RTNSET
      CHARACTER*14 MSGTXT  
      INTEGER*2 FILOPT,LENMSG
C      
      PARAMETER (MAXERR=3,MAXMSG=6)
      INTEGER*2 MSGIDX(MAXERR),MSGNBR(MAXMSG)
      DATA MSGNBR /382,383,191,385,386,387/
C      
      NERR = 0
      RTNSET = '0'
      NCVBG  = 2
      NFRMBG = 1
C      
C
C       .. POSITION FILE TO START OF NEXT AVAILABLE FRAME
      NNXT=NBRFRM
      FILOPT = 6
      KNTROW = 0
      DO 9 I=1,NNXT
         CALL RDFRAME(CVAL(NCVBG),RVAL,MXDATROW,NFRMBG,FILOPT,IGRAPH,
     +                NUMCOL,COLHDR,FRMTITLE,FRMSUB,NFRMFN,RTNCODE)
         IF (RTNCODE.NE.'0') GO TO 10
    9 CONTINUE
   10 CONTINUE
      IF (RTNCODE.NE.'0') THEN
         NERR=NERR+1
         MSGIDX(NERR)=ICHAR(RTNCODE)-48
         IF (RTNCODE.EQ.'1') THEN
C             .. END OF FILE -- CANNOT ADD A FRAME
            NERR=NERR+1
            MSGIDX(NERR)=6
            IF (RTNSET.EQ.'0') RTNSET=RTNCODE
            RTNCODE = '0'
            NFRMCUR = I
            GO TO 50
         ELSE   
            GO TO 900
         ENDIF
      ENDIF
      FILOPT = 4
C
      NFRMBG = NDATROW+1
      CALL RDFRAME(CVAL(NCVBG),RVAL,MXDATROW,NFRMBG,FILOPT,IGRAPH,
     +             NUMCOL,COLHDR,FRMTITLE,FRMSUB,NFRMFN,RTNCODE)
      IF (RTNCODE.NE.'0') THEN
         NERR=NERR+1
         MSGIDX(NERR)=ICHAR(RTNCODE)-48
         GO TO 900
      ENDIF
      NDATROW = NDATROW + NFRMFN-NFRMBG+1
      NBRFRM = NBRFRM+1
      FRMPTR(NBRFRM)=NFRMBG
      TTLSAV(1,NBRFRM)=FRMTITLE
      TTLSAV(2,NBRFRM)=FRMSUB
      NFRMCUR=NBRFRM
C
   50 CONTINUE     
C
C       ** POSITION FILE TO START OF FIRST FRAME IN MEMORY
C
      FILOPT = 5
      NPREV=NFRMCUR-1
      DO 55 I=1,NPREV
         CALL RDFRAME(CVAL(NCVBG),RVAL,MXDATROW,NFRMBG,FILOPT,IGRAPH,
     +                NUMCOL,COLHDR,FRMTITLE,FRMSUB,NFRMFN,RTNCODE)
         IF (RTNCODE.NE.'0') GO TO 56
   55 CONTINUE
   56 CONTINUE
      IF (RTNCODE.NE.'0') THEN
         NERR=NERR+1
         MSGIDX(NERR)=ICHAR(RTNCODE)-48
         IF (RTNCODE.EQ.'2') THEN
C             .. ERROR: ATTEMPT TO POSITION FILE BEFORE START OF DATA
            RTNCODE='0'
         ENDIF
      ENDIF
C
      IF (NERR.GT.0) GO TO 900      
C      
      RETURN
C
C       ** ERROR PROCESSING
C
  900 CONTINUE
C
C             .. TEXT MESSAGE
         DO 905 I=1,NERR
            MSGN1 = MSGNBR(MSGIDX(I))
            IF (MSGNBR(I).EQ.1 .OR. MSGNBR(I).EQ.3) THEN
               MSGTXT='  GRAPHICS.API'
               LENMSG=14
            ELSE
               MSGTXT=' '
               LENMSG=0
            ENDIF      
            CALL WRTMSG(2,MSGN1,12,1,1,MSGTXT,LENMSG)
  905    CONTINUE      
         IF (RTNSET.NE.'0') RTNCODE=RTNSET
C  
      RETURN      
      END
