"! Query Provider ל-ZCO_C_SKFPOSTINGPREVIEW: שטוח את מסמכי ה-Builder לשורות תצוגה.
CLASS zcl_co_skf_preview_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

  PRIVATE SECTION.
    TYPES ty_rows TYPE STANDARD TABLE OF zco_c_skfpostingpreview WITH EMPTY KEY.

    CONSTANTS:
      BEGIN OF c_parameter,
        fiscal_year_period TYPE string VALUE `P_FISCALYEARPERIOD`,
        topic              TYPE string VALUE `P_TOPIC`,
      END OF c_parameter.

    METHODS get_parameter
      IMPORTING it_parameters   TYPE if_rap_query_request=>tt_parameters
                iv_name         TYPE string
      RETURNING VALUE(rv_value) TYPE string.

    METHODS to_rows
      IMPORTING it_documents   TYPE zif_co_skf_types=>ty_documents
      RETURNING VALUE(rt_rows) TYPE ty_rows.

    METHODS sort_rows
      IMPORTING it_sort_elements TYPE if_rap_query_request=>tt_sort_elements
      CHANGING  ct_rows          TYPE ty_rows.

    METHODS get_page
      IMPORTING it_rows        TYPE ty_rows
                io_paging      TYPE REF TO if_rap_query_paging
      RETURNING VALUE(rt_page) TYPE ty_rows.
ENDCLASS.



CLASS zcl_co_skf_preview_query IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    TRY.
        DATA(lt_parameters) = io_request->get_parameters( ).
        DATA(lt_documents) = NEW zcl_co_skf_doc_builder( )->build_documents(
          iv_topic  = CONV #( get_parameter( it_parameters = lt_parameters iv_name = c_parameter-topic ) )
          io_period = zcl_co_fiscal_period=>from_value(
                        get_parameter( it_parameters = lt_parameters iv_name = c_parameter-fiscal_year_period ) ) ).

        DATA(lt_rows) = to_rows( lt_documents ).
        sort_rows( EXPORTING it_sort_elements = io_request->get_sort_elements( )
                   CHANGING  ct_rows          = lt_rows ).

        IF io_request->is_total_numb_of_rec_requested( ).
          io_response->set_total_number_of_records( lines( lt_rows ) ).
        ENDIF.
        IF io_request->is_data_requested( ).
          io_response->set_data( get_page( it_rows = lt_rows io_paging = io_request->get_paging( ) ) ).
        ENDIF.

      CATCH zcx_co_skf_error INTO DATA(lx_error).
        " ההודעה (פרמטר חסר / תקופה שגויה) מוצגת למשתמש ב-Fiori
        RAISE EXCEPTION TYPE cx_rap_query_provider EXPORTING previous = lx_error.
    ENDTRY.
  ENDMETHOD.


  METHOD get_parameter.
    rv_value = VALUE #( it_parameters[ parameter_name = iv_name ]-value OPTIONAL ).
  ENDMETHOD.


  METHOD to_rows.
    LOOP AT it_documents INTO DATA(ls_document).
      DATA(lv_document_index) = sy-tabix.
      LOOP AT ls_document-items INTO DATA(ls_item).
        APPEND VALUE #( documentindex        = lv_document_index
                        itemindex            = sy-tabix
                        headertext           = ls_document-header_text
                        postingdate          = ls_document-posting_date
                        statisticalkeyfigure = ls_item-statistical_key_figure
                        costcenter           = ls_item-cost_center
                        fiscalyear           = ls_item-fiscal_year
                        fiscalperiod         = ls_item-fiscal_period
                        quantity             = ls_item-quantity
                        quantityunit         = ls_item-quantity_unit ) TO rt_rows.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD sort_rows.
    IF it_sort_elements IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lt_order) = VALUE abap_sortorder_tab( FOR ls_sort IN it_sort_elements
                                               ( name = ls_sort-element_name descending = ls_sort-descending ) ).
    SORT ct_rows BY (lt_order).
  ENDMETHOD.


  METHOD get_page.
    DATA(lv_offset)    = io_paging->get_offset( ).
    DATA(lv_page_size) = io_paging->get_page_size( ).
    DATA(lv_last) = COND i( WHEN lv_page_size = if_rap_query_paging=>page_size_unlimited
                            THEN lines( it_rows )
                            ELSE lv_offset + lv_page_size ).

    LOOP AT it_rows INTO DATA(ls_row) FROM lv_offset + 1 TO lv_last.
      APPEND ls_row TO rt_page.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
