CLASS ltc_budget_builder DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut     TYPE REF TO lcl_budget_builder.
    DATA ms_request TYPE lcl_budget_builder=>ty_request.

    METHODS setup.
    METHODS balanced_pair_per_branch FOR TESTING.
    METHODS zero_budget_is_skipped   FOR TESTING.
    METHODS missing_param_is_error   FOR TESTING.
ENDCLASS.


CLASS ltc_budget_builder IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_cut->mt_param_cache = VALUE #( ( name = 'ZFM_REFRESH_BUDDOC' value = 'ZREF' )
                                      ( name = 'ZFM_UPD_BUDTYPE'    value = 'Y150' ) ).
    ms_request = VALUE #( fiscal_year_period  = '2026009' commitment_item = 'CI1'
                          source_funds_center = 'RESERVE' ).
  ENDMETHOD.


  METHOD balanced_pair_per_branch.
    mo_cut->build( EXPORTING it_rows     = VALUE #( ( cost_center = 'BR1' budget_amount = 100 ) )
                             is_request  = ms_request
                   IMPORTING es_document = DATA(ls_document) ).

    cl_abap_unit_assert=>assert_equals( exp = 2         act = lines( ls_document-items ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'BR1'     act = ls_document-items[ 1 ]-funds_center ).
    cl_abap_unit_assert=>assert_equals( exp = 100       act = ls_document-items[ 1 ]-total_amount ).
    cl_abap_unit_assert=>assert_equals( exp = 'RESERVE' act = ls_document-items[ 2 ]-funds_center ).
    cl_abap_unit_assert=>assert_equals( exp = -100      act = ls_document-items[ 2 ]-total_amount ).
    cl_abap_unit_assert=>assert_equals( exp = '009'     act = ls_document-items[ 2 ]-budgeting_period ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260930' ) act = ls_document-header-posting_date ).
  ENDMETHOD.


  METHOD zero_budget_is_skipped.
    mo_cut->build( EXPORTING it_rows     = VALUE #( ( cost_center = 'BR1' budget_amount = 0 ) )
                             is_request  = ms_request
                   IMPORTING es_document = DATA(ls_document) ).

    cl_abap_unit_assert=>assert_initial( ls_document-items ).
  ENDMETHOD.


  METHOD missing_param_is_error.
    " סוג תקציב לא מתוחזק
    mo_cut->mt_param_cache = VALUE #( ( name = 'ZFM_REFRESH_BUDDOC' value = 'ZREF' )
                                      ( name = 'ZFM_UPD_BUDTYPE'    value = '' ) ).

    mo_cut->build( EXPORTING it_rows       = VALUE #( ( cost_center = 'BR1' budget_amount = 100 ) )
                             is_request    = ms_request
                   IMPORTING ev_error_text = DATA(lv_error_text) ).

    cl_abap_unit_assert=>assert_not_initial( lv_error_text ).
  ENDMETHOD.

ENDCLASS.
