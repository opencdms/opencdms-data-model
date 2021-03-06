$STORAGE:2
      SUBROUTINE TXTSIZ(STRING,XNWPOS,YNWPOS,THGT,ASP,IFONT,PATH,COLOR,
     +           LIMITS,IBKG)
C------------------------------------------------------------------------------
C     ROUTINE TO ADJUST THE SIZE OF A TEXT STRING USING THE CUSOR OR MOUSE.
C
C     INPUT ARGUMENTS:
C
C     STRING        CHAR  TEXT STRING TO BE MODIFIED
C     XNWPOS,YNWPOS REAL  POSITION OF TEXT STRING (BOTTOM, CENTER IN NORMALIZED
C                         WORLD COORDINATES)
C     THGT          REAL  CURRENT TEXT HEIGHT (NWC)
C     ASP           REAL  CURRENT TEXT ASPECT RATIO
C     IFONT         INT2  CURRENT TEXT FONT
C     PATH          INT2  CURRENT TEXT PATH
C     COLOR         INT2  CURRENT TEXT COLOR
C     LIMITS        INT2  FLAG TO CONTROL TEXT POSITION: 
C                         0 = NO CHECKS
C                         1 = LEFT AND RIGHT SIDE EDGE CHECK
C                         2 = TOP AND BOTTOM EDGE CHECK
C     IBKG          INT2  FLAG TO SPECIFY BACKGROUND COLOR: 
C                         -1   = USE CURRENT BACKGROUND COLOR
C                         0-15 = SPECIFIC COLOR INDEX OTHER THAN BKG COLOR
C     OUTPUT ARGUMENTS:
C
C     XNWPOS,YNWPOS REAL  POSITION OF TEXT STRING (BOTTOM, CENTER IN NORMALIZED
C                         WORLD COORDINATES)--MAY BE REVISED IF A LIMIT CHECK
C                         WAS REQUESTED
C     THGT          REAL  NEW TEXT HEIGHT (NWC)
C     ASP           REAL  NEW TEXT ASPECT RATIO
C
C     REMARKS:
C
C     FIRST, THE CURRENT WORLD COORDINATE VALUES ARE SAVED. THE DISPLAY IS SET
C     TO CLICOM'S NORMALIZED WORLD COORDINATES TO SIMPLIFY ALL CALCULATIONS.
C     HALO'S XOR MODE IS USED TO REVISE TEXT SINCE IT CAN SHOW CHANGES WITHOUT
C     AFFECTING ANY OTHER ITEMS.  XOR MODE DRAWS TEXT IN AN OUTLINE FORM. AFTER
C     THE NEW SIZE IS DETERMINED, THE TEXT IS DRAWN AGAIN WHICH REMOVES THE OLD
C     TEXT.  THE TEXT IS THEN REDRAWN IN OUTLINE FORM AT THE NEW SIZE.  
C------------------------------------------------------------------------------
$INCLUDE: 'GRFPARM.INC'
$INCLUDE: 'GRAFVAR.INC'
C
C       ** LOCAL COMMON TO SAVE SPACE IN D-GROUP
C
      INTEGER       IFONT, PATH, COLOR, LIMITS, IBKG, SZCOLOR
      INTEGER       BGCOLOR, IXOR, PVCOLR, PVFILL, PVPATH
      REAL          ASP,CURSTEP,MOUSTEP,HEIGHT,INHEIGHT,INWID,OFFSET,
     +              OLDASP,OLDHT,PLHGT,PLWIDTH,PVASP,PVHGT,REVWID,
     +              SAVHGT,SAVWID,WASP,XDIST,YDIST,XFACTOR,YFACTOR,
     +              XMSTEP,X1BAR,Y1BAR,X2BAR,Y2BAR,XHIGH,YHIGH,
     +              XLOW,YLOW,XPOS,YPOS,XSL,YSL,XSH,YSH,XPREV,YPREV,
     +              XWPOS,YWPOS,XTPOS,YTPOS
      CHARACTER*78  MSG
      CHARACTER*1   RTNCODE
      CHARACTER*2   INCHAR
      CHARACTER*(*) STRING
      LOGICAL       CHANGE, FIRSTCALL, LONGTXT
      COMMON /TXSZSV/ CURSTEP,MOUSTEP,HEIGHT,INHEIGHT,INWID,OFFSET,
     +                OLDASP,OLDHT,PLHGT,PLWIDTH,PVASP,PVHGT,REVWID,
     +                SAVHGT,SAVWID,WASP,XDIST,YDIST,XFACTOR,YFACTOR,
     +                XMSTEP,X1BAR,Y1BAR,X2BAR,Y2BAR,XHIGH,YHIGH,
     +                XLOW,YLOW,XPOS,YPOS,XSL,YSL,XSH,YSH,XPREV,YPREV,
     +                XWPOS,YWPOS,XTPOS,YTPOS,  BGCOLOR,IXOR,PVCOLR,
     +                PVFILL,PVPATH,SZCOLOR,  CHANGE,  
     +                MSG,RTNCODE,INCHAR
      DATA FIRSTCALL /.TRUE./
C
C   CONVERT CURRENT DISPLAY FROM WORLD TO NORMALIZED WORLD COORDS (0-1)
C
      IF (FIRSTCALL) THEN
         CALL GETMSG(541,MSG)
         CALL GETMSG(999,MSG)
         FIRSTCALL = .FALSE.
      ENDIF
      CALL INQWOR(XSL,YSL,XSH,YSH)
      CALL SETWOR(0.,0.,1.,1.)
      CALL INQWOR(XLOW,YLOW,XHIGH,YHIGH)
      CALL GETWASP(WASP)
      XWPOS  = XNWPOS
      YWPOS  = YNWPOS
      HEIGHT = THGT
C
C   SET VERTICAL SENSITIVITY VALUES FOR CURSOR AND MOUSE.  THEY DETERMINE IF
C   THE MOVEMENT OF THE CURSOR OR MOUSE IS SUFFICIENT TO TRIGGER A CHANGE IN 
C   THE SIZE OR ASPECT OF THE TEXT. SINCE CURSOR MOVEMENT IS FIXED AT 1/200TH 
C   OF THE WORLD BY RDLOC, THE CURSTEP VALUE IS SET TO A VALUE WHICH ALWAYS
C   TRIGGERS MOVEMENT EVERY TIME A CURSOR KEY IS PRESSED.
C
      CURSTEP = (YHIGH - YLOW) / 1000.
      MOUSTEP = (YHIGH - YLOW) / 200.
      XMSTEP  = (XHIGH - XLOW) / 200.
C
C     DETERMINE THE MAXIMUM HEIGHT AND WIDTH THAT THE TEXT CAN BE (NWC)
C
      PLHGT = 1.0
      IF (PATH .EQ. 0) THEN
         PLWIDTH = GANWRT - GANWLF
         IXOR = LNG(MSG)
C        
C        TEST FOR STRING, SAMPLE 123.  USED FOR CHANGING THE SIZE OF TEXT
C        IN THE LEGEND AND AXIS LABELS.  MAX SIZE IS 40% OF PLOT AREA
C
         IF (STRING(2:IXOR+1) .EQ. MSG(1:IXOR)) THEN
            PLWIDTH = 0.4
            PLHGT   = 0.4 / WASP
         ENDIF
         IXOR = 0
      ELSE
         PLWIDTH = GANWTP - GANWBT
      ENDIF
C
C  SAVE CURRENT BACKGROUND COLOR, AND XOR STATUS AND SET TEXT ATTRIBS.
C
      IF (IBKG .EQ. -1) THEN
         CALL INQBKN(BGCOLOR)
      ELSE
         BGCOLOR = IBKG
      ENDIF
      IF (COLOR.EQ.0) THEN
         SZCOLOR = 1
      ELSE
         SZCOLOR = COLOR
      ENDIF      
      CALL INQXOR(IXOR)
      OLDHT = HEIGHT
      OLDASP = ASP
C      
      IF (PATH.EQ.0 .OR. PATH.EQ.2) THEN
         ANG=0.
      ELSE
         ANG=90.
      ENDIF      
      CALL DEFHST(IFONT,SZCOLOR,ANG,ASP,HEIGHT,TXTHTW)
      CALL SETSTA(ANG)
      CALL INQSTS(STRING,INHEIGHT,INWID,OFFSET)
C
C   CLEAR BOX CONTAINING THIS TEXT STRING
C
      CALL SETXOR(0)
      CALL SETCOL(BGCOLOR)
      CALL SETHAT(1)
      CALL COMTPOS(XWPOS,YWPOS,INWID,INHEIGHT,PATH,XTPOS
     +            ,YTPOS,X1BAR,Y1BAR,X2BAR,Y2BAR,LIMITS)
      CALL BAR(X1BAR,Y1BAR,X2BAR,Y2BAR)
C
C   SET LOCATOR ORIGIN AND XOR ON FOR THIS ROUTINE AND WRITE TEXT IN XOR MODE.
C   THE VARIABLES, X/YPREV & X/YPOS, ARE USED TO DETERMINE IF THERE HAS BEEN A
C   CHANGE IN POSITION THAT WARRANTS REVISING THE TEXT SIZE OR ASPECT. THEY DO
C   NOT AFFECT THE TEXT POSITION VARIABLES, X/YNWPOS.
C
      CALL SETXOR(1)
      XPREV = (XHIGH - XLOW) / 2.
      YPREV = (YHIGH - YLOW) / 2.
      XPOS = XPREV
      YPOS = YPREV      
      CALL ORGLOC(XPOS,YPOS)
      CALL COMTPOS(XWPOS,YWPOS,INWID,INHEIGHT,PATH,XTPOS
     +            ,YTPOS,X1BAR,Y1BAR,X2BAR,Y2BAR,LIMITS)
      CALL MOVTCA(XTPOS,YTPOS)
      CALL DELTCU( )
      CALL STEXT(STRING)
C
C   USER COULD HAVE CHANGED TEXT IN OPTMAN THAT IS TOO LONG TO FIT IN THE
C   REQUIRED SPACE.  SET A LOGICAL VARIABLE TO PERMIT USER TO CHANGE LENGTH
C
      IF (PATH .GT. 0) THEN
         REVWID = INWID * WASP
      ELSE
         REVWID = INWID
      ENDIF
      IF (REVWID .GT. PLWIDTH .OR. INHEIGHT .GT. PLHGT) THEN
         LONGTXT = .TRUE.
      ELSE
         LONGTXT = .FALSE.
      ENDIF
C
C   READ LOCATOR POSITION AND EVALUATE CHARACTERS RETURNED.
C   ADJUST TEXT HEIGHT AND WIDTH AS REQUESTED. 
C
      CHANGE = .FALSE.
20    CONTINUE
         CALL RDLOC(XPOS,YPOS,INCHAR,RTNCODE)
         CALL DELHCU( )
C
C     IF ENTER(RETURN) HAS BEEN PRESSED SAVE VALUE, RESET ENVIRONMENT,
C     CLEAR TEXT AND WRITE IT IN CORRECT XOR MODE AND RETURN. 
C
         IF (INCHAR.EQ.'RE'.OR.INCHAR.EQ.'4F'.OR.INCHAR.EQ.'ES') THEN
            CALL MOVTCA(XTPOS,YTPOS)
            CALL DELTCU( )
            CALL STEXT(STRING)
            IF (INCHAR.EQ.'4F'.OR.INCHAR.EQ.'ES') THEN
               HEIGHT = OLDHT
               ASP = OLDASP
               CALL DEFHST(IFONT,COLOR,ANG,ASP,HEIGHT,TXTHTW)
               CALL SETSTA(ANG)
               CALL INQSTS(STRING,INHEIGHT,INWID,OFFSET)
               CALL COMTPOS(XWPOS,YWPOS,INWID,INHEIGHT,PATH,XTPOS
     +                     ,YTPOS,X1BAR,Y1BAR,X2BAR,Y2BAR,LIMITS)
            ELSE IF (SZCOLOR.NE.COLOR) THEN
               CALL DEFHST(IFONT,COLOR,ANG,ASP,HEIGHT,TXTHTW)
               CALL SETSTA(ANG)
            END IF
            CALL SETXOR(IXOR)
            CALL MOVTCA(XTPOS,YTPOS)
            CALL DELTCU( )
            CALL STEXT(STRING)
            CALL ORGLOC(XPOS,YPOS)
C             .. SAVE CURRENT LOCATION WHICH MAY HAVE BEEN REVISED TO
C                MEETS LIMIT CHECK REQUIREMENTS
            XNWPOS=XWPOS
            YNWPOS=YWPOS
            CALL SETWOR(XSL,YSL,XSH,YSH)
            THGT = HEIGHT
            RETURN
         END IF
C
C     MODIFY HEIGHT AND/OR WIDTH AS INDICATED BY LOCATOR.  FOR CURSOR
C     MOVEMENT MODIFY THE SIZE BY A CONSTANT RATIO.  FOR MOUSE MOVEMENT
C     MODIFY THE SIZE BY A RATIO WHICH DEPENDS UPON HOW FAR (AND THEREFORE
C     HOW FAST) THE MOUSE HAS BEEN MOVED. CURRENTLY, A LARGER PHYSICAL MOVEMENT
C     OF THE MOUSE IS NEEDED TO GET A CORRESPONDING MOVEMENT ON THE SCREEN. 
C
         PVHGT = HEIGHT
         PVASP = ASP
         IF (RTNCODE.EQ.'1') THEN
            YFACTOR = MOUSTEP
            XFACTOR = XMSTEP 
            YDIST = ABS((YPOS-YPREV)/(YHIGH - YLOW)) / 2.
            XDIST = ABS((XPOS-XPREV)/(XHIGH - XLOW)) / 1.2
         ELSE
            YFACTOR = CURSTEP
            XFACTOR = CURSTEP
            YDIST = .08
            XDIST = .08
         END IF
         IF (YPOS.GT.YPREV+YFACTOR) THEN
            HEIGHT = HEIGHT * (1. + YDIST)
            CHANGE = .TRUE.
         ELSE IF (YPOS.LT.YPREV-YFACTOR) THEN
            HEIGHT = HEIGHT * (1. - YDIST) 
            CHANGE = .TRUE.
            IF (HEIGHT .LT. 0.005) THEN
               HEIGHT = 0.005
            ENDIF
         END IF
         IF (XPOS.GT.XPREV+XFACTOR) THEN
            ASP = ASP * (1. + XDIST) 
            CHANGE = .TRUE.
         ELSE IF (XPOS.LT.XPREV-XFACTOR) THEN
            ASP = ASP * (1. - XDIST)
            CHANGE = .TRUE.
            IF (ASP .LT. 0.005) THEN
               ASP = 0.005
            ENDIF
         END IF
C
C     HEIGHT AND/OR WIDTH CHANGED - REDRAW TEXT
C
         IF (CHANGE) THEN   
            CHANGE = .FALSE.
            CALL MOVTCA(XTPOS,YTPOS)
            CALL DELTCU( )
            CALL STEXT(STRING)
            CALL DEFHST(IFONT,SZCOLOR,ANG,ASP,HEIGHT,TXTHTW)
            CALL SETXOR(1)
            CALL SETSTA(ANG)
            CALL INQSTS(STRING,INHEIGHT,INWID,OFFSET)
            IF (PATH .GT. 0) THEN
                REVWID = INWID * WASP
            ELSE
               REVWID = INWID
            ENDIF
C
C     CHECK THAT THE HEIGHT AND WIDTH OF TEXT DOES NOT EXCEED THE SIZE OF
C     THE PLOT AREA.  RESET TO TEXT SIZE/ASP TO LAST VALUE THAT WAS OK
C
            IF (REVWID .GT. PLWIDTH .OR. INHEIGHT .GT. PLHGT) THEN
               IF (.NOT.LONGTXT) THEN
                  HEIGHT   = PVHGT
                  ASP      = PVASP
                  CALL DEFHST(IFONT,SZCOLOR,ANG,ASP,HEIGHT,TXTHTW)
                  CALL SETXOR(1)
                  CALL SETSTA(ANG)
                  CALL INQSTS(STRING,INHEIGHT,INWID,OFFSET)
                  CALL BEEP
               ENDIF
            ELSE
               IF (LONGTXT) THEN
                  LONGTXT = .FALSE.
               ENDIF
            ENDIF
            XPOS = XPREV
            YPOS = YPREV
            CALL ORGLOC(XPOS,YPOS)
            CALL COMTPOS(XWPOS,YWPOS,INWID,INHEIGHT,PATH,XTPOS
     +                  ,YTPOS,X1BAR,Y1BAR,X2BAR,Y2BAR,LIMITS)
            CALL MOVTCA(XTPOS,YTPOS)
            CALL DELTCU( )
            CALL STEXT(STRING)
         END IF
      GO TO 20
      END
