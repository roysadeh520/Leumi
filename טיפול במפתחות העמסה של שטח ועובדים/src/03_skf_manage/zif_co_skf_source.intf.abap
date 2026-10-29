"! מקורות הנתונים לרישום מפתחות סטטיסטיים.
"! מופרד מבניית המסמכים כדי שהבנייה תהיה ניתנת לבדיקה ב-ABAP Unit ללא DB.
INTERFACE zif_co_skf_source
  PUBLIC.

  "! שורות שטח בתוקף לתקופת החתך (P1)
  METHODS read_area_rows
    IMPORTING io_period      TYPE REF TO zcl_co_fiscal_period
    RETURNING VALUE(rt_rows) TYPE zif_co_skf_types=>ty_area_rows.

  "! שורות עובדים/משרות שתאריך המפתח שלהן בתקופת החתך (P2, P3)
  METHODS read_hr_rows
    IMPORTING io_period      TYPE REF TO zcl_co_fiscal_period
    RETURNING VALUE(rt_rows) TYPE zif_co_skf_types=>ty_hr_rows.

ENDINTERFACE.
