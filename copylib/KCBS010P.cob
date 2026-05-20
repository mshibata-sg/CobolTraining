      ******************************************************************
      * Copyright (c) 2026 システム技研株式会社
      * All Rights Reserved.
      *
      * 本ファイルの利用条件は LICENSE.materials に記載されています。
      * The terms and conditions for use of this file are described
      * in LICENSE.materials.
      ******************************************************************
      ******************************************************************
      *    KCBS010P : 日付チェック
      ******************************************************************
       01  KCBS010-P1.
           03  S010-DATE.
             05  S010-P1-Y1                PIC  9(02).
             05  S010-DATE6.
               07  S010-D6-Y2              PIC  9(02).
               07  S010-D6-MM              PIC  9(02).
               07  S010-D6-DD              PIC  9(02).
           03  S010-DATE8       REDEFINES  S010-DATE.
             05  S010-D8-YY                PIC  9(04).
             05  S010-D8-MM                PIC  9(02).
             05  S010-D8-DD                PIC  9(02).
           03  S010-RCD                    PIC  X(01).
