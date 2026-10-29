"! מסמך תקציב שהוכן ונבדק בפעולה וממתין לשמירה (transactional buffer)
CLASS lcl_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA gt_documents TYPE STANDARD TABLE OF zcl_fm_budget_poster_bapi=>ty_document WITH EMPTY KEY.
ENDCLASS.


"! בניית מסמך תקציב הכיבוד מתוך ZCO_REFRESHMENTCOST - אפיון טכני סעיף 21.
"! לכל סניף 2 שורות: פלוס למרכז הקרנות של הסניף, מינוס ליחידה התקציבית המקורית (רזרבה).
CLASS lcl_budget_builder DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_row,
        cost_center   TYPE c LENGTH 10,
        budget_amount TYPE zcl_fm_budget_poster_bapi=>ty_amount,
      END OF ty_row,
      ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_request,
        fiscal_year_period     TYPE fis_jahrper,
        statistical_key_figure TYPE c LENGTH 6,
        commitment_item        TYPE c LENGTH 24,
        source_funds_center    TYPE c LENGTH 16,
      END OF ty_request.

    TYPES:
      BEGIN OF ty_param,
        name  TYPE c LENGTH 30,
        value TYPE c LENGTH 50,
      END OF ty_param.

    "! מטמון פרמטרים (ZCA_PARAM); בבדיקות ממולא מראש במקום DB
    DATA mt_param_cache TYPE HASHED TABLE OF ty_param WITH UNIQUE KEY name.

    METHODS read_rows
      IMPORTING is_request     TYPE ty_request
      RETURNING VALUE(rt_rows) TYPE ty_rows.

    "! סניף עם תקציב 0 (ללא תעריף) לא נכלל. בשגיאה: ev_error_text מלא ואין מסמך
    METHODS build
      IMPORTING it_rows       TYPE ty_rows
                is_request    TYPE ty_request
      EXPORTING es_document   TYPE zcl_fm_budget_poster_bapi=>ty_document
                ev_error_text TYPE string.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF c_budget,
        fm_area         TYPE c LENGTH 4 VALUE '1000',
        version         TYPE c LENGTH 3 VALUE '000',
        document_state  TYPE c LENGTH 1 VALUE '1',
        process         TYPE c LENGTH 4 VALUE 'ENTR',
        budget_category TYPE c LENGTH 2 VALUE 'F9',
        value_type      TYPE c LENGTH 2 VALUE 'B1',
        currency        TYPE c LENGTH 5 VALUE 'ILS',
      END OF c_budget.

    METHODS get_param
      IMPORTING iv_name         TYPE csequence
      RETURNING VALUE(rv_value) TYPE ty_param-value.

    METHODS last_day
      IMPORTING iv_period      TYPE fis_jahrper
      RETURNING VALUE(rv_date) TYPE d.
ENDCLASS.


CLASS lcl_budget_builder IMPLEMENTATION.

  METHOD read_rows.
    SELECT FROM zco_refreshmentcost
      FIELDS costcenter   AS cost_center,
             budgetamount AS budget_amount
      WHERE fiscalyearperiod     = @is_request-fiscal_year_period
        AND statisticalkeyfigure = @is_request-statistical_key_figure
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.


  METHOD build.
    CLEAR: es_document, ev_error_text.

    IF NOT matches( val = is_request-fiscal_year_period regex = `\d{4}0(0[1-9]|1[0-2])` ).
      ev_error_text = |תקופת חתך { is_request-fiscal_year_period } אינה תקינה (YYYYPPP, תקופות 001-012)| ##NO_TEXT.
      RETURN.
    ENDIF.
    IF is_request-commitment_item IS INITIAL OR is_request-source_funds_center IS INITIAL.
      ev_error_text = `חובה למלא פריט התחייבות ויחידה תקציבית מקור` ##NO_TEXT.
      RETURN.
    ENDIF.

    DATA(lv_document_type) = get_param( 'ZFM_REFRESH_BUDDOC' ).
    DATA(lv_budget_type)   = get_param( 'ZFM_UPD_BUDTYPE' ).
    IF lv_document_type IS INITIAL OR lv_budget_type IS INITIAL.
      ev_error_text = `פרמטר ZFM_REFRESH_BUDDOC או ZFM_UPD_BUDTYPE לא מתוחזק בטבלה ZCA_PARAM` ##NO_TEXT.
      RETURN.
    ENDIF.

    DATA(lv_period) = is_request-fiscal_year_period.
    es_document-header = VALUE #( fm_area        = c_budget-fm_area
                                  version        = c_budget-version
                                  document_date  = cl_abap_context_info=>get_system_date( )
                                  posting_date   = last_day( lv_period )
                                  document_type  = lv_document_type
                                  document_state = c_budget-document_state
                                  process        = c_budget-process
                                  header_text    = |תקציב כריכים-{ lv_period+4(3) }.{ lv_period(4) }| ) ##NO_TEXT.

    " שדות זהים לכל השורות
    DATA(ls_template) = VALUE zcl_fm_budget_poster_bapi=>ty_item(
      fiscal_year      = lv_period(4)
      cash_year        = lv_period(4)
      budget_category  = c_budget-budget_category
      budget_type      = lv_budget_type
      commitment_item  = is_request-commitment_item
      value_type       = c_budget-value_type
      currency         = c_budget-currency
      budgeting_period = lv_period+4(3) ).

    LOOP AT it_rows INTO DATA(ls_row) WHERE budget_amount <> 0.
      " TODO(OPEN): הונח שמרכז הקרנות של הסניף = מרכז העלות (ראה שאלות פתוחות 16)
      DATA(ls_branch) = ls_template.
      ls_branch-item_number  = lines( es_document-items ) + 1.
      ls_branch-funds_center = ls_row-cost_center.
      ls_branch-total_amount = ls_row-budget_amount.

      DATA(ls_source) = ls_template.
      ls_source-item_number  = ls_branch-item_number + 1.
      ls_source-funds_center = is_request-source_funds_center.
      ls_source-total_amount = - ls_row-budget_amount.

      APPEND ls_branch TO es_document-items.
      APPEND ls_source TO es_document-items.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_param.
    READ TABLE mt_param_cache WITH TABLE KEY name = iv_name INTO DATA(ls_cached).
    IF sy-subrc = 0.
      rv_value = ls_cached-value.
      RETURN.
    ENDIF.
    " ZCA_PARAM במבנה TVARVC: NAME / LOW
    SELECT SINGLE low FROM zca_param WHERE name = @iv_name INTO @rv_value.
  ENDMETHOD.


  METHOD last_day.
    DATA(lv_next_month) = CONV d( COND string( WHEN iv_period+4(3) = '012'
                                               THEN |{ iv_period(4) + 1 }0101|
                                               ELSE |{ iv_period(4) }{ iv_period+5(2) + 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }01| ) ).
    rv_date = lv_next_month - 1.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_refreshmentcost DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR RefreshmentCost RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK RefreshmentCost.

    METHODS read FOR READ
      IMPORTING keys FOR READ RefreshmentCost RESULT result.

    METHODS postbudget FOR MODIFY
      IMPORTING keys FOR ACTION RefreshmentCost~postBudget.
ENDCLASS.


CLASS lhc_refreshmentcost IMPLEMENTATION.

  METHOD get_global_authorizations.
    " ההרשאה נקבעת ב-Business Catalog נפרד (סעיף 15)
    result-%action-postbudget = if_abap_behv=>auth-allowed.
  ENDMETHOD.


  METHOD lock.
    " אין נעילה ברמת השורה - ה-BAPI נועל בעצמו
  ENDMETHOD.


  METHOD read.
    " הרשימה ב-UI נקראת ישירות מה-CDS
  ENDMETHOD.


  METHOD postbudget.
    DATA(lo_builder) = NEW lcl_budget_builder( ).

    LOOP AT keys INTO DATA(ls_key).
      DATA(ls_request) = VALUE lcl_budget_builder=>ty_request(
                           fiscal_year_period     = ls_key-%param-FiscalYearPeriod
                           statistical_key_figure = ls_key-%param-StatisticalKeyFigure
                           commitment_item        = ls_key-%param-CommitmentItem
                           source_funds_center    = ls_key-%param-SourceFundsCenter ).
      DATA(lt_rows) = lo_builder->read_rows( ls_request ).

      lo_builder->build( EXPORTING it_rows       = lt_rows
                                   is_request    = ls_request
                         IMPORTING es_document   = DATA(ls_document)
                                   ev_error_text = DATA(lv_error_text) ).
      IF lv_error_text IS NOT INITIAL.
        APPEND VALUE #( %cid = ls_key-%cid ) TO failed-refreshmentcost.
        APPEND VALUE #( %cid = ls_key-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = lv_error_text ) ) TO reported-refreshmentcost.
        CONTINUE.
      ENDIF.

      LOOP AT lt_rows INTO DATA(ls_row) WHERE budget_amount = 0.
        APPEND new_message_with_text( severity = if_abap_behv_message=>severity-warning
                                      text     = |סניף { ls_row-cost_center }: אין תעריף כיבוד או כמות 0 - לא נכלל| )
               TO reported-%other ##NO_TEXT.
      ENDLOOP.

      IF ls_document-items IS INITIAL.
        APPEND new_message_with_text( severity = if_abap_behv_message=>severity-warning
                                      text     = `אין סניפים עם תקציב לתקופה - לא נרשם דבר` ) TO reported-%other ##NO_TEXT.
        CONTINUE.
      ENDIF.

      " בדיקה לפני השמירה (TESTRUN) - כשל = לא נרשם דבר
      " TODO(VERIFY): ש-TESTRUN של BAPI_0050_CREATE לא כותב ל-DB (מותר רק קריאה בשלב הזה)
      DATA(ls_check) = NEW zcl_fm_budget_poster_bapi( )->post( is_document = ls_document
                                                               iv_test_run = abap_true
                                                               iv_commit   = abap_false ).
      IF ls_check-is_success = abap_false.
        APPEND VALUE #( %cid = ls_key-%cid ) TO failed-refreshmentcost.
        LOOP AT ls_check-messages INTO DATA(ls_message) WHERE type CA 'EAX'.
          APPEND VALUE #( %cid = ls_key-%cid
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = ls_message-text ) ) TO reported-refreshmentcost.
        ENDLOOP.
        CONTINUE.
      ENDIF.

      APPEND ls_document TO lcl_buffer=>gt_documents.
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
    " רישום בלי COMMIT - RAP מבצע את ה-COMMIT בסוף השמירה (ראה שאלות פתוחות T1)
    LOOP AT lcl_buffer=>gt_documents INTO DATA(ls_document).
      DATA(ls_result) = NEW zcl_fm_budget_poster_bapi( )->post( is_document = ls_document
                                                                iv_test_run = abap_false
                                                                iv_commit   = abap_false ).

      " TODO(VERIFY): הודעות בשלב save (reported) - נתמך בגרסאות 2023 ומעלה
      APPEND new_message_with_text(
               severity = COND #( WHEN ls_result-is_success = abap_true
                                  THEN if_abap_behv_message=>severity-success
                                  ELSE if_abap_behv_message=>severity-error )
               text     = COND #( WHEN ls_result-is_success = abap_true
                                  THEN |נרשם מסמך תקציב { ls_result-document_number }/{ ls_result-document_year }, | &&
                                       |{ lines( ls_document-items ) / 2 } סניפים|
                                  ELSE |רישום התקציב נכשל| ) ) TO reported-%other ##NO_TEXT.
    ENDLOOP.
  ENDMETHOD.


  METHOD cleanup.
    CLEAR lcl_buffer=>gt_documents.
  ENDMETHOD.

ENDCLASS.
