// תקציב מול ביצוע + מפתחות סטטיסטיים - אפיון טכני סעיף 22 (חלק שני)
// אותו מהלך כמו ZCO_ActWithSKF, מעל I_FundsMgmtBdgtWthPerdActlCube.
// TODO(VERIFY): שמות השדות ב-I_FundsMgmtBdgtWthPerdActlCube, והאם יש לו פרמטרים - לאמת ב-ADT.
//               טיפוסי ה-cast בענף השני חייבים להתאים לטיפוסים המובנים של הענף הראשון.
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'תקציב מול ביצוע עם מפתחות סטטיסטיים'
@Analytics.dataCategory: #CUBE
@Analytics.internalName: #LOCAL
@Metadata.ignorePropagatedAnnotations: true
define view entity ZFM_BudActWithSKF
  as select from I_FundsMgmtBdgtWthPerdActlCube as Budget
{
  key Budget.FndsMgmtAnalysisSourceTech,
  key Budget.FinancialManagementArea,
  key Budget.CommitmentItem,
  key Budget.BudgetPeriod,
  key Budget.FunctionalArea,
  key Budget.Fund,
  key Budget.FundedProgram,
  key Budget.FundsCenter,
  key Budget.CompanyCode,
  key Budget.GLAccount,
  key Budget.FinMgmtAreaFiscalYear,
  key Budget.FinMgmtAreaPeriod,
  key Budget.FundsMgmtValueType,
  key Budget.BudgetCategory,
  key Budget.BudgetType,
  key Budget.BudgetVersion,
  key Budget.PurchaseOrder,
  key cast( '' as abap.char( 6 ) )                     as StatisticalKeyFigure,
      Budget.ZZ1_BudgetUnitFictr_COS,

      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'FinancialManagementAreaCrcy'
      Budget.BudgetAmountInFMACrcy,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'FinancialManagementAreaCrcy'
      Budget.CmtmtOpenItemAmountInFMACrcy,
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'FinancialManagementAreaCrcy'
      Budget.CtrlgItemAmountInFMACrcy,
      Budget.FinancialManagementAreaCrcy,
      // TODO(VERIFY): שדות הסכום במטבע תנועה (FndsMgmtActlAmountInTransCrcy, CtrlgItemAmountInTransCrcy)
      //               והמטבע שלהם - להוסיף אחרי אימות שם שדה המטבע ב-Cube

      @Aggregation.default: #SUM
      @Semantics.quantity.unitOfMeasure: 'StatisticalKeyFigureUnit'
      cast( 0 as abap.quan( 23, 3 ) )                  as StatisticalKeyFigureQuantity,
      cast( '' as abap.unit( 3 ) )                     as StatisticalKeyFigureUnit
}

union all

select from I_FinStatisticalKeyFigureItem as SkfItem
{
  key cast( '3' as abap.char( 1 ) )                    as FndsMgmtAnalysisSourceTech,
  key cast( '1000' as abap.char( 4 ) )                 as FinancialManagementArea,
  // האפיון: CommitmentItem "ערך מ-I_FinStatisticalKeyFigureItem" - אין שדה כזה ב-SKF; ריק (ראה שאלות פתוחות)
  key cast( '' as abap.char( 24 ) )                    as CommitmentItem,
  key cast( '' as abap.char( 10 ) )                    as BudgetPeriod,
  key cast( '' as abap.char( 16 ) )                    as FunctionalArea,
  key cast( '10' as abap.char( 10 ) )                  as Fund,
  key cast( '' as abap.char( 24 ) )                    as FundedProgram,
  key cast( SkfItem.CostCenter as abap.char( 16 ) )    as FundsCenter,
  key SkfItem.CompanyCode,
  key cast( '' as abap.char( 10 ) )                    as GLAccount,
  key SkfItem.FiscalYear                               as FinMgmtAreaFiscalYear,
  key SkfItem.FiscalPeriod                             as FinMgmtAreaPeriod,
  key cast( '' as abap.char( 2 ) )                     as FundsMgmtValueType,
  key cast( '' as abap.char( 2 ) )                     as BudgetCategory,
  key cast( '' as abap.char( 4 ) )                     as BudgetType,
  key cast( '' as abap.char( 3 ) )                     as BudgetVersion,
  key cast( '' as abap.char( 10 ) )                    as PurchaseOrder,
  key SkfItem.StatisticalKeyFigure,
      cast( SkfItem.CostCenter as abap.char( 16 ) )    as ZZ1_BudgetUnitFictr_COS,

      cast( 0 as abap.curr( 23, 2 ) )                  as BudgetAmountInFMACrcy,
      cast( 0 as abap.curr( 23, 2 ) )                  as CmtmtOpenItemAmountInFMACrcy,
      cast( 0 as abap.curr( 23, 2 ) )                  as CtrlgItemAmountInFMACrcy,
      cast( '' as abap.cuky( 5 ) )                     as FinancialManagementAreaCrcy,

      cast( SkfItem.StatisticalKeyFigureQuantity as abap.quan( 23, 3 ) ) as StatisticalKeyFigureQuantity,
      SkfItem.StatisticalKeyFigureUnit
}
