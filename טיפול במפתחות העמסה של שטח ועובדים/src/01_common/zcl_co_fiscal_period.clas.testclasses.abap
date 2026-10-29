CLASS ltc_fiscal_period DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS last_day_of_september FOR TESTING RAISING cx_static_check.
    METHODS last_day_of_december  FOR TESTING RAISING cx_static_check.
    METHODS last_day_leap_feb     FOR TESTING RAISING cx_static_check.
    METHODS first_day             FOR TESTING RAISING cx_static_check.
    METHODS display_text          FOR TESTING RAISING cx_static_check.
    METHODS rejects_period_13     FOR TESTING.
    METHODS rejects_non_numeric   FOR TESTING.
ENDCLASS.


CLASS ltc_fiscal_period IMPLEMENTATION.

  METHOD last_day_of_september.
    cl_abap_unit_assert=>assert_equals(
      exp = CONV d( '20260930' )
      act = zcl_co_fiscal_period=>from_value( '2026009' )->get_last_day( ) ).
  ENDMETHOD.

  METHOD last_day_of_december.
    cl_abap_unit_assert=>assert_equals(
      exp = CONV d( '20261231' )
      act = zcl_co_fiscal_period=>from_value( '2026012' )->get_last_day( ) ).
  ENDMETHOD.

  METHOD last_day_leap_feb.
    cl_abap_unit_assert=>assert_equals(
      exp = CONV d( '20280229' )
      act = zcl_co_fiscal_period=>from_value( '2028002' )->get_last_day( ) ).
  ENDMETHOD.

  METHOD first_day.
    cl_abap_unit_assert=>assert_equals(
      exp = CONV d( '20260901' )
      act = zcl_co_fiscal_period=>from_value( '2026009' )->get_first_day( ) ).
  ENDMETHOD.

  METHOD display_text.
    cl_abap_unit_assert=>assert_equals(
      exp = `009.2026`
      act = zcl_co_fiscal_period=>from_value( '2026009' )->get_display_text( ) ).
  ENDMETHOD.

  METHOD rejects_period_13.
    TRY.
        zcl_co_fiscal_period=>from_value( '2026013' ).
        cl_abap_unit_assert=>fail( 'Period 013 must be rejected' ).
      CATCH zcx_co_skf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD rejects_non_numeric.
    TRY.
        zcl_co_fiscal_period=>from_value( '2026-09' ).
        cl_abap_unit_assert=>fail( 'Non numeric value must be rejected' ).
      CATCH zcx_co_skf_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
