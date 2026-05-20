      ******************************************************************
      * Copyright (c) 2026 システム技研株式会社
      * All Rights Reserved.
      *
      * 本ファイルの利用条件は LICENSE.materials に記載されています。
      * The terms and conditions for use of this file are described
      * in LICENSE.materials.
      ******************************************************************
      ******************************************************************
      *    KCCFSHO : 商品マスタ                        LRECL=50
      ******************************************************************
           03  CFSHO-SHOHIN-NO             PIC  9(05).
           03  CFSHO-SHOHIN-MEI            PIC  N(10).
           03  CFSHO-TANKA                 PIC S9(05)V9(2)
                                                      PACKED-DECIMAL.
           03  CFSHO-ZAIKO-INF.
             05  CFSHO-ZENGETU-ZAIKO       PIC S9(07) PACKED-DECIMAL.
             05  CFSHO-TOUGETU-NYUKO       PIC S9(07) PACKED-DECIMAL.
             05  CFSHO-TOUGETU-SYUKO       PIC S9(07) PACKED-DECIMAL.
           03  FILLER                      PIC  X(09).

