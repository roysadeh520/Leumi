// "טיפול בתקציב כיבוד בסניפים" (ZCO_REFRESH_BUD) - אפיון טכני סעיפים 17-19
// כמות (עובדים/משרות) לסניף * תעריף כיבוד לסניף (I_PlanCostRate) = תקציב.
// הרשימה ב-Fiori = ריצת מבחן; הכפתור "בצע עדכון" = רישום התקציב (BDEF).
// TODO(VERIFY): שמות השדות ב-I_PlanCostRate (תוקף, מטבע, יחידת מחיר) ומצב השחרור שלו
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'תקציב כיבוד לסניפים'
@Metadata.ignorePropagatedAnnotations: true
@UI.headerInfo: { typeName: 'סניף', typeNamePlural: 'סניפים' }
define root view entity ZCO_REFRESHMENTCOST
  as select from    ZI_CO_BranchSkfQuantity as Quantity

    // סוג הפעילות של הכיבוד - ZCA_PARAM במבנה TVARVC (NAME / LOW)
    inner join      zca_param               as ActivityParam on ActivityParam.name = 'ZCO_REFRESH_ACTTP'

    // סניף ללא תעריף נשאר ברשימה עם תקציב 0 - כדי שיהיה גלוי בריצת מבחן
    // TODO(VERIFY): השוואת ActivityType (CHAR 6) ל-LOW (CHAR 255) בתנאי ה-JOIN
    left outer join I_PlanCostRate          as Rate          on  Rate.ControllingArea               =  Quantity.ControllingArea
                                                             and Rate.CostCenter                    =  Quantity.CostCenter
                                                             and Rate.ActivityType                  =  ActivityParam.low
                                                             and Rate.PlanningCategory              =  'PLN'
                                                             and Rate.ValidityStartFiscalYearPeriod <= Quantity.FiscalYearPeriod
                                                             and Rate.ValidityEndFiscalYearPeriod   >= Quantity.FiscalYearPeriod
{
      @UI.lineItem: [{ position: 10 }, { type: #FOR_ACTION, dataAction: 'postBudget', label: 'בצע עדכון' }]
  key Quantity.CompanyCode,

      @UI.lineItem: [{ position: 20 }]
      @UI.selectionField: [{ position: 10 }]
      @Consumption.filter: { mandatory: true, selectionType: #SINGLE, multipleSelections: false }
      @EndUserText.label: 'תקופת חתך (YYYYPPP)'
  key Quantity.FiscalYearPeriod,

      @UI.lineItem: [{ position: 30 }]
      @UI.selectionField: [{ position: 20 }]
      @Consumption.filter: { mandatory: true, selectionType: #SINGLE, multipleSelections: false, defaultValue: 'HCTOT' }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_StatisticalKeyFigureStdVH', element: 'StatisticalKeyFigure' } }]
      @EndUserText.label: 'מפתח חלוקה (עובדים/משרות)'
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
