       IDENTIFICATION DIVISION.
       PROGRAM-ID. KUBM020.

      ******************************************************************
      * システム名　　：研修(ID:K)
      * サブシステム名：受注(ID:JK)
      * プログラム名　：売上集計
      * 作成日／作成者：2026/06/08　[柴田真衣]
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
           COPY KUCF010.

       FD  OTF-FILE.
       01  OTF-REC.
           COPY KUCF020.  
           
       WORKING-STORAGE SECTION.
       01  KUBM020-EOF         PIC X(1) VALUE "N".
       01  IN-CNT              PIC 9(9) VALUE 0.
       01  OUT-CNT             PIC 9(9) VALUE 0.

       01  WK-KEY.
       05  WK-SHOHIN-NO     PIC 9(5).
       05  WK-JUCHU-YY      PIC 9(4).
       05  WK-JUCHU-MM      PIC 9(2).

       PROCEDURE DIVISION.
           PERFORM  INIT-RTN.
           PERFORM  MAIN-RTN  UNTIL  KUBM020-EOF = "Y".
           PERFORM  TERM-RTN.
           STOP RUN.
      ******************************************************************
      * 初期処理
      ******************************************************************
       INIT-RTN SECTION.   
           OPEN INPUT ITF-FILE. 
           OPEN OUTPUT OTF-FILE.

           DISPLAY "*** KUBM020 START ***".

      * 1件読む    
           PERFORM  READ-RTN.

       INIT-EXT.    
           EXIT.
      ******************************************************************
      * 主処理
      ******************************************************************
       MAIN-RTN SECTION.      

      *判定(商品＋年月 )  
           IF WK-SHOHIN-NO = LOW-VALUES
              OR (UF010-SHOHIN-NO IS NOT = WK-SHOHIN-NO
              OR UF010-JUCHU-YY IS NOT = WK-JUCHU-YY
              OR UF010-JUCHU-MM IS NOT = WK-JUCHU-MM)

      *前データ出力    
           IF WK-SHOHIN-NO IS NOT ZERO
              PERFORM  WRITE-RTN
           END-IF

      *初期化
           MOVE SPACES TO OTF-REC
           MOVE ZERO TO UF020-KINGAKU
           END-IF

      *キー保存 (比較)
           MOVE UF010-SHOHIN-NO OF ITF-REC TO WK-SHOHIN-NO
           MOVE UF010-JUCHU-YY OF ITF-REC TO WK-JUCHU-YY
           MOVE UF010-JUCHU-MM OF ITF-REC TO WK-JUCHU-MM
           
      *先頭レコード項目セット
      *(キーが変わったときに、出力レコードに正しい値をセットする)
           MOVE UF010-SHOHIN-NO OF ITF-REC TO UF020-SHOHIN-NO
           MOVE UF010-JUCHU-YY OF ITF-REC TO UF020-JUCHU-YY
           MOVE UF010-JUCHU-MM OF ITF-REC TO UF020-JUCHU-MM

      *金額集計
           IF  UF010-DATA-KBN = "1"
              ADD UF010-KINGAKU OF ITF-REC TO 
                  UF020-KINGAKU OF OTF-REC	
           ELSE 
           IF UF010-DATA-KBN = "9"
               SUBTRACT UF010-KINGAKU OF ITF-REC FROM 
                        UF020-KINGAKU OF OTF-REC
               END-IF
           END-IF

      *次レコード読む
           PERFORM  READ-RTN

      *最終出力
           IF KUBM020-EOF = "Y"
              PERFORM WRITE-RTN
           END-IF

           EXIT.    
      ******************************************************************
      * 終了処理
      ******************************************************************  
       TERM-RTN SECTION.
           DISPLAY "ITF-CNT:" IN-CNT
           DISPLAY "OTF-CNT:" OUT-CNT
           DISPLAY "*** KUBM020 END ***"
             
           CLOSE ITF-FILE.
           CLOSE OTF-FILE.

       TERM-EXT.
           EXIT.
      ******************************************************************
      * １レコード読込み処理
      ******************************************************************  
       READ-RTN SECTION.
           READ ITF-FILE
             AT END 
               MOVE "Y" TO KUBM020-EOF
             NOT AT END 
               ADD 1 TO IN-CNT
           END-READ.

       READ-EXT.
           EXIT.
      ******************************************************************
      * １レコード書き込み処理
      ******************************************************************  
       WRITE-RTN SECTION.
           IF WK-SHOHIN-NO IS NOT ZERO
              WRITE OTF-REC
              ADD 1 TO OUT-CNT
           END-IF

           EXIT.
             