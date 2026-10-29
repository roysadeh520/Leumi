CLASS ltd_params DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_co_param_provider.
ENDCLASS.

CLASS ltd_params IMPLEMENTATION.
  METHOD zif_co_param_provider~get_value.
    rv_value = SWITCH #( iv_name
                         WHEN 'ZFM_REFRESH_BUDDOC' THEN 'ZREF'
                         WHEN 'ZFM_UPD_BUDTYPE'    THEN 'Y150' ).
  ENDMETHOD.
ENDCLASS.


CLASS ltc_budget_builder DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut     TYPE REF TO zcl_fm_refresh_budget_builder.
    DATA mo_period  TYPE REF TO zcl_co_fiscal_period.
    DATA ms_request TYPE zcl_fm_refresh_budget_builder=>ty_request.

    METHODS setup RAISING cx_static_check.
    METHODS two_items_per_branch    FOR TESTING RAISING cx_static_check.
    METHODS document_is_balanced    FOR TESTING RAISING cx_static_check.
    METHODS zero_budget_is_skipped  FOR TESTING RAISING cx_static_check.
    METHODS header_from_spec        FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltc_budget_builder IMPLEMENTATION.

  METHOD setup.
    mo_cut     = NEW #( io_params = NEW ltd_params( ) iv_document_date = '20261005' ).
    mo_period  = zcl_co_fiscal_period=>from_value( '2026009' ).
    ms_request = VALUE #( commitment_item = 'CI1' source_funds_center = 'RESERVE' ).
  ENDMETHOD.


  METHOD two_items_per_branch.
    DATA(ls_document) = mo_cut->build_document(
      it_rows    = VALUE #( ( fiscal_year_period = '2026009' cost_center = 'BR1' budget_amount = 100 ) )
      io_period  = mo_period
      is_request = ms_request ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( ls_document-items ) ).
    DATA(ls_branch) = ls_document-items[ 1 ].
    DATA(ls_source) = ls_document-items[ 2 ].
    cl_abap_unit_assert=>assert_equals( exp = 'BR1'     act = ls_branch-funds_center ).
    cl_abap_unit_assert=>assert_equals( exp = 100       act = ls_branch-total_amount ).
    cl_abap_unit_assert=>assert_equals( exp = 'RESERVE' act = ls_source-funds_center ).
    cl_abap_unit_assert=>assert_equals( exp = -100      act = ls_source-total_amount ).
    cl_abap_unit_assert=>assert_equals( exp = '009'     act = ls_source-budgeting_period ).
    cl_abap_unit_assert=>assert_equals( exp = 'Y150'    act = ls_source-budget_type ).
    cl_abap_unit_assert=>assert_equals( exp = 2         act = ls_source-item_number ).
  ENDMETHOD.


  METHOD document_is_balanced.
    DATA(ls_document) = mo_cut->build_document(
      it_rows    = VALUE #( ( fiscal_year_period = '2026009' cost_center = 'BR1' budget_amount = 100 )
                            ( fiscal_year_period = '2026009' cost_center = 'BR2' budget_amount = '55.50' ) )
      io_period  = mo_period
      is_request = ms_request ).

    cl_abap_unit_assert=>assert_equals( exp = 4 act = lines( ls_document-items ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = REDUCE zif_fm_budget_poster=>ty_amount( INIT lv_sum = 0
                                                    FOR ls_item IN ls_document-items
                                                    NEXT lv_sum = lv_sum + ls_item-total_amount ) ).
  ENDMETHOD.


  METHOD zero_budget_is_skipped.
    DATA(ls_document) = mo_cut->build_document(
      it_rows    = VALUE #( ( fiscal_year_period = '2026009' cost_center = 'BR1' budget_amount = 0 ) )
      io_period  = mo_period
      is_request = ms_request ).

    cl_abap_unit_assert=>assert_initial( ls_document-items ).
  ENDMETHOD.


  METHOD header_from_spec.
    DATA(ls_header) = mo_cut->build_document( it_rows    = VALUE #( )
                                              io_period  = mo_period
                                              is_request = ms_request )-header.

    cl_abap_unit_assert=>assert_equals( exp = '1000'              act = ls_header-fm_area ).
    cl_abap_unit_assert=>assert_equals( exp = 'ZREF'              act = ls_header-document_type ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260930' ) act = ls_header-posting_date ).
    cl_abap_unit_assert=>assert_equals( exp = `תקציב כריכים-009.2026`
                                        act = CONV string( ls_header-header_text ) ).
  ENDMETHOD.

ENDCLASS.
