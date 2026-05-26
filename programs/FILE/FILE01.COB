       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILE01.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ITF-FILE ASSIGN TO ITF
           ORGANIZATION SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  ITF-FILE.
       01  ITF-REC.
           03 EMP-NO                   PIC X(4).
           03 EMP-NAME                 PIC N(20).
           03 EMP-JOINED-DATE.  
               05 EMP-JOINED-DATE-Y    PIC 9(4).
               05 EMP-JOINED-DATE-M    PIC 9(2).
               05 EMP-JOINED-DATE-D    PIC 9(2).

       WORKING-STORAGE SECTION.
       01  WK-EOF                      PIC X(1) VALUE "N".

       PROCEDURE DIVISION.
           OPEN INPUT ITF-FILE.

           READ ITF-FILE
               AT END                                              
                 MOVE "Y" TO WK-EOF
               END-READ.

           PERFORM UNTIL WK-EOF = "Y"
               DISPLAY EMP-NO  " "
                       EMP-JOINED-DATE-Y "/"
                       EMP-JOINED-DATE-M "/"
                       EMP-JOINED-DATE-D
               READ ITF-FILE
                   AT END MOVE "Y" TO WK-EOF
               END-READ
           END-PERFORM.  

           CLOSE ITF-FILE.
           STOP RUN.
