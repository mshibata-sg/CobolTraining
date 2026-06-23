       IDENTIFICATION DIVISION.
       PROGRAM-ID. KJBM011.

      ******************************************************************
      * システム名　　：研修(ID:K)
      * サブシステム名：受注(ID:JK)
      * プログラム名　：受注チェックファイ
      * 作成日／作成者：2026/06/22　[柴田真衣]
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
      **********************************************************************
      *******                EMBEDDED SQL VARIABLES                  *******
       77 OCSQL     PIC X(8) VALUE "OCSQL".
       77 OCSQLDIS  PIC X(8) VALUE "OCSQLDIS".
       77 OCSQLPRE  PIC X(8) VALUE "OCSQLPRE".
       77 OCSQLEXE  PIC X(8) VALUE "OCSQLEXE".
       77 OCSQLRBK  PIC X(8) VALUE "OCSQLRBK".
       77 OCSQLCMT  PIC X(8) VALUE "OCSQLCMT".
       77 OCSQLIMM  PIC X(8) VALUE "OCSQLIMM".
       77 OCSQLOCU  PIC X(8) VALUE "OCSQLOCU".
       77 OCSQLCCU  PIC X(8) VALUE "OCSQLCCU".
       77 OCSQLFTC  PIC X(8) VALUE "OCSQLFTC".
       77 OCSQLCAL  PIC X(8) VALUE "OCSQLCAL".
       01 SQLV.
           05 SQL-ARRSZ  PIC S9(9) COMP-5 VALUE 5.
           05 SQL-COUNT  PIC S9(9) COMP-5 VALUE ZERO.
           05 SQL-ADDR   POINTER OCCURS 5 TIMES VALUE NULL.
           05 SQL-LEN    PIC S9(9) COMP-5 OCCURS 5 TIMES VALUE ZERO.
           05 SQL-TYPE   PIC X OCCURS 5 TIMES.
           05 SQL-PREC   PIC X OCCURS 5 TIMES.
      **********************************************************************
       01 SQL-STMT-0.
           05 SQL-IPTR   POINTER VALUE NULL.
           05 SQL-PREP   PIC X VALUE "N".
           05 SQL-OPT    PIC X VALUE "C".
           05 SQL-PARMS  PIC S9(4) COMP-5 VALUE 0.
           05 SQL-STMLEN PIC S9(4) COMP-5 VALUE 106.
           05 SQL-STMT   PIC X(106) VALUE "SELECT CMJUCHU_DATA_KBN,CMJUC
      -    "HU_JUCHU_NO,CMJUCHU_JUCHU_DATE,CMJUCHU_SHOHIN_NO,CMJUCHU_SUR
      -    "YO FROM KCCMJUCHU".
           05 SQL-CNAME  PIC X(9) VALUE "CUR-JUCHU".
           05 FILLER     PIC X VALUE LOW-VALUE.
      **********************************************************************
      *******          PRECOMPILER-GENERATED VARIABLES               *******
       01 SQLV-GEN-VARS.
           05 SQL-VAR-0001  PIC S9(1) COMP-3.
           05 SQL-VAR-0002  PIC S9(5) COMP-3.
           05 SQL-VAR-0003  PIC S9(5) COMP-3.
      *******       END OF PRECOMPILER-GENERATED VARIABLES           *******
      **********************************************************************

       01  WK-COUNT PIC 9(6) VALUE 0.

      *EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  WS-CONNSTR PIC X(200).
       01  CMJUCHU-DATA-KBN   PIC 9(1).
       01  CMJUCHU-JUCHU-NO   PIC 9(4).
       01  CMJUCHU-JUCHU-DATE PIC X(6).
       01  CMJUCHU-SHOHIN-NO  PIC X(5).
       01  CMJUCHU-SURYO      PIC 9(5).
      *EXEC SQL END DECLARE SECTION END-EXEC.

      *SQL
      *EXEC SQL INCLUDE SQLCA END-EXEC.
       01 SQLCA.
           05 SQLSTATE PIC X(5).
              88  SQL-SUCCESS           VALUE '00000'.
              88  SQL-RIGHT-TRUNC       VALUE '01004'.
              88  SQL-NODATA            VALUE '02000'.
              88  SQL-DUPLICATE         VALUE '23000' THRU '23999'.
              88  SQL-MULTIPLE-ROWS     VALUE '21000'.
              88  SQL-NULL-NO-IND       VALUE '22002'.
              88  SQL-INVALID-CURSOR-STATE VALUE '24000'.
           05 FILLER   PIC X.
           05 SQLVERSN PIC 99 VALUE 03.
           05 SQLCODE  PIC S9(9) COMP-5 VALUE ZERO.
           05 SQLERRM.
               49 SQLERRML PIC S9(4) COMP-5 VALUE ZERO.
               49 SQLERRMC PIC X(486).
           05 SQLERRD OCCURS 6 TIMES PIC S9(9) COMP-5 VALUE ZERO.
           05 FILLER   PIC X(4).
           05 SQL-HCONN USAGE POINTER VALUE NULL.

       PROCEDURE DIVISION.
      *データベース
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

      *    EXEC SQL
      *        CONNECT TO :WS-CONNSTR
      *    END-EXEC.
           MOVE 200 TO SQL-LEN(1)
           CALL OCSQL    USING WS-CONNSTR
                               SQL-LEN(1)
                               SQLCA
           END-CALL
                   .

      *エラーチェック
           IF SQLCODE < 0
               PERFORM ERROR-RTN
           END-IF.

           PERFORM INIT-RTN.
           PERFORM MAIN-RTN.
           PERFORM TERM-RTN.
           STOP RUN.

      ******************************************************************
      *
      ******************************************************************
       INIT-RTN  SECTION.
           DISPLAY "*** KJBM011 START ***".

           OPEN OUTPUT OTF-FILE.

      *カーソ
      *    EXEC SQL
      *        DECLARE CUR-JUCHU CURSOR FOR
      *        SELECT
      *            CMJUCHU_DATA_KBN,
      *            CMJUCHU_JUCHU_NO,
      *            CMJUCHU_JUCHU_DATE,
      *            CMJUCHU_SHOHIN_NO,
      *            CMJUCHU_SURYO
      *        FROM KCCMJUCHU
      *    END-EXEC.
                   .

      *カーソルOPEN
      *    EXEC SQL OPEN CUR-JUCHU END-EXEC.
           IF SQL-PREP OF SQL-STMT-0 = "N"
               MOVE 0 TO SQL-COUNT
               CALL OCSQLPRE USING SQLV
                                   SQL-STMT-0
                                   SQLCA
           END-IF
           CALL OCSQLOCU USING SQL-STMT-0
                               SQLCA
           END-CALL
                                           .
           IF SQLCODE < 0
               PERFORM ERROR-RTN
           END-IF.

           PERFORM FETCH-SEC

           IF SQLCODE < 0
           PERFORM ERROR-RTN
           END-IF.

       EXT.
           EXIT.
      ******************************************************************
      *
      ******************************************************************
       MAIN-RTN  SECTION.

      *SQLCODE=100（データなし）になるまでループ
           PERFORM UNTIL SQLCODE = 100

      *エラーチェック
               IF SQLCODE < 0
                   PERFORM ERROR-RTN
               END-IF

      *
               MOVE SPACE TO OTF-REC

      *英数字項目として転送(処理)
               MOVE CMJUCHU-DATA-KBN TO JF020-DATA-KBN
               MOVE CMJUCHU-JUCHU-NO TO JF020-JUCHU-NO-X
               MOVE ZERO TO JF020-JUCHU-Y1
               MOVE CMJUCHU-JUCHU-DATE TO JF020-JUCHU-DATE6
               MOVE CMJUCHU-SHOHIN-NO TO JF020-SHOHIN-NO
               MOVE CMJUCHU-SURYO TO JF020-SURYO-X
               MOVE SPACE TO JF020-ERR-KBN-TBL
               MOVE SPACE TO JF020-SHOHIN-MEI
               MOVE ZERO TO JF020-TANKA
               MOVE ZERO TO JF020-KINGAKU

      *出
               WRITE OTF-REC
               ADD 1 TO WK-COUNT

               PERFORM FETCH-SEC

           END-PERFORM.

       EXT.
           EXIT.
      ******************************************************************
      * 終
      ******************************************************************
       TERM-RTN SECTION.
      *カーソルCLOSE
      *    EXEC SQL CLOSE CUR-JUCHU END-EXEC.
           CALL OCSQLCCU USING SQL-STMT-0
                               SQLCA
                                            .

      *DB切断
      *    EXEC SQL DISCONNECT ALL END-EXEC.
           CALL OCSQLDIS USING SQLCA END-CALL
                                           .

           DISPLAY "OTF-CNT:" WK-COUNT.
           DISPLAY "*** KJBM011 END ***".

           CLOSE OTF-FILE.

       EXT.
           EXIT.
      ******************************************************************
      *エラー
      ******************************************************************
       ERROR-RTN SECTION.
           DISPLAY "SQL ERROR :" SQLCODE.
           DISPLAY "MESSAGE :" SQLERRMC.
           MOVE 9 TO RETURN-CODE.
           STOP RUN.
       EXT.
           EXIT.
      ******************************************************************
      * 1行
      ******************************************************************
       FETCH-SEC SECTION.
      *    EXEC SQL
      *        FETCH CUR-JUCHU
      *        INTO :CMJUCHU-DATA-KBN,
      *             :CMJUCHU-JUCHU-NO,
      *             :CMJUCHU-JUCHU-DATE,
      *             :CMJUCHU-SHOHIN-NO,
      *             :CMJUCHU-SURYO
      *    END-EXEC.
           SET SQL-ADDR(1) TO ADDRESS OF
             SQL-VAR-0001
           MOVE "3" TO SQL-TYPE(1)
           MOVE 1 TO SQL-LEN(1)
               MOVE X'00' TO SQL-PREC(1)
           SET SQL-ADDR(2) TO ADDRESS OF
             SQL-VAR-0002
           MOVE "3" TO SQL-TYPE(2)
           MOVE 3 TO SQL-LEN(2)
               MOVE X'00' TO SQL-PREC(2)
           SET SQL-ADDR(3) TO ADDRESS OF
             CMJUCHU-JUCHU-DATE
           MOVE "X" TO SQL-TYPE(3)
           MOVE 6 TO SQL-LEN(3)
           SET SQL-ADDR(4) TO ADDRESS OF
             CMJUCHU-SHOHIN-NO
           MOVE "X" TO SQL-TYPE(4)
           MOVE 5 TO SQL-LEN(4)
           SET SQL-ADDR(5) TO ADDRESS OF
             SQL-VAR-0003
           MOVE "3" TO SQL-TYPE(5)
           MOVE 3 TO SQL-LEN(5)
               MOVE X'00' TO SQL-PREC(5)
           MOVE 5 TO SQL-COUNT
           CALL OCSQLFTC USING SQLV
                               SQL-STMT-0
                               SQLCA
           IF SQLCODE = 0
             MOVE SQL-VAR-0001 TO CMJUCHU-DATA-KBN
             MOVE SQL-VAR-0002 TO CMJUCHU-JUCHU-NO
             MOVE SQL-VAR-0003 TO CMJUCHU-SURYO
           END-IF
                   .

       EXT.
           EXIT.

      **********************************************************************
      *  : ESQL for GnuCOBOL/OpenCOBOL Version 3 (2024.11.27) Build May 18 2026

      *******               EMBEDDED SQL VARIABLES USAGE             *******
      *  CMJUCHU-DATA-KBN         IN USE THROUGH TEMP VAR SQL-VAR-0001 DECIMAL(1,0)
      *  CMJUCHU-JUCHU-DATE       IN USE CHAR(6)
      *  CMJUCHU-JUCHU-NO         IN USE THROUGH TEMP VAR SQL-VAR-0002 DECIMAL(5,0)
      *  CMJUCHU-SHOHIN-NO        IN USE CHAR(5)
      *  CMJUCHU-SURYO            IN USE THROUGH TEMP VAR SQL-VAR-0003 DECIMAL(5,0)
      *  CUR-JUCHU                IN USE CURSOR
      *  WS-CONNSTR               IN USE CHAR(200)
      **********************************************************************
