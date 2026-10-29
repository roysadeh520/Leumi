// פרמטרים לפעולה "בצע עדכון" של תקציב הכיבוד (סעיף 16)
@EndUserText.label: 'תקציב כיבוד - פרמטרים'
define abstract entity ZCO_A_REFRESHBUDPARAM
{
  @EndUserText.label: 'תקופת חתך (YYYYPPP)'
  FiscalYearPeriod     : fis_jahrper;

  @EndUserText.label: 'מפתח חלוקה (עובדים/משרות)'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_StatisticalKeyFigureStdVH', element: 'StatisticalKeyFigure' } }]
  StatisticalKeyFigure : abap.char( 6 );

  @EndUserText.label: 'פריט התחייבות'
  CommitmentItem       : abap.char( 24 );

  @EndUserText.label: 'יחידה תקציבית (מקור)'
  SourceFundsCenter    : abap.char( 16 );
}
