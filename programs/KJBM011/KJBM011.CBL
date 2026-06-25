       IDENTIFICATION DIVISION.
       PROGRAM-ID. KJBM011.

      ******************************************************************
      * システム名　　：研修(ID:K)
      * サブシステム名：受注(ID:JK)
      * プログラム名　：受注チェックファイル作成
      * 作成日／作成者：2026/06/23　[柴田真衣]
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

       01  WK-COUNT PIC 9(6) VALUE 0.

       EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  WS-CONNSTR PIC X(200).
       EXEC SQL INCLUDE KCCMJUCHU END-EXEC.
       EXEC SQL END DECLARE SECTION END-EXEC.

      *SQLの結果を受け取る
       EXEC SQL INCLUDE SQLCA END-EXEC.

       PROCEDURE DIVISION.
           PERFORM INIT-RTN.
           PERFORM MAIN-RTN UNTIL SQLCODE = 100.
           PERFORM TERM-RTN.
           STOP RUN.

      ******************************************************************
      * 初期処理
      ******************************************************************
       INIT-RTN  SECTION.

           DISPLAY "*** KJBM011 START ***".

           OPEN OUTPUT OTF-FILE.

      *データベースに接続               
           STRING               
               "DRIVER={PostgreSQL Unicode};"
               "SERVER=db;"
               "PORT=5432;"
               "DATABASE=postgres;"
               "UID=postgres;"
               "PWD=postgres;"
               "CONNSETTINGS=SET CLIENT_ENCODING TO SJIS"
               DELIMITED BY SIZE
               INTO  WS-CONNSTR
           END-STRING.

           EXEC SQL
               CONNECT TO :WS-CONNSTR
           END-EXEC.
           
      *エラーチェック
           IF SQLCODE < 0
               PERFORM ERROR-RTN
           END-IF.

      *カーソル宣言 
           EXEC SQL
               DECLARE CUR-JUCHU CURSOR FOR
               SELECT     
                   CMJUCHU_DATA_KBN,
                   CMJUCHU_JUCHU_NO,
                   CMJUCHU_JUCHU_DATE,
                   CMJUCHU_SHOHIN_NO,
                   CMJUCHU_SURYO
               FROM KCCMJUCHU
           END-EXEC.

      *カーソルOPEN
           EXEC SQL OPEN CUR-JUCHU END-EXEC.
           IF SQLCODE < 0
               PERFORM ERROR-RTN
           END-IF.

           PERFORM FETCH-SEC.

       EXT.
           EXIT.
      ******************************************************************
      * 主処理
      ******************************************************************
       MAIN-RTN  SECTION.

      *初期化
           MOVE SPACE TO OTF-REC.

      *英数字項目として転送(処理)            
           MOVE CMJUCHU-DATA-KBN TO JF020-DATA-KBN.
           MOVE CMJUCHU-JUCHU-NO TO JF020-JUCHU-NO-X.
           MOVE ZERO TO JF020-JUCHU-Y1.
           MOVE CMJUCHU-JUCHU-DATE TO JF020-JUCHU-DATE6.
           MOVE CMJUCHU-SHOHIN-NO TO JF020-SHOHIN-NO.
           MOVE CMJUCHU-SURYO TO JF020-SURYO-X.
           MOVE SPACE TO JF020-ERR-KBN-TBL.
           MOVE SPACE TO JF020-SHOHIN-MEI.
           MOVE ZERO TO JF020-TANKA.
           MOVE ZERO TO JF020-KINGAKU.

      *出力
           WRITE OTF-REC
           ADD 1 TO WK-COUNT.
           
           PERFORM FETCH-SEC.

       EXT.
           EXIT.
      ******************************************************************
      * 終了処理
      ******************************************************************  
       TERM-RTN SECTION.
      *カーソルCLOSE
           EXEC SQL CLOSE CUR-JUCHU END-EXEC.
      
      *DB切断
           EXEC SQL DISCONNECT ALL END-EXEC.
             
           DISPLAY "OTF-CNT:" WK-COUNT.
           DISPLAY "*** KJBM011 END ***".
           
           CLOSE OTF-FILE.
           
       EXT.
           EXIT.
      ******************************************************************
      *エラー処理 
      ******************************************************************  
       ERROR-RTN SECTION.
           DISPLAY "SQL ERROR :" SQLCODE.
           DISPLAY "MESSAGE :" SQLERRMC.
           MOVE 9 TO RETURN-CODE.
           STOP RUN.
       EXT.
           EXIT.
      ******************************************************************
      * 1行取得
      ****************************************************************** 
       FETCH-SEC SECTION. 
           EXEC SQL
               FETCH CUR-JUCHU
               INTO :CMJUCHU-DATA-KBN,
                    :CMJUCHU-JUCHU-NO,
                    :CMJUCHU-JUCHU-DATE,
                    :CMJUCHU-SHOHIN-NO,
                    :CMJUCHU-SURYO
           END-EXEC.
           
           IF SQLCODE < 0
               PERFORM ERROR-RTN
           END-IF.
        
       EXT.
           EXIT.
             