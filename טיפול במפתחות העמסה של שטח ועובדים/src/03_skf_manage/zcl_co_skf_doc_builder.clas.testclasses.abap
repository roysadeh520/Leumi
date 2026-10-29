"! מקור נתונים מזויף - מחזיר שורות שהוגדרו בבדיקה
CLASS ltd_source DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_co_skf_source.
    DATA mt_area_rows TYPE zif_co_skf_types=>ty_area_rows.
    DATA mt_hr_rows   TYPE zif_co_skf_types=>ty_hr_rows.
ENDCLASS.

CLASS ltd_source IMPLEMENTATION.
  METHOD zif_co_skf_source~read_area_rows.
    rt_rows = mt_area_rows.
  ENDMETHOD.

  METHOD zif_co_skf_source~read_hr_rows.
    rt_rows = mt_hr_rows.
  ENDMETHOD.
ENDCLASS.


"! פרמטרים מזויפים - טבלה בזיכרון במקום ZCA_PARAM
CLASS ltd_params DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_co_param_provider.
    TYPES:
      BEGIN OF ty_param,
        name  TYPE zif_co_param_provider=>ty_name,
        value TYPE zif_co_param_provider=>ty_value,
      END OF ty_param.
    DATA mt_params TYPE HASHED TABLE OF ty_param WITH UNIQUE KEY name.
ENDCLASS.

CLASS ltd_params IMPLEMENTATION.
  METHOD zif_co_param_provider~get_value.
    READ TABLE mt_params WITH TABLE KEY name = iv_name INTO DATA(ls_param).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_co_skf_error MESSAGE e001(zco_skf) WITH iv_name.
    ENDIF.
    rv_value = ls_param-value.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_doc_builder DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS c_document_date TYPE d VALUE '20261005'.
    CONSTANTS c_key_date      TYPE d VALUE '20260930'.

    DATA mo_source TYPE REF TO ltd_source.
    DATA mo_params TYPE REF TO ltd_params.
    DATA mo_cut    TYPE REF TO zcl_co_skf_doc_builder.
    DATA mo_period TYPE REF TO zcl_co_fiscal_period.

    METHODS setup RAISING cx_static_check.

    METHODS area_sums_same_cost_center   FOR TESTING RAISING cx_static_check.
    METHODS area_posts_on_last_day       FOR TESTING RAISING cx_static_check.
    METHODS budget_creates_4_documents   FOR TESTING RAISING cx_static_check.
    METHODS budget_level_sums_org_units  FOR TESTING RAISING cx_static_check.
    METHODS location_uses_building_skf   FOR TESTING RAISING cx_static_check.
    METHODS location_skips_no_building   FOR TESTING RAISING cx_static_check.
    METHODS missing_param_raises         FOR TESTING RAISING cx_static_check.
    METHODS unknown_topic_raises         FOR TESTING RAISING cx_static_check.
    METHODS no_rows_no_documents         FOR TESTING RAISING cx_static_check.

    METHODS given_two_org_units_in_one_cc.
ENDCLASS.


CLASS ltc_doc_builder IMPLEMENTATION.

  METHOD setup.
    mo_source = NEW #( ).
    mo_params = NEW #( ).
    mo_params->mt_params = VALUE #( ( name = 'ZCO_HC_SKF_DET'  value = 'HCDET' )
                                    ( name = 'ZCO_POS_SKF_DET' value = 'POSDET' )
                                    ( name = 'ZCO_HC_SKF_TOT'  value = 'HCTOT' )
                                    ( name = 'ZCO_POS_SKF_TOT' value = 'POSTOT' )
                                    ( name = 'B1010001HCD'     value = 'B1HCD' )
                                    ( name = 'B1010001POSD'    value = 'B1POSD' )
                                    ( name = 'B1010001HCT'     value = 'B1HCT' )
                                    ( name = 'B1010001POST'    value = 'B1POST' ) ).
    mo_cut = NEW #( io_source        = mo_source
                    io_params        = mo_params
                    iv_document_date = c_document_date ).
    mo_period = zcl_co_fiscal_period=>from_value( '2026009' ).
  ENDMETHOD.


  METHOD area_sums_same_cost_center.
    mo_source->mt_area_rows = VALUE #( ( cost_center = 'CC1' meas = 'R100' meas_value = 100 meas_unit = 'M2' )
                                       ( cost_center = 'CC1' meas = 'R100' meas_value = 50  meas_unit = 'M2' )
                                       ( cost_center = 'CC1' meas = 'R101' meas_value = 80  meas_unit = 'M2' ) ).

    DATA(lt_documents) = mo_cut->build_documents( iv_topic  = zif_co_skf_types=>c_topic-area
                                                  io_period = mo_period ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_documents ) ).
    DATA(lt_items) = lt_documents[ 1 ]-items.
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_items ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 150
      act = lt_items[ statistical_key_figure = 'R100' cost_center = 'CC1' ]-quantity ).
  ENDMETHOD.


  METHOD area_posts_on_last_day.
    mo_source->mt_area_rows = VALUE #( ( cost_center = 'CC1' meas = 'R100' meas_value = 1 ) ).

    DATA(ls_document) = mo_cut->build_documents( iv_topic  = zif_co_skf_types=>c_topic-area
                                                 io_period = mo_period )[ 1 ].

    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260930' ) act = ls_document-posting_date ).
    cl_abap_unit_assert=>assert_equals( exp = c_document_date     act = ls_document-document_date ).
    cl_abap_unit_assert=>assert_equals( exp = '1000'              act = ls_document-controlling_area ).
    cl_abap_unit_assert=>assert_equals( exp = `נתוני שטח - 009.2026`
                                        act = CONV string( ls_document-header_text ) ).
  ENDMETHOD.


  METHOD budget_creates_4_documents.
    given_two_org_units_in_one_cc( ).

    DATA(lt_documents) = mo_cut->build_documents( iv_topic  = zif_co_skf_types=>c_topic-headcount_by_budget
                                                  io_period = mo_period ).

    cl_abap_unit_assert=>assert_equals( exp = 4 act = lines( lt_documents ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lines( lt_documents[ 1 ]-items ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 'HCDET'
      act = lt_documents[ 1 ]-items[ 1 ]-statistical_key_figure ).
  ENDMETHOD.


  METHOD budget_level_sums_org_units.
    given_two_org_units_in_one_cc( ).

    DATA(lt_documents) = mo_cut->build_documents( iv_topic  = zif_co_skf_types=>c_topic-headcount_by_budget
                                                  io_period = mo_period ).

    " מסמך 3 = עובדים ברמה תקציבית: 10 + 5 תחת מרכז עלות 100
    DATA(lt_items) = lt_documents[ 3 ]-items.
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_items ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'HCTOT' act = lt_items[ 1 ]-statistical_key_figure ).
    cl_abap_unit_assert=>assert_equals( exp = 15      act = lt_items[ 1 ]-quantity ).
  ENDMETHOD.


  METHOD location_uses_building_skf.
    given_two_org_units_in_one_cc( ).

    DATA(lt_documents) = mo_cut->build_documents( iv_topic  = zif_co_skf_types=>c_topic-headcount_by_location
                                                  io_period = mo_period ).

    cl_abap_unit_assert=>assert_equals( exp = 4 act = lines( lt_documents ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'B1HCD'  act = lt_documents[ 1 ]-items[ 1 ]-statistical_key_figure ).
    cl_abap_unit_assert=>assert_equals( exp = 'B1POST' act = lt_documents[ 4 ]-items[ 1 ]-statistical_key_figure ).
  ENDMETHOD.


  METHOD location_skips_no_building.
    mo_source->mt_hr_rows = VALUE #( ( key_date = c_key_date org_unit = '50000001' cost_center = '100'
                                       headcount = 3 total_positions = 3 ) ).

    DATA(lt_documents) = mo_cut->build_documents( iv_topic  = zif_co_skf_types=>c_topic-headcount_by_location
                                                  io_period = mo_period ).

    cl_abap_unit_assert=>assert_initial( lt_documents ).
  ENDMETHOD.


  METHOD missing_param_raises.
    mo_source->mt_hr_rows = VALUE #( ( key_date = c_key_date org_unit = '50000001' cost_center = '100'
                                       real_estate_cost_center = 'B9999999' headcount = 1 ) ).
    TRY.
        mo_cut->build_documents( iv_topic  = zif_co_skf_types=>c_topic-headcount_by_location
                                 io_period = mo_period ).
        cl_abap_unit_assert=>fail( 'Missing building parameter must stop the run' ).
      CATCH zcx_co_skf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.


  METHOD unknown_topic_raises.
    TRY.
        mo_cut->build_documents( iv_topic = 'P9' io_period = mo_period ).
        cl_abap_unit_assert=>fail( 'Unknown topic must be rejected' ).
      CATCH zcx_co_skf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.


  METHOD no_rows_no_documents.
    cl_abap_unit_assert=>assert_initial(
      mo_cut->build_documents( iv_topic  = zif_co_skf_types=>c_topic-area
                               io_period = mo_period ) ).
  ENDMETHOD.


  METHOD given_two_org_units_in_one_cc.
    mo_source->mt_hr_rows = VALUE #(
      ( key_date = c_key_date org_unit = '50000001' cost_center = '100'
        real_estate_cost_center = 'B1010001' headcount = 10 total_positions = 12 )
      ( key_date = c_key_date org_unit = '50000002' cost_center = '100'
        real_estate_cost_center = 'B1010001' headcount = 5  total_positions = 6 ) ).
  ENDMETHOD.

ENDCLASS.
