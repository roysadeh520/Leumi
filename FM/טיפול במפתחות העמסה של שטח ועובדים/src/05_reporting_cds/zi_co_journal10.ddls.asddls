// תנועות פיננסיות מקובצות למרכזי עלות - בסיס לאיחוד עם מפתחות סטטיסטיים (אפיון טכני סעיף 22)
// Ledger 0L, רק שורות עם מרכז עלות, מסוכם (Group By) לפי השדות שבאפיון.
// TODO(VERIFY): שמות השדות/האסוציאציות ב-I_JournalEntryItemCube ובמבטי הטקסט - לאמת ב-ADT
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'תנועות CO מקובצות למרכזי עלות'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_CO_Journal10
  as select from I_JournalEntryItemCube as Journal

  association [0..*] to I_CostCenterText             as _CostCenterText        on  _CostCenterText.ControllingArea = Journal.ControllingArea
                                                                               and _CostCenterText.CostCenter      = Journal.CostCenter
  association [0..*] to I_CostCenterText             as _PartnerCostCenterText on  _PartnerCostCenterText.ControllingArea = Journal.ControllingArea
                                                                               and _PartnerCostCenterText.CostCenter      = Journal.PartnerCostCenter
  association [0..*] to I_CostCenter                 as _CostCenterMaster      on  _CostCenterMaster.ControllingArea = Journal.ControllingArea
                                                                               and _CostCenterMaster.CostCenter      = Journal.CostCenter
  association [0..*] to I_GLAccountText              as _GLAccountText         on  _GLAccountText.ChartOfAccounts = Journal.ChartOfAccounts
                                                                               and _GLAccountText.GLAccount       = Journal.GLAccount
  association [0..*] to I_FunctionalAreaText         as _FunctionalAreaText    on  _FunctionalAreaText.FunctionalArea = Journal.FunctionalArea
  association [0..*] to I_AccountingDocumentTypeText as _DocumentTypeText      on  _DocumentTypeText.AccountingDocumentType = Journal.AccountingDocumentType
{
  key Journal.Ledger,
  key Journal.CompanyCode,
  key Journal.FiscalYear,
  key Journal.FiscalPeriod,
  key Journal.ControllingArea,
  key Journal.BusinessTransactionType,
  key Journal.GLAccount,
  key Journal.CostCenter,
  key Journal.ProfitCenter,
  key Journal.FunctionalArea,
  key Journal.PartnerCostCenter,
  key Journal.AccountingDocumentType,
  key Journal.PurchasingDocument,
  key Journal.PurchasingDocumentItem,
  key Journal.CostCtrActivityType,
  key Journal.OrderID,
  key Journal.CommitmentItem,
  key Journal.FundsCenter,
  key Journal.FundedProgram,
  key Journal.Fund,
  key Journal.BudgetPeriod,

      // ---- טקסטים (שפת המשתמש; מרכז עלות - הגרסה התקפה היום) ----
      Journal._CompanyCode.CompanyCodeName,
      _GLAccountText[1: Language = $session.system_language].GLAccountLongName,
      _CostCenterText[1: Language = $session.system_language
                     and ValidityStartDate <= $session.system_date
                     and ValidityEndDate   >= $session.system_date].CostCenterName,
      _FunctionalAreaText[1: Language = $session.system_language].FunctionalAreaName,
      _PartnerCostCenterText[1: Language = $session.system_language
                            and ValidityStartDate <= $session.system_date
                            and ValidityEndDate   >= $session.system_date].CostCenterName as PartnerCostCenterName,
      _DocumentTypeText[1: Language = $session.system_language].AccountingDocumentTypeName,

      // ---- שדות מותאמים של מרכז העלות ----
      _CostCenterMaster[1: ValidityStartDate <= $session.system_date
                       and ValidityEndDate   >= $session.system_date].ZZ1_Unit_Type_COS,
      _CostCenterMaster[1: ValidityStartDate <= $session.system_date
                       and ValidityEndDate   >= $session.system_date].ZZ1_CC_Class_COS,
      _CostCenterMaster[1: ValidityStartDate <= $session.system_date
                       and ValidityEndDate   >= $session.system_date].ZZ1_IfAllocUnit_COS,

      // ---- סכומים ----
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      sum( Journal.AmountInCompanyCodeCurrency ) as AmountInCompanyCodeCurrency,
      Journal.CompanyCodeCurrency,
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      sum( Journal.Quantity )                    as Quantity,
      Journal.BaseUnit
}
where
      Journal.Ledger     = '0L'
  and Journal.CostCenter <> ''
group by
  Journal.Ledger,
  Journal.CompanyCode,
  Journal.FiscalYear,
  Journal.FiscalPeriod,
  Journal.ControllingArea,
  Journal.BusinessTransactionType,
  Journal.GLAccount,
  Journal.CostCenter,
  Journal.ProfitCenter,
  Journal.FunctionalArea,
  Journal.PartnerCostCenter,
  Journal.AccountingDocumentType,
  Journal.PurchasingDocument,
  Journal.PurchasingDocumentItem,
  Journal.CostCtrActivityType,
  Journal.OrderID,
  Journal.CommitmentItem,
  Journal.FundsCenter,
  Journal.FundedProgram,
  Journal.Fund,
  Journal.BudgetPeriod,
  Journal._CompanyCode.CompanyCodeName,
  _GLAccountText[1: Language = $session.system_language].GLAccountLongName,
  _CostCenterText[1: Language = $session.system_language
                 and ValidityStartDate <= $session.system_date
                 and ValidityEndDate   >= $session.system_date].CostCenterName,
  _FunctionalAreaText[1: Language = $session.system_language].FunctionalAreaName,
  _PartnerCostCenterText[1: Language = $session.system_language
                        and ValidityStartDate <= $session.system_date
                        and ValidityEndDate   >= $session.system_date].CostCenterName,
  _DocumentTypeText[1: Language = $session.system_language].AccountingDocumentTypeName,
  _CostCenterMaster[1: ValidityStartDate <= $session.system_date
                   and ValidityEndDate   >= $session.system_date].ZZ1_Unit_Type_COS,
  _CostCenterMaster[1: ValidityStartDate <= $session.system_date
                   and ValidityEndDate   >= $session.system_date].ZZ1_CC_Class_COS,
  _CostCenterMaster[1: ValidityStartDate <= $session.system_date
                   and ValidityEndDate   >= $session.system_date].ZZ1_IfAllocUnit_COS,
  Journal.CompanyCodeCurrency,
  Journal.BaseUnit
