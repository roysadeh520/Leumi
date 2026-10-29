# טיפול במפתחות העמסה: שטח, עובדים ומשרות - מסמך פיתוח

המסמך מפרט את **כל האובייקטים שצריך ליצור** ואת **סדר הפעולות**, על בסיס `אפיון.txt`.
הקוד נמצא בתיקייה `src/`. שאלות ונקודות לא ברורות מרוכזות ב-[`שאלות פתוחות.md`](./שאלות%20פתוחות.md).

> הקוד נכתב מתוך האפיון, ללא גישה למערכת SAP, ולא עבר הפעלה (Activation).
> `TODO(VERIFY)` = לאמת שם שדה או חתימה במערכת. `TODO(OPEN)` = מחכה להחלטה עסקית.
> **משימה ראשונה למפתח:** שאלה 0 בקובץ השאלות הפתוחות (תאימות ה-BAPIs ל-RAP).

---

## 1. איך זה עובד

לכל אפליקציה יש **אריח Fiori אחד** (List Report):
1. המשתמש מזין תקופת חתך ונושא. **הרשימה = ריצת מבחן**: בדיוק השורות שיירשמו.
2. לחיצה על **"בצע עדכון"** = ריצת עדכון:
   - **בפעולה:** בונים את המסמכים ובודקים אותם ב-BAPI (CHECK / TESTRUN). אם יש שגיאה, לא נרשם דבר, וההודעה מוצגת מיד.
   - **בשמירה (RAP save):** ה-BAPI נקרא בלי COMMIT, ו-RAP מבצע את ה-COMMIT בעצמו.
   - **בסוף:** המשתמש רואה את מספרי המסמכים שנרשמו.

הרשימה והכפתור משתמשים באותה לוגיקה, ולכן מה שמוצג הוא בדיוק מה שנרשם.

### Clean Core
| רכיב | רמה | נימוק |
|---|---|---|
| CDS נתוני שטח (`VIBDRO`, `VIBDMEAS`) | **C** | הטבלאות אינן משוחררות. ראה שאלה 1 |
| רישום דרך `BAPI_ACC_STAT_KEY_FIG_*` ו-`BAPI_0050_CREATE` | **B** | API קלאסי, דרך Wrapper |
| כל השאר (RAP, CDS, לוגיקה) | **A** | APIs משוחררים בלבד, וה-Wrappers משוחררים C1 |

---

## 2. טבלאות
**לא נדרשות טבלאות חדשות.** הנתונים נרשמים במסמכים סטנדרטיים של CO ו-FM. הפרמטרים נשמרים ב-`ZCA_PARAM`, במבנה של TVARVC (`NAME` / `LOW`).

---

## 3. רשימת אובייקטים - לפי סדר יצירה

### שלב 0 - הגדרות (מיישם, לא פיתוח)
| מה | פירוט |
|---|---|
| מפתחות סטטיסטיים | `R100`, `R101` (שטח), `HCDET`, `POSDET`, `HCTOT`, `POSTOT`, ו-4 מפתחות לכל בניין |
| `ZCA_PARAM` | `ZCO_HC_SKF_DET`, `ZCO_POS_SKF_DET`, `ZCO_HC_SKF_TOT`, `ZCO_POS_SKF_TOT`, `ZCO_REFRESH_ACTTP`, `ZFM_REFRESH_BUDDOC`, `ZFM_UPD_BUDTYPE`, ולכל בניין `<מרכז עלות>HCD/HCT/POSD/POST` |
| סוג פעילות כיבוד + תעריפים לסניפים | "נהל סוגי פעילות" + "ערוך מחירים עבור סוגי פעילות" |

### שלב 1 - חבילות
| חבילה | גרסת שפה | תוכן |
|---|---|---|
| `ZCO_SKF_WRAPPER` | Standard ABAP | 2 Wrappers + 2 CDS נתוני שטח. כל אובייקט משוחרר **C1** (לשונית API State) |
| `ZCO_SKF` | ABAP for Cloud Development | כל השאר |

### שלב 2 - חבילת `ZCO_SKF_WRAPPER`
| # | סוג | שם | קובץ |
|---|---|---|---|
| 2.1 | Class | `ZCL_CO_SKF_POSTER_BAPI` - רישום מפתחות סטטיסטיים | `src/00_wrappers_tier_b/` |
| 2.2 | Class | `ZCL_FM_BUDGET_POSTER_BAPI` - רישום תקציב | `src/00_wrappers_tier_b/` |
| 2.3 | CDS Cube | `ZCO_RESTATKEYDATADET` - פירוט נתוני שטח (סעיף 2) | `src/02_area_cds/` |
| 2.4 | CDS Cube | `ZCO_RESTATKEYDATATOT` - סיכום נתוני שטח (סעיף 3) | `src/02_area_cds/` |

### שלב 3 - משותף (`ZCO_SKF`)
| # | סוג | שם | פירוט |
|---|---|---|---|
| 3.1 | Domain + Data Element | `ZCO_SKF_TOPIC` | CHAR 2, ערכים קבועים: `P1` נתוני שטח, `P2` עובדים לפי שיוך תקציבי, `P3` עובדים לפי מיקום נדל"ן |
| 3.2 | CDS Value Help | `ZCO_I_SkfTopicVH` | `src/01_common/` |

### שלב 4 - אפליקציה "עדכון מפתחות העמסה" `ZCO_SKF_MANAGE` (`ZCO_SKF`)
| # | סוג | שם | תפקיד |
|---|---|---|---|
| 4.1 | Custom Entity (root) | `ZCO_C_SKFPOSTINGPREVIEW` | הרשימה (ריצת מבחן) + כפתור |
| 4.2 | Abstract Entity | `ZCO_A_SKFPOSTPARAM` | חלון הפעולה: תקופה + נושא |
| 4.3 | Class | `ZCL_CO_SKF_MANAGE` | **כל הלוגיקה**: בניית המסמכים לכל נושא (סעיפים 6-14) + מילוי הרשימה |
| 4.4 | Behavior Definition | `ZCO_C_SKFPOSTINGPREVIEW` | `static action postDocuments` |
| 4.5 | Class (Behavior Pool) | `ZBP_CO_SKF_MANAGE` | הכפתור: בדיקה בפעולה, רישום ב-save |
| 4.6 | Service Definition + Binding | `ZCO_UI_SKF_MANAGE` / `_O4` | OData V4 - UI |
| 4.7 | Fiori Elements App + IAM App + Business Catalog | `ZCO_SKF_MANAGE` | List Report, אריח "עדכון מפתחות העמסה" |

הקבצים של שלב 4 נמצאים ב-`src/03_skf_manage/`.

**הלוגיקה לפי נושא** (`ZCL_CO_SKF_MANAGE`):

| נושא | מקור | מפתח סטטיסטי | מרכז עלות | כמות | תאריך רישום |
|---|---|---|---|---|---|
| P1 | `ZCO_RESTATKEYDATATOT` | `MEAS` | `COSTCENTER` | `MEASVALUE` | יום אחרון בתקופה |
| P2 ×4 מסמכים | `ZC_HR_BudgetReport` | `ZCA_PARAM`: `ZCO_HC/POS_SKF_DET/TOT` | ארגוני: `ORGUNIT` / תקציבי: `COSTCENTER` (מסוכם) | `HEADCOUNT` / `TOTALPOSITIONS` | `KEYDATE` |
| P3 ×4 מסמכים | `ZC_HR_BudgetReport` | `ZCA_PARAM`: `<בניין>HCD/POSD/HCT/POST` | ארגוני: `ORGUNIT` / תקציבי: `COSTCENTER` (מסוכם) | `HEADCOUNT` / `TOTALPOSITIONS` | `KEYDATE` |

### שלב 5 - אפליקציה "טיפול בתקציב כיבוד בסניפים" `ZCO_REFRESH_BUD` (`ZCO_SKF`)
| # | סוג | שם | תפקיד |
|---|---|---|---|
| 5.1 | CDS View Entity | `ZI_CO_BranchSkfQuantity` | כמות לסניף (סעיף 17) |
| 5.2 | CDS Root View Entity | `ZCO_REFRESHMENTCOST` | כמות × תעריף = תקציב (סעיפים 18-19). זו גם הרשימה (ריצת מבחן) |
| 5.3 | Abstract Entity | `ZCO_A_REFRESHBUDPARAM` | חלון הפעולה: תקופה, מפתח חלוקה, פריט התחייבות, יחידה תקציבית מקור |
| 5.4 | Behavior Definition | `ZCO_REFRESHMENTCOST` | `static action postBudget` |
| 5.5 | Class (Behavior Pool) | `ZBP_CO_REFRESH_BUD` | הכפתור + בניית מסמך התקציב (סעיף 21) |
| 5.6 | Service Definition + Binding | `ZCO_UI_REFRESH_BUD` / `_O4` | OData V4 - UI |
| 5.7 | Fiori Elements App + IAM App + Business Catalog **נפרד** | `ZCO_REFRESH_BUD` | הפרדת הרשאות לפי סעיף 15 |

הקבצים של שלב 5 נמצאים ב-`src/04_refreshment_budget/`.

### שלב 6 - CDS לדו"חות (`ZCO_SKF`)
| # | שם | תפקיד |
|---|---|---|
| 6.1 | `ZI_CO_Journal10` | תנועות 0L עם מרכז עלות, מקובצות |
| 6.2 | `ZCO_ActWithSKF` | Cube: עלויות + מפתחות סטטיסטיים (Union All) |
| 6.3 | `ZFM_BudActWithSKF` | Cube: תקציב מול ביצוע + מפתחות סטטיסטיים (Union All) |

הקבצים של שלב 6 נמצאים ב-`src/05_reporting_cds/`.

### שלב 7 - הרשאות
שני ה-Business Catalogs מתווספים לרולים המתאימים, כל אחד בנפרד.

### סיכום: 5 קלאסים, וזה המינימום
| קלאס | למה הוא נדרש |
|---|---|
| 2 Wrappers | ABAP Cloud לא יכול לקרוא ל-BAPI ישירות, ולכן חייב Wrapper בחבילה קלאסית |
| 2 Behavior Pools | RAP דורש קלאס ייעודי לכל BDEF |
| `ZCL_CO_SKF_MANAGE` | רשימה מסוג Custom Entity דורשת Query Provider. הלוגיקה של P1-P3 נמצאת בו |

באפליקציית התקציב אין צורך בקלאס לוגיקה נפרד: הרשימה היא ה-CDS עצמו, והלוגיקה יושבת ב-Behavior Pool.

---

## 4. בדיקות
| # | בדיקה | צפי |
|---|---|---|
| 1 | ABAP Unit (`ZCL_CO_SKF_MANAGE`, `ZBP_CO_REFRESH_BUD`) | כל הבדיקות עוברות |
| 2 | P1, תקופה 2026009 | ברשימה: שורה לכל מרכז עלות × R100/R101. בעדכון: מסמך נרשם (KB33N) |
| 3 | P2 | 4 מסמכים. הסכום ברמה התקציבית שווה לסכום היחידות הארגוניות |
| 4 | P3, בניין בלי פרמטר | הודעת שגיאה ולא נרשם דבר |
| 5 | תקציב: עדכון | מסמך מאוזן (סכום 0), 2 שורות לכל סניף, בתקופה הנכונה |
| 6 | תקציב: סניף בלי תעריף | אזהרה, הסניף לא נכלל |
| 7 | `ZCO_ActWithSKF` / `ZFM_BudActWithSKF` | עלויות ומפתחות באותו דו"ח, בלי שכפול שורות |
| 8 | הרשאות | משתמש עם אפליקציה 1 בלבד לא רואה את אפליקציה 2 |
