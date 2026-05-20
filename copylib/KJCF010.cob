      ******************************************************************
      * Copyright (c) 2026 システム技研株式会社
      * All Rights Reserved.
      *
      * 本ファイルの利用条件は LICENSE.materials に記載されています。
      * The terms and conditions for use of this file are described
      * in LICENSE.materials.
      ******************************************************************
      ******************************************************************
      *    KJCF010 : 受注データ                        LRECL=50
      ******************************************************************
           03  JF010-DATA-KBN              PIC  X(01).
           03  FILLER                      PIC  X(01).
           03  JF010-JUCHU-NO-X.
             05  JF010-JUCHU-NO            PIC  9(04).
           03  FILLER                      PIC  X(01).
           03  JF010-JUCHU-DATE.
             05  JF010-JUCHU-YY            PIC  9(02).
             05  JF010-JUCHU-MM            PIC  9(02).
             05  JF010-JUCHU-DD            PIC  9(02).
           03  FILLER                      PIC  X(01).
           03  JF010-SHOHIN-NO             PIC  9(05).
           03  FILLER                      PIC  X(01).
           03  JF010-SURYO-X.
             05  JF010-SURYO               PIC  9(05).
           03  FILLER                      PIC  X(25).
