# Deliverable templates

## README.md

```markdown
# <שם הפיתוח>

המסמך מסביר מה נבנה ואיך יוצרים כל אובייקט ב-ADT, שלב אחרי שלב. מבוסס על `אפיון.txt`.
- הקוד: `src/`
- שאלות פתוחות: [`שאלות פתוחות.md`](./שאלות%20פתוחות.md)

> הקוד נכתב מתוך האפיון, ללא גישה למערכת SAP, ולא עבר הפעלה (Activation).
> `TODO(VERIFY)` = לאמת שם שדה / חתימה במערכת. `TODO(OPEN)` = מחכה להחלטה עסקית.
> **משימה ראשונה למפתח:** <T1 ...>

## איך זה עובד
<למשתמש: מה מזינים, מה הרשימה מראה (ריצת מבחן), מה קורה בלחיצה על הכפתור, מה מוצג בסוף>

| רכיב | Clean Core | נימוק |
|---|---|---|

- **טבלאות חדשות:** <אין / למה כן>
- **<N> קלאסים:** <כל קלאס + למה הוא נדרש>

## מה מדביקים ומה נוצר לבד
- **📋 להדביק:** כל אובייקט שיש לו קובץ ב-`src/`. יוצרים ב-ADT, מעתיקים את כל תוכן הקובץ במקום מה שה-ADT יצר, מפעילים (Ctrl+F3).
- **⚙️ נוצר לבד / טופס:** Service Binding, אפליקציית Fiori, IAM App, Business Catalog, Domain, Data Element.

**סדר השלבים חשוב** - כל אובייקט תלוי בקודמים.

## שלב 0 - הגדרות (מיישם, לא פיתוח)
| מה | פירוט |   <- ZCA_PARAM entries, customizing, master data

## שלב 1 - חבילות ⚙️
## שלב 2 - Wrappers 📋 (+ שחרור C1)
## שלב N - <רכיב> (CDS 📋 → RAP: BDEF 📋 → Ctrl+1 ⚙️ → Behavior Pool 📋 → Service Definition 📋 → Binding ⚙️ + Preview)
## שלב N - אפליקציות Fiori, הרשאות ואריחים ⚙️
   ADT: קליק ימני על ה-Service Binding → Create SAP Fiori App → List Report → Main Entity → חבילה → Finish
   IAM App → Business Catalog → רול (Maintain Business Roles)

## בדיקות
| בדיקה | צפי |

## בעיות נפוצות
| בעיה | פתרון |
```

## שאלות פתוחות.md

```markdown
# שאלות פתוחות

הקוד נכתב לפי ההנחה בכל שאלה. מקומות תלויים מסומנים `TODO(OPEN)` / `TODO(VERIFY)`.
**מי עונה:** CO / FM = מיישם, HR = צוות HR, BUS = עסקי, DEV = מפתח.

## א. בדיקות טכניות במערכת (DEV) - לפני הכל
### T1. <נושא> ⚠️ חוסם
- **הרקע:** ...
- **מה לבדוק:** ...
- **אם יש בעיה:** ...

## ב. החלטות עסקיות
### 1. <נושא> - <מי עונה> [⚠️ אם חשוב]
- **באפיון / הבעיה:** ...
- **הנחנו:** ... **לאשר.** / **להחליט:** ...
```

Keep every question to 2-4 lines. Remove questions that are only technical assumptions with an obvious answer; keep only what someone must verify or decide.
