"! תקופת חתך (Value Object) בפורמט YYYYPPP, לדוגמה 2026009.
"! מרכז במקום אחד את כל החישובים על התקופה: שנה, תקופה, יום ראשון/אחרון, טקסט לתצוגה.
"! הנחה: שנת כספים = שנה קלנדרית, תקופה = חודש (001-012). ראה שאלות פתוחות.
CLASS zcl_co_fiscal_period DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES ty_value  TYPE n LENGTH 7.
    TYPES ty_year   TYPE n LENGTH 4.
    TYPES ty_period TYPE n LENGTH 3.

    CLASS-METHODS from_value
      IMPORTING iv_value         TYPE csequence
      RETURNING VALUE(ro_period) TYPE REF TO zcl_co_fiscal_period
      RAISING   zcx_co_skf_error.

    METHODS get_value  RETURNING VALUE(rv_value)  TYPE ty_value.
    METHODS get_year   RETURNING VALUE(rv_year)   TYPE ty_year.
    METHODS get_period RETURNING VALUE(rv_period) TYPE ty_period.

    METHODS get_first_day RETURNING VALUE(rv_date) TYPE d.
    METHODS get_last_day  RETURNING VALUE(rv_date) TYPE d.

    "! תצוגה לטקסטי כותרת: 009.2026
    METHODS get_display_text RETURNING VALUE(rv_text) TYPE string.

    METHODS constructor
      IMPORTING iv_year   TYPE i
                iv_period TYPE i.

  PRIVATE SECTION.
    CONSTANTS c_first_period TYPE i VALUE 1.
    CONSTANTS c_last_period  TYPE i VALUE 12.

    DATA mv_year   TYPE i.
    DATA mv_period TYPE i.

    CLASS-METHODS raise_invalid
      IMPORTING iv_value TYPE csequence
      RAISING   zcx_co_skf_error.
ENDCLASS.



CLASS zcl_co_fiscal_period IMPLEMENTATION.

  METHOD from_value.
    IF NOT matches( val = iv_value regex = `\d{7}` ).
      raise_invalid( iv_value ).
    ENDIF.

    DATA(lv_year)   = CONV i( substring( val = iv_value off = 0 len = 4 ) ).
    DATA(lv_period) = CONV i( substring( val = iv_value off = 4 len = 3 ) ).

    IF lv_year = 0 OR lv_period NOT BETWEEN c_first_period AND c_last_period.
      raise_invalid( iv_value ).
    ENDIF.

    ro_period = NEW #( iv_year = lv_year iv_period = lv_period ).
  ENDMETHOD.


  METHOD constructor.
    mv_year   = iv_year.
    mv_period = iv_period.
  ENDMETHOD.


  METHOD get_value.
    rv_value = |{ get_year( ) }{ get_period( ) }|.
  ENDMETHOD.


  METHOD get_year.
    rv_year = mv_year.
  ENDMETHOD.


  METHOD get_period.
    rv_period = mv_period.
  ENDMETHOD.


  METHOD get_first_day.
    rv_date = |{ get_year( ) }{ mv_period WIDTH = 2 ALIGN = RIGHT PAD = '0' }01|.
  ENDMETHOD.


  METHOD get_last_day.
    " היום האחרון = היום הראשון של החודש הבא פחות יום
    DATA lv_first_of_next_month TYPE d.
    IF mv_period = c_last_period.
      lv_first_of_next_month = |{ mv_year + 1 WIDTH = 4 ALIGN = RIGHT PAD = '0' }0101|.
    ELSE.
      lv_first_of_next_month = |{ get_year( ) }{ mv_period + 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }01|.
    ENDIF.
    rv_date = lv_first_of_next_month - 1.
  ENDMETHOD.


  METHOD get_display_text.
    rv_text = |{ get_period( ) }.{ get_year( ) }|.
  ENDMETHOD.


  METHOD raise_invalid.
    RAISE EXCEPTION TYPE zcx_co_skf_error MESSAGE e002(zco_skf) WITH iv_value.
  ENDMETHOD.

ENDCLASS.
