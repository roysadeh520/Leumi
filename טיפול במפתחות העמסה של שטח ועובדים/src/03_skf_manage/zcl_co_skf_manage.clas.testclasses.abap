CLASS ltc_skf_manage DEFINITION DEFERRED.
CLASS zcl_co_skf_manage DEFINITION LOCAL FRIENDS ltc_skf_manage.

CLASS ltc_skf_manage DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_co_skf_manage.

    METHODS setup.
    METHODS last_day_of_period       FOR TESTING.
    METHODS budget_level_sums_by_cc  FOR TESTING RAISING cx_static_check.
    METHODS location_uses_building   FOR TESTING RAISING cx_static_check.
    METHODS missing_param_stops_run  FOR TESTING.
ENDCLASS.


CLASS ltc_skf_manage IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    " פרמטרים בזיכרון במקום ZCA_PARAM
    mo_cut->mt_param_cache = VALUE #( ( name = 'ZCO_HC_SKF_DET'  value = 'HCDET' )
                                      ( name = 'ZCO_POS_SKF_DET' value = 'POSDET' )
                                      ( name = 'ZCO_HC_SKF_TOT'  value = 'HCTOT' )
                                      ( name = 'ZCO_POS_SKF_TOT' value = 'POSTOT' )
                                      ( name = 'B1010001HCD'     value = 'B1HCD' )
                                      ( name = 'B1010001POSD'    value = 'B1POSD' )
                                      ( name = 'B1010001HCT'     value = 'B1HCT' )
                                      ( name = 'B1010001POST'    value = 'B1POST' ) ).
  ENDMETHOD.


  METHOD last_day_of_period.
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260930' ) act = mo_cut->last_day( '2026009' ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20261231' ) act = mo_cut->last_day( '2026012' ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20280229' ) act = mo_cut->last_day( '2028002' ) ).
  ENDMETHOD.


  METHOD budget_level_sums_by_cc.
    " שתי יחידות ארגוניות תחת אותו מרכז עלות תקציבי 100
    DATA(lt_documents) = mo_cut->build_hr_documents(
      it_rows   = VALUE #( ( key_date = '20260930' org_unit = '50000001' cost_center = '100' headcount = 10 )
                           ( key_date = '20260930' org_unit = '50000002' cost_center = '100' headcount = 5 ) )
      it_specs  = mo_cut->get_hr_specs( 'P2' )
      iv_period = '2026009' ).

    cl_abap_unit_assert=>assert_equals( exp = 4 act = lines( lt_documents ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_documents[ 1 ]-items ) ). " ארגוני
    DATA(ls_budget_item) = lt_documents[ 3 ]-items[ 1 ].                                " תקציבי
    cl_abap_unit_assert=>assert_equals( exp = 1       act = lines( lt_documents[ 3 ]-items ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'HCTOT' act = ls_budget_item-statistical_key_figure ).
    cl_abap_unit_assert=>assert_equals( exp = 15      act = ls_budget_item-quantity ).
  ENDMETHOD.


  METHOD location_uses_building.
    DATA(lt_documents) = mo_cut->build_hr_documents(
      it_rows   = VALUE #( ( key_date = '20260930' org_unit = '50000001' cost_center = '100'
                             real_estate_cost_center = 'B1010001' headcount = 3 )
                           ( key_date = '20260930' org_unit = '50000002' cost_center = '100' headcount = 9 ) )
      it_specs  = mo_cut->get_hr_specs( 'P3' )
      iv_period = '2026009' ).

    " השורה ללא בניין לא נכללת
    cl_abap_unit_assert=>assert_equals( exp = 'B1HCD' act = lt_documents[ 1 ]-items[ 1 ]-statistical_key_figure ).
    cl_abap_unit_assert=>assert_equals( exp = 3       act = lt_documents[ 1 ]-items[ 1 ]-quantity ).
  ENDMETHOD.


  METHOD missing_param_stops_run.
    TRY.
        mo_cut->build_hr_documents(
          it_rows   = VALUE #( ( key_date = '20260930' org_unit = '1' real_estate_cost_center = 'B9999999' ) )
          it_specs  = mo_cut->get_hr_specs( 'P3' )
          iv_period = '2026009' ).
        cl_abap_unit_assert=>fail( 'Missing building parameter must stop the run' ).
      CATCH lcx_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
