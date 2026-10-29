// פרמטרים לפעולה "בצע עדכון" - חלון שנפתח בלחיצה על הכפתור
@EndUserText.label: 'עדכון מפתחות העמסה - פרמטרים'
define abstract entity ZCO_A_SKFPOSTPARAM
{
  @EndUserText.label: 'תקופת חתך (YYYYPPP)'
  FiscalYearPeriod : fis_jahrper;

  @EndUserText.label: 'נושא'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCO_I_SkfTopicVH', element: 'Topic' } }]
  Topic            : zco_skf_topic;
}
