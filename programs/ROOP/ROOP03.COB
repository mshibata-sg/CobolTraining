       IDENTIFICATION DIVISION.
       PROGRAM-ID. ROOP03.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WK-IDX      PIC 9(02) VALUE ZERO.
       01  WK-TOTAL    PIC 9(03) VALUE ZERO.

       PROCEDURE DIVISION.
           PERFORM VARYING WK-IDX FROM 1 BY 1
                   UNTIL WK-IDX > 10
                   ADD WK-IDX TO WK-TOTAL
           END-PERFORM.

           DISPLAY "TOTAL:" WK-TOTAL.
                 
           STOP RUN.



