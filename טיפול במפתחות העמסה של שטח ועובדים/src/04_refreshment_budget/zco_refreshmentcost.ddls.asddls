// תקציב כיבוד לסניפים - אפיון טכני סעיפים 17-19
// כמות (עובדים/משרות) לסניף * תעריף כיבוד לסניף (I_PlanCostRate) = תקציב.
// מוצג בריצת מבחן (Fiori List Report) ומשמש מקור לרישום התקציב.
// TODO(VERIFY): שמות השדות ב-I_PlanCostRate (תוקף, מטבע, יחידת מחיר) ומצב השחרור שלו
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'תקציב כיבוד לסניפים'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZCO_REFRESHMENTCOST
  with parameters
    @EndUserText.label: 'תקופת חתך (YYYYPPP)'
    P_FiscalYearPeriod     : fis_jahrper,
    @EndUserText.label: 'מפתח חלוקה (עובדים/משרות)'
    @Consumption.defaultValue: 'HCTOT'
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_StatisticalKeyFigureStdVH', element: 'StatisticalKeyFigure' } }]
    P_StatisticalKeyFigure : abap.char( 6 )
  as select from    ZI_CO_BranchSkfQuantity( P_FiscalYearPeriod     : $parameters.P_FiscalYearPeriod,
                                             P_StatisticalKeyFigure : $parameters.P_StatisticalKeyFigure ) as Quantity

    cross join      ZI_CO_RefreshmentActivityType                                                         as RefreshmentActivity

    // סניף ללא תעריף נשאר ברשימה עם תקציב 0 - כדי שיהיה גלוי בריצת מבחן
    left outer join I_PlanCostRate                                                                        as Rate on  Rate.ControllingArea               = Quantity.ControllingArea
                                                                                                                  and Rate.CostCenter                    = Quantity.CostCenter
                                                                                                                  and Rate.ActivityType                  = RefreshmentActivity.ActivityType
                                                                                                                  and Rate.PlanningCategory              = 'PLN'
                                                                                                                  and Rate.ValidityStartFiscalYearPeriod <= $parameters.P_FiscalYearPeriod
                                                                                                                  and Rate.ValidityEndFiscalYearPeriod   >= $parameters.P_FiscalYearPeriod
{
      @UI.lineItem: [{ position: 10 }]
  key Quantity.CompanyCode,
      @UI.lineItem: [{ position: 20 }]
  key Quantity.FiscalYearPeriod,
      @UI.lineItem: [{ position: 30 }]
  key Quantity.StatisticalKeyFigure,
      @UI.lineItem: [{ position: 40 }]
  key Quantity.CostCenter,

      @UI.lineItem: [{ position: 50, label: 'כמות' }]
      @Semantics.quantity.unitOfMeasure: 'StatisticalKeyFigureUnit'
      Quantity.StatisticalKeyFigureQuantity,
      Quantity.StatisticalKeyFigureUnit,

      @UI.lineItem: [{ position: 60, label: 'תעריף' }]
      @Semantics.amount.currencyCode: 'Currency'
      Rate.CostRateTotalAmount,

      @UI.lineItem: [{ position: 70, label: 'תקציב' }]
      @Semantics.amount.currencyCode: 'Currency'
      cast( coalesce( get_numeric_value( Rate.CostRateTotalAmount ), 0 )
            * get_numeric_value( Quantity.StatisticalKeyFigureQuantity ) as abap.decfloat34 ) as BudgetAmount,

      Rate.Currency
}
