       IDENTIFICATION DIVISION.
       PROGRAM-ID. KJBM020.

      ******************************************************************
      * システム名　　：研修(ID:K)
      * サブシステム名：受注(ID:JK)
      * プログラム名　：受注データ形式チェック
      * 作成日／作成者：2026/06/03　[柴田真衣]
      * 変更日／変更者：
      * 　　　変更内容：
      ******************************************************************

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
       01  ITF-REC.
              COPY KJCF020.

       FD  OTF-FILE.
       01  OTF-REC.
           COPY KJCF020.  
           
       WORKING-STORAGE SECTION.
       01  KJCF020-EOF         PIC X(1) VALUE "N".
       01  IN-CNT              PIC 9(9) VALUE 0.
       01  OUT-CNT             PIC 9(9) VALUE 0.
           COPY KCBS010P.

       PROCEDURE DIVISION.
      ******************************************************************
      * 初期処理
      ******************************************************************
           OPEN INPUT ITF-FILE. 
           OPEN OUTPUT OTF-FILE.

      ******************************************************************
      * 主処理
      ******************************************************************
           READ ITF-FILE
             AT END
                MOVE "Y" TO KJCF020-EOF
             NOT AT END 
                ADD 1 TO IN-CNT
             END-READ

           PERFORM UNTIL KJCF020-EOF = "Y"
             MOVE SPACES TO JF020-ERR-KBN-TBL OF ITF-REC
    
             IF (JF020-DATA-KBN OF ITF-REC = 1) OR 
                (JF020-DATA-KBN OF ITF-REC = 9)
                CONTINUE
             ELSE
                MOVE 1 TO JF020-ERR-KBN OF ITF-REC(1)
             END-IF

             IF JF020-JUCHU-NO OF ITF-REC IS NUMERIC AND 
                JF020-JUCHU-NO OF ITF-REC NOT = 0
                CONTINUE
             ELSE
                MOVE 1 TO JF020-ERR-KBN OF ITF-REC(2)
             END-IF
      *
             MOVE S010-DATE TO JF020-JUCHU-DATE OF ITF-REC 
             CALL "KCBS010" USING KCBS010-P1

             IF S010-RCD NOT ="E"
               MOVE S010-P1-Y1 TO JF020-JUCHU-DATE OF ITF-REC
               CONTINUE
             ELSE
                MOVE 1 TO JF020-ERR-KBN OF ITF-REC(3)
             END-IF
      *
             IF JF020-SHOHIN-NO OF ITF-REC IS NUMERIC 
                AND JF020-SHOHIN-NO OF ITF-REC NOT = 0
                CONTINUE
             ELSE
                MOVE 1 TO JF020-ERR-KBN OF ITF-REC(5)
             END-IF

             IF JF020-SURYO OF ITF-REC IS NUMERIC AND 
                JF020-SURYO OF ITF-REC >= 1 AND 
                JF020-SURYO OF ITF-REC <= 999
                CONTINUE
             ELSE
                MOVE 1 TO JF020-ERR-KBN OF ITF-REC(6)
             END-IF
    
             MOVE ITF-REC TO OTF-REC

             WRITE OTF-REC
             ADD 1 TO OUT-CNT
    
             READ ITF-FILE
               AT END 
                  MOVE "Y" TO KJCF020-EOF
               NOT AT END 
                  ADD 1 TO IN-CNT
             END-READ
           END-PERFORM.
           
           DISPLAY "*** KJBM020 START ***"
           DISPLAY "ITF-CNT:" IN-CNT
           DISPLAY "OTF-CNT:" OUT-CNT
           DISPLAY "*** KJBM020 END ***"
             
      ******************************************************************
      * 終了処理
      ******************************************************************  
           CLOSE ITF-FILE.
           CLOSE OTF-FILE.
           STOP RUN.
           