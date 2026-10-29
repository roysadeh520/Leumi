"! "עדכון מפתחות העמסה" (ZCO_SKF_MANAGE) - אפיון טכני סעיפים 5-14.
"! - Query Provider של ZCO_C_SKFPOSTINGPREVIEW: הרשימה ב-Fiori = ריצת מבחן
"! - get_documents: אותה בנייה משמשת את "בצע עדכון" (ZBP_CO_SKF_MANAGE) - מה שמוצג הוא מה שנרשם
CLASS zcl_co_skf_manage DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_build_result,
        documents  TYPE zcl_co_skf_poster_bapi=>ty_documents,
        error_text TYPE string,
      END OF ty_build_result.

    "! בונה את מסמכי הרישום, ללא שינוי ב-DB. בשגיאה: error_text מלא ואין מסמכים
    METHODS get_documents
      IMPORTING iv_topic             TYPE zco_skf_topic
                iv_fiscal_year_period TYPE csequence
      RETURNING VALUE(rs_result)     TYPE ty_build_result.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF c_topic,
        area                  TYPE zco_skf_topic VALUE 'P1', " נתוני שטח
        headcount_by_budget   TYPE zco_skf_topic VALUE 'P2', " עובדים לפי שיוך תקציבי וארגוני
        headcount_by_location TYPE zco_skf_topic VALUE 'P3', " עובדים לפי מיקום נדל"ן
      END OF c_topic.

    CONSTANTS c_controlling_area TYPE c LENGTH 4 VALUE '1000'.

    TYPES ty_quantity  TYPE zcl_co_skf_poster_bapi=>ty_quantity.
    TYPES ty_documents TYPE zcl_co_skf_poster_bapi=>ty_documents.

    "! שורת רישום אחידה (שטח / HR) לפני קיבוץ למסמכים
    TYPES:
      BEGIN OF ty_line,
        posting_date           TYPE d,
        statistical_key_figure TYPE c LENGTH 6,
        cost_center            TYPE c LENGTH 10,
        quantity               TYPE ty_quantity,
        quantity_unit          TYPE c LENGTH 3,
      END OF ty_line,
      ty_lines TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_hr_row,
        key_date                TYPE d,
        org_unit                TYPE c LENGTH 10,
        cost_center             TYPE c LENGTH 10,
        real_estate_cost_center TYPE c LENGTH 10,
        headcount               TYPE ty_quantity,
        total_positions         TYPE ty_quantity,
      END OF ty_hr_row,
      ty_hr_rows TYPE STANDARD TABLE OF ty_hr_row WITH EMPTY KEY.

    "! מסמך אחד מנתוני HR. P2: skf_param קבוע. P3: מפתח = בניין + building_suffix
    TYPES:
      BEGIN OF ty_hr_spec,
        header_text     TYPE string,
        is_positions    TYPE abap_boolean, " ' ' = עובדים (HEADCOUNT), X = משרות (TOTALPOSITIONS)
        is_budget_level TYPE abap_boolean, " ' ' = יח' ארגונית (ORGUNIT), X = יח' תקציבית (COSTCENTER)
        skf_param       TYPE string,
        building_suffix TYPE string,
      END OF ty_hr_spec,
      ty_hr_specs TYPE STANDARD TABLE OF ty_hr_spec WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_param,
        name  TYPE c LENGTH 30,
        value TYPE c LENGTH 50,
      END OF ty_param.

    DATA mt_param_cache TYPE HASHED TABLE OF ty_param WITH UNIQUE KEY name.

    METHODS build_documents
      IMPORTING iv_topic            TYPE zco_skf_topic
                iv_period           TYPE fis_jahrper
      RETURNING VALUE(rt_documents) TYPE ty_documents
      RAISING   lcx_error.

    METHODS read_area_lines
      IMPORTING iv_period       TYPE fis_jahrper
      RETURNING VALUE(rt_lines) TYPE ty_lines.

    METHODS read_hr_rows
      IMPORTING iv_period      TYPE fis_jahrper
      RETURNING VALUE(rt_rows) TYPE ty_hr_rows.

    METHODS build_hr_documents
      IMPORTING it_rows             TYPE ty_hr_rows
                it_specs            TYPE ty_hr_specs
                iv_period           TYPE fis_jahrper
      RETURNING VALUE(rt_documents) TYPE ty_documents
      RAISING   lcx_error.

    METHODS get_hr_specs
      IMPORTING iv_topic        TYPE zco_skf_topic
      RETURNING VALUE(rt_specs) TYPE ty_hr_specs.

    "! מסמך לכל תאריך רישום; שורות זהות (מפתח + מרכז עלות) מסוכמות לשורה אחת
    METHODS to_documents
      IMPORTING it_lines            TYPE ty_lines
                iv_header_text      TYPE string
                iv_period           TYPE fis_jahrper
      RETURNING VALUE(rt_documents) TYPE ty_documents.

    METHODS get_param
      IMPORTING iv_name         TYPE csequence
      RETURNING VALUE(rv_value) TYPE ty_param-value
      RAISING   lcx_error.

    " ---- תקופת חתך YYYYPPP (הנחה: שנה קלנדרית, תקופה = חודש) ----
    METHODS to_period
      IMPORTING iv_value         TYPE csequence
      RETURNING VALUE(rv_period) TYPE fis_jahrper
      RAISING   lcx_error.

    METHODS first_day IMPORTING iv_period TYPE fis_jahrper RETURNING VALUE(rv_date) TYPE d.
    METHODS last_day  IMPORTING iv_period TYPE fis_jahrper RETURNING VALUE(rv_date) TYPE d.
ENDCLASS.



CLASS zcl_co_skf_manage IMPLEMENTATION.

  " ======================================================================
  " תצוגה ב-Fiori (ריצת מבחן)
  " ======================================================================

  METHOD if_rap_query_provider~select.
    DATA lt_rows TYPE STANDARD TABLE OF zco_c_skfpostingpreview WITH EMPTY KEY.

    TRY.
        DATA(lt_filters) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(lx_filter).
        RAISE EXCEPTION TYPE cx_rap_query_provider EXPORTING previous = lx_filter.
    ENDTRY.

    DATA(lv_period) = VALUE #( lt_filters[ name = 'FISCALYEARPERIOD' ]-range[ 1 ]-low OPTIONAL ).
    DATA(lv_topic)  = VALUE #( lt_filters[ name = 'TOPIC' ]-range[ 1 ]-low OPTIONAL ).

    TRY.
        DATA(lt_documents) = build_documents( iv_topic  = CONV #( lv_topic )
                                              iv_period = to_period( lv_period ) ).
      CATCH lcx_error INTO DATA(lx_error).
        " ההודעה (פרמטר חסר / תקופה שגויה) מוצגת למשתמש
        RAISE EXCEPTION TYPE cx_rap_query_provider EXPORTING previous = lx_error.
    ENDTRY.

    LOOP AT lt_documents INTO DATA(ls_document).
      DATA(lv_document_index) = sy-tabix.
      LOOP AT ls_document-items INTO DATA(ls_item).
        APPEND VALUE #( fiscalyearperiod     = lv_period
                        topic                = lv_topic
                        documentindex        = lv_document_index
                        itemindex            = sy-tabix
                        headertext           = ls_document-header_text
                        postingdate          = ls_document-posting_date
                        statisticalkeyfigure = ls_item-statistical_key_figure
                        costcenter           = ls_item-cost_center
                        quantity             = ls_item-quantity
                        quantityunit         = ls_item-quantity_unit ) TO lt_rows.
      ENDLOOP.
    ENDLOOP.

    DATA(lt_sort) = VALUE abap_sortorder_tab( FOR ls_sort IN io_request->get_sort_elements( )
                                              ( name = ls_sort-element_name descending = ls_sort-descending ) ).
    IF lt_sort IS NOT INITIAL.
      SORT lt_rows BY (lt_sort).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_rows ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      DATA(lv_offset)    = io_request->get_paging( )->get_offset( ).
      DATA(lv_page_size) = io_request->get_paging( )->get_page_size( ).
      DATA(lv_to) = COND i( WHEN lv_page_size = if_rap_query_paging=>page_size_unlimited
                            THEN lines( lt_rows )
                            ELSE lv_offset + lv_page_size ).
      DATA(lt_page) = lt_rows.
      CLEAR lt_page.
      LOOP AT lt_rows INTO DATA(ls_row) FROM lv_offset + 1 TO lv_to.
        APPEND ls_row TO lt_page.
      ENDLOOP.
      io_response->set_data( lt_page ).
    ENDIF.
  ENDMETHOD.


  " ======================================================================
  " בניית מסמכים (משותף לתצוגה ולעדכון)
  " ======================================================================

  METHOD get_documents.
    TRY.
        rs_result-documents = build_documents( iv_topic  = iv_topic
                                               iv_period = to_period( iv_fiscal_year_period ) ).
      CATCH lcx_error INTO DATA(lx_error).
        rs_result-error_text = lx_error->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD build_documents.
    " כל המסמכים נבנים לפני רישום כלשהו: פרמטר חסר עוצר את הכל לפני שנרשם משהו
    CASE iv_topic.
      WHEN c_topic-area.
        rt_documents = to_documents( it_lines       = read_area_lines( iv_period )
                                     iv_header_text = `נתוני שטח - `
                                     iv_period      = iv_period ) ##NO_TEXT.
      WHEN c_topic-headcount_by_budget OR c_topic-headcount_by_location.
        rt_documents = build_hr_documents( it_rows   = read_hr_rows( iv_period )
                                           it_specs  = get_hr_specs( iv_topic )
                                           iv_period = iv_period ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW lcx_error( |נושא { iv_topic } אינו נתמך| ) ##NO_TEXT.
    ENDCASE.
  ENDMETHOD.


  METHOD read_area_lines.
    DATA(lv_first_day) = first_day( iv_period ).
    DATA(lv_last_day)  = last_day( iv_period ).

    " סעיף 8: כלל ייחוס בתוקף בתקופת החתך; בנוסף רק מדידות שבתוקף בתקופה (ראה שאלות פתוחות 5).
    " מפתח סטטיסטי = סוג המדידה (R100/R101), רישום ביום האחרון של התקופה
    SELECT FROM zco_restatkeydatatot
      FIELDS @lv_last_day AS posting_date,
             meas         AS statistical_key_figure,
             costcenter   AS cost_center,
             measvalue    AS quantity,
             measunit     AS quantity_unit
      WHERE validityendfiscalyearperiod >= @iv_period
        AND validfrom                   <= @lv_last_day
        AND validto                     >= @lv_first_day
      INTO CORRESPONDING FIELDS OF TABLE @rt_lines.
  ENDMETHOD.


  METHOD read_hr_rows.
    DATA(lv_first_day) = first_day( iv_period ).
    DATA(lv_last_day)  = last_day( iv_period ).

    " TODO(VERIFY): שמות השדות ב-ZC_HR_BudgetReport (CDS של צוות HR)
    SELECT FROM zc_hr_budgetreport
      FIELDS keydate              AS key_date,
             orgunit              AS org_unit,
             costcenter           AS cost_center,
             realestatecostcenter AS real_estate_cost_center,
             headcount,
             totalpositions       AS total_positions
      WHERE keydate BETWEEN @lv_first_day AND @lv_last_day
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.


  METHOD get_hr_specs.
    rt_specs = SWITCH #( iv_topic
      " סעיפים 10-12
      WHEN c_topic-headcount_by_budget THEN VALUE #(
        ( header_text = `נתוני עובדים ברמת יח ארגונית-`  skf_param = `ZCO_HC_SKF_DET` )
        ( header_text = `נתוני משרות ברמת יח ארגונית-`   skf_param = `ZCO_POS_SKF_DET` is_positions = abap_true )
        ( header_text = `נתוני עובדים ברמת יח תקציבית-`  skf_param = `ZCO_HC_SKF_TOT`  is_budget_level = abap_true )
        ( header_text = `נתוני משרות ברמת יח תקציבית-`   skf_param = `ZCO_POS_SKF_TOT` is_positions = abap_true
                                                                                       is_budget_level = abap_true ) )
      " סעיפים 13-14: מפתח = מרכז עלות הבניין + סיומת (לדוגמה B1010001HCD)
      WHEN c_topic-headcount_by_location THEN VALUE #(
        ( header_text = `עובדים לפי מיקום ברמת יח ארגונית-` building_suffix = `HCD` )
        ( header_text = `משרות לפי מיקום ברמת יח ארגונית-`  building_suffix = `POSD` is_positions = abap_true )
        ( header_text = `עובדים לפי מיקום ברמת יח תקציבית-` building_suffix = `HCT`  is_budget_level = abap_true )
        ( header_text = `משרות לפי מיקום ברמת יח תקציבית-`  building_suffix = `POST` is_positions = abap_true
                                                                                   is_budget_level = abap_true ) ) ) ##NO_TEXT.
  ENDMETHOD.


  METHOD build_hr_documents.
    LOOP AT it_specs INTO DATA(ls_spec).
      DATA(lt_lines) = VALUE ty_lines( ).

      LOOP AT it_rows INTO DATA(ls_row).
        " P3: עובדים ללא שיוך לבניין לא נכללים
        IF ls_spec-building_suffix IS NOT INITIAL AND ls_row-real_estate_cost_center IS INITIAL.
          CONTINUE.
        ENDIF.

        " ברמה תקציבית שורות של אותו מרכז עלות מסוכמות ב-to_documents (= סיכום לפי KEYDATE + COSTCENTER)
        APPEND VALUE #(
          posting_date           = ls_row-key_date
          statistical_key_figure = get_param( COND string( WHEN ls_spec-building_suffix IS INITIAL
                                                      THEN ls_spec-skf_param
                                                      ELSE |{ ls_row-real_estate_cost_center ALPHA = OUT }{ ls_spec-building_suffix }| ) )
          cost_center            = COND #( WHEN ls_spec-is_budget_level = abap_true
                                           THEN ls_row-cost_center ELSE ls_row-org_unit )
          quantity               = COND #( WHEN ls_spec-is_positions = abap_true
                                           THEN ls_row-total_positions ELSE ls_row-headcount ) ) TO lt_lines.
      ENDLOOP.

      APPEND LINES OF to_documents( it_lines       = lt_lines
                                    iv_header_text = ls_spec-header_text
                                    iv_period      = iv_period ) TO rt_documents.
    ENDLOOP.
  ENDMETHOD.


  METHOD to_documents.
    LOOP AT it_lines INTO DATA(ls_line) GROUP BY ls_line-posting_date INTO DATA(lv_posting_date).
      DATA(ls_document) = VALUE zcl_co_skf_poster_bapi=>ty_document(
        controlling_area = c_controlling_area
        posting_date     = lv_posting_date
        document_date    = cl_abap_context_info=>get_system_date( )
        header_text      = |{ iv_header_text }{ iv_period+4(3) }.{ iv_period(4) }| ).

      LOOP AT GROUP lv_posting_date INTO DATA(ls_member).
        ASSIGN ls_document-items[ statistical_key_figure = ls_member-statistical_key_figure
                                  cost_center            = ls_member-cost_center ] TO FIELD-SYMBOL(<ls_item>).
        IF sy-subrc = 0.
          <ls_item>-quantity += ls_member-quantity.
        ELSE.
          INSERT VALUE #( statistical_key_figure = ls_member-statistical_key_figure
                          cost_center            = ls_member-cost_center
                          fiscal_year            = iv_period(4)
                          fiscal_period          = iv_period+4(3)
                          quantity               = ls_member-quantity
                          quantity_unit          = ls_member-quantity_unit ) INTO TABLE ls_document-items.
        ENDIF.
      ENDLOOP.

      INSERT ls_document INTO TABLE rt_documents.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_param.
    " פרמטרי בניין נקראים לכל שורת HR - מטמון חוסך גישות חוזרות
    READ TABLE mt_param_cache WITH TABLE KEY name = iv_name INTO DATA(ls_cached).
    IF sy-subrc = 0.
      rv_value = ls_cached-value.
      RETURN.
    ENDIF.

    " ZCA_PARAM במבנה TVARVC: NAME / LOW
    SELECT SINGLE low FROM zca_param WHERE name = @iv_name INTO @rv_value.
    IF rv_value IS INITIAL.
      RAISE EXCEPTION NEW lcx_error( |פרמטר { iv_name } לא מתוחזק בטבלה ZCA_PARAM| ) ##NO_TEXT.
    ENDIF.

    INSERT VALUE #( name = iv_name value = rv_value ) INTO TABLE mt_param_cache.
  ENDMETHOD.


  METHOD to_period.
    IF NOT matches( val = iv_value regex = `\d{4}0(0[1-9]|1[0-2])` ).
      RAISE EXCEPTION NEW lcx_error( |תקופת חתך { iv_value } אינה תקינה (YYYYPPP, תקופות 001-012)| ) ##NO_TEXT.
    ENDIF.
    rv_period = iv_value.
  ENDMETHOD.


  METHOD first_day.
    rv_date = |{ iv_period(4) }{ iv_period+5(2) }01|.
  ENDMETHOD.


  METHOD last_day.
    " היום הראשון של החודש הבא פחות יום
    DATA(lv_next_month) = CONV d( COND string( WHEN iv_period+4(3) = '012'
                                               THEN |{ iv_period(4) + 1 }0101|
                                               ELSE |{ iv_period(4) }{ iv_period+5(2) + 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }01| ) ).
    rv_date = lv_next_month - 1.
  ENDMETHOD.

ENDCLASS.
