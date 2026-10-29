// פירוט נתוני שטח - אפיון טכני סעיף 2
// יחידות שכירות (VIBDRO) + מדידות שטח R100/R101 (VIBDMEAS) + כללי ייחוס למרכזי עלות.
// חבילה: ZCO_SKF_WRAPPER (Standard ABAP) - קריאה ישירה לטבלאות RE = Clean Core Level C.
// משוחרר C1 כדי שקוד ה-ABAP Cloud יוכל לצרוך אותו. ראה שאלות פתוחות: חיפוש CDS משוחרר חלופי ל-RE.
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'פירוט נתוני שטח'
@Analytics.dataCategory: #CUBE
@Analytics.internalName: #LOCAL
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: { serviceQuality: #C, sizeCategory: #L, dataClass: #MIXED }
define view entity ZCO_RESTATKEYDATADET
  as select from    vibdro                as RentalObject

    left outer join vibdmeas              as Measurement    on  Measurement.intreno = RentalObject.intreno
                                                            and (
                                                               Measurement.meas     = 'R100'
                                                               or Measurement.meas  = 'R101'
                                                             )

    inner join      I_OrderSettlementRule as SettlementRule on SettlementRule.ControllingObject = RentalObject.objnr
{
      // ---- VIBDRO - יחידת שכירות ----
      // TODO(OPEN): האפיון מבקש "את כל השדות" מהטבלאות - הוכנסו השדות הרלוונטיים; להשלים לפי הצורך
  key RentalObject.intreno                         as Intreno,
  key Measurement.meas                             as Meas,
  key Measurement.validto                          as ValidTo,
      // TODO(OPEN): להוסיף כמפתח את שדה מספר השורה בכלל הייחוס מ-I_OrderSettlementRule (לאמת שם שדה)
      RentalObject.objnr                           as Objnr,
      RentalObject.imkey                           as Imkey,
      RentalObject.xmetxt                          as Xmetxt,
      RentalObject.bukrs                           as CompanyCode,

      // ---- VIBDMEAS - מדידת שטח ----
      Measurement.validfrom                        as ValidFrom,
      @Aggregation.default: #SUM
      @Semantics.quantity.unitOfMeasure: 'MeasUnit'
      Measurement.measvalue                        as MeasValue,
      Measurement.measunit                         as MeasUnit,

      // ---- I_OrderSettlementRule - כלל ייחוס ----
      SettlementRule.AccountAssignmentType         as AccountAssignmentType,
      SettlementRule.CostCenter                    as CostCenter,
      SettlementRule.SettlementPercentageRate      as SettlementPercentageRate,
      SettlementRule.ValidityStartFiscalYear       as ValidityStartFiscalYear,
      SettlementRule.ValidityStartFiscalPeriod     as ValidityStartFiscalPeriod,
      SettlementRule.ValidityEndFiscalYear         as ValidityEndFiscalYear,
      SettlementRule.ValidityEndFiscalPeriod       as ValidityEndFiscalPeriod,

      // תוקף כלל הייחוס כ-YYYYPPP; ללא הגבלה (ריק) = 9999999 - מאפשר סינון פשוט לפי תקופת חתך
      cast( case SettlementRule.ValidityEndFiscalYear
              when '0000' then '9999999'
              else concat( SettlementRule.ValidityEndFiscalYear, SettlementRule.ValidityEndFiscalPeriod )
            end as abap.numc( 7 ) )               as ValidityEndFiscalYearPeriod
}
// כלל ייחוס בתוקף: ללא הגבלה, או תקופת סיום >= התקופה הנוכחית (YYYYPPP)
where
     SettlementRule.ValidityEndFiscalYear = '0000'
  or concat( SettlementRule.ValidityEndFiscalYear, SettlementRule.ValidityEndFiscalPeriod )
       >= concat( substring( $session.system_date, 1, 4 ), concat( '0', substring( $session.system_date, 5, 2 ) ) )
