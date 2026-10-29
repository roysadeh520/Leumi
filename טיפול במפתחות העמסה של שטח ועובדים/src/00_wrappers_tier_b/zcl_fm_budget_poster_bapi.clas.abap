"! ABAP Wrapper (Clean Core Level B) מעל BAPI_0050_CREATE.
"! חבילה: ZCO_SKF_WRAPPER, גרסת שפה Standard ABAP, שחרור C1.
"! TODO(VERIFY): חתימת BAPI_0050_CREATE ושמות השדות במבנים BAPI_0050_HEADER / _ITEM / _PERIOD
"!               ו-HEADER_DATA_ADD - לאמת ב-SE37 במערכת לפני הפעלה.
CLASS zcl_fm_budget_poster_bapi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_fm_budget_poster.

  PRIVATE SECTION.
    TYPES ty_bapi_items   TYPE STANDARD TABLE OF bapi_0050_item WITH EMPTY KEY.
    TYPES ty_bapi_periods TYPE STANDARD TABLE OF bapi_0050_period WITH EMPTY KEY.
    TYPES ty_bapi_return  TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.

    METHODS to_bapi_header
      IMPORTING is_header        TYPE zif_fm_budget_poster=>ty_header
      RETURNING VALUE(rs_header) TYPE bapi_0050_header.

    METHODS to_bapi_items
      IMPORTING it_items        TYPE zif_fm_budget_poster=>ty_items
      RETURNING VALUE(rt_items) TYPE ty_bapi_items.

    "! PERIOD_DATA מקביל ל-ITEM_DATA - מבטיח שהתקציב נרשם בתקופה הנכונה
    METHODS to_bapi_periods
      IMPORTING it_items          TYPE zif_fm_budget_poster=>ty_items
      RETURNING VALUE(rt_periods) TYPE ty_bapi_periods.

    METHODS to_messages
      IMPORTING it_return          TYPE ty_bapi_return
      RETURNING VALUE(rt_messages) TYPE zif_co_bapi_messages=>ty_messages.

    METHODS has_error
      IMPORTING it_return           TYPE ty_bapi_return
      RETURNING VALUE(rv_has_error) TYPE abap_boolean.
ENDCLASS.



CLASS zcl_fm_budget_poster_bapi IMPLEMENTATION.

  METHOD zif_fm_budget_poster~post.
    DATA lt_items      TYPE ty_bapi_items.
    DATA lt_periods    TYPE ty_bapi_periods.
    DATA lt_return     TYPE ty_bapi_return.
    DATA ls_header_add TYPE bapi_0050_header_add.
    DATA lv_doc_year   TYPE bapi_0050_fields-doc_year.
    DATA lv_doc_number TYPE bapi_0050_fields-doc_num.

    lt_items   = to_bapi_items( is_document-items ).
    lt_periods = to_bapi_periods( is_document-items ).
    ls_header_add-header_text = is_document-header-header_text.

    " TODO(OPEN): UPDATE_MODE = '1' לפי האפיון - לאמת באיזה פרמטר/מבנה הוא נמצא בחתימה
    CALL FUNCTION 'BAPI_0050_CREATE'
      EXPORTING header_data     = to_bapi_header( is_document-header )
                header_data_add = ls_header_add
                testrun         = iv_test_run
      IMPORTING documentyear    = lv_doc_year
                documentnumber  = lv_doc_number
      TABLES    item_data       = lt_items
                period_data     = lt_periods
                return          = lt_return.

    IF has_error( lt_return ) OR iv_test_run = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      rs_result = VALUE #( is_success = xsdbool( NOT has_error( lt_return ) )
                           messages   = to_messages( lt_return ) ).
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING wait = abap_true.

    rs_result = VALUE #( is_success      = abap_true
                         document_year   = lv_doc_year
                         document_number = lv_doc_number
                         messages        = to_messages( lt_return ) ).
  ENDMETHOD.


  METHOD to_bapi_header.
    rs_header = VALUE #( fm_area    = is_header-fm_area
                         version    = is_header-version
                         docdate    = is_header-document_date
                         pstng_date = is_header-posting_date
                         doctype    = is_header-document_type
                         docstate   = is_header-document_state
                         process    = is_header-process ).
  ENDMETHOD.


  METHOD to_bapi_items.
    rt_items = VALUE #( FOR ls_item IN it_items
                        ( item_num     = ls_item-item_number
                          fisc_year    = ls_item-fiscal_year
                          cash_year    = ls_item-cash_year
                          budcat       = ls_item-budget_category
                          budtype      = ls_item-budget_type
                          fund         = ls_item-fund
                          funds_ctr    = ls_item-funds_center
                          cmmt_item    = ls_item-commitment_item
                          valtype      = ls_item-value_type
                          trans_curr   = ls_item-currency
                          total_amount = ls_item-total_amount ) ).
  ENDMETHOD.


  METHOD to_bapi_periods.
    rt_periods = VALUE #( FOR ls_item IN it_items
                          ( item_num         = ls_item-item_number
                            budgeting_period = ls_item-budgeting_period
                            period_amount    = ls_item-total_amount ) ).
  ENDMETHOD.


  METHOD to_messages.
    rt_messages = VALUE #( FOR ls_return IN it_return
                           ( type   = ls_return-type
                             id     = ls_return-id
                             number = ls_return-number
                             text   = ls_return-message ) ).
  ENDMETHOD.


  METHOD has_error.
    rv_has_error = xsdbool( line_exists( it_return[ type = 'E' ] )
                         OR line_exists( it_return[ type = 'A' ] )
                         OR line_exists( it_return[ type = 'X' ] ) ).
  ENDMETHOD.

ENDCLASS.
