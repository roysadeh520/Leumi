# מדריך יצירה ב-ADT, שלב אחרי שלב

המדריך מסביר איך יוצרים כל אובייקט ב-Eclipse (ADT) ומדביקים אליו את הקוד מ-`src/`.
**סדר השלבים חשוב**, כי כל אובייקט תלוי באובייקטים שנוצרו לפניו.

**כלל לכל אובייקט:** פותחים את הקובץ המתאים ב-`src/`, מעתיקים את כל התוכן, מדביקים במקום הקוד שה-ADT יצר, ומפעילים (Ctrl+F3).

---

## שלב 1 - חבילות
1. קליק ימני על חבילת האב → **New → ABAP Package**.
2. `ZCO_SKF_WRAPPER`, ובלשונית Properties: **ABAP Language Version = Standard ABAP**.
3. `ZCO_SKF`, ובלשונית Properties: **ABAP Language Version = ABAP for Cloud Development**.
4. לבחור אותו Transport לשתי החבילות.

---

## שלב 2 - Wrappers (חבילה `ZCO_SKF_WRAPPER`)
| # | פעולה ב-ADT | שם | קובץ |
|---|---|---|---|
| 2.1 | New → ABAP Class | `ZCL_CO_SKF_POSTER_BAPI` | `src/00_wrappers_tier_b/zcl_co_skf_poster_bapi.clas.abap` |
| 2.2 | New → ABAP Class | `ZCL_FM_BUDGET_POSTER_BAPI` | `src/00_wrappers_tier_b/zcl_fm_budget_poster_bapi.clas.abap` |

**שחרור לשימוש מ-ABAP Cloud (לכל אחד מהשניים):**
1. פותחים את הקלאס → בחלון **Properties** → לשונית **API State**.
2. **Add Release Contract → C1 - Use System-Internally**.
3. מסמנים **Use in Cloud Development** → Next → Finish.

> אם ההפעלה נכשלת על שם שדה במבנה BAPI, בודקים ב-SE37 את המבנה (`BAPISKFITM`, `BAPI_0050_ITEM` וכו') ומתקנים. מסומן `TODO(VERIFY)` בקוד.

---

## שלב 3 - CDS נתוני שטח (חבילה `ZCO_SKF_WRAPPER`)
| # | פעולה ב-ADT | שם | קובץ |
|---|---|---|---|
| 3.1 | New → Other → **Data Definition** → Template: *Define View Entity* | `ZCO_RESTATKEYDATADET` | `src/02_area_cds/zco_restatkeydatadet.ddls.asddls` |
| 3.2 | אותו דבר | `ZCO_RESTATKEYDATATOT` | `src/02_area_cds/zco_restatkeydatatot.ddls.asddls` |

אחרי ההפעלה, לשחרר את שניהם **C1 - Use in Cloud Development**, כמו בשלב 2.
**בדיקה:** קליק ימני על ה-CDS → **Open With → Data Preview** (F8). צריכים להופיע נתוני שטח עם מרכזי עלות.

---

## שלב 4 - דומיין ועזרת חיפוש (חבילה `ZCO_SKF`)
1. **New → Other → Domain** `ZCO_SKF_TOPIC`
   - Data Type: `CHAR`, Length: `2`.
   - בלשונית **Fixed Values**: `P1` = נתוני שטח, `P2` = נתוני עובדים לפי שיוך תקציבי, `P3` = נתוני עובדים לפי מיקום נדל"ן.
2. **New → Other → Data Element** `ZCO_SKF_TOPIC`
   - Domain: `ZCO_SKF_TOPIC`, Field Label: "נושא".
3. **New → Data Definition** `ZCO_I_SkfTopicVH`
   - הקוד: `src/03_skf_manage/zco_i_skftopicvh.ddls.asddls`.

---

## שלב 5 - אפליקציה "עדכון מפתחות העמסה" (חבילה `ZCO_SKF`)

### 5.1 ה-CDS של הרשימה ושל חלון הפעולה
| # | פעולה ב-ADT | שם | קובץ |
|---|---|---|---|
| a | New → Data Definition → Template: **Define Root Custom Entity** | `ZCO_C_SKFPOSTINGPREVIEW` | `src/03_skf_manage/zco_c_skfpostingpreview.ddls.asddls` |
| b | New → Data Definition → Template: **Define Abstract Entity** | `ZCO_A_SKFPOSTPARAM` | `src/03_skf_manage/zco_a_skfpostparam.ddls.asddls` |

> ההפעלה של (a) תציג אזהרה שהקלאס `ZCL_CO_SKF_MANAGE` עדיין לא קיים. זה תקין, הוא נוצר בשלב הבא.

### 5.2 קלאס הלוגיקה (Query Provider)
1. **New → ABAP Class** `ZCL_CO_SKF_MANAGE`.
2. מדביקים 4 חלקים, כל אחד בלשונית המתאימה בתחתית העורך:

| לשונית ב-ADT | קובץ |
|---|---|
| Global Class | `zcl_co_skf_manage.clas.abap` |
| Class-relevant Local Types | `zcl_co_skf_manage.clas.locals_def.abap` |
| Local Types | `zcl_co_skf_manage.clas.locals_imp.abap` |
| Test Classes | `zcl_co_skf_manage.clas.testclasses.abap` |

3. מפעילים, ואז מפעילים מחדש את `ZCO_C_SKFPOSTINGPREVIEW`.
4. **בדיקת יחידה:** Ctrl+Shift+F10. כל הבדיקות צריכות לעבור.

### 5.3 ה-RAP: Behavior Definition + Behavior Pool
1. קליק ימני על `ZCO_C_SKFPOSTINGPREVIEW` → **New Behavior Definition**.
   - Implementation Type: **Unmanaged**.
2. מחליפים את התוכן בקוד מ-`src/03_skf_manage/zco_c_skfpostingpreview.bdef.asbdef`.
3. **יצירת ה-Behavior Pool:**
   - בשורה הראשונה (`unmanaged implementation in class zbp_co_skf_manage unique;`) תופיע שגיאה שהקלאס לא קיים.
   - עומדים עליה ולוחצים **Ctrl+1 → Create behavior implementation class zbp_co_skf_manage**.
   - ה-ADT ייצור את הקלאס עם שלד.
4. בקלאס `ZBP_CO_SKF_MANAGE`, מדביקים:

| לשונית | קובץ |
|---|---|
| Global Class | `zbp_co_skf_manage.clas.abap` |
| Local Types | `zbp_co_skf_manage.clas.locals_imp.abap` |

5. מפעילים יחד: ה-BDEF + הקלאס. (Ctrl+Shift+F3, Activate All)

### 5.4 חשיפה כשירות OData
1. קליק ימני על `ZCO_C_SKFPOSTINGPREVIEW` → **New Service Definition** → שם `ZCO_UI_SKF_MANAGE`.
   - מחליפים בקוד מ-`src/03_skf_manage/zco_ui_skf_manage.srvd.srvdsrv` ומפעילים.
2. קליק ימני על ה-Service Definition → **New Service Binding**:
   - שם: `ZCO_UI_SKF_MANAGE_O4`.
   - Binding Type: **OData V4 - UI**.
3. בעורך ה-Binding: **Activate** ואז **Publish**.
4. **בדיקה בלי לבנות אפליקציה:**
   - בוחרים את `SkfPostingPreview` → **Preview**.
   - בדפדפן נפתחת רשימה. מזינים תקופה (למשל `2026009`) ונושא `P1` → **Go**.
   - הכפתור **"בצע עדכון"** אמור להופיע מעל הרשימה. **לנסות קודם במערכת פיתוח בלבד** (ראה שאלה T1).

---

## שלב 6 - אפליקציה "תקציב כיבוד" (חבילה `ZCO_SKF`)

### 6.1 CDS
| # | פעולה ב-ADT | שם | קובץ |
|---|---|---|---|
| a | New → Data Definition (*Define View Entity*) | `ZI_CO_BranchSkfQuantity` | `src/04_refreshment_budget/zi_co_branchskfquantity.ddls.asddls` |
| b | New → Data Definition (*Define Root View Entity*) | `ZCO_REFRESHMENTCOST` | `src/04_refreshment_budget/zco_refreshmentcost.ddls.asddls` |
| c | New → Data Definition (*Define Abstract Entity*) | `ZCO_A_REFRESHBUDPARAM` | `src/04_refreshment_budget/zco_a_refreshbudparam.ddls.asddls` |

**בדיקה:** Data Preview על `ZCO_REFRESHMENTCOST` → סניפים עם כמות, תעריף ותקציב.

### 6.2 ה-RAP
1. קליק ימני על `ZCO_REFRESHMENTCOST` → **New Behavior Definition**.
   - Implementation Type: **Unmanaged**.
   - הקוד: `src/04_refreshment_budget/zco_refreshmentcost.bdef.asbdef`.
2. **Ctrl+1** על השורה הראשונה → **Create behavior implementation class zbp_co_refresh_bud**.
3. בקלאס `ZBP_CO_REFRESH_BUD`, מדביקים:

| לשונית | קובץ |
|---|---|
| Global Class | `zbp_co_refresh_bud.clas.abap` |
| Local Types | `zbp_co_refresh_bud.clas.locals_imp.abap` |
| Test Classes | `zbp_co_refresh_bud.clas.testclasses.abap` |

4. Activate All, ואז בדיקת יחידה Ctrl+Shift+F10.

### 6.3 שירות
1. **Service Definition** `ZCO_UI_REFRESH_BUD`
   - הקוד: `src/04_refreshment_budget/zco_ui_refresh_bud.srvd.srvdsrv`.
2. **Service Binding** `ZCO_UI_REFRESH_BUD_O4`, OData V4 - UI → Publish → Preview.

---

## שלב 7 - CDS לדו"חות (חבילה `ZCO_SKF`)
New → Data Definition, לפי הסדר הזה:
1. `ZI_CO_Journal10`
2. `ZCO_ActWithSKF`
3. `ZFM_BudActWithSKF`

הקבצים ב-`src/05_reporting_cds/`.

> ב-Union, אם ההפעלה נכשלת על "type mismatch", צריך להתאים את ה-`cast` בענף השני לטיפוס של השדה בענף הראשון. כדי לראות את הטיפוס: Ctrl+Click על השדה.

**בדיקה:** Data Preview, או שאילתה ב-"Custom Analytical Queries" מעל ה-Cube.

---

## שלב 8 - אפליקציות Fiori ואריחים

### 8.1 יצירת אפליקציית Fiori (ב-SAP Business Application Studio, לכל אפליקציה)
1. **Fiori: Open Application Generator** → **List Report Page**.
2. Data Source: **Connect to a System** → בוחרים את המערכת → Service: `ZCO_UI_SKF_MANAGE_O4`.
   - באפליקציה השנייה: `ZCO_UI_REFRESH_BUD_O4`.
3. Main Entity:
   - אפליקציה 1: `SkfPostingPreview`.
   - אפליקציה 2: `RefreshmentCost`.
4. שם המודול:
   - אפליקציה 1: `zco_skf_manage`, כותרת "עדכון מפתחות העמסה".
   - אפליקציה 2: `zco_refresh_bud`, כותרת "טיפול בתקציב כיבוד בסניפים".
5. **Add deployment configuration** → ABAP → BSP: `ZCO_SKF_MANAGE` / `ZCO_REFRESH_BUD`, חבילה `ZCO_SKF`.
6. **Add FLP configuration**:
   - Semantic Object: `ZCOSKF`, Action: `manage`.
   - באפליקציה השנייה: Semantic Object `ZCOREFRESH`, Action `manage`.
7. `npm run deploy`.

> כל ההגדרות של המסך (עמודות, מסננים, הכפתור) כבר מוגדרות באנוטציות `@UI` ב-CDS. אין צורך לשנות קוד ב-BAS.

### 8.2 הרשאות ואריח (ב-ADT, לכל אפליקציה)
1. **IAM App:** קליק ימני על החבילה → New → Other → **IAM App**.
   - שם: `ZCO_SKF_MANAGE` / `ZCO_REFRESH_BUD`, Type: **External App**.
   - בלשונית **Services**: מוסיפים את ה-Service Binding.
   - בלשונית **Overview**: מקשרים את ה-Fiori Launchpad App Descriptor שנוצר בפריסה.
   - **Publish Locally**.
2. **Business Catalog:** New → Other → **Business Catalog**.
   - אחד לכל אפליקציה, **בנפרד**: `ZCO_SKF_MANAGE_BC`, `ZCO_REFRESH_BUD_BC`.
   - בכל אחד: New **App Assignment** → ה-IAM App המתאים → Publish Locally.
3. **רול:** באפליקציית Fiori **Maintain Business Roles**:
   - פותחים את הרול הרלוונטי ומוסיפים את ה-Business Catalog.
   - ב-Launchpad Space/Page מוסיפים את האריח.

---

## בעיות נפוצות
| בעיה | פתרון |
|---|---|
| Custom Entity לא מחזירה נתונים | לבדוק שהמסננים "תקופת חתך" ו"נושא" מולאו. הם חובה |
| שגיאה "parameter ... לא מתוחזק" | חסרה רשומה ב-`ZCA_PARAM` (ראה README שלב 0) |
| דאמפ `BEHAVIOR_ILLEGAL_STATEMENT` בלחיצה על "בצע עדכון" | ה-BAPI מבצע COMMIT בעצמו. ראה שאלה T1 |
| ה-Wrapper לא נגיש מ-`ZCO_SKF` | לא שוחרר C1 (שלב 2) |
| הכפתור לא מופיע ב-Preview | ה-BDEF או ה-Behavior Pool לא הופעלו. Activate All |
