// כמות מפתח סטטיסטי לסניף לתקופה - אפיון טכני סעיף 17
// סכום STATISTICALKEYFIGUREQUANTITY לפי מרכז עלות, רק סניפים (ZZ1_Unit_Type_COS = '1').
// TODO(VERIFY): שמות השדות ב-I_FinStatisticalKeyFigureItem (בעיקר שדה היחידה) ומצב השחרור שלו
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'כמות מפתח סטטיסטי לסניף'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_CO_BranchSkfQuantity
  as select from I_FinStatisticalKeyFigureItem as SkfItem

    // האפיון: right join עם I_CostCenter = רק סניפים. inner join נותן אותה תוצאה (סינון)
    inner join   I_CostCenter                  as Branch on  Branch.ControllingArea   = SkfItem.ControllingArea
                                                         and Branch.CostCenter        = SkfItem.CostCenter
                                                         and Branch.ZZ1_Unit_Type_COS = '1'
{
  key SkfItem.ControllingArea,
  key SkfItem.CompanyCode,
  key SkfItem.FiscalYearPeriod,
  key SkfItem.StatisticalKeyFigure,
  key SkfItem.CostCenter,

      @Semantics.quantity.unitOfMeasure: 'StatisticalKeyFigureUnit'
      sum( SkfItem.StatisticalKeyFigureQuantity ) as StatisticalKeyFigureQuantity,
      SkfItem.StatisticalKeyFigureUnit
}
// מרכז עלות בתוקף ביום הראשון של התקופה (I_CostCenter תלוי-זמן)
where
      Branch.ValidityStartDate <= cast( concat( substring( SkfItem.FiscalYearPeriod, 1, 4 ),
                                                concat( substring( SkfItem.FiscalYearPeriod, 6, 2 ), '01' ) ) as abap.dats )
  and Branch.ValidityEndDate   >= cast( concat( substring( SkfItem.FiscalYearPeriod, 1, 4 ),
                                                concat( substring( SkfItem.FiscalYearPeriod, 6, 2 ), '01' ) ) as abap.dats )
group by
  SkfItem.ControllingArea,
  SkfItem.CompanyCode,
  SkfItem.FiscalYearPeriod,
  SkfItem.StatisticalKeyFigure,
  SkfItem.CostCenter,
  SkfItem.StatisticalKeyFigureUnit
