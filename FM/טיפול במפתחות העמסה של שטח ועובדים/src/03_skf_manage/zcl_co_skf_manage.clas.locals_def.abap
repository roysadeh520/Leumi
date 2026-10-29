"! שגיאה עסקית שעוצרת לפני רישום (פרמטר חסר, תקופה שגויה, נושא לא נתמך)
CLASS lcx_error DEFINITION INHERITING FROM cx_static_check FINAL.
  PUBLIC SECTION.
    METHODS constructor IMPORTING iv_text TYPE string.
    METHODS get_text REDEFINITION.
  PRIVATE SECTION.
    DATA mv_text TYPE string.
ENDCLASS.
