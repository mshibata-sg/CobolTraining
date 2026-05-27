       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILE03.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ITF-FILE ASSIGN TO ITF
           ORGANIZATION SEQUENTIAL.


       DATA DIVISION.
       FILE SECTION.
       FD  ITF-FILE.
       01  ITF-REC.
           03 EMP-CODE                 PIC X(5).
           03 EMP-NAME                 PIC N(20).
           03 EMP-UNTI-PRICE           PIC 9(8).

       WORKING-STORAGE SECTION.
       01  WK-EOF         PIC X(1) VALUE "N".
       01  WK-COUNTER     PIC 9(4) VALUE 0.

       PROCEDURE DIVISION.
           OPEN INPUT ITF-FILE.
    
           READ ITF-FILE
           AT END                                              
           MOVE "Y" TO WK-EOF
           END-READ.
    
           PERFORM UNTIL WK-EOF = "Y"
               ADD 1 TO WK-COUNTER
                
               READ ITF-FILE
                   AT END MOVE "Y" TO WK-EOF
               END-READ
           END-PERFORM.  
           DISPLAY "TOTAL RECORDS:" WK-COUNTER.
    
           CLOSE ITF-FILE.
           STOP RUN.
               
