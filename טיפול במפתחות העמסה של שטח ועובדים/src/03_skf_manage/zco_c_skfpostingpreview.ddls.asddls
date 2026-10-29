// תצוגת ריצת מבחן ב-Fiori (List Report) - "עדכון מפתחות העמסה"
// מציג בדיוק את השורות שה-Job ירשום, מאותו Builder (מקור אמת אחד).
// לנושא P1: מעבר מהשורה לפירוט נתוני השטח (ZCO_RESTATKEYDATADET) לפי מרכז עלות.
@EndUserText.label: 'עדכון מפתחות העמסה - תצוגה מקדימה'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CO_SKF_PREVIEW_QUERY'
@UI.headerInfo: { typeName: 'שורת רישום', typeNamePlural: 'שורות רישום',
                  title: { value: 'StatisticalKeyFigure' }, description: { value: 'CostCenter' } }
define custom entity ZCO_C_SKFPOSTINGPREVIEW
  with parameters
    @EndUserText.label: 'תקופת חתך (YYYYPPP)'
    P_FiscalYearPeriod : fis_jahrper,
    @EndUserText.label: 'נושא'
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCO_I_SkfTopicVH', element: 'Topic' } }]
    P_Topic            : zco_skf_topic
{
      @UI.facet: [ { id: 'Item', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'שורת רישום', position: 10 },
                   { id: 'AreaDetails', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'פירוט נתוני שטח',
                     position: 20, targetElement: '_AreaDetails' } ]
      @UI.hidden: true
  key DocumentIndex        : abap.int4;
      @UI.hidden: true
  key ItemIndex            : abap.int4;

      @UI.lineItem: [{ position: 10 }]
      @EndUserText.label: 'כותרת מסמך'
      HeaderText           : abap.char( 50 );

      @UI.lineItem: [{ position: 20 }]
      @EndUserText.label: 'תאריך רישום'
      PostingDate          : abap.dats;

      @UI.lineItem: [{ position: 30 }]
      @UI.identification: [{ position: 10 }]
      @EndUserText.label: 'מפתח סטטיסטי'
      StatisticalKeyFigure : abap.char( 6 );

      @UI.lineItem: [{ position: 40 }]
      @UI.identification: [{ position: 20 }]
      @EndUserText.label: 'מרכז עלות'
      CostCenter           : abap.char( 10 );

      @UI.lineItem: [{ position: 50 }]
      @EndUserText.label: 'שנה'
      FiscalYear           : abap.numc( 4 );

      @UI.lineItem: [{ position: 60 }]
      @EndUserText.label: 'תקופה'
      FiscalPeriod         : abap.numc( 3 );

      @UI.lineItem: [{ position: 70 }]
      @UI.identification: [{ position: 30 }]
      @EndUserText.label: 'כמות'
      @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
      Quantity             : abap.quan( 16, 3 );

      @EndUserText.label: 'יחידה'
      QuantityUnit         : abap.unit( 3 );

      // TODO(VERIFY): ניווט מ-custom entity ל-CDS רגיל - לבדוק ב-Preview של ה-Service Binding
      _AreaDetails         : association [0..*] to ZCO_RESTATKEYDATADET on _AreaDetails.CostCenter = $projection.CostCenter
                                                                       and _AreaDetails.Meas       = $projection.StatisticalKeyFigure;
}
