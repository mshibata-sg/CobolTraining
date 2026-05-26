       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILE02.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ITF-FILE ASSIGN TO ITF
           ORGANIZATION SEQUENTIAL.

           SELECT OTF-FILE ASSIGN TO OTF
           ORGANIZATION SEQUENTIAL.
        
       DATA DIVISION.
       FILE SECTION.
       FD  ITF-FILE.
       01  ITF-REC         PIC X(80).

       FD  OTF-FILE.
       01  OTF-REC        PIC X(80).

       WORKING-STORAGE SECTION.
       01  WK-EOF         PIC X(1) VALUE "N".

       PROCEDURE DIVISION.
       
           OPEN INPUT ITF-FILE.
           OPEN OUTPUT OTF-FILE.

           READ ITF-FILE
           AT END
            MOVE "Y" TO WK-EOF
           END-READ.

           PERFORM UNTIL WK-EOF = "Y"
               MOVE ITF-REC TO OTF-REC
               WRITE OTF-REC
               
               READ ITF-FILE
                   AT END MOVE "Y" TO WK-EOF
               END-READ
           END-PERFORM.

           CLOSE ITF-FILE.
           CLOSE OTF-FILE.
           STOP RUN.
           