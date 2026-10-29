"! לוג אפליקציה (BALI) משותף ל-Application Jobs של הפיתוח.
"! כשל בלוג לעולם לא עוצר ריצה: כל קריאת BALI תופסת cx_bali_runtime ובולעת אותה.
CLASS zcl_co_job_log DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES ty_severity TYPE c LENGTH 1.

    CONSTANTS:
      BEGIN OF c_severity,
        info    TYPE ty_severity VALUE 'I',
        success TYPE ty_severity VALUE 'S',
        warning TYPE ty_severity VALUE 'W',
        error   TYPE ty_severity VALUE 'E',
      END OF c_severity.

    CONSTANTS c_object TYPE c LENGTH 20 VALUE 'ZCO_SKF' ##NO_TEXT.

    CLASS-METHODS open
      IMPORTING iv_subobject   TYPE csequence
                iv_external_id TYPE csequence
      RETURNING VALUE(ro_log)  TYPE REF TO zcl_co_job_log.

    METHODS add_text
      IMPORTING iv_severity TYPE ty_severity
                iv_text     TYPE csequence.

    "! מוסיף הודעות T100 שהוחזרו מ-BAPI (דרך ה-Wrapper)
    METHODS add_messages
      IMPORTING it_messages TYPE zif_co_bapi_messages=>ty_messages.

    METHODS add_exception
      IMPORTING ix_error TYPE REF TO cx_root.

    METHODS has_errors RETURNING VALUE(rv_has_errors) TYPE abap_boolean.

    "! שמירה + שיוך ל-Application Job הנוכחי (הלוג מוצג באפליקציית Application Jobs)
    METHODS save.

  PRIVATE SECTION.
    DATA mo_log        TYPE REF TO if_bali_log.
    DATA mv_has_items  TYPE abap_boolean.
    DATA mv_has_errors TYPE abap_boolean.

    METHODS constructor
      IMPORTING iv_subobject   TYPE csequence
                iv_external_id TYPE csequence.
ENDCLASS.



CLASS zcl_co_job_log IMPLEMENTATION.

  METHOD open.
    ro_log = NEW #( iv_subobject = iv_subobject iv_external_id = iv_external_id ).
  ENDMETHOD.


  METHOD constructor.
    TRY.
        mo_log = cl_bali_log=>create( ).
        mo_log->set_header( header = cl_bali_header_setter=>create( object      = c_object
                                                                    subobject   = CONV #( iv_subobject )
                                                                    external_id = CONV #( iv_external_id ) ) ).
      CATCH cx_bali_runtime.
        " אובייקט הלוג חסר או אין הרשאה: הלוג לא נכתב, הריצה ממשיכה
        CLEAR mo_log.
    ENDTRY.
  ENDMETHOD.


  METHOD add_text.
    IF iv_severity = c_severity-error.
      mv_has_errors = abap_true.
    ENDIF.
    IF mo_log IS NOT BOUND.
      RETURN.
    ENDIF.
    TRY.
        mo_log->add_item( item = cl_bali_free_text_setter=>create( severity = iv_severity
                                                                   text     = CONV #( iv_text ) ) ).
        mv_has_items = abap_true.
      CATCH cx_bali_runtime ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.


  METHOD add_messages.
    LOOP AT it_messages INTO DATA(ls_message).
      add_text( iv_severity = SWITCH #( ls_message-type
                                        WHEN 'E' OR 'A' OR 'X' THEN c_severity-error
                                        WHEN 'W'               THEN c_severity-warning
                                        WHEN 'S'               THEN c_severity-success
                                        ELSE                        c_severity-info )
                iv_text     = ls_message-text ).
    ENDLOOP.
  ENDMETHOD.


  METHOD add_exception.
    add_text( iv_severity = c_severity-error
              iv_text     = ix_error->get_text( ) ).
  ENDMETHOD.


  METHOD has_errors.
    rv_has_errors = mv_has_errors.
  ENDMETHOD.


  METHOD save.
    IF mv_has_items = abap_false OR mo_log IS NOT BOUND.
      RETURN.
    ENDIF.
    TRY.
        cl_bali_log_db=>get_instance( )->save_log( log                        = mo_log
                                                   assign_to_current_appl_job = abap_true ).
        COMMIT WORK.
      CATCH cx_bali_runtime ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
