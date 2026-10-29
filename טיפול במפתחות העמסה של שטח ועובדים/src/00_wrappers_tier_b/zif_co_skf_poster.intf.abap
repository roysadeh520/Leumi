"! רישום מסמך מפתחות סטטיסטיים (CO) - חוזה משוחרר לקוד ה-ABAP Cloud.
"! המימוש הנוכחי: ZCL_CO_SKF_POSTER_BAPI (Classic API = Clean Core Level B).
"! אם יימצא API משוחרר (Level A) - מחליפים רק את המימוש, הלוגיקה לא משתנה.
"! חבילה: ZCO_SKF_WRAPPER (Standard ABAP), שחרור C1.
INTERFACE zif_co_skf_poster
  PUBLIC.

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
    BEGIN OF ty_result,
      is_success      TYPE abap_boolean,
      document_number TYPE c LENGTH 10,
      messages        TYPE zif_co_bapi_messages=>ty_messages,
    END OF ty_result.

  "! בדיקה בלבד - ללא שינוי ב-DB (משמש ריצת מבחן)
  METHODS check
    IMPORTING is_document      TYPE ty_document
    RETURNING VALUE(rs_result) TYPE ty_result.

  "! רישום + COMMIT. בכשל: ROLLBACK והודעות בתוצאה
  METHODS post
    IMPORTING is_document      TYPE ty_document
    RETURNING VALUE(rs_result) TYPE ty_result.

ENDINTERFACE.
