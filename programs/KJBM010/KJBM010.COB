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
              ORGANIZATION SEQUENTIAL.

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
             END-READ. 
              
           PERFORM UNTIL KJCF010-EOF = "Y"
             MOVE SPACES TO OTF-REC

             MOVE JF010-DATA-KBN TO JF020-DATA-KBN
             MOVE JF010-JUCHU-NO-X TO JF020-JUCHU-NO-X 
             MOVE ZERO TO JF020-JUCHU-Y1
             MOVE JF010-JUCHU-DATE TO JF020-JUCHU-DATE6	
             MOVE JF010-SHOHIN-NO TO JF020-SHOHIN-NO-X
             MOVE JF010-SURYO-X TO JF020-SURYO-X
             MOVE SPACES TO JF020-ERR-KBN-TBL
             MOVE SPACES TO JF020-SHOHIN-MEI
             MOVE ZERO TO JF020-TANKA
             MOVE ZERO TO JF020-KINGAKU
               WRITE OTF-REC

           READ ITF-FILE
             AT END 
               MOVE "Y" TO KJCF010-EOF
             END-READ
           END-PERFORM.
             
      ******************************************************************
      * 終了処理
      ******************************************************************  
           CLOSE ITF-FILE.
           CLOSE OTF-FILE.
           STOP RUN.
    
        
             