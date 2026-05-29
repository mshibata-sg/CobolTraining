       IDENTIFICATION DIVISION.
       PROGRAM-ID. KJBM010.

      ******************************************************************
      * システム名　　：研修(ID:K)
      * サブシステム名：受注(ID:JK)
      * プログラム名　：受注チェックファイル作成
      * 作成日／作成者：2026/05/28　[柴田真衣]
      * 変更日／変更者：
      * 　　　変更内容：
      ******************************************************************

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
              SELECT ITF-FILE ASSIGN TO ITF
              ORGANIZATION LINE SEQUENTIAL.

              SELECT OTF-FILE ASSIGN TO OTF
              ORGANIZATION SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  ITF-FILE.
       01  ITF-REC.
           COPY KJCF010.     

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
             MOVE SPACES TO OTF-REC

             MOVE JF010-DATA-KBN TO JF020-DATA-KBN
             MOVE JF010-JUCHU-NO-X TO JF020-JUCHU-NO-X 
             MOVE ZERO TO JF020-JUCHU-Y1
             MOVE JF010-JUCHU-DATE TO JF020-JUCHU-DATE6	
             MOVE JF010-JUCHU-NO-X TO JF020-SHOHIN-NO
             MOVE JF010-SURYO-X TO JF020-SURYO-X
             MOVE SPACES TO JF020-ERR-KBN-TBL
             MOVE SPACES TO JF020-SHOHIN-MEI
             MOVE ZERO TO JF020-TANKA
             MOVE ZERO TO JF020-KINGAKU
             
             WRITE OTF-REC
             ADD 1 TO OUT-CNT

           READ ITF-FILE
             AT END 
             MOVE "Y" TO KJCF010-EOF
             NOT AT END 
             ADD 1 TO IN-CNT
             END-READ
           END-PERFORM.

           DISPLAY "*** KJBM010 START ***"
           DISPLAY "ITF-CNT:" IN-CNT
           DISPLAY "OTF-CNT:" OUT-CNT
           DISPLAY "*** KJBM010 END ***"
             
      ******************************************************************
      * 終了処理
      ******************************************************************  
           CLOSE ITF-FILE.
           CLOSE OTF-FILE.
           STOP RUN.
    
        
             