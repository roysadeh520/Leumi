"! טיפוסים וקבועים של אפליקציית "עדכון מפתחות העמסה" (ZCO_SKF_MANAGE).
INTERFACE zif_co_skf_types
  PUBLIC.

  "! נושא הריצה - ערכים קבועים בדומיין ZCO_SKF_TOPIC
  TYPES ty_topic TYPE zco_skf_topic.

  CONSTANTS:
    BEGIN OF c_topic,
      area                  TYPE ty_topic VALUE 'P1', " נתוני שטח
      headcount_by_budget   TYPE ty_topic VALUE 'P2', " עובדים ומשרות לפי שיוך תקציבי וארגוני
      headcount_by_location TYPE ty_topic VALUE 'P3', " עובדים ומשרות לפי מיקום נדל"ן
    END OF c_topic.

  TYPES ty_documents TYPE zif_co_skf_poster=>ty_documents.

  "! שורת שטח מ-ZCO_RESTATKEYDATATOT
  TYPES:
    BEGIN OF ty_area_row,
      cost_center   TYPE c LENGTH 10,
      meas          TYPE c LENGTH 4,
      meas_value    TYPE zif_co_skf_poster=>ty_quantity,
      meas_unit     TYPE c LENGTH 3,
      valid_from    TYPE d,
      valid_to      TYPE d,
    END OF ty_area_row,
    ty_area_rows TYPE STANDARD TABLE OF ty_area_row WITH EMPTY KEY.

  "! שורת עובדים/משרות מ-ZC_HR_BudgetReport (CDS של צוות HR)
  TYPES:
    BEGIN OF ty_hr_row,
      key_date                TYPE d,
      org_unit                TYPE c LENGTH 10,
      cost_center             TYPE c LENGTH 10,
      real_estate_cost_center TYPE c LENGTH 10,
      headcount               TYPE zif_co_skf_poster=>ty_quantity,
      total_positions         TYPE zif_co_skf_poster=>ty_quantity,
    END OF ty_hr_row,
    ty_hr_rows TYPE STANDARD TABLE OF ty_hr_row WITH EMPTY KEY.

ENDINTERFACE.
