"! בונה את מסמכי המפתחות הסטטיסטיים לרישום, לפי נושא ותקופת חתך (אפיון טכני סעיפים 6-14).
"! ללא שינוי ב-DB: משמש גם את ה-Job (ריצת מבחן/עדכון) וגם את תצוגת ה-Fiori - מקור אמת אחד.
"! כל המסמכים נבנים לפני רישום כלשהו: פרמטר חסר עוצר את הריצה לפני שנרשם משהו.
CLASS zcl_co_skf_doc_builder DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! @parameter io_source        | ברירת מחדל: ZCL_CO_SKF_SOURCE (החלפה בבדיקות)
    "! @parameter io_params        | ברירת מחדל: ZCL_CO_PARAM_PROVIDER (החלפה בבדיקות)
    "! @parameter iv_document_date | ברירת מחדל: תאריך המערכת
    METHODS constructor
      IMPORTING io_source        TYPE REF TO zif_co_skf_source     OPTIONAL
                io_params        TYPE REF TO zif_co_param_provider OPTIONAL
                iv_document_date TYPE d                            OPTIONAL.

    METHODS build_documents
      IMPORTING iv_topic            TYPE zif_co_skf_types=>ty_topic
                io_period           TYPE REF TO zcl_co_fiscal_period
      RETURNING VALUE(rt_documents) TYPE zif_co_skf_types=>ty_documents
      RAISING   zcx_co_skf_error.

  PRIVATE SECTION.
    CONSTANTS c_controlling_area TYPE c LENGTH 4 VALUE '1000'.
    CONSTANTS c_area_header_text TYPE string VALUE `נתוני שטח - ` ##NO_TEXT.

    TYPES ty_measure TYPE c LENGTH 1.
    CONSTANTS:
      BEGIN OF c_measure,
        headcount TYPE ty_measure VALUE 'H',
        positions TYPE ty_measure VALUE 'P',
      END OF c_measure.

    TYPES ty_level TYPE c LENGTH 1.
    CONSTANTS:
      BEGIN OF c_level,
        org_unit    TYPE ty_level VALUE 'O', " יחידה ארגונית - ORGUNIT (8 ספרות)
        budget_unit TYPE ty_level VALUE 'B', " יחידה תקציבית - COSTCENTER (3 ספרות)
      END OF c_level.

    "! הגדרת מסמך אחד מנתוני HR: מה נספר, באיזו רמה, ואיך נקבע המפתח הסטטיסטי
    TYPES:
      BEGIN OF ty_hr_document_spec,
        header_text     TYPE string,
        measure         TYPE ty_measure,
        level           TYPE ty_level,
        skf_param_name  TYPE zif_co_param_provider=>ty_name, " P2: מפתח קבוע מ-ZCA_PARAM
        building_suffix TYPE string,                         " P3: מפתח לפי בניין + סיומת
      END OF ty_hr_document_spec,
      ty_hr_document_specs TYPE STANDARD TABLE OF ty_hr_document_spec WITH EMPTY KEY.

    "! שורת רישום אחידה (מכל מקור) לפני קיבוץ למסמכים
    TYPES:
      BEGIN OF ty_posting_line,
        posting_date           TYPE d,
        statistical_key_figure TYPE c LENGTH 6,
        cost_center            TYPE c LENGTH 10,
        quantity               TYPE zif_co_skf_poster=>ty_quantity,
        quantity_unit          TYPE c LENGTH 3,
      END OF ty_posting_line,
      ty_posting_lines TYPE STANDARD TABLE OF ty_posting_line WITH EMPTY KEY.

    DATA mo_source        TYPE REF TO zif_co_skf_source.
    DATA mo_params        TYPE REF TO zif_co_param_provider.
    DATA mv_document_date TYPE d.

    METHODS build_area_documents
      IMPORTING io_period           TYPE REF TO zcl_co_fiscal_period
      RETURNING VALUE(rt_documents) TYPE zif_co_skf_types=>ty_documents.

    METHODS build_hr_documents
      IMPORTING io_period           TYPE REF TO zcl_co_fiscal_period
                it_specs            TYPE ty_hr_document_specs
      RETURNING VALUE(rt_documents) TYPE zif_co_skf_types=>ty_documents
      RAISING   zcx_co_skf_error.

    METHODS get_budget_assignment_specs
      RETURNING VALUE(rt_specs) TYPE ty_hr_document_specs.

    METHODS get_location_specs
      RETURNING VALUE(rt_specs) TYPE ty_hr_document_specs.

    METHODS to_hr_posting_lines
      IMPORTING it_hr_rows      TYPE zif_co_skf_types=>ty_hr_rows
                is_spec         TYPE ty_hr_document_spec
      RETURNING VALUE(rt_lines) TYPE ty_posting_lines
      RAISING   zcx_co_skf_error.

    METHODS determine_hr_skf
      IMPORTING is_hr_row     TYPE zif_co_skf_types=>ty_hr_row
                is_spec       TYPE ty_hr_document_spec
      RETURNING VALUE(rv_skf) TYPE zif_co_skf_poster=>ty_item-statistical_key_figure
      RAISING   zcx_co_skf_error.

    "! מסמך לכל תאריך רישום; שורות זהות (מפתח + מרכז עלות) מסוכמות לפריט אחד
    METHODS to_documents
      IMPORTING it_lines            TYPE ty_posting_lines
                iv_header_text      TYPE string
                io_period           TYPE REF TO zcl_co_fiscal_period
      RETURNING VALUE(rt_documents) TYPE zif_co_skf_types=>ty_documents.

    METHODS add_to_items
      IMPORTING is_line   TYPE ty_posting_line
                io_period TYPE REF TO zcl_co_fiscal_period
      CHANGING  ct_items  TYPE zif_co_skf_poster=>ty_items.
ENDCLASS.



CLASS zcl_co_skf_doc_builder IMPLEMENTATION.

  METHOD constructor.
    mo_source = COND #( WHEN io_source IS BOUND THEN io_source ELSE NEW zcl_co_skf_source( ) ).
    mo_params = COND #( WHEN io_params IS BOUND THEN io_params ELSE NEW zcl_co_param_provider( ) ).
    mv_document_date = COND #( WHEN iv_document_date IS NOT INITIAL
                               THEN iv_document_date
                               ELSE cl_abap_context_info=>get_system_date( ) ).
  ENDMETHOD.


  METHOD build_documents.
    CASE iv_topic.
      WHEN zif_co_skf_types=>c_topic-area.
        rt_documents = build_area_documents( io_period ).

      WHEN zif_co_skf_types=>c_topic-headcount_by_budget.
        rt_documents = build_hr_documents( io_period = io_period
                                           it_specs  = get_budget_assignment_specs( ) ).

      WHEN zif_co_skf_types=>c_topic-headcount_by_location.
        rt_documents = build_hr_documents( io_period = io_period
                                           it_specs  = get_location_specs( ) ).

      WHEN OTHERS.
        RAISE EXCEPTION TYPE zcx_co_skf_error MESSAGE e003(zco_skf) WITH iv_topic.
    ENDCASE.
  ENDMETHOD.


  METHOD build_area_documents.
    " סעיף 8: מפתח סטטיסטי = סוג המדידה (R100/R101), נרשם ביום האחרון של תקופת החתך
    DATA(lt_lines) = VALUE ty_posting_lines(
      FOR ls_row IN mo_source->read_area_rows( io_period )
      ( posting_date           = io_period->get_last_day( )
        statistical_key_figure = ls_row-meas
        cost_center            = ls_row-cost_center
        quantity               = ls_row-meas_value
        quantity_unit          = ls_row-meas_unit ) ).

    rt_documents = to_documents( it_lines       = lt_lines
                                 iv_header_text = c_area_header_text
                                 io_period      = io_period ).
  ENDMETHOD.


  METHOD build_hr_documents.
    " נתוני HR נקראים פעם אחת ומשמשים את כל 4 המסמכים
    DATA(lt_hr_rows) = mo_source->read_hr_rows( io_period ).

    LOOP AT it_specs INTO DATA(ls_spec).
      APPEND LINES OF to_documents( it_lines       = to_hr_posting_lines( it_hr_rows = lt_hr_rows
                                                                          is_spec    = ls_spec )
                                    iv_header_text = ls_spec-header_text
                                    io_period      = io_period ) TO rt_documents.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_budget_assignment_specs.
    " סעיפים 10-12
    rt_specs = VALUE #(
      ( header_text    = `נתוני עובדים ברמת יח ארגונית-` measure = c_measure-headcount
        level          = c_level-org_unit                 skf_param_name = 'ZCO_HC_SKF_DET' )
      ( header_text    = `נתוני משרות ברמת יח ארגונית-`  measure = c_measure-positions
        level          = c_level-org_unit                 skf_param_name = 'ZCO_POS_SKF_DET' )
      ( header_text    = `נתוני עובדים ברמת יח תקציבית-` measure = c_measure-headcount
        level          = c_level-budget_unit              skf_param_name = 'ZCO_HC_SKF_TOT' )
      ( header_text    = `נתוני משרות ברמת יח תקציבית-`  measure = c_measure-positions
        level          = c_level-budget_unit              skf_param_name = 'ZCO_POS_SKF_TOT' ) ) ##NO_TEXT.
  ENDMETHOD.


  METHOD get_location_specs.
    " סעיפים 13-14: המפתח נגזר ממרכז העלות של הבניין + סיומת (לדוגמה B1010001HCD)
    rt_specs = VALUE #(
      ( header_text = `עובדים לפי מיקום ברמת יח ארגונית-` measure = c_measure-headcount
        level       = c_level-org_unit                      building_suffix = `HCD` )
      ( header_text = `משרות לפי מיקום ברמת יח ארגונית-`  measure = c_measure-positions
        level       = c_level-org_unit                      building_suffix = `POSD` )
      ( header_text = `עובדים לפי מיקום ברמת יח תקציבית-` measure = c_measure-headcount
        level       = c_level-budget_unit                   building_suffix = `HCT` )
      ( header_text = `משרות לפי מיקום ברמת יח תקציבית-`  measure = c_measure-positions
        level       = c_level-budget_unit                   building_suffix = `POST` ) ) ##NO_TEXT.
  ENDMETHOD.


  METHOD to_hr_posting_lines.
    DATA(lv_is_by_location) = xsdbool( is_spec-building_suffix IS NOT INITIAL ).

    LOOP AT it_hr_rows INTO DATA(ls_hr_row).
      " עובדים ללא שיוך לבניין לא נכללים בהעמסה לפי מיקום (ראה שאלות פתוחות)
      IF lv_is_by_location = abap_true AND ls_hr_row-real_estate_cost_center IS INITIAL.
        CONTINUE.
      ENDIF.

      " ברמה תקציבית שורות של אותו מרכז עלות מסוכמות ב-to_documents (= סיכום לפי KEYDATE + COSTCENTER)
      APPEND VALUE #( posting_date           = ls_hr_row-key_date
                      statistical_key_figure = determine_hr_skf( is_hr_row = ls_hr_row
                                                                 is_spec   = is_spec )
                      cost_center            = SWITCH #( is_spec-level
                                                         WHEN c_level-org_unit THEN ls_hr_row-org_unit
                                                         ELSE                       ls_hr_row-cost_center )
                      quantity               = SWITCH #( is_spec-measure
                                                         WHEN c_measure-headcount THEN ls_hr_row-headcount
                                                         ELSE                          ls_hr_row-total_positions ) )
             TO rt_lines.
    ENDLOOP.
  ENDMETHOD.


  METHOD determine_hr_skf.
    IF is_spec-building_suffix IS INITIAL.
      rv_skf = mo_params->get_value( is_spec-skf_param_name ).
      RETURN.
    ENDIF.

    rv_skf = mo_params->get_value(
               CONV #( |{ is_hr_row-real_estate_cost_center ALPHA = OUT }{ is_spec-building_suffix }| ) ).
  ENDMETHOD.


  METHOD to_documents.
    LOOP AT it_lines INTO DATA(ls_line)
         GROUP BY ls_line-posting_date INTO DATA(lv_posting_date).

      DATA(ls_document) = VALUE zif_co_skf_poster=>ty_document(
        controlling_area = c_controlling_area
        posting_date     = lv_posting_date
        document_date    = mv_document_date
        header_text      = |{ iv_header_text }{ io_period->get_display_text( ) }| ).

      LOOP AT GROUP lv_posting_date INTO DATA(ls_member).
        add_to_items( EXPORTING is_line   = ls_member
                                io_period = io_period
                      CHANGING  ct_items  = ls_document-items ).
      ENDLOOP.

      INSERT ls_document INTO TABLE rt_documents.
    ENDLOOP.
  ENDMETHOD.


  METHOD add_to_items.
    ASSIGN ct_items[ statistical_key_figure = is_line-statistical_key_figure
                     cost_center            = is_line-cost_center ] TO FIELD-SYMBOL(<ls_item>).
    IF sy-subrc = 0.
      <ls_item>-quantity += is_line-quantity.
      RETURN.
    ENDIF.

    " שנה/תקופה = תקופת החתך (ראה שאלות פתוחות לגבי P1 ו-ValidFrom)
    INSERT VALUE #( statistical_key_figure = is_line-statistical_key_figure
                    cost_center            = is_line-cost_center
                    fiscal_year            = io_period->get_year( )
                    fiscal_period          = io_period->get_period( )
                    quantity               = is_line-quantity
                    quantity_unit          = is_line-quantity_unit ) INTO TABLE ct_items.
  ENDMETHOD.

ENDCLASS.
