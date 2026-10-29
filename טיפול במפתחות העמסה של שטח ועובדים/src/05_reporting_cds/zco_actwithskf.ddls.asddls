// עלויות בפועל + מפתחות סטטיסטיים באותו דו"ח - אפיון טכני סעיף 22
// Union All (ולא Join - Join היה משכפל שורות): שורה למפתח סטטיסטי לתקופה ברמת מרכז עלות.
// בשורות SKF השדות הפיננסיים ריקים; בשורות פיננסיות שדות ה-SKF ריקים.
// הערה: ב-Union של View Entity הטיפוסים נקבעים לפי הענף הראשון - ה-cast בענף השני חייב
//        להתאים לטיפוס המובנה (built-in) של השדה המקביל. לאמת בהפעלה ולתקן אורכים לפי הצורך.
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'עלויות בפועל עם מפתחות סטטיסטיים'
@Analytics.dataCategory: #CUBE
@Analytics.internalName: #LOCAL
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCO_ActWithSKF
  as select from ZI_CO_Journal10
{
  key Ledger,
  key CompanyCode,
  key FiscalYear,
  key FiscalPeriod,
  key BusinessTransactionType,
  key GLAccount,
  key CostCenter,
  key ProfitCenter,
  key FunctionalArea,
  key PartnerCostCenter,
  key AccountingDocumentType,
  key PurchasingDocument,
  key PurchasingDocumentItem,
  key CostCtrActivityType,
  key OrderID,
  key CommitmentItem,
  key FundsCenter,
  key FundedProgram,
  key Fund,
  key BudgetPeriod,
  key cast( '' as abap.char( 6 ) )              as StatisticalKeyFigure,
      CompanyCodeName,
      GLAccountLongName,
      CostCenterName,
      FunctionalAreaName,
      PartnerCostCenterName,
      AccountingDocumentTypeName,
      ZZ1_Unit_Type_COS,
      ZZ1_CC_Class_COS,
      ZZ1_IfAllocUnit_COS,
      // TODO(OPEN): מקור שדות ההיררכיה PARENTNODE / PARENTNODE2 / COSTCENTERHIERARCHYNAME לא מוגדר באפיון
      cast( '' as abap.char( 50 ) )             as ParentNode,
      cast( '' as abap.char( 50 ) )             as ParentNode2,
      cast( '' as abap.char( 42 ) )             as CostCenterHierarchyName,

      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmountInCompanyCodeCurrency,
      CompanyCodeCurrency,
      @Aggregation.default: #SUM
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      Quantity,
      BaseUnit,
      @Aggregation.default: #SUM
      @Semantics.quantity.unitOfMeasure: 'StatisticalKeyFigureUnit'
      cast( 0 as abap.quan( 23, 3 ) )           as StatisticalKeyFigureQuantity,
      cast( '' as abap.unit( 3 ) )              as StatisticalKeyFigureUnit
}

union all

select from I_FinStatisticalKeyFigureItem as SkfItem
{
  key cast( '0L' as abap.char( 2 ) )            as Ledger,         // האפיון: 'L0' - הונח שהכוונה ל-0L
  key SkfItem.CompanyCode,
  key SkfItem.FiscalYear,
  key SkfItem.FiscalPeriod,
  key cast( '' as abap.char( 4 ) )              as BusinessTransactionType,
  key cast( '' as abap.char( 10 ) )             as GLAccount,
  key SkfItem.CostCenter,
  key cast( '' as abap.char( 10 ) )             as ProfitCenter,
  key cast( '' as abap.char( 16 ) )             as FunctionalArea,
  key cast( '' as abap.char( 10 ) )             as PartnerCostCenter,
  key cast( '' as abap.char( 2 ) )              as AccountingDocumentType,
  key cast( '' as abap.char( 10 ) )             as PurchasingDocument,
  key cast( '00000' as abap.numc( 5 ) )         as PurchasingDocumentItem,
  key cast( '' as abap.char( 6 ) )              as CostCtrActivityType,
  key cast( '' as abap.char( 12 ) )             as OrderID,
  key cast( '' as abap.char( 24 ) )             as CommitmentItem,
  key cast( SkfItem.CostCenter as abap.char( 16 ) ) as FundsCenter,
  key cast( '' as abap.char( 24 ) )             as FundedProgram,
  key cast( '' as abap.char( 10 ) )             as Fund,
  key cast( '' as abap.char( 10 ) )             as BudgetPeriod,
  key SkfItem.StatisticalKeyFigure,
      SkfItem._CompanyCode.CompanyCodeName,
      cast( '' as abap.char( 50 ) )             as GLAccountLongName,
      // האפיון: CostCenterName מ-I_FinStatisticalKeyFigureItem; ריק עד שיאומת שם השדה/האסוציאציה
      cast( '' as abap.char( 20 ) )             as CostCenterName,
      cast( '' as abap.char( 25 ) )             as FunctionalAreaName,
      cast( '' as abap.char( 20 ) )             as PartnerCostCenterName,
      cast( '' as abap.char( 20 ) )             as AccountingDocumentTypeName,
      cast( '' as abap.char( 1 ) )              as ZZ1_Unit_Type_COS,
      cast( '' as abap.char( 2 ) )              as ZZ1_CC_Class_COS,
      cast( '' as abap.char( 1 ) )              as ZZ1_IfAllocUnit_COS,
      cast( '' as abap.char( 50 ) )             as ParentNode,
      cast( '' as abap.char( 50 ) )             as ParentNode2,
      cast( '' as abap.char( 42 ) )             as CostCenterHierarchyName,

      cast( 0 as abap.curr( 23, 2 ) )           as AmountInCompanyCodeCurrency,
      cast( '' as abap.cuky( 5 ) )              as CompanyCodeCurrency,
      cast( 0 as abap.quan( 23, 3 ) )           as Quantity,
      cast( '' as abap.unit( 3 ) )              as BaseUnit,
      cast( SkfItem.StatisticalKeyFigureQuantity as abap.quan( 23, 3 ) ) as StatisticalKeyFigureQuantity,
      SkfItem.StatisticalKeyFigureUnit
}
