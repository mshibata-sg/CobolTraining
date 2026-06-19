       IDENTIFICATION DIVISION.
       PROGRAM-ID. KJBM011.

      ******************************************************************
      * システム名　　：研修(ID:K)
      * サブシステム名：受注(ID:JK)
      * プログラム名　：受注チェックファイル作成
      * 作成日／作成者：2026/06/19　[柴田真衣]
      * 変更日／変更者：
      * 　　　変更内容：
      ******************************************************************

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           
           SELECT OTF-FILE ASSIGN TO OTF
           ORGANIZATION SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.  

       FD  OTF-FILE.
       01  OTF-REC.
           COPY KJCF020.  

      WORKING-STORAGE SECTION.
       01  WK-COUNT     PIC 9(6) VALUE 0.

      * SQLで使う変数
       EXEC SQL BEGIN DECLARE SECTION END-EXEC.    
       01 H-DATA_KBN   PIC X(1).
       01 H-JUCHU_NO   PIC S9(4) COMP-5.
       01 H-JUCHU_YY   PIC S9(2) COMP-5.
       01 H-JUCHU_MM   PIC S9(2) COMP-5.
       01 H-JUCHU_DD   PIC S9(2) COMP-5.
       01 H-TOKU_COD   PIC X(4).
       01 H-SHOHIN_NO  PIC X(5).
       01 H-SURYO      PIC S9(5) COMP-5.
       EXEC SQL END DECLARE SECTION END-EXEC.

      * 接続文字列
       01 WS-CONNSTR PIC X(100)
       VALUE 'DBNAME CONNSETTINGS=SET CLIENT_ENCODING TO ''SJIS'''.

      * SQLの結果を受け取る
       EXEC SQL INCLUDE SQLCA END-EXEC.

       PROCEDURE DIVISION.
      *データベースに接続
           EXEC SQL
               CONNECT TO :WS-CONNSTR
            END-EXEC.
           
      *データあり
           IF SQLCODE < 0
           PERFORM ERROR-RTN
           END-IF.

      ******************************************************************
      * 初期処理
      ******************************************************************
       INIT-RTN  SECTION.
           DISPLAY "*** KJBM011 START ***"

           OPEN OUTPUT OTF-FILE.

       EXT.
           EXIT.
      ******************************************************************
      * 主処理
      ******************************************************************
       MAIN-RTN  SECTION.
      *カーソル宣言 
           EXEC SQL
               DECLARE CUR-JUCHU CURSOR FOR
               SELECT 
               DATA_KBN,
               JUCHU_NO,
               JUCHU_YY,
               JUCHU_MM,
               JUCHU_DD,
               TOKU_COD,
               SHOHIN_NO,
               SURYO
               FROM SalesData
               ORDER BY JUCHU_NO
           END-EXEC.

      *カーソルOPEN
           EXEC SQL OPEN CUR-JUCHU END-EXEC.
           IF SQLCODE < 0
               PERFORM ERROR-RTN
           END-IF.

      *先に1回FETCH
           PERFORM FETCH-SEC SECTION.

      *SQLCODE=100（データなし）になるまでループ
           PERFORM UNTIL SQLCODE = 100
               IF SQLCODE < 0
               PERFORM ERROR-RTN
               END-IF

      *初期化
           MOVE SPACE TO OTF-REC

      *英数字項目として転送            
           MOVE H-DATA_KBN  TO JF020-DATA-KBN
           MOVE H-JUCHU_NO  TO JF020-JUCHU-NO
           
           MOVE ZERO TO JF020-JUCHU-DATE
           MOVE CMJYUCHU_JUCHU_DATE TO JH-JUCHU_YY
           MOVE CMJYUCHU_JUCHU_DATE TO H-JUCHU_MM
           MOVE CMJYUCHU_JUCHU_DATE TO H-JUCHU_DD

           MOVE H-SHOHIN_NO TO JF020-SHOHIN-NO
           MOVE H-SURYO TO JF020-SURYO
           MOVE SPACE TO JF020-ERROR-KBN
           MOVE SPACE TO JF020-SHOHIN-NAME
           MOVE ZERO TO JF020-TANKA
           MOVE ZERO TO JF020-KINGAKU

      *出力
           WRITE OTF-REC
           ADD 1 TO WK-COUNT
           
           PERFORM FETCH-SEC SECTION.

           END-PERFORM.

      *カーソルCLOSE
           EXEC SQL CLOSE CUR-JUCHU END-EXEC.

           IF SQLCODE < 0
               PERFORM ERROR-RTN
           END-IF.
      
      *DB切断
           EXEC SQL DISCONNECT ALL END-EXEC.
             
       EXT.
           EXIT.
      ******************************************************************
      * 終了処理
      ******************************************************************  
       TERM-RTN SECTION.
           DISPLAY "OTF-CNT:" WK-CNT
           DISPLAY "*** KJBM011 END ***"
           
           CLOSE OTF-FILE.
           
       EXT.
           EXIT.
      ******************************************************************
      *エラー処理 
      ******************************************************************  
       ERROR-RTN SECTION.
           DISPLAY "SQL ERROR :" SQLCODE
           DISPLAY "MESSAGE   :" SQLERRMC
           MOVE 9 TO RETURN-CODE.

       EXT.
           EXIT.
      ******************************************************************
      * FETCH
      ****************************************************************** 
       FETCH-SEC SECTION. 
           EXEC SQL
               FETCH CUR-JUCHU
               INTO :H-DATA_KBN,
                    :H-JUCHU_NO,
                    :H-JUCHU_YY,
                    :H-JUCHU_MM,
                    :H-JUCHU_DD,
                    :H-TOKU_COD,
                    :H-SHOHIN_NO,
                    :H-SURYO
           END-EXEC.
        
       EXT.
           EXIT.
             