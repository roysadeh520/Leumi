---
name: sap-leumi-dev
description: SAP ABAP development for Bank Leumi from a spec (אפיון) - analyze the spec, plan together with the user (objects, Clean Core levels, open questions) and only then develop in ABAP Cloud / RAP / CDS with as few objects as possible, and deliver to the Leumi repo with a single README and an open-questions file. Use whenever the user shares or points to a Leumi spec, asks to develop / plan / analyze an SAP development for Leumi (פיתוח, אפיון, CDS, RAP, אפליקציה, ממשק, ג'וב, BAPI, Clean Core), or asks to continue such a development. For outbound interface classes it combines with sap-application-job.
---

# SAP development for Bank Leumi - from spec to delivery

Four phases, always in this order. **No code before the user approves the plan (phase 2).**
Talk to the user in Hebrew. Code comments in Hebrew.

---

## Phase 1 - Analyze the spec

1. Read the **whole** spec (functional + technical). Do not skim.
2. Extract into a working list:
   - Components (apps, CDS, reports, interfaces, jobs) and the spec section of each.
   - Data sources (tables, CDS, other teams' CDS), APIs / BAPIs, parameters (`ZCA_PARAM` entries), constants.
   - User flows: what the user enters, what is shown, what is posted, test run vs. update run.
3. Find spec problems and keep them for phase 2:
   - Contradictions between the functional and technical parts.
   - Values that look wrong (e.g. posting period taken from an old `ValidFrom`), duplicates, typos.
   - Missing info: field names, structures, who owns a value, behavior on re-run or empty result.

## Phase 2 - Plan together (STOP point)

Present the plan in Hebrew, short and in tables, then **wait for approval**. Ask decisions with AskUserQuestion when they change what gets built.

The plan contains:

1. **Object list in creation order.** For each object: type, name, one-line purpose, **why it is needed**. Aim for the minimum (see "Minimum objects").
2. **Clean Core level per component** (A / B / C / D, see below). **Every C or D item must be explicitly approved by the user**, with the reason and the alternatives that were checked.
3. **Fixed decision points.** Always ask these unless the spec answers them clearly:
   - Update from the app (RAP button, immediate result on screen) or in the background (Application Job)?
   - Is scheduling needed now? (If yes → job.)
   - Transaction code requested? (No transactions in ABAP Cloud → Fiori tile; a GUI report is level B/C.)
   - New DB table really needed? (Prefer standard documents + `ZCA_PARAM`.)
4. **Conflicts between "few files" and "correct development".** Show both options with the trade-off and let the user choose. Never decide silently.
5. **Open questions.** Split into: technical checks for the developer in the system (T1, T2…) and business decisions (1, 2…). Each one says what we assume and who answers (CO / FM / HR / BUS / DEV).
6. **Target folder in the repo.** `<module>/<development name>/`, e.g. `FM/טיפול במפתחות העמסה…`. Ask for the module if it is not obvious.

Only after an explicit "yes" from the user, go to phase 3.

## Phase 3 - Develop

### Clean Core levels
| Level | What | Rule |
|---|---|---|
| **A** | Released APIs only (C1), ABAP for Cloud Development | Default for everything |
| **B** | Classic APIs (BAPI / FM) | Only through a **wrapper class** in a Standard ABAP package, released **C1 - Use in Cloud Development**. Public types of the wrapper are built-in types only |
| **C** | Unreleased objects (SAP tables like `VIBDRO`, unreleased CDS) | **Stop and get approval.** Put them in the wrapper package and release C1. Add a T-question: look for a released replacement |
| **D** | Modifications, implicit enhancements | Never without explicit approval |

Packages: one **Standard ABAP** package for wrappers and C-level objects (`Z<MOD>_<DEV>_WRAPPER`), one **ABAP for Cloud Development** package for everything else.

### Minimum objects
- One logic class per app at most. Helpers are **private methods** or **local classes** (`locals_def` / `locals_imp`), not global classes.
- **No interfaces** unless there are two real implementations. No separate builder / reader / logger / period classes.
- No exception class or message class of our own. Use a local exception (`lcx_error` in `locals_def`) or return an error text. Use a team object if one exists (see `references/team-objects.md`).
- RAP behavior pool = its own class (mandatory). If the list is a CDS view (not a custom entity), put the app logic in the behavior pool's local types; no extra class.
- Custom entity only when the list must be computed in ABAP. Otherwise a root view entity is the BO.
- **No unit tests** unless the user asks for them.
- Every object must appear in the plan with its reason. If you need one that was not in the plan, ask first.

### Which pattern
| Need | Pattern | Details |
|---|---|---|
| Screen: test-run list + "update" button + immediate result | RAP: root view entity or root custom entity + **unmanaged BDEF with `static action`** + abstract entity for the action dialog | `references/rap-patterns.md` |
| Classic BAPI posting from RAP | Check (`CHECK` BAPI / `TESTRUN`) in the **action**; post in **saver `save`** with **no COMMIT** (RAP commits). Wrapper has `iv_commit` switch | `references/rap-patterns.md` + T-question: "verify the BAPI has no COMMIT WORK / is RAP-compatible" |
| Background, scheduling, long runs, outbound interface | **Application Job** | Use the **sap-application-job** skill structure (TEST_RUN, BALI log, catalog + template). For outbound interfaces: class inheriting `ZCL_API_HANDLER_BASE`, exactly as that skill says |
| Analytics / reports | CDS cube (`@Analytics.dataCategory: #CUBE`), `Union All` instead of join when mixing measures of different grain | |

### RAP rules that cost time if forgotten
- A BO entity cannot have **parameters** → use mandatory single-value filters (`@Consumption.filter: { mandatory: true, selectionType: #SINGLE }`).
- **COMMIT WORK is forbidden** inside RAP. The interaction phase (actions) may only read; writes go to the saver.
- `reported` in `save` (to show document numbers) depends on the release → mark `TODO(VERIFY)`.
- Fiori app: **ADT → right-click the Service Binding → Create SAP Fiori App** (List Report). The whole UI comes from `@UI` annotations in the CDS. BAS / VS Code only if ADT does not offer it.

### Coding rules
- ABAP Cloud: `cl_abap_context_info=>get_system_date( )` / `get_user_technical_name( )`, no `sy-datum` / `sy-uname` in cloud code (allowed inside classic wrappers).
- `ZCA_PARAM` has the TVARVC structure: read `LOW` by `NAME`. Cache values in a hashed table when read per row. Missing parameter = error before any posting (fail fast).
- Constants for every fixed value from the spec (controlling area, budget category, currency…). No magic literals in logic.
- Build everything first, then post. If one document is invalid, nothing is posted.
- Names: `ZCL_` logic class, `ZBP_` behavior pool, `ZI_` interface CDS, `ZC_` / `Z<MOD>_C_` consumption / custom entity, `Z<MOD>_A_` abstract entity, `Z<MOD>_UI_` service. Names given in the spec win.
- Mark honestly:
  - `TODO(VERIFY)`: field name, structure or signature not verified in the system.
  - `TODO(OPEN)`: depends on an open business decision (refer to its number in `שאלות פתוחות.md`).
  - Never present guessed field names as facts.

## Phase 4 - Deliver

### Repo structure (one folder per development)
```
<MODULE>/<development name>/
├── אפיון.txt              the spec (as given)
├── README.md              the only explanation file
├── שאלות פתוחות.md        T-questions + business decisions
└── src/NN_<component>/    abapGit file names: *.clas.abap, *.clas.locals_def.abap,
                           *.clas.locals_imp.abap, *.ddls.asddls, *.bdef.asbdef, *.srvd.srvdsrv
```
Templates: `references/deliverable-templates.md`.

### README.md - one file, in creation order
- Short "how it works" for the user (test-run list, update button, what is shown).
- Clean Core table and the number of classes with the reason for each.
- "What you paste and what is generated": 📋 = file in `src/` to paste into the object created in ADT; ⚙️ = generated or a form (service binding, Fiori app, IAM app, business catalog, domain, data element).
- Steps 0…N: settings for the consultant, packages, wrappers + C1 release, CDS, RAP (BDEF → Ctrl+1 creates the behavior pool → paste), service definition + binding + Preview test, Fiori app from the binding, IAM app / business catalog / role.
- Tests table (functional checks, no unit tests) and common problems.
- State that the code was written without system access and was not activated.

### Checklist before commit
- [ ] Every object in `src/` is in the README with its reason, and vice versa.
- [ ] No references to objects that were removed or renamed (grep the names).
- [ ] Question numbers referenced in code and README exist in `שאלות פתוחות.md`.
- [ ] Every C/D item was approved by the user.
- [ ] Every `TODO(OPEN)` has a matching question.
- [ ] Nothing left from earlier iterations (old files, empty folders, temporary branches).

Commit to the Leumi repo and push. Tell the user in Hebrew: what was built, what still needs verification in the system (T-questions), and the link.
