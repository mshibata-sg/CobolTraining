       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATE01.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WK-DATA.
           03 WK-NUMBER PIC 9(8).
           03 WK-NAME   PIC X(20).
           03 WK-CODE   PIC 9(3).
           03 WK-SALARY PIC S9(10)V9(2).
           
       PROCEDURE DIVISION.
           DISPLAY "NUMBER"
           DISPLAY "NAME"
           DISPLAY "CODE"
           DISPLAY "SALARY"
           STOP RUN.
           