"! Application Job - "עדכון מפתחות העמסה" (ZCO_SKF_MANAGE), אפיון טכני סעיפים 5-14.
"! Catalog Entry: ZCO_SKF_MANAGE, Template: ZCO_SKF_MANAGE (TEST_RUN = X).
"! ריצת מבחן: בניית המסמכים + בדיקת BAPI (CHECK) + פירוט בלוג, ללא שינוי ב-DB.
"! ריצת עדכון: רישום כל מסמך בנפרד (COMMIT לכל מסמך) ודיווח מספר מסמך / שגיאות בלוג.
CLASS zcl_co_skf_manage_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_defaults.
    INTERFACES if_apj_rt_run.
    INTERFACES if_oo_adt_classrun.

    " פרמטרי job: כל attribute ציבורי הוא פרמטר; המסגרת ממלאת אותו לפני EXECUTE
    DATA fiscal_year_period TYPE fis_jahrper.
    DATA topic              TYPE zco_skf_topic.
    DATA test_run           TYPE abap_boolean.

    "! הזרקת תלויות לבדיקות; ה-job framework יוצר את המחלקה ללא פרמטרים
    METHODS constructor
      IMPORTING io_builder TYPE REF TO zcl_co_skf_doc_builder OPTIONAL
                io_poster  TYPE REF TO zif_co_skf_poster      OPTIONAL.

  PRIVATE SECTION.
    CONSTANTS c_log_subobject   TYPE c LENGTH 20 VALUE 'MANAGE' ##NO_TEXT.
    CONSTANTS c_max_logged_items TYPE i VALUE 200.

    CONSTANTS:
      BEGIN OF c_job_param,
        test_run TYPE c LENGTH 30 VALUE 'TEST_RUN',
        topic    TYPE c LENGTH 30 VALUE 'TOPIC',
      END OF c_job_param.

    DATA mo_builder TYPE REF TO zcl_co_skf_doc_builder.
    DATA mo_poster  TYPE REF TO zif_co_skf_poster.
    DATA mo_log     TYPE REF TO zcl_co_job_log.

    METHODS job_run.

    METHODS check_documents
      IMPORTING it_documents TYPE zif_co_skf_types=>ty_documents.

    METHODS post_documents
      IMPORTING it_documents TYPE zif_co_skf_types=>ty_documents.

    METHODS log_document_items
      IMPORTING is_document TYPE zif_co_skf_poster=>ty_document.

    METHODS get_user RETURNING VALUE(rv_user) TYPE string.
ENDCLASS.



CLASS zcl_co_skf_manage_job IMPLEMENTATION.

  METHOD constructor.
    mo_builder = COND #( WHEN io_builder IS BOUND THEN io_builder ELSE NEW zcl_co_skf_doc_builder( ) ).
    mo_poster  = COND #( WHEN io_poster  IS BOUND THEN io_poster  ELSE NEW zcl_co_skf_poster_bapi( ) ).
  ENDMETHOD.


  METHOD if_apj_dt_defaults~get_default_parameters.
    " ריצת מבחן מסומנת כברירת מחדל - עדכון בפועל נבחר במפורש
    et_parameter_val = VALUE #( ( name    = c_job_param-test_run
                                  t_value = VALUE #( ( sign = 'I' option = 'EQ' low = abap_true ) ) )
                                ( name    = c_job_param-topic
                                  t_value = VALUE #( ( sign = 'I' option = 'EQ'
                                                       low  = zif_co_skf_types=>c_topic-area ) ) ) ).
  ENDMETHOD.


  METHOD if_apj_rt_run~execute.
    TRY.
        job_run( ).
      CATCH cx_root INTO DATA(lx_unexpected).
        " Last-resort: ריצה שנכשלה תמיד משאירה לוג
        TRY.
            mo_log->add_exception( lx_unexpected ).
            mo_log->save( ).
          CATCH cx_root ##NO_HANDLER.
        ENDTRY.
    ENDTRY.
  ENDMETHOD.


  METHOD job_run.
    mo_log = zcl_co_job_log=>open( iv_subobject   = c_log_subobject
                                   iv_external_id = |{ topic }/{ fiscal_year_period }| ).

    mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-info
                      iv_text     = |{ COND string( WHEN test_run = abap_true THEN `ריצת מבחן` ELSE `ריצת עדכון` ) }, | &&
                                    |נושא { topic }, תקופה { fiscal_year_period }, משתמש { get_user( ) }| ) ##NO_TEXT.
    TRY.
        DATA(lt_documents) = mo_builder->build_documents(
                               iv_topic  = topic
                               io_period = zcl_co_fiscal_period=>from_value( fiscal_year_period ) ).
      CATCH zcx_co_skf_error INTO DATA(lx_error).
        " פרמטר חסר / תקופה לא תקינה - לא נרשם דבר
        mo_log->add_exception( lx_error ).
        mo_log->save( ).
        RETURN.
    ENDTRY.

    IF lt_documents IS INITIAL.
      mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-warning
                        iv_text     = `לא נמצאו נתונים לתקופה - לא נרשם דבר` ) ##NO_TEXT.
      mo_log->save( ).
      RETURN.
    ENDIF.

    IF test_run = abap_true.
      check_documents( lt_documents ).
    ELSE.
      post_documents( lt_documents ).
    ENDIF.

    mo_log->save( ).
  ENDMETHOD.


  METHOD check_documents.
    LOOP AT it_documents INTO DATA(ls_document).
      log_document_items( ls_document ).
      mo_log->add_messages( mo_poster->check( ls_document )-messages ).
    ENDLOOP.
  ENDMETHOD.


  METHOD post_documents.
    " כל מסמך עומד בפני עצמו: כשל במסמך אחד לא מבטל מסמכים שכבר נרשמו (ראה שאלות פתוחות)
    LOOP AT it_documents INTO DATA(ls_document).
      DATA(ls_result) = mo_poster->post( ls_document ).
      IF ls_result-is_success = abap_true.
        mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-success
                          iv_text     = |{ ls_document-header_text }: נרשם מסמך { ls_result-document_number }, | &&
                                        |{ lines( ls_document-items ) } שורות| ) ##NO_TEXT.
      ELSE.
        mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-error
                          iv_text     = |{ ls_document-header_text }: הרישום נכשל| ) ##NO_TEXT.
      ENDIF.
      mo_log->add_messages( ls_result-messages ).
    ENDLOOP.
  ENDMETHOD.


  METHOD log_document_items.
    mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-info
                      iv_text     = |{ is_document-header_text } | &&
                                    |(תאריך רישום { is_document-posting_date DATE = USER }): | &&
                                    |{ lines( is_document-items ) } שורות| ) ##NO_TEXT.

    LOOP AT is_document-items INTO DATA(ls_item) TO c_max_logged_items.
      mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-info
                        iv_text     = |{ ls_item-statistical_key_figure } / { ls_item-cost_center } / | &&
                                      |{ ls_item-fiscal_period }.{ ls_item-fiscal_year }: { ls_item-quantity } { ls_item-quantity_unit }| ).
    ENDLOOP.

    IF lines( is_document-items ) > c_max_logged_items.
      mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-info
                        iv_text     = |... ועוד { lines( is_document-items ) - c_max_logged_items } שורות - ראה תצוגה ב-Fiori| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD get_user.
    TRY.
        rv_user = cl_abap_context_info=>get_user_technical_name( ).
      CATCH cx_abap_context_info_error.
        CLEAR rv_user.
    ENDTRY.
  ENDMETHOD.


  " בדיקה מ-ADT (F9) - ריצת מבחן בלבד, ללא רישום
  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(lt_documents) = mo_builder->build_documents(
                               iv_topic  = zif_co_skf_types=>c_topic-area
                               io_period = zcl_co_fiscal_period=>from_value( '2026009' ) ).
        LOOP AT lt_documents INTO DATA(ls_document).
          out->write( |{ ls_document-header_text }: { lines( ls_document-items ) } items| ).
          out->write( mo_poster->check( ls_document )-messages ).
        ENDLOOP.
      CATCH zcx_co_skf_error INTO DATA(lx_error).
        out->write( lx_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
