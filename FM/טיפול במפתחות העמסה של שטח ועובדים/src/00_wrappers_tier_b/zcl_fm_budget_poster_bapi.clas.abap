"! ABAP Wrapper (Clean Core Level B) מעל BAPI_0050_CREATE - הזנת תקציב תקופתי.
"! לפי האפיון: BudgetEntryDocFM.CREATE (Level A) לא תומך בתקציב תקופתי.
"! חבילה: ZCO_SKF_WRAPPER, גרסת שפה Standard ABAP, שחרור C1.
"! TODO(VERIFY): חתימת BAPI_0050_CREATE ושמות השדות במבנים BAPI_0050_HEADER / _ITEM / _PERIOD
"!               ו-HEADER_DATA_ADD - לאמת ב-SE37 במערכת לפני הפעלה.
CLASS zcl_fm_budget_poster_bapi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_amount TYPE p LENGTH 12 DECIMALS 2.

    TYPES:
      BEGIN OF ty_header,
        fm_area        TYPE c LENGTH 4,
        version        TYPE c LENGTH 3,
        document_date  TYPE d,
        posting_date   TYPE d,
        document_type  TYPE c LENGTH 4,
        document_state TYPE c LENGTH 1,
        process        TYPE c LENGTH 4,
        header_text    TYPE c LENGTH 50,
      END OF ty_header.

    TYPES:
      BEGIN OF ty_item,
        item_number      TYPE n LENGTH 6,
        fiscal_year      TYPE n LENGTH 4,
        cash_year        TYPE n LENGTH 4,
        budget_category  TYPE c LENGTH 2,
        budget_type      TYPE c LENGTH 4,
        fund             TYPE c LENGTH 10,
        funds_center     TYPE c LENGTH 16,
        commitment_item  TYPE c LENGTH 24,
        value_type       TYPE c LENGTH 2,
        currency         TYPE c LENGTH 5,
        total_amount     TYPE ty_amount,
        budgeting_period TYPE n LENGTH 3,
      END OF ty_item,
      ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_document,
        header TYPE ty_header,
        items  TYPE ty_items,
      END OF ty_document.

    TYPES:
      BEGIN OF ty_message,
        type TYPE c LENGTH 1,
        text TYPE string,
      END OF ty_message,
      ty_messages TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_result,
        is_success      TYPE abap_boolean,
        document_year   TYPE n LENGTH 4,
        document_number TYPE c LENGTH 10,
        messages        TYPE ty_messages,
      END OF ty_result.

    "! @parameter iv_test_run | X = בדיקה בלבד ללא עדכון (TESTRUN של ה-BAPI)
    "! @parameter iv_commit   | X = ה-Wrapper מבצע COMMIT/ROLLBACK בעצמו (קריאה מ-Job / דוח).
    "!                         ' ' = מתוך RAP: RAP מבצע את ה-COMMIT, אסור לבצע אותו כאן.
    METHODS post
      IMPORTING is_document      TYPE ty_document
                iv_test_run      TYPE abap_boolean
                iv_commit        TYPE abap_boolean DEFAULT abap_true
      RETURNING VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
    TYPES ty_bapi_items   TYPE STANDARD TABLE OF bapi_0050_item WITH EMPTY KEY.
    TYPES ty_bapi_periods TYPE STANDARD TABLE OF bapi_0050_period WITH EMPTY KEY.
    TYPES ty_bapi_return  TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.

    METHODS to_bapi_header
      IMPORTING is_header        TYPE ty_header
      RETURNING VALUE(rs_header) TYPE bapi_0050_header.

    METHODS to_bapi_items
      IMPORTING it_items        TYPE ty_items
      RETURNING VALUE(rt_items) TYPE ty_bapi_items.

    "! PERIOD_DATA מקביל ל-ITEM_DATA - מבטיח שהתקציב נרשם בתקופה הנכונה
    METHODS to_bapi_periods
      IMPORTING it_items          TYPE ty_items
      RETURNING VALUE(rt_periods) TYPE ty_bapi_periods.

    METHODS to_messages
      IMPORTING it_return          TYPE ty_bapi_return
      RETURNING VALUE(rt_messages) TYPE ty_messages.

    METHODS has_error
      IMPORTING it_return           TYPE ty_bapi_return
      RETURNING VALUE(rv_has_error) TYPE abap_boolean.
ENDCLASS.



CLASS zcl_fm_budget_poster_bapi IMPLEMENTATION.

  METHOD post.
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
      IF iv_commit = abap_true.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ENDIF.
      rs_result = VALUE #( is_success = xsdbool( NOT has_error( lt_return ) )
                           messages   = to_messages( lt_return ) ).
      RETURN.
    ENDIF.

    IF iv_commit = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING wait = abap_true.
    ENDIF.

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
                           ( type = ls_return-type
                             text = ls_return-message ) ).
  ENDMETHOD.


  METHOD has_error.
    rv_has_error = xsdbool( line_exists( it_return[ type = 'E' ] )
                         OR line_exists( it_return[ type = 'A' ] )
                         OR line_exists( it_return[ type = 'X' ] ) ).
  ENDMETHOD.

ENDCLASS.
