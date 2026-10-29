"! Application Job - "טיפול בתקציב כיבוד בסניפים" (ZCO_REFRESH_BUD), אפיון טכני סעיפים 15-21.
"! אפליקציה ואריח נפרדים מ-ZCO_SKF_MANAGE משיקולי הרשאות (Catalog Entry + Business Catalog נפרדים).
"! ריצת מבחן: BAPI_0050_CREATE עם TESTRUN = X (בדיקה ללא עדכון) + פירוט בלוג.
CLASS zcl_co_refresh_bud_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_defaults.
    INTERFACES if_apj_rt_run.

    " פרמטרי job (סעיף 16)
    DATA fiscal_year_period     TYPE fis_jahrper.
    DATA statistical_key_figure TYPE c LENGTH 6.
    DATA commitment_item        TYPE c LENGTH 24.
    DATA source_funds_center    TYPE c LENGTH 16.
    DATA test_run               TYPE abap_boolean.

    METHODS constructor
      IMPORTING io_builder TYPE REF TO zcl_fm_refresh_budget_builder OPTIONAL
                io_poster  TYPE REF TO zif_fm_budget_poster          OPTIONAL.

  PRIVATE SECTION.
    CONSTANTS c_log_subobject TYPE c LENGTH 20 VALUE 'REFRESH_BUD' ##NO_TEXT.
    CONSTANTS c_default_skf   TYPE c LENGTH 6 VALUE 'HCTOT'.

    CONSTANTS:
      BEGIN OF c_job_param,
        test_run               TYPE c LENGTH 30 VALUE 'TEST_RUN',
        statistical_key_figure TYPE c LENGTH 30 VALUE 'STATISTICAL_KEY_FIGURE',
      END OF c_job_param.

    DATA mo_builder TYPE REF TO zcl_fm_refresh_budget_builder.
    DATA mo_poster  TYPE REF TO zif_fm_budget_poster.
    DATA mo_log     TYPE REF TO zcl_co_job_log.

    METHODS job_run.

    "! שדות חובה שלא ניתן לאכוף ב-Catalog
    METHODS has_mandatory_parameters RETURNING VALUE(rv_valid) TYPE abap_boolean.

    METHODS read_cost_rows
      IMPORTING io_period      TYPE REF TO zcl_co_fiscal_period
      RETURNING VALUE(rt_rows) TYPE zcl_fm_refresh_budget_builder=>ty_cost_rows.

    METHODS log_rows_without_budget
      IMPORTING it_rows TYPE zcl_fm_refresh_budget_builder=>ty_cost_rows.

    METHODS log_result
      IMPORTING is_document TYPE zif_fm_budget_poster=>ty_document
                is_result   TYPE zif_fm_budget_poster=>ty_result.
ENDCLASS.



CLASS zcl_co_refresh_bud_job IMPLEMENTATION.

  METHOD constructor.
    mo_builder = COND #( WHEN io_builder IS BOUND THEN io_builder ELSE NEW zcl_fm_refresh_budget_builder( ) ).
    mo_poster  = COND #( WHEN io_poster  IS BOUND THEN io_poster  ELSE NEW zcl_fm_budget_poster_bapi( ) ).
  ENDMETHOD.


  METHOD if_apj_dt_defaults~get_default_parameters.
    et_parameter_val = VALUE #( ( name    = c_job_param-test_run
                                  t_value = VALUE #( ( sign = 'I' option = 'EQ' low = abap_true ) ) )
                                ( name    = c_job_param-statistical_key_figure
                                  t_value = VALUE #( ( sign = 'I' option = 'EQ' low = c_default_skf ) ) ) ).
  ENDMETHOD.


  METHOD if_apj_rt_run~execute.
    TRY.
        job_run( ).
      CATCH cx_root INTO DATA(lx_unexpected).
        TRY.
            mo_log->add_exception( lx_unexpected ).
            mo_log->save( ).
          CATCH cx_root ##NO_HANDLER.
        ENDTRY.
    ENDTRY.
  ENDMETHOD.


  METHOD job_run.
    mo_log = zcl_co_job_log=>open( iv_subobject   = c_log_subobject
                                   iv_external_id = |REFRESH/{ fiscal_year_period }| ).

    IF has_mandatory_parameters( ) = abap_false.
      mo_log->save( ).
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_period) = zcl_co_fiscal_period=>from_value( fiscal_year_period ).
        DATA(lt_rows)   = read_cost_rows( lo_period ).
        DATA(ls_document) = mo_builder->build_document(
                              it_rows    = lt_rows
                              io_period  = lo_period
                              is_request = VALUE #( commitment_item     = commitment_item
                                                    source_funds_center = source_funds_center ) ).
      CATCH zcx_co_skf_error INTO DATA(lx_error).
        mo_log->add_exception( lx_error ).
        mo_log->save( ).
        RETURN.
    ENDTRY.

    log_rows_without_budget( lt_rows ).

    IF ls_document-items IS INITIAL.
      mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-warning
                        iv_text     = `אין סניפים עם תקציב לתקופה - לא נרשם דבר` ) ##NO_TEXT.
      mo_log->save( ).
      RETURN.
    ENDIF.

    log_result( is_document = ls_document
                is_result   = mo_poster->post( is_document = ls_document
                                               iv_test_run = test_run ) ).
    mo_log->save( ).
  ENDMETHOD.


  METHOD has_mandatory_parameters.
    rv_valid = abap_true.
    IF commitment_item IS INITIAL OR source_funds_center IS INITIAL OR statistical_key_figure IS INITIAL.
      mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-error
                        iv_text     = `חובה למלא פריט התחייבות, יחידה תקציבית מקור ומפתח חלוקה` ) ##NO_TEXT.
      rv_valid = abap_false.
    ENDIF.
  ENDMETHOD.


  METHOD read_cost_rows.
    DATA(lv_period) = io_period->get_value( ).

    SELECT FROM zco_refreshmentcost( p_fiscalyearperiod     = @lv_period,
                                     p_statisticalkeyfigure = @statistical_key_figure )
      FIELDS companycode      AS company_code,
             fiscalyearperiod AS fiscal_year_period,
             costcenter       AS cost_center,
             budgetamount     AS budget_amount
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.


  METHOD log_rows_without_budget.
    LOOP AT it_rows INTO DATA(ls_row) WHERE budget_amount = 0.
      mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-warning
                        iv_text     = |סניף { ls_row-cost_center }: אין תעריף כיבוד או כמות 0 - לא נכלל| ) ##NO_TEXT.
    ENDLOOP.
  ENDMETHOD.


  METHOD log_result.
    DATA(lv_branch_count) = lines( is_document-items ) / 2.

    IF is_result-is_success = abap_false.
      mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-error
                        iv_text     = |{ is_document-header-header_text }: נכשל ({ lv_branch_count } סניפים)| ) ##NO_TEXT.
    ELSEIF test_run = abap_true.
      mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-info
                        iv_text     = |ריצת מבחן: { lv_branch_count } סניפים, הבדיקה עברה - לא נרשם דבר| ) ##NO_TEXT.
      LOOP AT is_document-items INTO DATA(ls_item).
        mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-info
                          iv_text     = |{ ls_item-item_number } / { ls_item-funds_center } / { ls_item-total_amount } { ls_item-currency }| ).
      ENDLOOP.
    ELSE.
      mo_log->add_text( iv_severity = zcl_co_job_log=>c_severity-success
                        iv_text     = |נרשם מסמך תקציב { is_result-document_number }/{ is_result-document_year }, | &&
                                      |{ lv_branch_count } סניפים| ) ##NO_TEXT.
    ENDIF.

    mo_log->add_messages( is_result-messages ).
  ENDMETHOD.

ENDCLASS.
