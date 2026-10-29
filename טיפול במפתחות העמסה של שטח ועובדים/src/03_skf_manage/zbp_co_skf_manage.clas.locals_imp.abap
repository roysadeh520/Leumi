"! מסמכים שהוכנו ונבדקו בפעולה וממתינים לשמירה (transactional buffer)
CLASS lcl_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA gt_documents TYPE zcl_co_skf_poster_bapi=>ty_documents.
ENDCLASS.


CLASS lhc_preview DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Preview RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Preview.

    METHODS read FOR READ
      IMPORTING keys FOR READ Preview RESULT result.

    METHODS postdocuments FOR MODIFY
      IMPORTING keys FOR ACTION Preview~postDocuments.
ENDCLASS.


CLASS lhc_preview IMPLEMENTATION.

  METHOD get_global_authorizations.
    " ההרשאה נקבעת ברמת האפליקציה (Business Catalog) - ראה שאלות פתוחות 15
    result-%action-postdocuments = if_abap_behv=>auth-allowed.
  ENDMETHOD.


  METHOD lock.
    " אין נעילה ברמת השורה - ה-BAPI נועל את האובייקטים בעצמו
  ENDMETHOD.


  METHOD read.
    " הקריאה ל-UI דרך ZCL_CO_SKF_MANAGE (Query Provider)
  ENDMETHOD.


  METHOD postdocuments.
    DATA(lo_poster) = NEW zcl_co_skf_poster_bapi( ).

    LOOP AT keys INTO DATA(ls_key).
      DATA(ls_build) = NEW zcl_co_skf_manage( )->get_documents(
                         iv_topic              = ls_key-%param-Topic
                         iv_fiscal_year_period = ls_key-%param-FiscalYearPeriod ).

      IF ls_build-error_text IS NOT INITIAL.
        APPEND VALUE #( %cid = ls_key-%cid ) TO failed-preview.
        APPEND VALUE #( %cid = ls_key-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = ls_build-error_text ) ) TO reported-preview.
        CONTINUE.
      ENDIF.

      IF ls_build-documents IS INITIAL.
        APPEND new_message_with_text( severity = if_abap_behv_message=>severity-warning
                                      text     = `לא נמצאו נתונים לתקופה - לא נרשם דבר` ) TO reported-%other ##NO_TEXT.
        CONTINUE.
      ENDIF.

      " בדיקה לפני השמירה: אם מסמך אחד לא תקין - לא נרשם אף מסמך
      " TODO(VERIFY): ש-BAPI_ACC_STAT_KEY_FIG_CHECK לא כותב ל-DB (מותר רק קריאה בשלב הזה)
      DATA(lv_is_valid) = abap_true.
      LOOP AT ls_build-documents INTO DATA(ls_document).
        DATA(ls_check) = lo_poster->check( ls_document ).
        IF ls_check-is_success = abap_false.
          lv_is_valid = abap_false.
          LOOP AT ls_check-messages INTO DATA(ls_message) WHERE type CA 'EAX'.
            APPEND VALUE #( %cid = ls_key-%cid
                            %msg = new_message_with_text(
                                     severity = if_abap_behv_message=>severity-error
                                     text     = |{ ls_document-header_text }: { ls_message-text }| ) ) TO reported-preview.
          ENDLOOP.
        ENDIF.
      ENDLOOP.

      IF lv_is_valid = abap_false.
        APPEND VALUE #( %cid = ls_key-%cid ) TO failed-preview.
        CONTINUE.
      ENDIF.

      APPEND LINES OF ls_build-documents TO lcl_buffer=>gt_documents.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lsc_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save    REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.


CLASS lsc_saver IMPLEMENTATION.

  METHOD save.
    " רישום בלי COMMIT - RAP מבצע את ה-COMMIT בסוף השמירה (ראה שאלות פתוחות 0)
    DATA(lo_poster) = NEW zcl_co_skf_poster_bapi( ).

    LOOP AT lcl_buffer=>gt_documents INTO DATA(ls_document).
      DATA(ls_result) = lo_poster->post( is_document = ls_document
                                         iv_commit   = abap_false ).

      " TODO(VERIFY): הודעות בשלב save (reported) - נתמך בגרסאות 2023 ומעלה
      APPEND new_message_with_text(
               severity = COND #( WHEN ls_result-is_success = abap_true
                                  THEN if_abap_behv_message=>severity-success
                                  ELSE if_abap_behv_message=>severity-error )
               text     = COND #( WHEN ls_result-is_success = abap_true
                                  THEN |{ ls_document-header_text }: נרשם מסמך { ls_result-document_number }|
                                  ELSE |{ ls_document-header_text }: הרישום נכשל| ) ) TO reported-%other ##NO_TEXT.
    ENDLOOP.
  ENDMETHOD.


  METHOD cleanup.
    CLEAR lcl_buffer=>gt_documents.
  ENDMETHOD.

ENDCLASS.
