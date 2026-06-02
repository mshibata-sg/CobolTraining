       IDENTIFICATION DIVISION.
       PROGRAM-ID. KJBM020.

      ******************************************************************
      * システム名　　：研修(ID:K)
      * サブシステム名：受注(ID:JK)
      * プログラム名　：受注データ形式チェック
      * 作成日／作成者：2026/06/　[柴田真衣]
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
       01  KJCF010-EOF         PIC X(1) VALUE "N".
       01  IN-CNT              PIC 9(9) VALUE 0.
       01  OUT-CNT             PIC 9(9) VALUE 0.
       01  COPY KCBS010.

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
             MOVE "Y" TO KJCF010-EOF
             NOT AT END 
             ADD 1 TO IN-CNT
             END-READ. 

           PERFORM UNTIL KJCF010-EOF = "Y"
             MOVE SPACES TO JF020-ERR-KBN-TBL
    
             IF JF020-DATA-KBN = 1 OR JF020-DATA-KBN = 9
                CONTINUE
             ELSE
                MOVE 1 TO JF020-ERR-KBN(1)
             END-IF.
             IF JF020-JUCHU-NO IS NUMERIC AND JF020-JUCHU-NO NOT = ZERO
                CONTINUE
             ELSE
                MOVE 1 TO JF020-ERR-KBN(2)
             END-IF.
                MOVE S010-DATE TO JF020-JUCHU-DATE
             CALL "KCBS10" USING KCBS010-P1
             IF S010-RCD NOT = "E"
                MOVE S010-P1-Y1 TO JF020-JUCHU-DATE
             ELSE
                MOVE 1 TO JF020-ERR-KBN(3)
             END-IF.
             IF JF020-SHOHIN-NO IS NUMERIC AND JF020-SHOHIN-NO NOT = ZERO
                CONTINUE
             ELSE
                MOVE 1 TO JF020-ERR-KBN(5)
             END-IF.
             IF JF020-SURYO IS NUMERIC AND 
                (JF020-SURYO >=1 AND JF020-SURYO <=999)
             CONTINUE
             ELSE
                MOVE 1 TO JF020-ERR-KBN(6)
             END-IF.
    
             WRITE OTF-REC.
             ADD 1 TO OUT-CNT
    
             READ ITF-FILE
             AT END 
             MOVE "Y" TO KJCF010-EOF
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