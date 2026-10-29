// סיכום נתוני שטח - אפיון טכני סעיף 3
// מבט מצומצם מעל ZCO_RESTATKEYDATADET, מסוכם לפי מרכז עלות / סוג מדידה / תקופת תוקף.
// מקור הנתונים לרישום מפתחות שטח (אופציה P1).
// חבילה: ZCO_SKF_WRAPPER, משוחרר C1.
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'סיכום נתוני שטח'
@Analytics.dataCategory: #CUBE
@Analytics.internalName: #LOCAL
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCO_RESTATKEYDATATOT
  as select from ZCO_RESTATKEYDATADET
{
  key Objnr,
  key Imkey,
  key AccountAssignmentType,
  key CostCenter,
  key Meas,
  key ValidFrom,
  key ValidTo,
      Xmetxt,
      // נדרש לסינון תקופת חתך בריצת עדכון (סעיף 8) - לא הופיע בטבלת השדות של סעיף 3
      ValidityEndFiscalYear,
      ValidityEndFiscalPeriod,
      ValidityEndFiscalYearPeriod,

      @Aggregation.default: #SUM
      @Semantics.quantity.unitOfMeasure: 'MeasUnit'
      sum( MeasValue ) as MeasValue,
      MeasUnit
}
group by
  Objnr,
  Imkey,
  AccountAssignmentType,
  CostCenter,
  Meas,
  ValidFrom,
  ValidTo,
  Xmetxt,
  ValidityEndFiscalYear,
  ValidityEndFiscalPeriod,
  ValidityEndFiscalYearPeriod,
  MeasUnit
