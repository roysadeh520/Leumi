# RAP patterns - copy-paste skeletons

Replace `<...>`. Hebrew comments as in the team's code. Reference implementation:
`FM/טיפול במפתחות העמסה של שטח ועובדים/src/` in the Leumi repo.

---

## 1. BAPI wrapper (Level B) - Standard ABAP package, released C1

```abap
"! ABAP Wrapper (Clean Core Level B) מעל <BAPI>.
"! חבילה: Z<MOD>_<DEV>_WRAPPER, Standard ABAP, שחרור C1 (Use in Cloud Development).
"! TODO(VERIFY): חתימת ה-BAPI ושמות שדות המבנים ב-SE37.
CLASS zcl_<x>_bapi DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    " טיפוסים מובנים בלבד - לא לחשוף DDIC לא משוחרר לקוד הענן
    TYPES: BEGIN OF ty_document, ... END OF ty_document.
    TYPES: BEGIN OF ty_message, type TYPE c LENGTH 1, text TYPE string, END OF ty_message,
           ty_messages TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.
    TYPES: BEGIN OF ty_result,
             is_success      TYPE abap_boolean,
             document_number TYPE c LENGTH 10,
             messages        TYPE ty_messages,
           END OF ty_result.

    "! בדיקה בלבד, ללא שינוי ב-DB (CHECK BAPI / TESTRUN)
    METHODS check IMPORTING is_document TYPE ty_document RETURNING VALUE(rs_result) TYPE ty_result.

    "! @parameter iv_commit | X = ה-Wrapper מבצע COMMIT/ROLLBACK (Job / דוח).
    "!                       ' ' = מתוך RAP save: RAP מבצע את ה-COMMIT, אסור כאן.
    METHODS post IMPORTING is_document      TYPE ty_document
                           iv_commit        TYPE abap_boolean DEFAULT abap_true
                 RETURNING VALUE(rs_result) TYPE ty_result.
  PRIVATE SECTION.
    " to_bapi_header / to_bapi_items / to_messages / has_error
ENDCLASS.

CLASS zcl_<x>_bapi IMPLEMENTATION.
  METHOD post.
    CALL FUNCTION '<BAPI>' EXPORTING ... IMPORTING ... TABLES ... return = lt_return.
    IF has_error( lt_return ).
      IF iv_commit = abap_true.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ENDIF.
      rs_result = VALUE #( is_success = abap_false messages = to_messages( lt_return ) ).
      RETURN.
    ENDIF.
    IF iv_commit = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
    ENDIF.
    rs_result = VALUE #( is_success = abap_true document_number = lv_doc_no messages = to_messages( lt_return ) ).
  ENDMETHOD.
  ...
ENDCLASS.
```

---

## 2. List + "update" button - unmanaged BO with static action

### Root entity
- List computed by CDS → `define root view entity` (the CDS itself is the BO; logic goes in the behavior pool).
- List computed in ABAP → `define root custom entity` + `@ObjectModel.query.implementedBy: 'ABAP:ZCL_<APP>'`.
- **No parameters** on a BO entity. Use mandatory filters:
```cds
@UI.selectionField: [{ position: 10 }]
@Consumption.filter: { mandatory: true, selectionType: #SINGLE, multipleSelections: false }
key FiscalYearPeriod : fis_jahrper;
```
- The button on the list toolbar:
```cds
@UI.lineItem: [{ type: #FOR_ACTION, dataAction: '<actionName>', label: 'בצע עדכון' }]
```

### Abstract entity = the action dialog
```cds
@EndUserText.label: '<app> - פרמטרים'
define abstract entity Z<MOD>_A_<APP>PARAM
{
  @EndUserText.label: 'תקופת חתך (YYYYPPP)'
  FiscalYearPeriod : fis_jahrper;
  ...
}
```

### BDEF
```cds
unmanaged implementation in class zbp_<app> unique;
strict ( 2 );

define behavior for Z<ROOT_ENTITY> alias <Alias>
lock master
authorization master ( global )
{
  static action <actionName> parameter Z<MOD>_A_<APP>PARAM;
}
```
Create the behavior pool with **Ctrl+1** on the first line, then paste the local types.

### Behavior pool - local types
```abap
"! מסמכים שהוכנו ונבדקו בפעולה וממתינים לשמירה (transactional buffer)
CLASS lcl_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA gt_documents TYPE zcl_<x>_bapi=>ty_documents.
ENDCLASS.

CLASS lhc_<alias> DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR <Alias> RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK <Alias>.
    METHODS read FOR READ IMPORTING keys FOR READ <Alias> RESULT result.
    METHODS <actionname> FOR MODIFY IMPORTING keys FOR ACTION <Alias>~<actionName>.
ENDCLASS.

CLASS lhc_<alias> IMPLEMENTATION.
  METHOD get_global_authorizations.
    " ההרשאה נקבעת ב-Business Catalog
    result-%action-<actionname> = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD lock.
    " אין נעילה ברמת השורה - ה-BAPI נועל בעצמו
  ENDMETHOD.

  METHOD read.
    " הרשימה נקראת דרך ה-CDS / Query Provider
  ENDMETHOD.

  METHOD <actionname>.
    LOOP AT keys INTO DATA(ls_key).
      " 1. בניית המסמכים (קריאה בלבד)
      " 2. שגיאה → failed + reported עם %cid, CONTINUE
      IF lv_error_text IS NOT INITIAL.
        APPEND VALUE #( %cid = ls_key-%cid ) TO failed-<alias>.
        APPEND VALUE #( %cid = ls_key-%cid
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = lv_error_text ) ) TO reported-<alias>.
        CONTINUE.
      ENDIF.
      " 3. בדיקה ב-BAPI (CHECK / TESTRUN, iv_commit = ' ') - כשל = לא נרשם דבר
      " TODO(VERIFY): ש-CHECK/TESTRUN לא כותב ל-DB (מותר רק קריאה בשלב הפעולה)
      " 4. הכל תקין → APPEND ל-lcl_buffer=>gt_documents
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save    REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_saver IMPLEMENTATION.
  METHOD save.
    " רישום בלי COMMIT - RAP מבצע את ה-COMMIT בסוף השמירה
    LOOP AT lcl_buffer=>gt_documents INTO DATA(ls_document).
      DATA(ls_result) = NEW zcl_<x>_bapi( )->post( is_document = ls_document iv_commit = abap_false ).
      " TODO(VERIFY): הודעות בשלב save (reported) - תלוי גרסה
      APPEND new_message_with_text(
               severity = COND #( WHEN ls_result-is_success = abap_true
                                  THEN if_abap_behv_message=>severity-success
                                  ELSE if_abap_behv_message=>severity-error )
               text     = COND #( WHEN ls_result-is_success = abap_true
                                  THEN |נרשם מסמך { ls_result-document_number }|
                                  ELSE |הרישום נכשל| ) ) TO reported-%other.
    ENDLOOP.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR lcl_buffer=>gt_documents.
  ENDMETHOD.
ENDCLASS.
```

---

## 3. Query provider for a custom entity (logic class)

```abap
CLASS zcl_<app> DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
    "! אותה בנייה משמשת את הרשימה ואת הכפתור - מה שמוצג הוא מה שנרשם
    METHODS get_documents IMPORTING ... RETURNING VALUE(rs_result) TYPE ty_build_result.
  PRIVATE SECTION.
    " כל הלוגיקה כאן כ-private methods; lcx_error ב-locals_def
ENDCLASS.

METHOD if_rap_query_provider~select.
  DATA lt_rows TYPE STANDARD TABLE OF z<custom_entity> WITH EMPTY KEY.
  TRY.
      DATA(lt_filters) = io_request->get_filter( )->get_as_ranges( ).
    CATCH cx_rap_query_filter_no_range INTO DATA(lx_filter).
      RAISE EXCEPTION TYPE cx_rap_query_provider EXPORTING previous = lx_filter.
  ENDTRY.
  DATA(lv_period) = VALUE #( lt_filters[ name = 'FISCALYEARPERIOD' ]-range[ 1 ]-low OPTIONAL ).
  " ... בניית lt_rows, שגיאה → RAISE EXCEPTION TYPE cx_rap_query_provider EXPORTING previous = lx_error

  " מיון
  DATA(lt_sort) = VALUE abap_sortorder_tab( FOR ls_sort IN io_request->get_sort_elements( )
                                            ( name = ls_sort-element_name descending = ls_sort-descending ) ).
  IF lt_sort IS NOT INITIAL.
    SORT lt_rows BY (lt_sort).
  ENDIF.

  IF io_request->is_total_numb_of_rec_requested( ).
    io_response->set_total_number_of_records( lines( lt_rows ) ).
  ENDIF.
  IF io_request->is_data_requested( ).
    " דפדוף: get_paging( )->get_offset( ) / get_page_size( ) (page_size_unlimited = הכל)
    io_response->set_data( lt_page ).
  ENDIF.
ENDMETHOD.
```

### Local exception (`locals_def` + `locals_imp`)
```abap
CLASS lcx_error DEFINITION INHERITING FROM cx_static_check FINAL.
  PUBLIC SECTION.
    METHODS constructor IMPORTING iv_text TYPE string.
    METHODS get_text REDEFINITION.
  PRIVATE SECTION.
    DATA mv_text TYPE string.
ENDCLASS.

CLASS lcx_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_text = iv_text.
  ENDMETHOD.
  METHOD get_text.
    result = mv_text.
  ENDMETHOD.
ENDCLASS.
```

---

## 4. Small helpers (private methods, not classes)

```abap
" ZCA_PARAM (TVARVC) עם מטמון
METHOD get_param.
  READ TABLE mt_param_cache WITH TABLE KEY name = iv_name INTO DATA(ls_cached).
  IF sy-subrc = 0.
    rv_value = ls_cached-value.
    RETURN.
  ENDIF.
  SELECT SINGLE low FROM zca_param WHERE name = @iv_name INTO @rv_value.
  IF rv_value IS INITIAL.
    RAISE EXCEPTION NEW lcx_error( |פרמטר { iv_name } לא מתוחזק בטבלה ZCA_PARAM| ).
  ENDIF.
  INSERT VALUE #( name = iv_name value = rv_value ) INTO TABLE mt_param_cache.
ENDMETHOD.

" תקופת חתך YYYYPPP: בדיקה + יום אחרון
METHOD to_period.
  IF NOT matches( val = iv_value regex = `\d{4}0(0[1-9]|1[0-2])` ).
    RAISE EXCEPTION NEW lcx_error( |תקופת חתך { iv_value } אינה תקינה (YYYYPPP)| ).
  ENDIF.
  rv_period = iv_value.
ENDMETHOD.

METHOD last_day.
  DATA(lv_next_month) = CONV d( COND string( WHEN iv_period+4(3) = '012'
                                             THEN |{ iv_period(4) + 1 }0101|
                                             ELSE |{ iv_period(4) }{ iv_period+5(2) + 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }01| ) ).
  rv_date = lv_next_month - 1.
ENDMETHOD.
```
