"! קריאת נתוני המקור מה-CDS-ים (שטח: ZCO_RESTATKEYDATATOT, עובדים: ZC_HR_BudgetReport).
CLASS zcl_co_skf_source DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_co_skf_source.
ENDCLASS.



CLASS zcl_co_skf_source IMPLEMENTATION.

  METHOD zif_co_skf_source~read_area_rows.
    DATA(lv_cutoff)    = io_period->get_value( ).
    DATA(lv_first_day) = io_period->get_first_day( ).
    DATA(lv_last_day)  = io_period->get_last_day( ).

    " סעיף 8: כלל ייחוס ללא הגבלה או בתוקף עד תקופת החתך ואילך.
    " בנוסף: רק מדידות שתקפות בתקופת החתך - אחרת יירשמו גם מדידות היסטוריות (ראה שאלות פתוחות)
    SELECT FROM zco_restatkeydatatot
      FIELDS costcenter AS cost_center,
             meas,
             measvalue  AS meas_value,
             measunit   AS meas_unit,
             validfrom  AS valid_from,
             validto    AS valid_to
      WHERE validityendfiscalyearperiod >= @lv_cutoff
        AND validfrom                   <= @lv_last_day
        AND validto                     >= @lv_first_day
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.


  METHOD zif_co_skf_source~read_hr_rows.
    DATA(lv_first_day) = io_period->get_first_day( ).
    DATA(lv_last_day)  = io_period->get_last_day( ).

    " TODO(VERIFY): שמות השדות ב-ZC_HR_BudgetReport (CDS של צוות HR) והאם יש לו פרמטרים
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

ENDCLASS.
