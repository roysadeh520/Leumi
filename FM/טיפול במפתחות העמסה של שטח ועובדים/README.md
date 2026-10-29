# טיפול במפתחות העמסה: שטח, עובדים ומשרות

המסמך מסביר מה נבנה, ואיך יוצרים כל אובייקט ב-ADT, שלב אחרי שלב. המסמך מבוסס על `אפיון.txt`.
- הקוד נמצא בתיקייה `src/`.
- שאלות ונקודות לא ברורות: [`שאלות פתוחות.md`](./שאלות%20פתוחות.md).

> הקוד נכתב מתוך האפיון, ללא גישה למערכת SAP, ולא עבר הפעלה (Activation).
> `TODO(VERIFY)` = לאמת שם שדה או חתימה במערכת. `TODO(OPEN)` = מחכה להחלטה עסקית.
> **משימה ראשונה למפתח:** שאלה T1 (תאימות ה-BAPIs ל-RAP).

---

## איך זה עובד

לכל אפליקציה יש **אריח Fiori אחד** (List Report):
1. המשתמש מזין תקופת חתך ונושא. **הרשימה = ריצת מבחן**: בדיוק השורות שיירשמו.
2. לחיצה על **"בצע עדכון"**:
   - הבדיקה ב-BAPI (CHECK / TESTRUN) רצה מיד.
   - אם יש שגיאה, לא נרשם דבר והשגיאה מוצגת.
   - אם הכל תקין, הרישום מתבצע בשמירת RAP, ומספרי המסמכים מוצגים למשתמש.

הרשימה והכפתור משתמשים באותה לוגיקה, ולכן מה שמוצג הוא בדיוק מה שנרשם.

| רכיב | Clean Core | נימוק |
|---|---|---|
| CDS נתוני שטח (`VIBDRO`, `VIBDMEAS`) | **C** | הטבלאות אינן משוחררות (שאלה T2) |
| רישום דרך `BAPI_ACC_STAT_KEY_FIG_*`, `BAPI_0050_CREATE` | **B** | API קלאסי, דרך Wrapper |
| כל השאר | **A** | APIs משוחררים בלבד |

- **טבלאות חדשות:** אין. הנתונים נרשמים במסמכים סטנדרטיים של CO ו-FM.
- **פרמטרים:** נשמרים ב-`ZCA_PARAM`, במבנה של TVARVC (`NAME` / `LOW`).
- **5 קלאסים בסך הכל:**
  - 2 Wrappers, כי ABAP Cloud לא קורא ל-BAPI ישירות.
  - 2 Behavior Pools, כי RAP דורש קלאס ייעודי לכל BDEF.
  - `ZCL_CO_SKF_MANAGE`, שהוא ה-Query Provider של הרשימה ומכיל את הלוגיקה של P1-P3.

---

## מה מדביקים ומה נוצר לבד
- **📋 להדביק:** כל אובייקט שיש לו קובץ ב-`src/`. יוצרים אותו ב-ADT, מעתיקים את כל תוכן הקובץ במקום מה שה-ADT יצר, ומפעילים (Ctrl+F3).
- **⚙️ נוצר לבד או בטופס:** Service Binding, אפליקציית Fiori, IAM App, Business Catalog, Domain ו-Data Element. אין להם קבצים בריפו.

**סדר השלבים חשוב**, כי כל אובייקט תלוי באובייקטים שנוצרו לפניו.

---

## שלב 0 - הגדרות (מיישם, לא פיתוח)
| מה | פירוט |
|---|---|
| מפתחות סטטיסטיים | `R100`, `R101` (שטח), `HCDET`, `POSDET`, `HCTOT`, `POSTOT`, ו-4 מפתחות לכל בניין |
| `ZCA_PARAM` | `ZCO_HC_SKF_DET`, `ZCO_POS_SKF_DET`, `ZCO_HC_SKF_TOT`, `ZCO_POS_SKF_TOT`, `ZCO_REFRESH_ACTTP`, `ZFM_REFRESH_BUDDOC`, `ZFM_UPD_BUDTYPE`, ולכל בניין `<מרכז עלות>HCD/HCT/POSD/POST` (לדוגמה `B1010001POSD`) |
| סוג פעילות כיבוד + תעריפים לסניפים | "נהל סוגי פעילות" + "ערוך מחירים עבור סוגי פעילות" |

---

## שלב 1 - חבילות ⚙️
1. קליק ימני על חבילת האב → **New → ABAP Package**.
2. `ZCO_SKF_WRAPPER`: **ABAP Language Version = Standard ABAP**.
   - תוכן: ה-Wrappers וה-CDS שקוראים אובייקטים לא משוחררים.
3. `ZCO_SKF`: **ABAP Language Version = ABAP for Cloud Development**.
   - תוכן: כל השאר.
4. אותו Transport לשתי החבילות.

---

## שלב 2 - Wrappers 📋 (חבילה `ZCO_SKF_WRAPPER`)
| פעולה ב-ADT | שם | קובץ |
|---|---|---|
| New → ABAP Class | `ZCL_CO_SKF_POSTER_BAPI` (רישום מפתחות סטטיסטיים) | `src/00_wrappers_tier_b/zcl_co_skf_poster_bapi.clas.abap` |
| New → ABAP Class | `ZCL_FM_BUDGET_POSTER_BAPI` (רישום תקציב) | `src/00_wrappers_tier_b/zcl_fm_budget_poster_bapi.clas.abap` |

**שחרור לשימוש מ-ABAP Cloud (לכל אחד מהשניים):**
1. Properties → לשונית **API State**.
2. **Add Release Contract → C1**.
3. **Use in Cloud Development** → Finish.

> אם ההפעלה נכשלת על שם שדה במבנה BAPI: בודקים ב-SE37 ומתקנים (`TODO(VERIFY)` בקוד).

---

## שלב 3 - CDS נתוני שטח 📋 (חבילה `ZCO_SKF_WRAPPER`)
| פעולה ב-ADT | שם | קובץ |
|---|---|---|
| New → Data Definition → *Define View Entity* | `ZCO_RESTATKEYDATADET` (פירוט, סעיף 2) | `src/02_area_cds/zco_restatkeydatadet.ddls.asddls` |
| אותו דבר | `ZCO_RESTATKEYDATATOT` (סיכום, סעיף 3) | `src/02_area_cds/zco_restatkeydatatot.ddls.asddls` |

- לשחרר את שניהם **C1**, כמו בשלב 2.
- **בדיקה:** F8 (Data Preview). צריכים להופיע נתוני שטח עם מרכזי עלות.

---

## שלב 4 - נושא ועזרת חיפוש (חבילה `ZCO_SKF`)
1. ⚙️ **New → Domain** `ZCO_SKF_TOPIC`:
   - CHAR 2.
   - Fixed Values: `P1` = נתוני שטח, `P2` = נתוני עובדים לפי שיוך תקציבי, `P3` = נתוני עובדים לפי מיקום נדל"ן.
2. ⚙️ **New → Data Element** `ZCO_SKF_TOPIC`:
   - Domain `ZCO_SKF_TOPIC`, Label "נושא".
3. 📋 **New → Data Definition** `ZCO_I_SkfTopicVH`:
   - `src/03_skf_manage/zco_i_skftopicvh.ddls.asddls`.

---

## שלב 5 - אפליקציה "עדכון מפתחות העמסה" (חבילה `ZCO_SKF`)

### 5.1 📋 CDS של הרשימה ושל חלון הפעולה
| פעולה ב-ADT | שם | קובץ |
|---|---|---|
| New → Data Definition → **Define Root Custom Entity** | `ZCO_C_SKFPOSTINGPREVIEW` (הרשימה + הכפתור) | `src/03_skf_manage/zco_c_skfpostingpreview.ddls.asddls` |
| New → Data Definition → **Define Abstract Entity** | `ZCO_A_SKFPOSTPARAM` (חלון: תקופה + נושא) | `src/03_skf_manage/zco_a_skfpostparam.ddls.asddls` |

> בשלב הזה תופיע אזהרה שהקלאס `ZCL_CO_SKF_MANAGE` לא קיים. זה תקין, הוא נוצר בשלב הבא.

### 5.2 📋 קלאס הלוגיקה
1. **New → ABAP Class** `ZCL_CO_SKF_MANAGE`.
2. מדביקים כל קובץ בלשונית המתאימה בתחתית העורך:

| לשונית ב-ADT | קובץ (`src/03_skf_manage/`) |
|---|---|
| Global Class | `zcl_co_skf_manage.clas.abap` |
| Class-relevant Local Types | `zcl_co_skf_manage.clas.locals_def.abap` |
| Local Types | `zcl_co_skf_manage.clas.locals_imp.abap` |
| Test Classes | `zcl_co_skf_manage.clas.testclasses.abap` |

3. מפעילים, ואז מפעילים מחדש את `ZCO_C_SKFPOSTINGPREVIEW`.
4. בדיקת יחידה: Ctrl+Shift+F10.

**מה הקלאס עושה לפי נושא:**

| נושא | מקור | מפתח סטטיסטי | מרכז עלות | כמות | תאריך רישום |
|---|---|---|---|---|---|
| P1 | `ZCO_RESTATKEYDATATOT` | `MEAS` | `COSTCENTER` | `MEASVALUE` | יום אחרון בתקופה |
| P2 (4 מסמכים) | `ZC_HR_BudgetReport` | `ZCA_PARAM`: `ZCO_HC/POS_SKF_DET/TOT` | ארגוני: `ORGUNIT` / תקציבי: `COSTCENTER` (מסוכם) | `HEADCOUNT` / `TOTALPOSITIONS` | `KEYDATE` |
| P3 (4 מסמכים) | `ZC_HR_BudgetReport` | `ZCA_PARAM`: `<בניין>HCD/POSD/HCT/POST` | ארגוני: `ORGUNIT` / תקציבי: `COSTCENTER` (מסוכם) | `HEADCOUNT` / `TOTALPOSITIONS` | `KEYDATE` |

### 5.3 RAP: Behavior Definition + Behavior Pool
1. 📋 קליק ימני על `ZCO_C_SKFPOSTINGPREVIEW` → **New Behavior Definition**:
   - Implementation Type: **Unmanaged**.
   - מחליפים בקוד מ-`zco_c_skfpostingpreview.bdef.asbdef`.
2. ⚙️ **Ctrl+1** על השורה הראשונה → **Create behavior implementation class zbp_co_skf_manage**. ה-ADT יוצר שלד.
3. 📋 בקלאס `ZBP_CO_SKF_MANAGE` מדביקים:
   - Global Class ← `zbp_co_skf_manage.clas.abap`.
   - Local Types ← `zbp_co_skf_manage.clas.locals_imp.abap`.
4. **Activate All** (Ctrl+Shift+F3).

### 5.4 שירות OData
1. 📋 קליק ימני על `ZCO_C_SKFPOSTINGPREVIEW` → **New Service Definition** `ZCO_UI_SKF_MANAGE`:
   - `zco_ui_skf_manage.srvd.srvdsrv`.
2. ⚙️ קליק ימני על ה-Service Definition → **New Service Binding**:
   - `ZCO_UI_SKF_MANAGE_O4`, **OData V4 - UI**.
   - Activate → **Publish**.
3. **בדיקה:**
   - ב-Binding בוחרים `SkfPostingPreview` → **Preview**.
   - מזינים תקופה `2026009` ונושא `P1` → Go.
   - הכפתור "בצע עדכון" אמור להופיע. **לנסות במערכת פיתוח בלבד** (שאלה T1).

---

## שלב 6 - אפליקציה "טיפול בתקציב כיבוד בסניפים" (חבילה `ZCO_SKF`)

### 6.1 📋 CDS
| פעולה ב-ADT | שם | קובץ (`src/04_refreshment_budget/`) |
|---|---|---|
| New → Data Definition → *Define View Entity* | `ZI_CO_BranchSkfQuantity` (כמות לסניף, סעיף 17) | `zi_co_branchskfquantity.ddls.asddls` |
| New → Data Definition → *Define Root View Entity* | `ZCO_REFRESHMENTCOST` (כמות × תעריף = תקציב, סעיפים 18-19, וגם הרשימה) | `zco_refreshmentcost.ddls.asddls` |
| New → Data Definition → *Define Abstract Entity* | `ZCO_A_REFRESHBUDPARAM` (חלון: תקופה, מפתח חלוקה, פריט התחייבות, יחידת מקור) | `zco_a_refreshbudparam.ddls.asddls` |

**בדיקה:** F8 על `ZCO_REFRESHMENTCOST` → סניפים עם כמות, תעריף ותקציב.

### 6.2 RAP
1. 📋 קליק ימני על `ZCO_REFRESHMENTCOST` → **New Behavior Definition**:
   - **Unmanaged**.
   - הקוד: `zco_refreshmentcost.bdef.asbdef`.
2. ⚙️ **Ctrl+1** → **Create behavior implementation class zbp_co_refresh_bud**.
3. 📋 בקלאס `ZBP_CO_REFRESH_BUD` מדביקים (כאן גם בניית מסמך התקציב, סעיף 21):
   - Global Class ← `zbp_co_refresh_bud.clas.abap`.
   - Local Types ← `zbp_co_refresh_bud.clas.locals_imp.abap`.
   - Test Classes ← `zbp_co_refresh_bud.clas.testclasses.abap`.
4. Activate All, ואז Ctrl+Shift+F10.

### 6.3 שירות
1. 📋 **Service Definition** `ZCO_UI_REFRESH_BUD` ← `zco_ui_refresh_bud.srvd.srvdsrv`.
2. ⚙️ **Service Binding** `ZCO_UI_REFRESH_BUD_O4`, OData V4 - UI → Publish → Preview.

---

## שלב 7 - CDS לדו"חות 📋 (חבילה `ZCO_SKF`, `src/05_reporting_cds/`)
New → Data Definition, לפי הסדר:
1. `ZI_CO_Journal10`: תנועות 0L עם מרכז עלות, מקובצות.
2. `ZCO_ActWithSKF`: Cube של עלויות + מפתחות סטטיסטיים (Union All).
3. `ZFM_BudActWithSKF`: Cube של תקציב מול ביצוע + מפתחות סטטיסטיים (Union All).

> אם ב-Union מתקבלת שגיאת "type mismatch": מתאימים את ה-`cast` בענף השני לטיפוס השדה בענף הראשון (Ctrl+Click על השדה).

---

## שלב 8 - אפליקציות Fiori, הרשאות ואריחים ⚙️

### 8.1 אפליקציית Fiori (לכל אפליקציה)
1. קליק ימני על ה-Service Binding → **Create SAP Fiori App**.
2. Template: **List Report**.
3. Main Entity:
   - `SkfPostingPreview` (אפליקציה 1).
   - `RefreshmentCost` (אפליקציה 2).
4. שם וכותרת:
   - `ZCO_SKF_MANAGE`, "עדכון מפתחות העמסה".
   - `ZCO_REFRESH_BUD`, "טיפול בתקציב כיבוד בסניפים".
5. חבילה `ZCO_SKF` + Transport → Finish.

אין קוד לכתוב: המסך נבנה מהאנוטציות `@UI` ב-CDS.

> אם האפשרות לא מופיעה, גרסת ה-ADT או המערכת ישנה מדי. אותו אשף זמין ב-BAS / VS Code (SAP Fiori tools).

### 8.2 הרשאות ואריח (לכל אפליקציה, **בנפרד**, לפי סעיף 15)
1. **IAM App** (New → IAM App):
   - שם: `ZCO_SKF_MANAGE` / `ZCO_REFRESH_BUD`, Type **External App**.
   - Services: ה-Service Binding.
   - Overview: ה-App Descriptor שנוצר ב-8.1.
   - **Publish Locally**.
2. **Business Catalog**:
   - `ZCO_SKF_MANAGE_BC` / `ZCO_REFRESH_BUD_BC`.
   - App Assignment ל-IAM App → Publish Locally.
3. **רול**:
   - ב-**Maintain Business Roles**: מוסיפים את ה-Business Catalog לרול.
   - מוסיפים את האריח ל-Space/Page.

---

## בדיקות
| בדיקה | צפי |
|---|---|
| ABAP Unit (`ZCL_CO_SKF_MANAGE`, `ZBP_CO_REFRESH_BUD`) | כל הבדיקות עוברות |
| P1, תקופה 2026009 | ברשימה: שורה לכל מרכז עלות × R100/R101. בעדכון: מסמך נרשם (KB33N) |
| P2 | 4 מסמכים. הסכום ברמה התקציבית שווה לסכום היחידות הארגוניות |
| P3, בניין בלי פרמטר | שגיאה, לא נרשם דבר |
| תקציב: עדכון | מסמך מאוזן (סכום 0), 2 שורות לכל סניף, בתקופה הנכונה |
| תקציב: סניף בלי תעריף | אזהרה, הסניף לא נכלל |
| `ZCO_ActWithSKF` / `ZFM_BudActWithSKF` | עלויות ומפתחות באותו דו"ח, בלי שכפול שורות |
| הרשאות | משתמש עם אפליקציה 1 בלבד לא רואה את אפליקציה 2 |

## בעיות נפוצות
| בעיה | פתרון |
|---|---|
| הרשימה ריקה | המסננים "תקופת חתך" ו"נושא" הם חובה |
| "פרמטר ... לא מתוחזק" | חסרה רשומה ב-`ZCA_PARAM` (שלב 0) |
| דאמפ `BEHAVIOR_ILLEGAL_STATEMENT` ב"בצע עדכון" | ה-BAPI מבצע COMMIT בעצמו (שאלה T1) |
| ה-Wrapper לא נגיש מ-`ZCO_SKF` | לא שוחרר C1 (שלב 2) |
| הכפתור לא מופיע ב-Preview | ה-BDEF או ה-Behavior Pool לא הופעלו. Activate All |
