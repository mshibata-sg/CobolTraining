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

