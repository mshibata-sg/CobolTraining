       IDENTIFICATION DIVISION.
       PROGRAM-ID. ROOP04.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  NUMBER-TABLE.
           03 NUMBER-DATA   PIC 9(04) OCCURS 10 TIMES.
       01  WK-IDX           PIC 9(02) VALUE ZERO.
       01  WK-MAX           PIC 9(04) VALUE ZERO.

       PROCEDURE DIVISION.
           MOVE 14 TO NUMBER-DATA(1).
           MOVE 27 TO NUMBER-DATA(2).
           MOVE 35 TO NUMBER-DATA(3).
           MOVE 48 TO NUMBER-DATA(4).
           MOVE 59 TO NUMBER-DATA(5).
           MOVE 63 TO NUMBER-DATA(6).
           MOVE 72 TO NUMBER-DATA(7).
           MOVE 81 TO NUMBER-DATA(8).
           MOVE 90 TO NUMBER-DATA(9).
           MOVE 24 TO NUMBER-DATA(10).

           MOVE NUMBER-DATA(1) TO WK-MAX.     

           PERFORM VARYING WK-IDX FROM 1 BY 1
                  UNTIL WK-IDX > 10

              IF WK-MAX <= NUMBER-DATA(WK-IDX)
                 NUMBER-DATA(WK-IDX) TO WK-MAX
              END-IF

           END-PERFORM.

           DISPLAY WK-MAX

           STOP RUN.

           
