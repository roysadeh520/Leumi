// עזרת חיפוש לפרמטר "נושא" (P1/P2/P3) - מבוססת על ערכים קבועים של הדומיין ZCO_SKF_TOPIC
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'נושא עדכון מפתחות העמסה - עזרת חיפוש'
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.dataCategory: #VALUE_HELP
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCO_I_SkfTopicVH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZCO_SKF_TOPIC' )
{
      @ObjectModel.text.element: [ 'TopicText' ]
  key cast( value_low as zco_skf_topic ) as Topic,

      @Semantics.text: true
      text                               as TopicText
}
where
  language = $session.system_language
