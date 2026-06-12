       IDENTIFICATION DIVISION.
       PROGRAM-ID. KJBM030.

      ******************************************************************
      * システム名　　：研修(ID:K)
      * サブシステム名：受注(ID:JC)
      * プログラム名　：受注データ商品番号チェック
      * 作成日／作成者：2026/06/11　[柴田真衣]
      * 変更日／変更者：
      * 　　　変更内容：
      ******************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT ITF-FILE ASSIGN TO ITF
           ORGANIZATION SEQUENTIAL.

           SELECT IMF-FILE ASSIGN TO IMF
           ORGANIZATION SEQUENTIAL.

           SELECT OTF-FILE ASSIGN TO OTF
           ORGANIZATION SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION. 
       FD  ITF-FILE.
       01  ITF-REC.
           COPY KJCF020.
       FD  IMF-FILE.
       01  IMF-REC.
           COPY KCCFSHO.
       FD  OTF-FILE.
       01  OTF-REC.
           COPY KJCF020.  
           
       WORKING-STORAGE SECTION.
       01  WK-ITF-EOF          PIC X(1) VALUE "N".
       01  WK-IMF-EOF          PIC X(1) VALUE "N".
       01  IN-CNT              PIC 9(9) VALUE 0.
       01  IMF-CNT             PIC 9(9) VALUE 0.
       01  OUT-CNT             PIC 9(9) VALUE 0.

       PROCEDURE DIVISION.
           PERFORM INIT-RTN.
           PERFORM MATCH-RTN UNTIL WK-ITF-EOF = "Y" OR WK-IMF-EOF ="Y".
           PERFORM REMAIN-RTN.
           PERFORM TERM-RTN.
           STOP RUN.
      ******************************************************************
      * 初期処理
      ******************************************************************
       INIT-RTN  SECTION.   
           OPEN INPUT ITF-FILE. 
           OPEN INPUT IMF-FILE.
           OPEN OUTPUT OTF-FILE.

           DISPLAY "*** KJBM030 START ***"
       
           PERFORM READ-IMF-RTN.
           PERFORM READ-ITF-RTN.
	   EXT.
	       EXIT.
      ******************************************************************
      * 主処理
      ******************************************************************
       MATCH-RTN SECTION.
           IF JF020-ERR-KBN OF ITF-REC (5) NOT = SPACE
               PERFORM WRITE-RTN
               PERFORM READ-ITF-RTN
           ELSE
               EVALUATE TRUE
      *マッチ
                 WHEN JF020-SHOHIN-NO OF ITF-REC = CFSHO-SHOHIN-NO
                    MOVE CFSHO-SHOHIN-MEI TO JF020-SHOHIN-MEI OF ITF-REC
                    MOVE CFSHO-TANKA TO JF020-TANKA OF ITF-REC
      *金額
                 IF JF020-ERR-KBN OF ITF-REC (6) = SPACE
                    COMPUTE JF020-KINGAKU OF ITF-REC =
                      JF020-SURYO OF ITF-REC * CFSHO-TANKA
                 ELSE
                    MOVE ZERO TO JF020-KINGAKU OF ITF-REC
                 END-IF

                 PERFORM WRITE-RTN
                 PERFORM READ-ITF-RTN

      *不一致
                 WHEN JF020-SHOHIN-NO OF ITF-REC < CFSHO-SHOHIN-NO
                   MOVE "2" TO JF020-ERR-KBN OF ITF-REC (5)
                   PERFORM WRITE-RTN
                   PERFORM READ-ITF-RTN

      *ITF ＞ IMF
                 WHEN JF020-SHOHIN-NO OF ITF-REC > CFSHO-SHOHIN-NO
                   PERFORM READ-IMF-RTN
               END-EVALUATE
           END-IF.
       EXT.
           EXIT.    

       REMAIN-RTN SECTION.
           PERFORM UNTIL WK-ITF-EOF = "Y"
               MOVE "2" TO JF020-ERR-KBN OF ITF-REC (5)
               MOVE ITF-REC TO OTF-REC
               PERFORM WRITE-RTN
               PERFORM READ-ITF-RTN
           END-PERFORM.
       EXT.
           EXIT.
      ******************************************************************
      * 終了処理
      ******************************************************************  
       TERM-RTN SECTION.
           DISPLAY "ITF-CNT:" IN-CNT.
           DISPLAY "IMF-CNT:" IMF-CNT.
           DISPLAY "OTF-CNT:" OUT-CNT.
           DISPLAY "*** KJBM030 END ***".
           
           CLOSE IMF-FILE.
           CLOSE ITF-FILE.
           CLOSE OTF-FILE.
           
       EXT.
           EXIT.
      ******************************************************************
      * ITFの1レコード読み込み
      ****************************************************************** 
       READ-ITF-RTN SECTION.
           READ ITF-FILE
               AT END
                  MOVE "Y" TO WK-ITF-EOF
               NOT AT END 
                  ADD 1 TO IN-CNT
           END-READ.
       EXT.
           EXIT.
      ******************************************************************
      * IMFの1レコード読み込み
      ****************************************************************** 
       READ-IMF-RTN SECTION.
           READ  IMF-FILE
             AT END
                MOVE "Y" TO  WK-IMF-EOF            
			 NOT AT END
    		    ADD 1 TO IMF-CNT
           END-READ.
       EXT.
           EXIT.
      
      ******************************************************************
      * 1レコード書き込み
      ****************************************************************** 
       WRITE-RTN SECTION.  
           MOVE ITF-REC TO OTF-REC.
           WRITE OTF-REC.
           ADD 1 TO OUT-CNT.
       EXT.
           EXIT.
       