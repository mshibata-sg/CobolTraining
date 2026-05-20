      ******************************************************************
      * Copyright (c) 2026 システム技研株式会社
      * All Rights Reserved.
      *
      * 本ファイルの利用条件は LICENSE.materials に記載されています。
      * The terms and conditions for use of this file are described
      * in LICENSE.materials.
      ******************************************************************
      ******************************************************************
      *    KJCF020 : 受注チェックファイル              LRECL=100
      ******************************************************************
           03  JF020-DATA-KBN              PIC  X(01).
           03  JF020-JUCHU-NO-X.
             05  JF020-JUCHU-NO            PIC  9(04).
           03  JF020-JUCHU-DATE.
             05  JF020-JUCHU-Y1            PIC  9(02).
             05  JF020-JUCHU-DATE6.
               07  JF020-JUCHU-Y2          PIC  9(02).
               07  JF020-JUCHU-MM          PIC  9(02).
               07  JF020-JUCHU-DD          PIC  9(02).
           03  JF020-SHOHIN-NO-X.
             05  JF020-SHOHIN-NO           PIC  9(05).
           03  JF020-SURYO-X.
             05  JF020-SURYO               PIC  9(05).
           03  FILLER                      PIC  X(03).
           03  JF020-ERR-KBN-TBL.
             05   JF020-ERR-KBN            PIC  X(01)
                                           OCCURS 10 TIMES.
           03  JF020-SHOHIN-MEI            PIC  N(10).
           03  JF020-TANKA                 PIC S9(05)V9(2).
           03  JF020-KINGAKU               PIC S9(09).
           03  FILLER                      PIC  X(28).
