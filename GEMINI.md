# GEMINI.md

## Agent Rules

### Coding & Naming Conventions
- **Format**: Fixed-form format (Col 7: Indicator, 8-11: Area A, 12-72: Area B). Use `*` in col 7 for comments, enclosed in asterisks.
- **Casing**: All source code (keywords/user-defined) MUST be **UPPERCASE**.
- **Program IDs**: `KJBMxxx` or `KUBMxxx` (xxx = 3-digit number).
- **Files**: SELECT names = `ITF`/`OTF`/`MTF` (add sequential numbers if multiple). FD names = `<SELECT_name>-FILE`.
- **Error Handling**: On critical File/SQL errors, guide to call a dedicated section (e.g., `ERROR-RTN`) to:
  1. DISPLAY error message & code (e.g., SQLCODE).
  2. Set `RETURN-CODE` to non-zero (e.g., 9).
  3. `STOP RUN`.

## Project Environment & Setup
- **OS/Tools**: Ubuntu 24.04 Dev Container (VS Code), GnuCOBOL 3.2 OSS Consortium patch 2.0, PostgreSQL (`esqlOC` preprocessor), GCSORT.
- **DB Credentials**: `esqlOC` connects via ODBC (an ODBC connection string is required); the training environment has a built-in database accessible at host `db`, username `postgres`, password `postgres` with full access. and MUST specified `CONNSETTINGS=SET CLIENT_ENCODING to 'SJIS'`.
- **Compile Commands**:
  - Standard: `cobc -x -o <program-id> -I <copylib dir> <program-id>.cob`
  - With Embedded SQL: `cobc -x -o <program-id> -I <copylib dir> -I. -Q "-Wl,--no-as-needed" -locsql <program-id>.cob`

## Development Conventions
- **Directories**:
  - <something> is placeholder.
  - Code: `programs/<program_id>/` (source and test code).
  - Test Data: `data/<program_id>I.txt` (Shift-JIS encoding, multibyte spaces for `PIC N`, `\n` at EOF for line sequential). Use `iconv -f utf8 -t cp932` for conversion.
  - Copybooks: `copylib/` (filename matches COPY clause).
- **Test Data Creation**: Use `tools/make_data.py` with the target copybook ID (`<copylib-id>`):
  1. Generate a CSV template: `tools/make_data.py --template <copylib-id> > data/csv_tmp_file`
  2. Refer to `docs/FF_<copylib-id>.md` and fill in the required data according to each field's data type, appending records to the CSV template(`data/csv_tmp_file`).
  3. Convert the CSV to a data file: `tools/make_data.py <copylib-id> data/csv_tmp_file data/data_file`, then place `data_file` in the designated location.
  - **Note**: If a preceding program exists in the job flow, inspect its output file and use the output's copybook ID (not the current program's input copybook) to generate test data that reflects the actual upstream output.
- **SQL Preprocessing**: `esqlOC -Q -I <copylib dir> -I . -o <program_id>.cob <program_id>.cbl`
- **Encoding**: ALL COBOL source code (*.COB, *.CBL files) and I/O data files MUST be created and saved in **Shift-JIS (cp932)**. All other files (e.g., Markdown docs, scripts) must be in **UTF-8**. If GEMINI CLI fails to read Shift-JIS files, convert them temporarily using `iconv -f cp932 -t utf8`. When writing COBOL source or data files to disk, always convert from UTF-8 to Shift-JIS before saving: `iconv -f utf8 -t cp932`.

## Documentation & Samples
- **Docs (`docs/`)**: `FLOW_` (Job flow), `PRG_` (Specs), `FF_` (File formats), `TBL_` (DB tables), `SUB_` (Subprograms).
- **Samples (`sample/`)**: `calcyesterday` (Date calc), `fetchdb` (DB SELECT/cursor), `gcsort` (Sort utility), `updatedb` (DB UPDATE/transaction), `KJBM000` (Basic I/O), `pictures` (PIC clauses), `transtype` (Type conversion).

## Permitted COBOL Syntax
Strictly limit syntax to the following allowed keywords and statements:
- **Structure**: IDENTIFICATION/ENVIRONMENT/DATA/PROCEDURE DIVISION, PROGRAM-ID, INPUT-OUTPUT/FILE-CONTROL/FILE/WORKING-STORAGE/LINKAGE SECTION, user-defined SECTIONs.
- **Data**: Levels (01-49 and 77), PIC (9, X, S, V), VALUE, USAGE PACKED-DECIMAL, INITIALIZE, COPY.
- **File I/O**: SELECT ASSIGN TO [EXTERNAL], ORGANIZATION LINE SEQUENTIAL, FD, OPEN INPUT/OUTPUT, READ [NOT] AT END, WRITE, CLOSE.
- **Statements**: MOVE [CORR], PERFORM [UNTIL], IF, GO TO, COMPUTE, EXIT [PROGRAM], ADD TO, DISPLAY, ACCEPT, STOP RUN, EVALUATE WHEN [OTHER], CONTINUE, STRING (permitted for building database connection strings).
- **Operators**: IS NUMERIC, <, >, =, AND, OR, NOT, ZERO.
- **EXEC SQL**: BEGIN/END DECLARE SECTION, INCLUDE, CONNECT TO, DECLARE CURSOR, OPEN, FETCH INTO, CLOSE, DISCONNECT ALL, SELECT INTO, UPDATE SET, COMMIT, ROLLBACK.
- **SQL Vars**: SQLCODE, SQLERRMC.