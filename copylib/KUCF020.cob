      ******************************************************************
      * Copyright (c) 2026 システム技研株式会社
      * All Rights Reserved.
      *
      * 本ファイルの利用条件は LICENSE.materials に記載されています。
      * The terms and conditions for use of this file are described
      * in LICENSE.materials.
      ******************************************************************
      ******************************************************************
      *    KUCF020 : 売上集計ファイル                  LRECL=30
      ******************************************************************
           03  UF020-SHOHIN-NO             PIC  9(05).
           03  UF020-JUCHU-DATE.
             05  UF020-JUCHU-YY            PIC  9(04).
             05  UF020-JUCHU-MM            PIC  9(02).
           03  UF020-KINGAKU               PIC S9(09) PACKED-DECIMAL.
           03  FILLER                      PIC  X(14).
