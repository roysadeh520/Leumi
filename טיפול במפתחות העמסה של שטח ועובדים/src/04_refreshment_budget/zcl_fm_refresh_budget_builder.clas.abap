"! בונה את מסמך תקציב הכיבוד (BAPI_0050_CREATE) מתוך שורות ZCO_REFRESHMENTCOST - אפיון טכני סעיף 21.
"! לכל סניף 2 שורות: פלוס למרכז הקרנות של הסניף, מינוס ליחידה התקציבית המקורית (רזרבה).
CLASS zcl_fm_refresh_budget_builder DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_cost_row,
        company_code       TYPE c LENGTH 4,
        fiscal_year_period TYPE n LENGTH 7,
        cost_center        TYPE c LENGTH 10,
        budget_amount      TYPE zif_fm_budget_poster=>ty_amount,
      END OF ty_cost_row,
      ty_cost_rows TYPE STANDARD TABLE OF ty_cost_row WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_request,
        commitment_item     TYPE zif_fm_budget_poster=>ty_item-commitment_item,
        source_funds_center TYPE zif_fm_budget_poster=>ty_item-funds_center,
      END OF ty_request.

    METHODS constructor
      IMPORTING io_params        TYPE REF TO zif_co_param_provider OPTIONAL
                iv_document_date TYPE d                            OPTIONAL.

    "! שורות עם תקציב 0 (למשל סניף ללא תעריף) לא נכללות במסמך
    METHODS build_document
      IMPORTING it_rows            TYPE ty_cost_rows
                io_period          TYPE REF TO zcl_co_fiscal_period
                is_request         TYPE ty_request
      RETURNING VALUE(rs_document) TYPE zif_fm_budget_poster=>ty_document
      RAISING   zcx_co_skf_error.

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

    CONSTANTS:
      BEGIN OF c_param,
        document_type TYPE zif_co_param_provider=>ty_name VALUE 'ZFM_REFRESH_BUDDOC',
        budget_type   TYPE zif_co_param_provider=>ty_name VALUE 'ZFM_UPD_BUDTYPE',
      END OF c_param.

    CONSTANTS c_header_text TYPE string VALUE `תקציב כריכים-` ##NO_TEXT.

    DATA mo_params        TYPE REF TO zif_co_param_provider.
    DATA mv_document_date TYPE d.

    METHODS build_header
      IMPORTING io_period        TYPE REF TO zcl_co_fiscal_period
      RETURNING VALUE(rs_header) TYPE zif_fm_budget_poster=>ty_header
      RAISING   zcx_co_skf_error.

    "! זוג שורות מאוזן: +סניף / -מקור
    METHODS build_item_pair
      IMPORTING is_row          TYPE ty_cost_row
                is_request      TYPE ty_request
                is_template     TYPE zif_fm_budget_poster=>ty_item
                iv_next_number  TYPE i
      RETURNING VALUE(rt_items) TYPE zif_fm_budget_poster=>ty_items.
ENDCLASS.



CLASS zcl_fm_refresh_budget_builder IMPLEMENTATION.

  METHOD constructor.
    mo_params = COND #( WHEN io_params IS BOUND THEN io_params ELSE NEW zcl_co_param_provider( ) ).
    mv_document_date = COND #( WHEN iv_document_date IS NOT INITIAL
                               THEN iv_document_date
                               ELSE cl_abap_context_info=>get_system_date( ) ).
  ENDMETHOD.


  METHOD build_document.
    rs_document-header = build_header( io_period ).

    " שדות זהים לכל השורות - נקבעים פעם אחת
    DATA(ls_template) = VALUE zif_fm_budget_poster=>ty_item(
      fiscal_year      = io_period->get_year( )
      cash_year        = io_period->get_year( )
      budget_category  = c_budget-budget_category
      budget_type      = mo_params->get_value( c_param-budget_type )
      commitment_item  = is_request-commitment_item
      value_type       = c_budget-value_type
      currency         = c_budget-currency
      budgeting_period = io_period->get_period( ) ).

    DATA(lv_period) = io_period->get_value( ).
    LOOP AT it_rows INTO DATA(ls_row)
         WHERE fiscal_year_period = lv_period
           AND budget_amount     <> 0.
      APPEND LINES OF build_item_pair( is_row         = ls_row
                                       is_request     = is_request
                                       is_template    = ls_template
                                       iv_next_number = lines( rs_document-items ) + 1 ) TO rs_document-items.
    ENDLOOP.
  ENDMETHOD.


  METHOD build_header.
    rs_header = VALUE #( fm_area        = c_budget-fm_area
                         version        = c_budget-version
                         document_date  = mv_document_date
                         posting_date   = io_period->get_last_day( )
                         document_type  = mo_params->get_value( c_param-document_type )
                         document_state = c_budget-document_state
                         process        = c_budget-process
                         header_text    = |{ c_header_text }{ io_period->get_display_text( ) }| ).
  ENDMETHOD.


  METHOD build_item_pair.
    " TODO(OPEN): הונח שמספר מרכז הקרנות של הסניף זהה למספר מרכז העלות (ראה שאלות פתוחות)
    DATA(ls_branch) = is_template.
    ls_branch-item_number  = iv_next_number.
    ls_branch-funds_center = is_row-cost_center.
    ls_branch-total_amount = is_row-budget_amount.

    DATA(ls_source) = is_template.
    ls_source-item_number  = iv_next_number + 1.
    ls_source-funds_center = is_request-source_funds_center.
    ls_source-total_amount = - is_row-budget_amount.

    rt_items = VALUE #( ( ls_branch ) ( ls_source ) ).
  ENDMETHOD.

ENDCLASS.
