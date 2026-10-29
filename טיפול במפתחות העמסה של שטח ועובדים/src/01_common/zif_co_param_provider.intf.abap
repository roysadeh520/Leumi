"! גישה לפרמטרים עסקיים (ZCA_PARAM).
"! הלוגיקה תלויה בממשק ולא בטבלה - כך אפשר להחליף מימוש ולבדוק ב-ABAP Unit.
INTERFACE zif_co_param_provider
  PUBLIC.

  TYPES ty_name  TYPE c LENGTH 30.
  TYPES ty_value TYPE c LENGTH 50.

  "! מחזיר ערך פרמטר; פרמטר חסר או ריק = שגיאה (fail fast, לפני רישום כלשהו)
  METHODS get_value
    IMPORTING iv_name         TYPE ty_name
    RETURNING VALUE(rv_value) TYPE ty_value
    RAISING   zcx_co_skf_error.

ENDINTERFACE.
