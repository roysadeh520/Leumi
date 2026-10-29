"! ABAP Wrapper (Clean Core Level B) לרישום מפתחות סטטיסטיים דרך BAPI קלאסי.
"! חבילה: ZCO_SKF_WRAPPER, גרסת שפה Standard ABAP, שחרור C1 (Use in Cloud Development).
"! הוחלט על BAPI ולא על OData API_STSTCLKEYFIGUREDOCUMENT: קריאה ל-OData מאותה מערכת
"! (loopback) אינה מומלצת, וה-BAPI הוא ה-API הקלאסי המתועד לאותו אובייקט עסקי (BUS6031).
"! TODO(VERIFY): חתימת ה-BAPI ושמות שדות המבנים ב-SE37 במערכת לפני הפעלה.
CLASS zcl_co_skf_poster_bapi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " טיפוסים מובנים בלבד - כדי לא לחשוף טיפוסי DDIC לא משוחררים לקוד ה-ABAP Cloud
    TYPES ty_quantity TYPE p LENGTH 16 DECIMALS 3.

    TYPES:
      BEGIN OF ty_item,
        statistical_key_figure TYPE c LENGTH 6,
        cost_center            TYPE c LENGTH 10,
        fiscal_year            TYPE n LENGTH 4,
        fiscal_period          TYPE n LENGTH 3,
        quantity               TYPE ty_quantity,
        quantity_unit          TYPE c LENGTH 3,
      END OF ty_item,
      ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_document,
        controlling_area TYPE c LENGTH 4,
        posting_date     TYPE d,
        document_date    TYPE d,
        header_text      TYPE c LENGTH 50,
        items            TYPE ty_items,
      END OF ty_document,
      ty_documents TYPE STANDARD TABLE OF ty_document WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_message,
        type TYPE c LENGTH 1,
        text TYPE string,
      END OF ty_message,
      ty_messages TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_result,
        is_success      TYPE abap_boolean,
        document_number TYPE c LENGTH 10,
        messages        TYPE ty_messages,
      END OF ty_result.

    "! בדיקה בלבד - ללא שינוי ב-DB (ריצת מבחן)
    METHODS check
      IMPORTING is_document      TYPE ty_document
      RETURNING VALUE(rs_result) TYPE ty_result.

    "! רישום. בכשל: הודעות בתוצאה.
    "! @parameter iv_commit | X = ה-Wrapper מבצע COMMIT/ROLLBACK בעצמו (קריאה מ-Job / דוח).
    "!                       ' ' = מתוך RAP save: RAP מבצע את ה-COMMIT, אסור לבצע אותו כאן.
    METHODS post
      IMPORTING is_document      TYPE ty_document
                iv_commit        TYPE abap_boolean DEFAULT abap_true
      RETURNING VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
    TYPES ty_bapi_items  TYPE STANDARD TABLE OF bapiskfitm WITH EMPTY KEY.
    TYPES ty_bapi_return TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.

    METHODS to_bapi_header
      IMPORTING is_document      TYPE ty_document
      RETURNING VALUE(rs_header) TYPE bapidochdru12p.

    METHODS to_bapi_items
      IMPORTING it_items        TYPE ty_items
      RETURNING VALUE(rt_items) TYPE ty_bapi_items.

    METHODS to_messages
      IMPORTING it_return          TYPE ty_bapi_return
      RETURNING VALUE(rt_messages) TYPE ty_messages.

    METHODS has_error
      IMPORTING it_return           TYPE ty_bapi_return
      RETURNING VALUE(rv_has_error) TYPE abap_boolean.
ENDCLASS.



CLASS zcl_co_skf_poster_bapi IMPLEMENTATION.

  METHOD check.
    DATA lt_items  TYPE ty_bapi_items.
    DATA lt_return TYPE ty_bapi_return.

    lt_items = to_bapi_items( is_document-items ).

    CALL FUNCTION 'BAPI_ACC_STAT_KEY_FIG_CHECK'
      EXPORTING doc_header = to_bapi_header( is_document )
      TABLES    doc_items  = lt_items
                return     = lt_return.

    rs_result = VALUE #( is_success = xsdbool( NOT has_error( lt_return ) )
                         messages   = to_messages( lt_return ) ).
  ENDMETHOD.


  METHOD post.
    DATA lt_items  TYPE ty_bapi_items.
    DATA lt_return TYPE ty_bapi_return.
    DATA lv_doc_no TYPE bapidochdru12p-doc_no.

    lt_items = to_bapi_items( is_document-items ).

    CALL FUNCTION 'BAPI_ACC_STAT_KEY_FIG_POST'
      EXPORTING doc_header = to_bapi_header( is_document )
      IMPORTING doc_no     = lv_doc_no
      TABLES    doc_items  = lt_items
                return     = lt_return.

    IF has_error( lt_return ).
      IF iv_commit = abap_true.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ENDIF.
      rs_result = VALUE #( is_success = abap_false
                           messages   = to_messages( lt_return ) ).
      RETURN.
    ENDIF.

    IF iv_commit = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING wait = abap_true.
    ENDIF.

    rs_result = VALUE #( is_success      = abap_true
                         document_number = lv_doc_no
                         messages        = to_messages( lt_return ) ).
  ENDMETHOD.


  METHOD to_bapi_header.
    " התקופה נגזרת בבאפי מתאריך הרישום (= יום אחרון בתקופת החתך)
    rs_header = VALUE #( co_area    = is_document-controlling_area
                         postgdate  = is_document-posting_date
                         docdate    = is_document-document_date
                         doc_hdr_tx = is_document-header_text
                         username   = sy-uname ).
  ENDMETHOD.


  METHOD to_bapi_items.
    " TODO(OPEN): ה-BAPI לא מקבל יחידת מידה - נלקחת מהגדרת המפתח הסטטיסטי (ראה שאלות פתוחות)
    rt_items = VALUE #( FOR ls_item IN it_items
                        ( statkeyfig = ls_item-statistical_key_figure
                          stat_qty   = ls_item-quantity
                          rec_cctr   = ls_item-cost_center ) ).
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
