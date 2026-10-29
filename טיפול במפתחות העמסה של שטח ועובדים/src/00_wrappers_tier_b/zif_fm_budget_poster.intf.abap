"! רישום מסמך תקציב FM (הזנת תקציב תקופתי) - חוזה משוחרר לקוד ה-ABAP Cloud.
"! המימוש: ZCL_FM_BUDGET_POSTER_BAPI מעל BAPI_0050_CREATE (Level B).
"! לפי האפיון: BudgetEntryDocFM.CREATE (Level A) לא תומך בתקציב תקופתי.
"! חבילה: ZCO_SKF_WRAPPER (Standard ABAP), שחרור C1.
INTERFACE zif_fm_budget_poster
  PUBLIC.

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
    BEGIN OF ty_result,
      is_success      TYPE abap_boolean,
      document_year   TYPE n LENGTH 4,
      document_number TYPE c LENGTH 10,
      messages        TYPE zif_co_bapi_messages=>ty_messages,
    END OF ty_result.

  "! iv_test_run = X: בדיקה בלבד ללא עדכון (TESTRUN של ה-BAPI)
  METHODS post
    IMPORTING is_document      TYPE ty_document
              iv_test_run      TYPE abap_boolean
    RETURNING VALUE(rs_result) TYPE ty_result.

ENDINTERFACE.
