# Team objects (Leumi)

Existing objects to reuse instead of creating new ones. The user adds to this list over time.

| Object | What it is | How to use |
|---|---|---|
| `ZCA_PARAM` | Parameter table, TVARVC structure (`NAME`, `TYPE`, `NUMB`, `SIGN`, `OPTI`, `LOW`, `HIGH`) | `SELECT SINGLE low FROM zca_param WHERE name = @name`. In CDS: join on `name = '<PARAM>'` and use `low`. Every parameter the development needs is listed in README step 0 |
| `ZCL_API_HANDLER_BASE` | Base class for outbound interface classes | Only through the **sap-application-job** skill structure (inherit, `get_api_id`, `send`, `ZCX_API_DISPATCH_ERROR`) |
| `ZCL_API_JSON` | JSON serialize / deserialize for outbound interfaces | As in sap-application-job |
| `ZCX_API_DISPATCH_ERROR` | Exception for outbound interface send errors | As in sap-application-job |

## Conventions
- Controlling area / FM area: `1000` (as in the specs so far).
- Comments in Hebrew.
- Repo: one folder per module (`FM`, `CO`, …), one sub-folder per development.
