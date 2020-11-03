$STORAGE:2
      PROGRAM TRANSFER
C
C   PROGRAM COPIES DATA TO AND FROM THE CLICOM OFF-LINE ARCHIVE BY 
C   WRITING THE CALL TO BATCH FILE "ARCHIVE.BAT".  IT ALSO KEEPS TRACK OF
C   WHERE THE RECORDS ARE WRITTEN BY USING THE DATAEASE DATASET DIRECTORY
C   (DSD) FORM AND RECORDS THE NUMBER OF RECORDS WRITTEN/READ IN THE 
C   DATAEASE MASTER FILE DIRECTORY (RDRRAAAA.DBM).  THIS PROGRAM HAS BEEN
C   MODIFIED TO USE EITHER DATAEASE VERSION 2.5 OR DATAEASE VERSION 4.0
C
C   THIS ROUTINE IS ALSO USED TO CLEAR CLIMATE FILES FROM ON-LINE
C
      CHARACTER*2 RTNFLAG
      CHARACTER*3 RECDEF(8)
      CHARACTER*4 INLVL
      CHARACTER*22 FILENAME
      CHARACTER*24 FRMNAM(8)
      CHARACTER*64 HELPFILE
      INTEGER*4 NUMREC
C
      DATA RECDEF /'MLY','10D','DLY','SYN','HLY','15M','U-A','NML'/
      DATA FRMNAM /'MONTHLY DATA','TEN DAY DATA','DAILY DATA'
     +   ,'SYNOPTIC DATA','HOURLY DATA','FIFTEEN MINUTE DATA'
     +   ,'UPPER-AIR DATA','NORMALS'/
C
      HELPFILE = 'P:\HELP\MENU8.HLP'
C
C   SET THE OUTPUT BATCH FILE SO IT WILL CALL CLICOM2 IF NO DATA IS
C   SELECTED
C
      OPEN (61,FILE='P:\BATCH\ARCHIVE.BAT',STATUS='UNKNOWN')
      WRITE(61,'(A8)') 'CLICOM2 '
      REWIND (61)
C
C   IF LOW LEVEL USER, USE MENU ARCHIVE 2, IF HIGHER LEVEL
C   USE MENU ARCHIVE 1
C
      CALL GETAUT(INLVL)
20    CONTINUE
      CALL CLS
      IF (INLVL.EQ.'LOW ') THEN
         CALL LOCATE (1,15,IERR)
         CALL GETMNU('ARCHIVE2     ',HELPFILE,ICHOICE)
         IF (ICHOICE.EQ.2) THEN
            ICHOICE = 3
         END IF
      ELSE
         CALL LOCATE (1,15,IERR)
         CALL GETMNU('ARCHIVE1    ',HELPFILE,ICHOICE)
      END IF
      IF (ICHOICE.EQ.0) THEN
         CLOSE (61)
         CALL LOCATE(24,0,IERR)
         STOP ' '
      END IF
C
C   FIND THE FILE NAME OF THE DATAEASE DATASET DIRECTORY
C
      CALL FNDFIL('DATASET DIRECTORY       ',FILENAME,NUMREC)
      IF (FILENAME.EQ.' ') THEN
         CALL LOCATE(24,0,IERR)
         STOP ' '
      END IF
C
C   CALL THE APPROPRIATE SUBROUTINE TO READ DATA FROM OR WRITE DATA
C   TO THE OFF-LINE ARCHIVE OR CLEAR A FILE FROM ON-LINE
C
      IF (ICHOICE.EQ.1) THEN
         CALL FRMARCH(FILENAME,FRMNAM,RECDEF,RTNFLAG)
      ELSE IF (ICHOICE.EQ.2) THEN
         CALL TOARCH(FILENAME,RECDEF,RTNFLAG)
      ELSE
         CALL CLEAR(FRMNAM,RECDEF,RTNFLAG)
      END IF
      IF (RTNFLAG.EQ.'4F') THEN
         GO TO 20
      END IF
      CLOSE(61)
      CALL CLS
      CALL LOCATE(0,0,IERR)
      STOP ' ' 
      END
$PAGE
***********************************************************************
      SUBROUTINE TOARCH(FILENAME,RECDEF,RTNFLAG)
C
C   ROUTINE FOR OUTPUT TO ARCHIVE - IT ASKS THE USER FOR THE 
C   STATION/DATE RANGE AND THE FILE AND CARTRIDGE ID'S TO BE USED, 
C   CHECKS IF THE FILE AND CARTRIDGE ARE ALREADY IN USE, WRITES THE
C   NUMBER OF RECORDS IN THE FILE TO THE *.FDN FILE, AND WRITES THE
C   CALL TO THE TO-ARCH BATCH FILE.

      CHARACTER*1 DSDREC(72),RDREC(51),REPLY,DSDTYPE,RDREC4(55)
      CHARACTER*2 INNUM,INDEL,RTNFLAG,INCHAR
      CHARACTER*3 RECTYPE,DATASET,DDSID,RECDEF(8),DEVER
      CHARACTER*4 NUMUSES,INNUM4,INDEL4,CHRREC,CHRDEL
      CHARACTER*6 WRTDATE,RDDATE
      CHARACTER*8 DSDBSTN,DSDESTN,DSDBDATE,DSDEDATE,DSDFILE,DSDCART
     +           ,FIELD(8),BEGSTN,ENDSTN,BEGDATE,ENDDATE,FILEID,CARTID
     +           ,DEASFILE
      CHARACTER*14 FILE,FDFFILE,FILE4
      CHARACTER*22 FILENAME
      CHARACTER*24 INFORM,INFRM4
      CHARACTER*78 MSGLN1,MSGLN2
      INTEGER*2 RECNUM,RDRHDR,DSDHDR(2),RDRHD4,NUMREC2,NUMDEL2
      INTEGER*4 NUMREC,NUMDEL,DATAREC

      EQUIVALENCE (RDRHDR,RDREC(1)),(INFORM,RDREC(3))
     +      ,(INNUM,RDREC(30)),(INDEL,RDREC(32)),(FILE,RDREC(34))
      EQUIVALENCE (RDRHD4,RDREC4(1)),(INFRM4,RDREC4(3))
     +      ,(INNUM4,RDREC4(30)),(INDEL4,RDREC4(34)),(FILE4,RDREC4(38))
      EQUIVALENCE (CHRREC,NUMREC),(CHRDEL,NUMDEL)
      EQUIVALENCE (DSDHDR,DSDREC(1)),(DSDTYPE,DSDREC(5))
     +      ,(DDSID,DSDREC(6)),(DSDBSTN,DSDREC(9)),(DSDESTN,DSDREC(17))
     +      ,(DSDBDATE,DSDREC(25)),(DSDEDATE,DSDREC(33))
     +      ,(DSDFILE,DSDREC(41)),(DSDCART,DSDREC(49))
     +      ,(WRTDATE,DSDREC(57)),(RDDATE,DSDREC(63))
     +      ,(NUMUSES,DSDREC(69))
C
C   ASK THE USER FOR THE STATION, DATE, AND FILE INFO NEEDED
C
      DO 10 I = 1,8
         FIELD(I) = ' '
10    CONTINUE
30    CONTINUE
      CALL LOCATE(7,1,IERR)
      RTNFLAG = ' '
      CALL GETFRM('TO-ARCHA',' ',FIELD,8,RTNFLAG)
      IF (RTNFLAG.EQ.'4F') THEN
         RETURN
      END IF
      RECTYPE = FIELD(1)
      DATASET = FIELD(2)
      BEGSTN = FIELD(3)
      ENDSTN = FIELD(4)
      BEGDATE = FIELD(5)
      BEGDATE(7:8) = '01'
      ENDDATE = FIELD(6)
      ENDDATE(7:8) = '31'
      FILEID = FIELD(7)
      CARTID = FIELD(8)      
C
C  DETERMINE THE INDEX FOR THE RECORD TYPE SELECTED
C
      ITYPE = 0
      DO 40 I1 = 1,8
         IF (RECTYPE.EQ.RECDEF(I1)) THEN
            ITYPE = I1
         END IF
40    CONTINUE
      IF (ITYPE.EQ.0) THEN
         CALL WRTMSG(3,175,12,1,1,RECTYPE,3)
         GO TO 30
      END IF
C
C   CHECK FOR EXISTENCE OF THIS FILE/CARTRIDGE ID IN THE DSD FILE         
C
60    CONTINUE
      OPEN (25,FILE=FILENAME,STATUS='OLD',FORM='BINARY',SHARE='DENYWR'
     +       ,MODE='READWRITE',ACCESS='DIRECT',RECL=72,IOSTAT=IOCHK)
      IF (IOCHK.NE.0) THEN
         CALL OPENMSG(FILENAME,'ARCHIVE    ',IOCHK)
         GO TO 60
      END IF
      JREC = 0
      DO 100 I1 = 1,9999
         IREC = I1
         READ(25,REC=I1,ERR=120) DSDREC
         IF (DSDHDR(1).NE.12.AND.DSDHDR(1).NE.14) THEN
            GO TO 100
         END IF
C
C    THERE IS ALREADY A FILE ON THE CARTRIDGE SPECIFIED WITH THIS
C    NAME - OK?
C
         IF (DSDFILE.EQ.FILEID.AND.DSDCART.EQ.CARTID) THEN
             CALL LOCATE(20,0,IERR)
             CALL WRTMSG(4,358,12,0,0,' ',0)
             CALL WRTMSG(3,359,12,1,0,' ',0)
             CALL LOCATE(23,0,IERR)
             CALL OKREPLY(REPLY,RTNFLAG)
             CALL CLRMSG(4) 
             CALL CLRMSG(3) 
             CALL CLRMSG(2) 
             IF (RTNFLAG.EQ.'4F'.OR.REPLY.EQ.'N') THEN
                CLOSE (25)
                GO TO 30
             ELSE
                JREC = I1
                GO TO 120
             END IF
          END IF
100   CONTINUE
120   CONTINUE
      
C 
C    DETERMINE WHICH VERSION OF DATAEASE IS IN USE
C
      CALL GETDEASE(DEVER)
      IF (DEVER.EQ.'4.0') THEN
         GOTO 130
      END IF
C *****************************************************************************
C *                     CODE FOR DATAEASE 2.5
C *****************************************************************************
C  
C   FIND THE FILE NAME AND NUMBER OF RECORDS OF THE DATAEASE FORM WANTED.
C   THEN WRITE THE NUMBER OF RECORDS IN THE FILE TO BE ARCHIVED INTO THE 
C   APPROPRIATE FDN FILE.
C   ** NOTE:  FOR DATAEASE 2.5 THE NUMBER OF RECORDS IS WRITTEN WITH A
C             FORMAT OF 2I6.  THE FORMAT IS LARGE ENOUGH BECAUSE OF THE 65K
C             LIMIT ON RECORDS.  THIS FORMAT ALLOWS ROUTINE FRM-ARCH TO
C             DISTINGUISH BETWEEN .FDN FILES WRITTEN UNDER DEASE 2.5 (2I6)
C             AND DEASE 4.X (2I10) AND MAKE THE PROPER ADJUSTMENTS.  
C             CLICOM 2.1 ONLY USED DEASE 2.5 AND USED A FORMAT OF 2I6.
C
      CALL RDRREC(RECTYPE,RECNUM)
      IF (RECNUM.EQ.0) THEN
         RETURN
      ELSE
         READ(22,REC=RECNUM) RDREC
         DEASFILE = FILE(3:10)
         FDFFILE = FILE
         FDFFILE(12:14) = 'FDN'
         OPEN (72,FILE=FDFFILE,STATUS='UNKNOWN',FORM='FORMATTED')
         CHRREC(1:2) = INNUM(1:2)
         CHRREC(3:4) = 0
         CHRDEL(1:2) = INDEL(1:2)
         CHRDEL(3:4) = 0
         NUMREC2 = NUMREC
         NUMDEL2 = NUMDEL
         WRITE(72,'(2I6)') NUMREC2,NUMDEL2
         DATAREC = NUMREC
         CLOSE (72)
         CLOSE (22)
      END IF
      GOTO 140
C *****************************************************************************
C *                     CODE FOR DATAEASE 4.0
C *****************************************************************************
C  
C   FIND THE FILE NAME AND NUMBER OF RECORDS OF THE DATAEASE FORM WANTED.
C   THEN WRITE THE NUMBER OF RECORDS IN THE FILE TO BE ARCHIVED INTO THE 
C   APPROPRIATE FDN FILE.
C
 130  CALL RDRREC(RECTYPE,RECNUM)
      IF (RECNUM.EQ.0) THEN
         RETURN
      ELSE
         READ(22,REC=RECNUM) RDREC4
         DEASFILE = FILE4(3:10)
         FDFFILE = FILE4
         FDFFILE(12:14) = 'FDN'
         OPEN (72,FILE=FDFFILE,STATUS='UNKNOWN',FORM='FORMATTED')
         CHRREC = INNUM4(1:4)
         CHRDEL = INDEL4(1:4)
         WRITE(72,'(2I10)') NUMREC,NUMDEL
         DATAREC = NUMREC
         CLOSE (72)
         CLOSE (22)
      END IF
C ********************* END DATAEASE VERSION 4.0 CODE ************************

C
C   WRITE A NEW DATASET DIRECTORY RECORD OR UPDATE AN EXISTING ONE AS 
C   APPROPRIATE
C      
 140  DSDHDR(1) = 12
      DSDHDR(2) = 0
      DSDTYPE(1:1) = CHAR(ITYPE)
      DDSID = DATASET 
      DSDBSTN = BEGSTN
      DSDESTN = ENDSTN 
      DSDBDATE = BEGDATE 
      DSDEDATE = ENDDATE 
      DSDFILE = FILEID 
      DSDCART = CARTID 
C **DEBUG      
C      CALL DATE(IYEAR,ICOMP)
C      IMON = ICOMP / 256
C      IDAY = MOD(ICOMP,256)
C      IYEAR = IYEAR - 1900
C      WRITE(WRTDATE,'(3I2.2)') IMON,IDAY,IYEAR
C
      CALL GTDSDDAT(WRTDATE)
C      
      IF (JREC.GT.0) THEN
         WRITE (25,REC=JREC) DSDREC
      ELSE
         RDDATE = WRTDATE
         NUMUSES(1:1) = CHAR(0)
         NUMUSES(2:2) = CHAR(0)
         NUMUSES(3:3) = CHAR(0)
         NUMUSES(4:4) = CHAR(0)
         WRITE (25,REC=IREC) DSDREC
         CALL RDRREC('DDS',RECNUM)
         READ(22,REC=RECNUM) RDREC
         CHRREC = INNUM(1:2)
C    --- NUMREC NOW = INNUM BECAUSE OF EQUIVALENCE TO CHRREC
         NUMREC = NUMREC + 1                    
         INNUM(1:2) = CHRREC
         WRITE(22,REC=RECNUM) RDREC
         CLOSE(22)
      END IF
      CLOSE(25)
C
C    WRITE THE CALL TO THE TO-ARCH BAT FILE     
C
      WRITE(61,150)  CARTID, DEASFILE, FILEID 
150   FORMAT ('TO-ARCH',3(1X,A8))
C
C   WRITE SUMMARY MESSAGE TO USER
C
      CALL GETMSG(275,MSGLN1)
      CALL GETMSG(202,MSGLN2)
      CALL LOCATE(20,0,IERR)
      WRITE(*,200) DATAREC,RECTYPE,MSGLN1
200   FORMAT(/,2X,I6,A4,A64)
      LGTH = LNG(MSGLN2)
      CALL LOCATE(22,0,IERR)
      CALL WRTSTR(MSGLN2,LGTH,15,0)
      CALL GETCHAR(0,INCHAR)
      RETURN      
      END
$PAGE
************************************************************************
      SUBROUTINE FRMARCH(FILENAME,FRMNAM,RECDEF,RTNFLAG)
C
C   ROUTINE FOR RETRIEVING DATA FROM ARCHIVE - IT ASKS THE USER
C   FOR THE STATION/DATE RANGE WANTED, DETERMINES IF THE DATA IS STORED 
C   ON MULTIPLE CARTRIDGES, AND WRITES THE CALL TO THE FRM-ARCH BATCH
C   FILE.

      CHARACTER*1 DSDREC(72),DSDTYPE,ARROW1,ARROW2
      CHARACTER*2 RTNFLAG,INCHAR
      CHARACTER*3 RECTYPE,DATASET,RECDEF(8),DDSID,DEVERS
      CHARACTER*4 NUMUSES,CHRUSE
      CHARACTER*6 WRTDATE,RDDATE,TODATE
      CHARACTER*8 DSDBSTN,DSDESTN,DSDBDATE,DSDEDATE,DSDFILE,DSDCART
     +           ,FIELD(6),BEGSTN,ENDSTN,BEGDATE,ENDDATE,FILEID(6)
     +           ,CARTID(6),DEASFILE,DISPDATE
      CHARACTER*22 FILENAME,OUTFILE
      CHARACTER*24 FRMNAM(*)
      CHARACTER*30 FRMT
      CHARACTER*64 HELPFILE
      CHARACTER*72 DIRLIN(14)
      INTEGER*2 DSDHDR(2),SELREC(14),HSELREC(6)
      INTEGER*4 NUSE,NUMREC
      LOGICAL FILEOK(14),MSGSET

      EQUIVALENCE (DSDHDR,DSDREC(1)),(DSDTYPE,DSDREC(5))
     +      ,(DDSID,DSDREC(6)),(DSDBSTN,DSDREC(9)),(DSDESTN,DSDREC(17))
     +      ,(DSDBDATE,DSDREC(25)),(DSDEDATE,DSDREC(33))
     +      ,(DSDFILE,DSDREC(41)),(DSDCART,DSDREC(49))
     +      ,(WRTDATE,DSDREC(57)),(RDDATE,DSDREC(63))
     +      ,(NUMUSES,DSDREC(69)),(CHRUSE,NUSE)
C
      DATA HELPFILE/'P:\HELP\FRM-ARCH.HLP'/         
C
      CALL GETDEASE(DEVERS)
      IF (DEVERS.EQ.'4.0') THEN
         NMSG = 497
      ELSE
         NMSG = 496
      END IF
C
      ARROW1 = CHAR(16)
      ARROW2 = CHAR(17)
C
C   ASK THE USER FOR THE STATION AND DATES WANTED
C
      DO 10 I = 1,8
         FIELD(I) = ' '
10    CONTINUE
30    CONTINUE
      RTNFLAG = 'SS'
      CALL LOCATE(7,1,IERR)
      CALL GETFRM('FRM-ARCH',HELPFILE,FIELD,8,RTNFLAG)
      IF (RTNFLAG.EQ.'4F') THEN
         RETURN
      END IF
      RECTYPE = FIELD(1)
      DATASET = FIELD(2)
      BEGSTN = FIELD(3)
      ENDSTN = FIELD(4)
      BEGDATE = FIELD(5)
      BEGDATE(7:8) = '01'
      ENDDATE = FIELD(6)
      ENDDATE(7:8) = '31'
C
C  DETERMINE THE INDEX FOR THE RECORD TYPE SELECTED
C
      ITYPE = 0
      DO 40 I1 = 1,8
         IF (RECTYPE.EQ.RECDEF(I1)) THEN
            ITYPE = I1
         END IF
40    CONTINUE
      IF (ITYPE.EQ.0) THEN
         CALL WRTMSG(3,175,12,1,1,RECTYPE,3)
         GO TO 30
      END IF
C
C   FIND THE NAME OF THE DATAEASE FILE FOR THIS FORM
C
      CALL FNDFIL(FRMNAM(ITYPE),OUTFILE,NUMREC)
      IF (OUTFILE.EQ.'  ') THEN
         RETURN
      END IF
      DEASFILE = OUTFILE(3:10)
C
C   FIND THE RECORD(S) FOR THIS DATA IN THE DSD FILE.         
C
60    CONTINUE
      OPEN (25,FILE=FILENAME,STATUS='OLD',FORM='BINARY',SHARE='DENYWR'
     +       ,MODE='READ',ACCESS='DIRECT',RECL=72,IOSTAT=IOCHK)
      IF (IOCHK.NE.0) THEN
         CALL OPENMSG(FILENAME,'ARCHIVE    ',IOCHK)
         GO TO 60
      END IF
      JNUM = 0
      DO 100 I1 = 1,9999
         READ(25,REC=I1,ERR=120) DSDREC
         IF (DSDHDR(1).NE.12.AND.DSDHDR(1).NE.14) THEN
            GO TO 100
         END IF
         JTYPE = ICHAR(DSDTYPE)
         IF (ITYPE.NE.JTYPE.OR.DATASET.NE.DDSID.OR.BEGSTN.GT.DSDESTN
     +         .OR.ENDSTN.LT.DSDBSTN.OR.BEGDATE.GT.DSDEDATE.OR.
     +             ENDDATE.LT.DSDBDATE) THEN
             GO TO 100
         END IF     
         JNUM = JNUM + 1
         IF (JNUM.GT.14) THEN
            CALL WRTMSG(4,360,12,0,0,' ',0)
            CALL WRTMSG(3,361,12,1,1,' ',0)
            CLOSE(25)
            CALL CLS
            GO TO 30
         ELSE
            DISPDATE = '  /  /  '
            DISPDATE(1:2) = RDDATE(1:2)
            DISPDATE(4:5) = RDDATE(3:4)
            DISPDATE(7:8) = RDDATE(5:6)
            WRITE(DIRLIN(JNUM),90) DSDFILE,DSDCART,DSDBSTN,'-',DSDESTN
     +            ,DSDBDATE,'-',DSDEDATE,DISPDATE
90          FORMAT(2(A8,2X),1X,A8,A1,A8,3X,A6,A1,A6,2X,A8)
            SELREC(JNUM) = I1
         END IF
100   CONTINUE
120   CONTINUE
      CLOSE(25)
C
C  IF ONE RECORD FOUND WRITE THE CALL TO FRM-ARCH AND RETURN
C
      IF (JNUM.EQ.0) THEN
         CALL WRTMSG(3,177,12,1,1,' ',0)
         CALL CLS
         GO TO 30
      ELSE IF (JNUM.EQ.1) THEN
         READ(DIRLIN(JNUM),'(A8,2X,A8)') FILEID(1),CARTID(1)
         WRITE(61,130) CARTID(1),RECTYPE,DEASFILE,FILEID(1)
130      FORMAT ('FRM-ARCH ',A8,1X,A3,2(1X,A8))
C
C   IF MULTIPLE RECORDS FOUND ASK THE USER TO SELECT THE FILES HE WANTS
C
      ELSE 
         CALL CLS
         CALL WRTMSG(24,353,14,0,0,' ',0)
         CALL WRTMSG(23,354,14,0,0,' ',0)
         CALL WRTMSG(22,355,14,0,0,' ',0)
         CALL WRTMSG(21,356,14,0,0,' ',0)
         CALL WRTMSG(19,362,15,0,0,' ',0)
         CALL WRTMSG(1,NMSG,11,0,0,' ',0)
         IROW = 7
         DO 150 J = 1,JNUM
            JROW = IROW + J
            CALL LOCATE(JROW,4,IERR)
            CALL WRTSTR(DIRLIN(J),64,14,0)
150      CONTINUE
C
C   ASK THE USER TO HIGHLIGHT THE FILES THAT HE WANTS TO SELECT (MAX 6)     
C
         IROW = 8
         ITOP = 8
         IBOT = IROW + JNUM - 1
         ISEL = 0
160      CONTINUE
         CALL LOCATE(IROW,2,IERR)
         CALL CHRWRT(ARROW1,0,12,1)
         CALL LOCATE(IROW,69,IERR)
         CALL CHRWRT(ARROW2,0,12,1)
         CALL GETCHAR(0,INCHAR)
         IF (MSGSET) THEN
            MSGSET = .FALSE.
            CALL CLRMSG(2)
         END IF
         IF (INCHAR.EQ.'4F') THEN
            CALL CLS
            GO TO 30         
         ELSE IF (INCHAR.EQ.'2F') THEN
            GO TO 170
         ELSE IF (INCHAR.EQ.'UP'.OR.INCHAR.EQ.'UA') THEN
            CALL LOCATE(IROW,2,IERR)
            CALL WRTSTR(' ',1,12,0)
            CALL LOCATE(IROW,69,IERR)
            CALL WRTSTR(' ',1,12,0)
            IROW = IROW - 1
            IF (IROW.LT.ITOP) THEN
               IROW = IBOT
            END IF                     
         ELSE IF (INCHAR.EQ.'DP'.OR.INCHAR.EQ.'DA') THEN
            CALL LOCATE(IROW,2,IERR)
            CALL WRTSTR(' ',1,12,0)
            CALL LOCATE(IROW,69,IERR)
            CALL WRTSTR(' ',1,12,0)
            IROW = IROW + 1
            IF (IROW.GT.IBOT) THEN
               IROW = ITOP
            END IF                     
         ELSE IF (INCHAR.EQ.'  ') THEN
            J = IROW - ITOP + 1
            IF (FILEOK(J)) THEN
               IFG = 14
               IBG = 0
               FILEOK(J) = .FALSE.
               ISEL = ISEL - 1
            ELSE
               IF (ISEL.LT.6) THEN
                  IFG = 15
                  IBG = 1
                  ISEL = ISEL + 1
                  FILEOK(J) = .TRUE.
               ELSE
                  IFG = 14
                  IBG = 0
                  CALL WRTMSG(2,176,12,1,0,' ',0)
                  MSGSET = .TRUE.
               END IF
            END IF
            CALL LOCATE(IROW,4,IERR)
            CALL WRTSTR(DIRLIN(J),64,IFG,IBG)
         END IF
         GO TO 160
170      CONTINUE
         INUM = 0
         DO 180 J = 1,JNUM
            IF (FILEOK(J)) THEN
               INUM = INUM + 1
               READ(DIRLIN(J),'(A8,2X,A8)') FILEID(INUM),CARTID(INUM)
               HSELREC(INUM) = SELREC(J)
            END IF
180      CONTINUE            
C
C    IF ONLY ONE FILE SELECTED WRITE CALL TO FRM-ARCH BATCH FILE, ELSE
C    WRITE CALL TO MRG-ARCH BATCH FILE - PASS RECTYPE AS LAST PARAMETER
C
         IF (INUM.EQ.1) THEN
            WRITE(61,130) CARTID(1),RECTYPE,DEASFILE,FILEID(1)
         ELSE IF (INUM.GT.0) THEN
            WRITE(FRMT,190) INUM*2
  190       FORMAT('(''MRG-ARCH'',',I2,'(1X,A8),1X,A1)')
            WRITE(61,FRMT) (CARTID(J),FILEID(J),J=1,INUM),'@'
C  190       FORMAT ('MRG-ARCH',12(1X,A8),1X,A1,1X,A3)
C
            OPEN (62,FILE='P:\BATCH\CALLARC2.BAT',STATUS='UNKNOWN')
            WRITE(62,191) RECTYPE,DEASFILE
  191       FORMAT('MRG-ARC2 ',A3,1X,A8)
            CLOSE(62)
C
C    WRITE SELECTION INFO INTO FILE FOR USE BY SELECTION PROGRAM THAT
C    IS USED AS PART OF THE MERGE (SELMERGE) - ALSO INITIALIZE ALL
C    OUTPUT FILES (Q:FILE0001.TMP THRU Q:FILE0006.TMP) 
C
            OPEN(63,FILE='P:\DATA\SELECT.CMD',STATUS='UNKNOWN'
     +          ,FORM='UNFORMATTED')
            IMERGE = 1
            IREC = 0
            WRITE(63) RECTYPE,BEGSTN,ENDSTN,BEGDATE,ENDDATE,IMERGE
            CLOSE(63)
            DO 200 IMERGE = 1,6
               WRITE(OUTFILE,'(A9,I1,A4)')  'Q:FILE000',IMERGE,'.TMP'
               OPEN (63,FILE=OUTFILE,STATUS='UNKNOWN',FORM='BINARY')
               ENDFILE 63
               CLOSE (63)
200         CONTINUE      
         END IF
      END IF
C
C   UPDATE THE NUMBER OF USES AND LAST USED DATE FOR THE DATASET DIRECTORY
C   RECORDS USED
C
C      CALL DATE(IYEAR,ICOMP)
C      IMON = ICOMP / 256
C      IDAY = MOD(ICOMP,256)
C      IYEAR = IYEAR - 1900
C      WRITE(TODATE,'(3I2.2)') IMON,IDAY,IYEAR
      CALL GTDSDDAT(TODATE)
      OPEN (25,FILE=FILENAME,STATUS='OLD',FORM='BINARY',SHARE='DENYRW'
     +       ,MODE='READWRITE',ACCESS='DIRECT',RECL=72,IOSTAT=IOCHK)
      DO 300 J = 1,INUM
         READ(25,REC=HSELREC(J)) DSDREC
         RDDATE = TODATE         
         CHRUSE = NUMUSES
C   ---  NUSE = NUMUSES BECAUSE OF EQUIVALENCE TO CHRUSE
         NUSE = NUSE + 1 
         NUMUSES = CHRUSE
         WRITE(25,REC=HSELREC(J)) DSDREC
300   CONTINUE
      RETURN
      END
************************************************************************
      SUBROUTINE CLEAR(FRMNAM,RECDEF,RTNFLAG)
C
C   ROUTINE WRITES A BATCH FILE TO CLEAR CLIMATE DATA FROM ON-LINE
C
      CHARACTER*2 RTNFLAG,INNUM,INDEL
      CHARACTER*3 RECDEF(8),DEVER
      CHARACTER*4 INNUM4,INDEL4,CHRREC,CHRDEL
      CHARACTER*22 DEASFILE,NULLFILE
C      CHARACTER*22 FDFFILE
      CHARACTER*24 FRMNAM(*)
      CHARACTER*1 RDREC(51),RDREC4(55),REPLY
      INTEGER*2  RECNUM
      INTEGER*4 NUMREC,NUMDEL

      EQUIVALENCE (INNUM,RDREC(30)),(INDEL,RDREC(32))
      EQUIVALENCE (INNUM4,RDREC4(30)),(INDEL4,RDREC4(34))
      
      EQUIVALENCE (CHRREC,NUMREC),(CHRDEL,NUMDEL)
C
C   ASK THE USER FOR THE TYPE OF DATA TO CLEAR
C
      RTNFLAG = '  '
      CALL LOCATE(8,24,IERR)
      ITYPE = 0
      CALL GETMNU('ARCH-DTYPES','  ',ITYPE)
      IF (ITYPE.EQ.0) THEN
         RTNFLAG = '4F'
         RETURN
      END IF
C
C   FIND THE NAME OF THE DATAEASE CLIMATE FILE FOR THIS DATA TYPE
C
      CALL FNDFIL(FRMNAM(ITYPE),DEASFILE,NUMREC)
      IF (DEASFILE.EQ.'  ') THEN
         RETURN
      END IF
C
C  ASK USER IF HE REALLY WANTS TO CLEAR DATA      
C
      CALL WRTMSG(2,455,12,1,0,FRMNAM(ITYPE),24)
      CALL LOCATE(23,55,IERR)
      CALL OKREPLY(REPLY,RTNFLAG)
      IF (RTNFLAG.EQ.'4F'.OR. REPLY.NE.'Y') THEN
         RTNFLAG = '4F'
         RETURN
      ENDIF   
C
C  DELETE THE EXISTING CLIMATE DATA FILE AND RECREATE IT (0 LENGTH)
C
100   CONTINUE
      OPEN (25,FILE=DEASFILE,STATUS='OLD',MODE='WRITE',IOSTAT=IOCHK)
      IF (IOCHK.NE.0) THEN
         IF (IOCHK.NE.6416) THEN
            CALL OPENMSG(DEASFILE,'CLEAR          ',IOCHK)
            GO TO 100
         END IF
      ELSE
         CLOSE (25,STATUS='DELETE')
      END IF            
      OPEN (25,FILE=DEASFILE,STATUS='NEW',FORM='BINARY')
      CLOSE (25)
C
C  WRITE THE ARCHIVE BAT FILE TO COPY THE APPROPRIATE INDEX FILE
C
      WRITE(61,'(A8)') 'ECHO OFF'
      NULLFILE = 'Q:NULL????.I??'
      NULLFILE(7:10) = DEASFILE(3:6)
      DEASFILE(12:14) = '*  '
      WRITE(61,150) 'COPY ',NULLFILE,DEASFILE,'> NUL'
150   FORMAT (A5,A14,1X,A14,A5)
      WRITE(61,160) 'ECHO ',FRMNAM(ITYPE), 'file erased from on-line. '
160   FORMAT (A5,A15,A26)
      WRITE(61,'(A5)') 'PAUSE'
      WRITE(61,'(A8)') 'CLICOM2 '
C 
C    DETERMINE WHICH VERSION OF DATAEASE IS IN USE
C
      CALL GETDEASE(DEVER)
      IF (DEVER.EQ.'4.0') THEN
         GOTO 500
      END IF
      
C *****************************************************************************
C *                     CODE FOR DATAEASE 2.5
C *****************************************************************************
C
C   UPDATE THE RDRRAAAA AND *.FDN FILES TO INDICATE 0 RECORDS FOR THIS
C   DATAEASE FILE
C   ** NOTE:  *.FDN FILE DOES NOT HAVE TO BE UPDATED.  IT IS ALWAYS WRITTEN
C             EVERY TIME AN ARCHIVE IS PERFORMED.
C
      CALL RDRREC(RECDEF(ITYPE),RECNUM)
      READ(22,REC=RECNUM) RDREC
      NUMREC = 0
      NUMDEL = 0                    
      INNUM(1:2) = CHRREC
      INDEL(1:2) = CHRDEL
C --- INNUM NOW = 0 BECAUSE OF NUMREC EQUIVALENCE TO CHRREC
      WRITE(22,REC=RECNUM) RDREC
      CLOSE(22)
      GOTO 800
C *****************************************************************************
C *                     CODE FOR DATAEASE 4.0
C *****************************************************************************
C
C   UPDATE THE RDRRAAAA AND *.FDN FILES TO INDICATE 0 RECORDS FOR THIS
C   DATAEASE FILE
C
 500  CALL RDRREC(RECDEF(ITYPE),RECNUM)
      READ(22,REC=RECNUM) RDREC4
      NUMREC = 0
      NUMDEL = 0                    
      INNUM4(1:4) = CHRREC
      INDEL4(1:4) = CHRDEL
C --- INNUM4 NOW = 0 BECAUSE OF NUMREC EQUIVALENCE TO CHRREC
      WRITE(22,REC=RECNUM) RDREC4
      CLOSE(22)
C ************************** CODE FOR DATAEASE 4.0 ENDS ***********************

  800 CONTINUE
C      FDFFILE = DEASFILE
C      FDFFILE(12:14) = 'FDN'
C      OPEN (72,FILE=FDFFILE,STATUS='UNKNOWN',FORM='FORMATTED')
C      WRITE (72,'(2I10)') NUMREC, NUMDEL
C      CLOSE(72) 
      RETURN
      END
*****************************************************************************
      SUBROUTINE GTDSDDAT(CHRDATE)
C
C       ** OBJECTIVE:  GET THE DATE FORMAT FROM THE DATAEASE CONFIGURATION
C                      FILE.  RETURN THE CURRENT DATE IN THIS DATE FORMAT.
C       ** OUTPUT:
C             CHRDATE....CURRENT DATE IN THE FORMAT USED BY DATAEASE
C
      CHARACTER*6 CHRDATE
C      
      PARAMETER (MXFMT=3)
      INTEGER*2 IDATE(3),IDXDATE(3,MXFMT)
C
C       ** FORMAT   INDEX   DATE       NAME      
C          1        123     MM-DD-YY   NORTH AMERICAN
C          2        213     DD-MM-YY   INTERNATIONAL
C          3        312     YY-MM-DD   METRIC
C
      DATA IDXDATE/1,2,3,  2,1,3,  3,1,2/
      DATA IFMT/0/
C
C       ** GET THE CURRENT DATE FORMAT USED BY DATAEASE
C
      IF (IFMT.EQ.0) THEN
         CALL RDDATCFG(IFMT)
C          .. SET THE YEAR, MONTH, DAY INDEXES FOR THE CURRENT DATE FORMAT
         IDX1 = IDXDATE(1,IFMT)
         IDX2 = IDXDATE(2,IFMT)
         IDX3 = IDXDATE(3,IFMT)
      ENDIF               
C
C       ** WRITE THE CURRENT DATE IN THE DATAEASE DATE FORMAT      
C            
C       .. YEAR
      CALL DATE(IDATE(3),ICOMP)
      IDATE(3) = IDATE(3) - 1900
C       .. MONTH      
      IDATE(1) = ICOMP / 256
C       .. DAY
      IDATE(2) = MOD(ICOMP,256)
C      
      WRITE(CHRDATE,'(3I2.2)') IDATE(IDX1),IDATE(IDX2),IDATE(IDX3)
C
      RETURN
      END      

