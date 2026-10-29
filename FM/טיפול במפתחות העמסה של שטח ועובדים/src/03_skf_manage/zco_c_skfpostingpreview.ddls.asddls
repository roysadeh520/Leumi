// "עדכון מפתחות העמסה" (ZCO_SKF_MANAGE) - Fiori List Report
// הרשימה = ריצת מבחן: בדיוק השורות שיירשמו. הכפתור "בצע עדכון" = ריצת עדכון (BDEF).
// תקופה ונושא הם מסננים חובה (ולא פרמטרים - RAP BO לא תומך ב-CDS עם פרמטרים).
// לנושא P1: מעבר מהשורה לפירוט נתוני השטח (ZCO_RESTATKEYDATADET) לפי מרכז עלות.
@EndUserText.label: 'עדכון מפתחות העמסה'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_CO_SKF_MANAGE'
@UI.headerInfo: { typeName: 'שורת רישום', typeNamePlural: 'שורות רישום',
                  title: { value: 'StatisticalKeyFigure' }, description: { value: 'CostCenter' } }
define root custom entity ZCO_C_SKFPOSTINGPREVIEW
{
      @UI.facet: [ { id: 'Item', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'שורת רישום', position: 10 },
                   { id: 'AreaDetails', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'פירוט נתוני שטח',
                     position: 20, targetElement: '_AreaDetails' } ]
      @UI.selectionField: [{ position: 10 }]
      @Consumption.filter: { mandatory: true, selectionType: #SINGLE, multipleSelections: false }
      @EndUserText.label: 'תקופת חתך (YYYYPPP)'
      // כפתור העדכון ברשימה; התקופה והנושא מוזנים בחלון הפעולה
      @UI.lineItem: [{ type: #FOR_ACTION, dataAction: 'postDocuments', label: 'בצע עדכון' }]
  key FiscalYearPeriod     : fis_jahrper;

      @UI.selectionField: [{ position: 20 }]
      @Consumption.filter: { mandatory: true, selectionType: #SINGLE, multipleSelections: false }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCO_I_SkfTopicVH', element: 'Topic' } }]
      @EndUserText.label: 'נושא'
  key Topic                : zco_skf_topic;

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
