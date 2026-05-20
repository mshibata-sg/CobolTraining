      ******************************************************************
      * Copyright (c) 2026 システム技研株式会社
      * All Rights Reserved.
      *
      * 本ファイルの利用条件は LICENSE.materials に記載されています。
      * The terms and conditions for use of this file are described
      * in LICENSE.materials.
      ******************************************************************
      ******************************************************************
      *    KUCF010 : 売上ファイル                      LRECL=100
      ******************************************************************
           03  UF010-DATA-KBN              PIC  X(01).
           03  UF010-JUCHU-DATE.
             05  UF010-JUCHU-YY            PIC  9(04).
             05  UF010-JUCHU-MM            PIC  9(02).
             05  UF010-JUCHU-DD            PIC  9(02).
           03  UF010-JUCHU-NO              PIC  9(04).
           03  UF010-SHOHIN-NO             PIC  9(05).
           03  UF010-SHOHIN-MEI            PIC  N(10).
           03  UF010-TANKA                 PIC S9(05)V9(2)
                                                      PACKED-DECIMAL.
           03  UF010-SURYO                 PIC S9(05) PACKED-DECIMAL.
           03  UF010-KINGAKU               PIC S9(09) PACKED-DECIMAL.
           03  FILLER                      PIC  X(50).
