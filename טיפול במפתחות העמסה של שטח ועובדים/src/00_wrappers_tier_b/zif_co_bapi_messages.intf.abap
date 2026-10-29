"! מבנה הודעות אחיד שמוחזר מה-Wrappers לקוד ה-ABAP Cloud.
"! בכוונה בטיפוסים מובנים - כדי לא לחשוף BAPIRET2 / טיפוסי DDIC לא משוחררים.
"! חבילה: ZCO_SKF_WRAPPER (Standard ABAP), שחרור C1 (Use in Cloud Development).
INTERFACE zif_co_bapi_messages
  PUBLIC.

  TYPES:
    BEGIN OF ty_message,
      type   TYPE c LENGTH 1,
      id     TYPE c LENGTH 20,
      number TYPE n LENGTH 3,
      text   TYPE string,
    END OF ty_message,
    ty_messages TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.

ENDINTERFACE.
