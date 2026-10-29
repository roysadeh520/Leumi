# טיפול במפתחות העמסה: שטח, עובדים ומשרות - מסמך פיתוח

מסמך זה מפרט את **כל האובייקטים שצריך ליצור** ואת **סדר הפעולות**, על בסיס `אפיון.txt`.
הקוד נמצא בתיקייה `src/`. שאלות ונקודות לא ברורות מרוכזות ב-[`שאלות פתוחות.md`](./שאלות%20פתוחות.md).

> **שימו לב:** הקוד נכתב מתוך האפיון, ללא גישה למערכת SAP. הוא לא עבר הפעלה (Activation).
> מקומות שבהם צריך לאמת שם שדה או חתימה במערכת מסומנים ב-`TODO(VERIFY)`.
> החלטות שמחכות לתשובה עסקית מסומנות ב-`TODO(OPEN)`.

---

## 1. ארכיטקטורה והחלטות Clean Core

| רכיב | פתרון | רמת Clean Core | נימוק |
|---|---|---|---|
| ריכוז נתוני שטח | CDS (`ZCO_RESTATKEYDATADET`, `ZCO_RESTATKEYDATATOT`) | **C** | האפיון קורא ישירות את הטבלאות `VIBDRO` ו-`VIBDMEAS`, שאינן משוחררות. אם יימצא CDS משוחרר של RE, הרמה עולה ל-A (שאלה 1). |
| רישום מפתחות סטטיסטיים | ABAP Wrapper מעל `BAPI_ACC_STAT_KEY_FIG_POST` | **B** | API קלאסי ומתועד. האפיון עצמו קבע "נהיה ב-B". |
| רישום תקציב כיבוד | ABAP Wrapper מעל `BAPI_0050_CREATE` | **B** | לפי האפיון, `BudgetEntryDocFM.CREATE` (Level A) לא תומך בתקציב תקופתי. |
| לוגיקה, Jobs, תצוגות Fiori, CDS דו"חות | ABAP for Cloud Development | **A** | משתמשים רק ב-APIs משוחררים וב-Wrappers משוחררים (C1). |

### למה Application Job ולא RAP Action?
- רישום ב-BAPI קלאסי מחייב `COMMIT WORK`. בתוך RAP (interaction phase או save sequence) אסור לבצע COMMIT, ולכן הרישום חייב לרוץ ב-LUW נפרד.
- Application Job מתאים לסגירת תקופה. האפיון מבקש גם אפשרות לתזמון עתידי, וה-Job תומך בזה מובנית: תזמון, לוג והרשאה דרך קטלוג.
- זהו גם המבנה הקבוע של הצוות: `TEST_RUN`, Application Log ו-Catalog Entry + Template.

### איך זה נראה למשתמש
לכל אפליקציה יש **שני אריחים** באותו Business Catalog:
1. **תצוגה (ריצת מבחן)**: Fiori Elements List Report. המשתמש מזין תקופה ונושא ורואה בדיוק את השורות שיירשמו.
2. **הפעלה (ריצת עדכון)**: אפליקציית Application Jobs עם Template, שבו ריצת מבחן מסומנת כברירת מחדל. הלוג מוצג מתוך ה-Job.

התצוגה וה-Job משתמשים **באותה מחלקת Builder**. כך מה שמוצג בריצת מבחן הוא בדיוק מה שנרשם, ויש מקור אמת אחד.

```
                    ┌───────────────────────── ZCO_SKF (ABAP Cloud, Level A) ─────────────────────────┐
 Fiori LR  ──OData──▶ ZCO_C_SKFPOSTINGPREVIEW ─▶ ZCL_CO_SKF_PREVIEW_QUERY ─┐
                                                                           ├─▶ ZCL_CO_SKF_DOC_BUILDER ─▶ ZIF_CO_SKF_SOURCE ─▶ CDS
 App Job   ─────────▶ ZCL_CO_SKF_MANAGE_JOB ───────────────────────────────┘            │
                              │                                                         └─▶ ZIF_CO_PARAM_PROVIDER ─▶ ZCA_PARAM
                              └─▶ ZIF_CO_SKF_POSTER ───────────────────────────────────────────────────────────────┐
                    └──────────────────────────────────────────────────────────────────────────────────────────┘  │
                    ┌──────────── ZCO_SKF_WRAPPER (Standard ABAP, Level B/C, משוחרר C1) ──────────┐               │
                    │ ZCL_CO_SKF_POSTER_BAPI ─▶ BAPI_ACC_STAT_KEY_FIG_CHECK / _POST  ◀────────────┼───────────────┘
                    │ ZCL_FM_BUDGET_POSTER_BAPI ─▶ BAPI_0050_CREATE                               │
                    │ ZCO_RESTATKEYDATADET / TOT ─▶ VIBDRO, VIBDMEAS, I_OrderSettlementRule        │
                    └──────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. טבלאות

**לא נדרשות טבלאות DB חדשות.**
- הנתונים העסקיים נשמרים במסמכים סטנדרטיים: מסמכי מפתחות סטטיסטיים ב-CO ומסמכי תקציב ב-FM.
- הפרמטרים נשמרים בטבלה הקיימת `ZCA_PARAM`.
- היסטוריית הריצות נשמרת ב-Application Log של ה-Job.

אם יוחלט שצריך מנגנון שמונע רישום כפול של אותה תקופה (שאלה 6), תידרש טבלת סטטוס. היא מפורטת בשאלה עצמה.

---

## 3. רשימת אובייקטים - לפי סדר יצירה

### שלב 0 - הגדרות (מיישם CO/FM, לא פיתוח)
| # | מה | פירוט |
|---|---|---|
| 0.1 | מפתחות סטטיסטיים - שטח | `R100`, `R101` (מזהה מפתח = סוג המדידה ב-RE, ראה שאלה 4) |
| 0.2 | מפתחות סטטיסטיים - עובדים/משרות | `HCDET`, `POSDET`, `HCTOT`, `POSTOT` |
| 0.3 | מפתחות סטטיסטיים - לכל בניין | 4 מפתחות לכל בניין רלוונטי |
| 0.4 | `ZCA_PARAM` | `ZCO_HC_SKF_DET`=HCDET, `ZCO_POS_SKF_DET`=POSDET, `ZCO_HC_SKF_TOT`=HCTOT, `ZCO_POS_SKF_TOT`=POSTOT, `ZCO_REFRESH_ACTTP`, `ZFM_REFRESH_BUDDOC`, `ZFM_UPD_BUDTYPE`=Y150, ולכל בניין `<מרכז עלות>HCD/HCT/POSD/POST` (לדוגמה `B1010001POSD`) |
| 0.5 | סוג פעילות כיבוד + תעריפים | "נהל סוגי פעילות" + "ערוך מחירים עבור סוגי פעילות" לכל סניף |
| 0.6 | שיוך יחידות ארגוניות | תחזוקה באפליקציית HR (תנאי מוקדם לפי האפיון) |

### שלב 1 - חבילות (Packages)
| חבילה | גרסת שפה | תוכן |
|---|---|---|
| `ZCO_SKF_WRAPPER` | **Standard ABAP** | Wrappers ו-CDS שקוראים אובייקטים לא משוחררים. כל אובייקט משוחרר ב-**C1 - Use in Cloud Development** |
| `ZCO_SKF` | **ABAP for Cloud Development** | כל השאר |

### שלב 2 - אובייקטי DDIC ותשתית (חבילה `ZCO_SKF`)
| # | סוג | שם | פירוט |
|---|---|---|---|
| 2.1 | Domain | `ZCO_SKF_TOPIC` | CHAR 2, ערכים קבועים: `P1` נתוני שטח, `P2` נתוני עובדים לפי שיוך תקציבי, `P3` נתוני עובדים לפי מיקום נדל"ן |
| 2.2 | Data Element | `ZCO_SKF_TOPIC` | על הדומיין, תווית "נושא" |
| 2.3 | Message Class | `ZCO_SKF` | `000` `&1&2&3&4` · `001` פרמטר &1 לא מתוחזק בטבלה ZCA_PARAM · `002` תקופת חתך &1 אינה תקינה (YYYYPPP, תקופות 001-012) · `003` נושא &1 אינו נתמך |
| 2.4 | Application Log Object | `ZCO_SKF` | תת-אובייקטים: `MANAGE`, `REFRESH_BUD` |

### שלב 3 - Wrappers (חבילה `ZCO_SKF_WRAPPER`, Standard ABAP, שחרור C1)
| # | סוג | שם | קובץ |
|---|---|---|---|
| 3.1 | Interface | `ZIF_CO_BAPI_MESSAGES` | `src/00_wrappers_tier_b/zif_co_bapi_messages.intf.abap` |
| 3.2 | Interface | `ZIF_CO_SKF_POSTER` | `src/00_wrappers_tier_b/zif_co_skf_poster.intf.abap` |
| 3.3 | Class | `ZCL_CO_SKF_POSTER_BAPI` | `src/00_wrappers_tier_b/zcl_co_skf_poster_bapi.clas.abap` |
| 3.4 | Interface | `ZIF_FM_BUDGET_POSTER` | `src/00_wrappers_tier_b/zif_fm_budget_poster.intf.abap` |
| 3.5 | Class | `ZCL_FM_BUDGET_POSTER_BAPI` | `src/00_wrappers_tier_b/zcl_fm_budget_poster_bapi.clas.abap` |

**שחרור:** בכל אובייקט, בלשונית API State, מוסיפים Release Contract **C1** עם Visibility "Use in Cloud Development".

### שלב 4 - רכיבים משותפים (חבילה `ZCO_SKF`)
| # | סוג | שם | תפקיד | קובץ |
|---|---|---|---|---|
| 4.1 | Exception Class | `ZCX_CO_SKF_ERROR` | חריגה עסקית אחידה | `src/01_common/zcx_co_skf_error.clas.abap` |
| 4.2 | Class + Unit Test | `ZCL_CO_FISCAL_PERIOD` | תקופת חתך: שנה, תקופה, יום ראשון ואחרון, טקסט לתצוגה | `src/01_common/zcl_co_fiscal_period.clas*.abap` |
| 4.3 | Interface | `ZIF_CO_PARAM_PROVIDER` | חוזה לקריאת פרמטרים | `src/01_common/zif_co_param_provider.intf.abap` |
| 4.4 | Class | `ZCL_CO_PARAM_PROVIDER` | קריאה מ-ZCA_PARAM + מטמון | `src/01_common/zcl_co_param_provider.clas.abap` |
| 4.5 | Class | `ZCL_CO_JOB_LOG` | Application Log (BALI) משותף ל-Jobs | `src/01_common/zcl_co_job_log.clas.abap` |
| 4.6 | CDS (Value Help) | `ZCO_I_SkfTopicVH` | עזרת חיפוש לנושא | `src/01_common/zco_i_skftopicvh.ddls.asddls` |

> `ZCA_PARAM` צריכה להיות נגישה מ-ABAP Cloud: הטבלה בגרסת שפה Cloud, או משוחררת C1. ראה שאלה 2.

### שלב 5 - CDS נתוני שטח (חבילה `ZCO_SKF_WRAPPER`, שחרור C1)
| # | סוג | שם | סעיף באפיון | קובץ |
|---|---|---|---|---|
| 5.1 | CDS View Entity, Cube | `ZCO_RESTATKEYDATADET` "פירוט נתוני שטח" | 2, 4 | `src/02_area_cds/zco_restatkeydatadet.ddls.asddls` |
| 5.2 | CDS View Entity, Cube | `ZCO_RESTATKEYDATATOT` "סיכום נתוני שטח" | 3, 4 | `src/02_area_cds/zco_restatkeydatatot.ddls.asddls` |

שני ה-CDS מוגדרים כאנליטיים (`@Analytics.dataCategory: #CUBE`), כך שהם זמינים גם בשאילתות.

### שלב 6 - אפליקציה 1: "עדכון מפתחות העמסה" `ZCO_SKF_MANAGE` (חבילה `ZCO_SKF`)
| # | סוג | שם | תפקיד | קובץ |
|---|---|---|---|---|
| 6.1 | Interface | `ZIF_CO_SKF_TYPES` | טיפוסים + קבועי נושא P1/P2/P3 | `src/03_skf_manage/zif_co_skf_types.intf.abap` |
| 6.2 | Interface | `ZIF_CO_SKF_SOURCE` | חוזה לקריאת נתוני מקור | `src/03_skf_manage/zif_co_skf_source.intf.abap` |
| 6.3 | Class | `ZCL_CO_SKF_SOURCE` | SELECT מ-`ZCO_RESTATKEYDATATOT` ו-`ZC_HR_BudgetReport` | `src/03_skf_manage/zcl_co_skf_source.clas.abap` |
| 6.4 | Class + Unit Test | `ZCL_CO_SKF_DOC_BUILDER` | **לב הלוגיקה**: בניית מסמכי הרישום לכל נושא (סעיפים 6-14) | `src/03_skf_manage/zcl_co_skf_doc_builder.clas*.abap` |
| 6.5 | Class (Application Job) | `ZCL_CO_SKF_MANAGE_JOB` | ריצת מבחן / עדכון + לוג | `src/03_skf_manage/zcl_co_skf_manage_job.clas.abap` |
| 6.6 | CDS Custom Entity | `ZCO_C_SKFPOSTINGPREVIEW` | תצוגת ריצת מבחן, כולל מעבר לפירוט שטח | `src/03_skf_manage/zco_c_skfpostingpreview.ddls.asddls` |
| 6.7 | Class (Query Provider) | `ZCL_CO_SKF_PREVIEW_QUERY` | ממלא את ה-Custom Entity מתוך ה-Builder | `src/03_skf_manage/zcl_co_skf_preview_query.clas.abap` |
| 6.8 | Service Definition | `ZCO_UI_SKF_MANAGE` | חושף תצוגה, סיכום ופירוט שטח ועזרת חיפוש | `src/03_skf_manage/zco_ui_skf_manage.srvd.srvdsrv` |
| 6.9 | Service Binding | `ZCO_UI_SKF_MANAGE_O4` | OData V4 - UI → Publish | (נוצר ב-ADT) |
| 6.10 | Fiori Elements App | `zco_skf_manage` | List Report על `SkfPostingPreview`. נוצר ב-BAS ונפרס ל-BSP | (נוצר ב-BAS) |
| 6.11 | Application Job Catalog Entry | `ZCO_SKF_MANAGE` | Class = `ZCL_CO_SKF_MANAGE_JOB`. פרמטרים: `FISCAL_YEAR_PERIOD` (חובה), `TOPIC` (חובה, single), `TEST_RUN` (checkbox) | (נוצר ב-ADT) |
| 6.12 | Application Job Template | `ZCO_SKF_MANAGE` | `TEST_RUN = X`, `TOPIC = P1` | (נוצר ב-ADT) |
| 6.13 | IAM App + Business Catalog | `ZCO_SKF_MANAGE` | אפליקציית ה-Fiori + Catalog Entry | (נוצר ב-ADT) |
| 6.14 | Launchpad | 2 אריחים | "עדכון מפתחות העמסה - תצוגה" ו-"עדכון מפתחות העמסה - הפעלה" (Application Jobs מסונן ל-Template) | (Launchpad Designer / App Descriptor) |

**הלוגיקה לפי נושא** (`ZCL_CO_SKF_DOC_BUILDER`):

| נושא | מקור | מסמכים | מפתח סטטיסטי | מרכז עלות | כמות | תאריך רישום |
|---|---|---|---|---|---|---|
| P1 שטח | `ZCO_RESTATKEYDATATOT` | 1 | `MEAS` | `COSTCENTER` | `MEASVALUE` | יום אחרון בתקופה |
| P2 עובדים, ארגוני | `ZC_HR_BudgetReport` | 1 | `ZCA_PARAM` `ZCO_HC_SKF_DET` | `ORGUNIT` | `HEADCOUNT` | `KEYDATE` |
| P2 משרות, ארגוני | 〃 | 1 | `ZCO_POS_SKF_DET` | `ORGUNIT` | `TOTALPOSITIONS` | `KEYDATE` |
| P2 עובדים, תקציבי | 〃 (סיכום לפי KEYDATE + COSTCENTER) | 1 | `ZCO_HC_SKF_TOT` | `COSTCENTER` | `HEADCOUNT` | `KEYDATE` |
| P2 משרות, תקציבי | 〃 | 1 | `ZCO_POS_SKF_TOT` | `COSTCENTER` | `TOTALPOSITIONS` | `KEYDATE` |
| P3 עובדים, ארגוני | 〃 | 1 | `<בניין>HCD` | `ORGUNIT` | `HEADCOUNT` | `KEYDATE` |
| P3 משרות, ארגוני | 〃 | 1 | `<בניין>POSD` | `ORGUNIT` | `TOTALPOSITIONS` | `KEYDATE` |
| P3 עובדים, תקציבי | 〃 (סיכום לפי KEYDATE + בניין + COSTCENTER) | 1 | `<בניין>HCT` | `COSTCENTER` | `HEADCOUNT` | `KEYDATE` |
| P3 משרות, תקציבי | 〃 | 1 | `<בניין>POST` | `COSTCENTER` | `TOTALPOSITIONS` | `KEYDATE` |

איזור בקרה קבוע `1000`, תאריך מסמך = היום, וכותרות המסמכים לפי האפיון.

### שלב 7 - אפליקציה 2: "טיפול בתקציב כיבוד בסניפים" `ZCO_REFRESH_BUD` (חבילה `ZCO_SKF`)
| # | סוג | שם | תפקיד | קובץ |
|---|---|---|---|---|
| 7.1 | CDS View Entity | `ZI_CO_RefreshmentActivityType` | סוג פעילות כיבוד מ-ZCA_PARAM | `src/04_refreshment_budget/zi_co_refreshmentactivitytype.ddls.asddls` |
| 7.2 | CDS View Entity (פרמטרים) | `ZI_CO_BranchSkfQuantity` | כמות SKF לסניף (סעיף 17) | `src/04_refreshment_budget/zi_co_branchskfquantity.ddls.asddls` |
| 7.3 | CDS View Entity (פרמטרים) | `ZCO_REFRESHMENTCOST` | כמות × תעריף = תקציב (סעיפים 18-19) | `src/04_refreshment_budget/zco_refreshmentcost.ddls.asddls` |
| 7.4 | Class + Unit Test | `ZCL_FM_REFRESH_BUDGET_BUILDER` | בניית מסמך התקציב (סעיף 21) | `src/04_refreshment_budget/zcl_fm_refresh_budget_builder.clas*.abap` |
| 7.5 | Class (Application Job) | `ZCL_CO_REFRESH_BUD_JOB` | ריצת מבחן (TESTRUN של ה-BAPI) / עדכון + לוג | `src/04_refreshment_budget/zcl_co_refresh_bud_job.clas.abap` |
| 7.6 | Service Definition | `ZCO_UI_REFRESH_BUD` | חושף את `ZCO_REFRESHMENTCOST` | `src/04_refreshment_budget/zco_ui_refresh_bud.srvd.srvdsrv` |
| 7.7 | Service Binding | `ZCO_UI_REFRESH_BUD_O4` | OData V4 - UI | (ADT) |
| 7.8 | Fiori Elements App | `zco_refresh_bud` | List Report עם פרמטרים: תקופת חתך ומפתח חלוקה (ברירת מחדל HCTOT) | (BAS) |
| 7.9 | Catalog Entry + Template | `ZCO_REFRESH_BUD` | פרמטרים: `FISCAL_YEAR_PERIOD`, `STATISTICAL_KEY_FIGURE` (ברירת מחדל HCTOT), `COMMITMENT_ITEM`, `SOURCE_FUNDS_CENTER`, `TEST_RUN` | (ADT) |
| 7.10 | IAM App + Business Catalog **נפרד** | `ZCO_REFRESH_BUD` | הפרדת הרשאות לפי סעיף 15 | (ADT) |
| 7.11 | Launchpad | 2 אריחים | תצוגה + הפעלה | |

### שלב 8 - CDS לדו"חות (חבילה `ZCO_SKF`)
| # | סוג | שם | תפקיד | קובץ |
|---|---|---|---|---|
| 8.1 | CDS View Entity | `ZI_CO_Journal10` | תנועות 0L עם מרכז עלות, מקובצות + טקסטים | `src/05_reporting_cds/zi_co_journal10.ddls.asddls` |
| 8.2 | CDS Cube (Union All) | `ZCO_ActWithSKF` | עלויות + מפתחות סטטיסטיים | `src/05_reporting_cds/zco_actwithskf.ddls.asddls` |
| 8.3 | CDS Cube (Union All) | `ZFM_BudActWithSKF` | תקציב מול ביצוע + מפתחות סטטיסטיים | `src/05_reporting_cds/zfm_budactwithskf.ddls.asddls` |

### שלב 9 - הרשאות (סעיף 23)
- להוסיף את שני ה-Business Catalogs לרולים המתאימים, כל אחד בנפרד.
- ה-CDS-ים מוגדרים כרגע `#NOT_REQUIRED`. ראה שאלה 15 בנוגע ל-DCL לפי מרכז עלות.

---

## 4. עקרונות Clean Code שיושמו
| עיקרון | איפה |
|---|---|
| **אחריות יחידה (SRP)** | קריאת נתונים (`*_SOURCE`), בניית מסמכים (`*_BUILDER`), רישום (`*_POSTER`), תזמור (`*_JOB`), לוג (`ZCL_CO_JOB_LOG`) ותקופה (`ZCL_CO_FISCAL_PERIOD`) מופרדים כל אחד למחלקה משלו |
| **היפוך תלויות (DIP)** | הלוגיקה תלויה בממשקים (`ZIF_CO_SKF_SOURCE`, `ZIF_CO_PARAM_PROVIDER`, `ZIF_CO_SKF_POSTER`, `ZIF_FM_BUDGET_POSTER`) ומקבלת אותם בהזרקה דרך הקונסטרקטור |
| **בידוד אובייקטים לא משוחררים** | כל מה שאינו Level A יושב רק בחבילת `ZCO_SKF_WRAPPER`, מאחורי ממשק. מעבר עתידי ל-API משוחרר = החלפת מימוש בלבד |
| **מקור אמת אחד (DRY)** | תצוגת ה-Fiori וה-Job משתמשים באותו Builder. ארבעת המסמכים של P2/P3 מוגדרים כטבלת הגדרות (`ty_hr_document_spec`) ולא כקוד משוכפל |
| **ללא מספרי קסם** | כל הערכים הקבועים מהאפיון (`1000`, `F9`, `B1`, `ILS`, `ENTR`, סיומות בניין, שמות פרמטרים) מוגדרים כקבועים עם שם |
| **Fail fast** | כל המסמכים נבנים לפני הרישום. פרמטר חסר עוצר את הריצה לפני שנרשם משהו |
| **שמות משמעותיים, מתודות קצרות** | כל מתודה עושה דבר אחד, והשם שלה אומר מה |
| **בדיקות יחידה** | ABAP Unit ל-`ZCL_CO_FISCAL_PERIOD`, ל-`ZCL_CO_SKF_DOC_BUILDER` ול-`ZCL_FM_REFRESH_BUDGET_BUILDER` עם Test Doubles, בלי DB |
| **ABAP Cloud** | `cl_abap_context_info` במקום `sy-datum`/`sy-uname` בקוד הענן, ו-BALI במקום BAL קלאסי |

---

## 5. בדיקות (סעיף 24)
| # | בדיקה | צפי |
|---|---|---|
| 1 | ABAP Unit על שלוש המחלקות (Ctrl+Shift+F10) | כל הבדיקות עוברות |
| 2 | P1 ריצת מבחן בתצוגה, תקופה 2026009 | שורה לכל מרכז עלות × R100/R101, תאריך רישום 30.09.2026 |
| 3 | P1 ריצת מבחן ב-Job | בלוג: המסמך, השורות והודעות `BAPI_ACC_STAT_KEY_FIG_CHECK`. לא נרשם דבר |
| 4 | P1 ריצת עדכון | מסמך CO נרשם. לבדוק ב-KB33N / "Display Statistical Key Figures" |
| 5 | P2 ריצת עדכון | 4 מסמכים. הסכום ברמה התקציבית שווה לסכום היחידות הארגוניות |
| 6 | P3 עם בניין שחסר לו פרמטר ב-ZCA_PARAM | הריצה נעצרת עם הודעה 001 ולא נרשם דבר |
| 7 | P3 עובד ללא בניין | לא נכלל |
| 8 | תקציב כיבוד, ריצת מבחן | ב-Fiori: כמות × תעריף. ב-Job: הבדיקה עברה ולא נרשם מסמך |
| 9 | תקציב כיבוד, עדכון | מסמך תקציב מאוזן (סכום 0), שתי שורות לכל סניף, בתקופה הנכונה |
| 10 | סניף ללא תעריף | אזהרה בלוג, הסניף לא נכלל |
| 11 | `ZCO_ActWithSKF` / `ZFM_BudActWithSKF` בשאילתה | עלויות ומפתחות באותו דו"ח, ללא שכפול שורות |
| 12 | הרשאות | משתמש עם רול של אפליקציה 1 בלבד לא רואה את אפליקציה 2 |

---

## 6. מבנה התיקייה
```
אפיון.txt                      - האפיון המקורי
README.md                      - המסמך הזה
שאלות פתוחות.md                - נקודות לא ברורות / החלטות לאישור
src/00_wrappers_tier_b/        - ZCO_SKF_WRAPPER (Standard ABAP, C1)
src/01_common/                 - רכיבים משותפים
src/02_area_cds/               - CDS נתוני שטח (בחבילת ה-Wrapper)
src/03_skf_manage/             - אפליקציה 1: עדכון מפתחות העמסה
src/04_refreshment_budget/     - אפליקציה 2: תקציב כיבוד
src/05_reporting_cds/          - CDS לדו"חות
```
שמות הקבצים בפורמט abapGit (`*.clas.abap`, `*.ddls.asddls` וכו'). קבצי ה-XML המלווים לא נכללו, ולכן יוצרים כל אובייקט ב-ADT ומעתיקים אליו את הקוד.
