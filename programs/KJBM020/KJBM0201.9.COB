       IDENTIFICATION DIVISION.
       PROGRAM-ID. KJBM020.

      ******************************************************************
      * システム名　　：研修(ID:K)
      * サブシステム名：受注(ID:JK)
      * プログラム名　：受注データ形式チェック
      * 作成日／作成者：2026/06/04　[柴田真衣]
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
           PERFORM INIT-RTN.
           PERFORM MAIN-RTN UNTIL KJCF020-EOF = "Y"
           PERFORM TERM-RTN.
           STOP RUN.
           
      ******************************************************************
      * 初期処理
      ******************************************************************
       INIT-RTN  SECTION.   
           OPEN INPUT ITF-FILE. 
           OPEN OUTPUT OTF-FILE.

           DISPLAY "*** KJBM020 START ***"

           PERFORM READ-RTN.
	   INIT-EXT.
	       EXIT.
      ******************************************************************
      * 主処理
      ******************************************************************
       MAIN-RTN  SECTION.
           MOVE SPACES TO JF020-ERR-KBN-TBL OF ITF-REC
    
           IF (JF020-DATA-KBN OF ITF-REC = "1") OR 
                (JF020-DATA-KBN OF ITF-REC = "9")
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
      
           MOVE JF020-JUCHU-DATE OF ITF-REC TO S010-DATE
           CALL "KCBS010" USING KCBS010-P1

           IF   S010-RCD NOT ="E"
           MOVE S010-DATE8 TO JF020-JUCHU-DATE OF ITF-REC 
           ELSE
                MOVE 1 TO JF020-ERR-KBN OF ITF-REC(3)
           END-IF
      
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
           
           PERFORM WRITE-RTN.
             
           PERFORM READ-RTN.
           
       MAIN-EXT.
           EXIT.     
      ******************************************************************
      * 終了処理
      ******************************************************************  
       TERM-RTN SECTION.
           DISPLAY "ITF-CNT:" IN-CNT
           DISPLAY "OTF-CNT:" OUT-CNT
           DISPLAY "*** KJBM020 END ***"
           
           CLOSE ITF-FILE.
           CLOSE OTF-FILE.
           
       TERM-EXT.
           EXIT.
      ******************************************************************
      * 1レコード読み込み
      ****************************************************************** 
       READ-RTN SECTION.
           READ ITF-FILE
                AT END
                   MOVE "Y" TO KJCF020-EOF
               NOT AT END 
                   ADD 1 TO IN-CNT
           END-READ.
       READ-EXT.
           EXIT.
      ******************************************************************
      * 1レコード読み込み
      ****************************************************************** 
       WRITE-RTN SECTION.  
           WRITE OTF-REC
           ADD 1 TO OUT-CNT.
       