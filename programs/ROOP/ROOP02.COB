       IDENTIFICATION DIVISION.
       PROGRAM-ID. ROOP02.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WK-TEMPERATURE PIC 9(3) VALUE ZERO.

       PROCEDURE DIVISION.
           EVALUATE TRUE
             WHEN WK-TEMPERATURE >=35
                  DISPLAY "VERY HOT"
             WHEN WK-TEMPERATURE >=25
                  DISPLAY "WARM"
             WHEN WK-TEMPERATURE >=15
                  DISPLAY "COOL"
             WHEN WK-TEMPERATURE < 15
                  DISPLAY "COLD"
           END-EVALUATE.

           STOP RUN.

