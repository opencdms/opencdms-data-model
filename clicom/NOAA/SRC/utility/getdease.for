$storage:2

      SUBROUTINE GETDEASE(DEVERS)
C
C   ROUTINE TO FIND THE THE VERSION OF DATAEASE CURRENTLY IN USE BASED ON THE
C   DEASE ENVIRONMENT VARIABLE THAT HAS BEEN SET IN THE DOS ENVIRONMENT
C   AREA (MAX 500 CHAR)
C
      CHARACTER*100 STRBUF(5),ENVSTR
      CHARACTER*3 DEVERS
      CHARACTER*1 NULL
      EQUIVALENCE (STRBUF,ENVSTR)      
C
      NULL = CHAR(0)
C
C   GET THE ENVIRONMENT AREA - RETURNED AS A SINGLE STRING
C      
      CALL GETENV(ENVSTR)
      I = 0
C
C   SEARCH THE ENVIRONMENT STRING FOR THE DATAEASE VERSION
C
 40   CONTINUE     
      I = I + 1
      IF (I.GT.500) THEN
         GO TO 90
      END IF
C
C     CHECK TO SEE IF THIS IS THE STRING WANTED
C
      IF (ENVSTR(I:I).EQ.NULL) THEN
         GO TO 90
      ELSE IF (ENVSTR(I:I+4).EQ.'DEASE') THEN
         DEVERS=ENVSTR(I+6:I+8)
         IF (DEVERS(1:1).EQ.'4') THEN
            DEVERS='4.0'
         ENDIF   
         RETURN
C
C   FIND THE END OF THIS STRING (HENCE THE BEGINNING OF THE NEXT)            
C
      ELSE
         DO 80 J = I,999
            IF (ENVSTR(J:J).EQ.NULL) THEN
               I = J
               GO TO 40
            END IF
  80     CONTINUE                  
      END IF             
  90  CONTINUE
      CALL WRTMSG(3,408,12,1,1,' ',0)
      STOP ' '
      END
