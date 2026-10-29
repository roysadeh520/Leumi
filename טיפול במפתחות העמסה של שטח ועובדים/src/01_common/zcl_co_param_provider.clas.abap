"! מימוש ZIF_CO_PARAM_PROVIDER מעל ZCA_PARAM, עם מטמון לריצה.
"! TODO(OPEN): מבנה ZCA_PARAM לא מופיע באפיון. הונח NAME / VALUE.
"!             אם קיימת כבר מחלקת קריאה ארגונית ל-ZCA_PARAM - להחליף את הגוף של read_from_db בקריאה אליה.
CLASS zcl_co_param_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_co_param_provider.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_cached_param,
        name  TYPE zif_co_param_provider=>ty_name,
        value TYPE zif_co_param_provider=>ty_value,
      END OF ty_cached_param,
      ty_cached_params TYPE HASHED TABLE OF ty_cached_param WITH UNIQUE KEY name.

    DATA mt_cache TYPE ty_cached_params.

    METHODS read_from_db
      IMPORTING iv_name         TYPE zif_co_param_provider=>ty_name
      RETURNING VALUE(rv_value) TYPE zif_co_param_provider=>ty_value.
ENDCLASS.



CLASS zcl_co_param_provider IMPLEMENTATION.

  METHOD zif_co_param_provider~get_value.
    " פרמטרי בניין נקראים פעם לכל שורת HR - המטמון חוסך גישות חוזרות ל-DB
    READ TABLE mt_cache WITH TABLE KEY name = iv_name INTO DATA(ls_cached).
    IF sy-subrc = 0.
      rv_value = ls_cached-value.
      RETURN.
    ENDIF.

    rv_value = read_from_db( iv_name ).
    IF rv_value IS INITIAL.
      RAISE EXCEPTION TYPE zcx_co_skf_error MESSAGE e001(zco_skf) WITH iv_name.
    ENDIF.

    INSERT VALUE #( name = iv_name value = rv_value ) INTO TABLE mt_cache.
  ENDMETHOD.


  METHOD read_from_db.
    " TODO(OPEN): שמות השדות בטבלה - לאמת מול ZCA_PARAM במערכת
    SELECT SINGLE value
      FROM zca_param
      WHERE name = @iv_name
      INTO @rv_value.
  ENDMETHOD.

ENDCLASS.
