// סוג הפעילות של תעריף כיבוד - מתוך ZCA_PARAM (פרמטר ZCO_REFRESH_ACTTP).
// מבודד את מבנה ZCA_PARAM במקום אחד ב-CDS.
// TODO(OPEN): שמות השדות ב-ZCA_PARAM - הונח NAME / VALUE
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'סוג פעילות - תעריף כיבוד'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_CO_RefreshmentActivityType
  as select from zca_param
{
  key cast( substring( value, 1, 6 ) as abap.char( 6 ) ) as ActivityType
}
where
  name = 'ZCO_REFRESH_ACTTP'
