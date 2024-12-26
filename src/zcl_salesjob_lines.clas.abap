CLASS zcl_salesjob_lines DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_apj_dt_exec_object .
    INTERFACES if_apj_rt_exec_object .

    INTERFACES if_oo_adt_classrun .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SALESJOB_LINES IMPLEMENTATION.


  METHOD if_apj_dt_exec_object~get_parameters.
    " Return the supported selection parameters here
    et_parameter_def = VALUE #(
      ( selname = 'S_ID'    kind = if_apj_dt_exec_object=>select_option datatype = 'C' length = 10 param_text = 'My ID'                                      changeable_ind = abap_true )
      ( selname = 'P_DESCR' kind = if_apj_dt_exec_object=>parameter     datatype = 'C' length = 80 param_text = 'My Description'   lowercase_ind = abap_true changeable_ind = abap_true )
      ( selname = 'P_COUNT' kind = if_apj_dt_exec_object=>parameter     datatype = 'I' length = 10 param_text = 'My Count'                                   changeable_ind = abap_true )
      ( selname = 'P_SIMUL' kind = if_apj_dt_exec_object=>parameter     datatype = 'C' length =  1 param_text = 'My Simulate Only' checkbox_ind = abap_true  changeable_ind = abap_true )
    ).

    " Return the default parameters values here
    et_parameter_val = VALUE #(
      ( selname = 'S_ID'    kind = if_apj_dt_exec_object=>select_option sign = 'I' option = 'EQ' low = '4711' )
      ( selname = 'P_DESCR' kind = if_apj_dt_exec_object=>parameter     sign = 'I' option = 'EQ' low = 'My Default Description' )
      ( selname = 'P_COUNT' kind = if_apj_dt_exec_object=>parameter     sign = 'I' option = 'EQ' low = '200' )
      ( selname = 'P_SIMUL' kind = if_apj_dt_exec_object=>parameter     sign = 'I' option = 'EQ' low = abap_true )
    ).
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    TYPES ty_id TYPE c LENGTH 10.

    DATA s_id    TYPE RANGE OF ty_id.
    DATA p_descr TYPE c LENGTH 80.
    DATA p_count TYPE i.
    DATA p_simul TYPE abap_boolean.

    DATA: jobname   type cl_apj_rt_api=>TY_JOBNAME.
    DATA: jobcount  type cl_apj_rt_api=>TY_JOBCOUNT.
    DATA: catalog   type cl_apj_rt_api=>TY_CATALOG_NAME.
    DATA: template  type cl_apj_rt_api=>TY_TEMPLATE_NAME.

    DATA: lt_billinglines TYPE TABLE OF zbillinglines,
          wa_billinglines TYPE zbillinglines,
          lt_billingprocessed TYPE STANDARD TABLE OF zbillingproc,
          wa_billingprocessed TYPE zbillingproc.

    GET TIME STAMP FIELD DATA(lv_timestamp).

    " Getting the actual parameter values
    LOOP AT it_parameters INTO DATA(ls_parameter).
      CASE ls_parameter-selname.
        WHEN 'S_ID'.
          APPEND VALUE #( sign   = ls_parameter-sign
                          option = ls_parameter-option
                          low    = ls_parameter-low
                          high   = ls_parameter-high ) TO s_id.
        WHEN 'P_DESCR'. p_descr = ls_parameter-low.
        WHEN 'P_COUNT'. p_count = ls_parameter-low.
        WHEN 'P_SIMUL'. p_simul = ls_parameter-low.
      ENDCASE.
    ENDLOOP.

    try.
*      read own runtime info catalog
       cl_apj_rt_api=>GET_JOB_RUNTIME_INFO(
                        importing
                          ev_jobname        = jobname
                          ev_jobcount       = jobcount
                          ev_catalog_name   = catalog
                          ev_template_name  = template ).

       catch cx_apj_rt.

    endtry.

    SELECT FROM I_BillingDocument AS header
      FIELDS header~BillingDocument,  header~BillingDocumentType, header~Division, header~BillingDocumentDate, header~BillingDocumentIsCancelled,
              header~CompanyCode, header~FiscalYear, header~AccountingDocument, header~SoldToParty, header~CustomerGroup,header~SalesDistrict,header~SalesOrganization,
              header~DocumentReferenceID
      WHERE NOT EXISTS (
               SELECT BillingDocument FROM zbillingproc
               WHERE header~BillingDocument = zbillingproc~BillingDocument AND
                 header~CompanyCode = zbillingproc~bukrs AND
                 header~FiscalYear = zbillingproc~fiscalyearvalue )
*            AND header~BillingDocument = '0090000103'
      INTO TABLE @DATA(ltheader).

    LOOP AT ltheader INTO DATA(waheader).
      lv_timestamp = cl_abap_tstmp=>add_to_short( tstmp = lv_timestamp secs = 11111 ).

* Delete already processed sales line
      delete from zbillinglines
        Where zbillinglines~bukrs = @waheader-CompanyCode AND
        zbillinglines~fiscalyearvalue = @waheader-FiscalYear AND
        zbillinglines~billingdocument = @waheader-BillingDocument.

      SELECT FROM I_BillingDocItemPrcgElmntBasic FIELDS BillingDocument , BillingDocumentItem, ConditionRateValue, ConditionAmount, ConditionType
        WHERE BillingDocument = @waheader-BillingDocument
        INTO TABLE @DATA(it_price).

      SELECT FROM I_BillingDocumentItemBasic AS item
        join I_ProductDescription as pd on item~Product = pd~Product and pd~LanguageISOCode = 'EN'
        FIELDS item~BillingDocumentItem, item~Plant, item~ProfitCenter, item~Product, item~BillingQuantity, item~BaseUnit, item~BillingQuantityUnit, item~NetAmount,
             item~TaxAmount, item~TransactionCurrency, item~CancelledBillingDocument, item~BillingQuantityinBaseUnit,
             pd~ProductDescription
        WHERE item~BillingDocument = @waheader-BillingDocument
           INTO TABLE @DATA(ltlines).
      LOOP AT ltlines INTO DATA(walines).


        wa_billinglines-client = SY-MANDT.
        wa_billinglines-bukrs = waheader-CompanyCode.
        wa_billinglines-fiscalyearvalue = waheader-FiscalYear.
        wa_billinglines-billingdocument = waheader-BillingDocument.
        wa_billinglines-billingdocumentitem = walines-BillingDocumentItem.
        wa_billinglines-billingdocumentdate = waheader-BillingDocumentDate.
        wa_billinglines-product = walines-Product.

        wa_billinglines-materialdescription  = walines-ProductDescription.
        wa_billinglines-netamount            = walines-NetAmount.
        wa_billinglines-taxamount            = walines-TaxAmount.

        READ TABLE it_price INTO DATA(wa_price) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'ZMRP'.
        wa_billinglines-mrp                  = wa_price-ConditionRateValue.
        CLEAR wa_price.

        READ TABLE it_price INTO DATA(wa_price0) WITH KEY BillingDocument = waheader-BillingDocument
                                                    BillingDocumentItem = walines-BillingDocumentItem
                                                    ConditionType = 'ZR00'.
*        ls_response-BasicAmt = wa_price0-ConditionRateValue.
        CLEAR wa_price0.

        READ TABLE it_price INTO DATA(wa_priceIRD) WITH KEY BillingDocument = waheader-BillingDocument
                                                    BillingDocumentItem = walines-BillingDocumentItem
                                                    ConditionType = 'ZBSP'.
        if wa_priceird is not initial.
            wa_billinglines-itemrate = wa_priceIRD-ConditionRateValue.
        else.
            READ TABLE it_price INTO DATA(wa_priceIRE) WITH KEY BillingDocument = waheader-BillingDocument
                                                    BillingDocumentItem = walines-BillingDocumentItem
                                                    ConditionType = 'ZEXP'.
            wa_billinglines-itemrate = wa_priceIRE-ConditionRateValue.
        endif.
        CLEAR wa_priceIRD.
        CLEAR wa_priceire.

        READ TABLE it_price INTO DATA(wa_price1) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'JOIG'.
        wa_billinglines-igst                    = wa_price1-ConditionAmount.
        wa_billinglines-rateigst                = wa_price1-ConditionRateValue.
        CLEAR wa_price1.

        READ TABLE it_price INTO DATA(wa_price2) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'JOSG'.
        wa_billinglines-sgst                    = wa_price2-ConditionAmount.
        wa_billinglines-cgst                    = wa_price2-ConditionAmount.
        wa_billinglines-ratecgst                = wa_price2-ConditionRateValue.
        wa_billinglines-ratesgst                = wa_price2-ConditionRateValue.
        CLEAR wa_price2.

        READ TABLE it_price INTO DATA(wa_price4) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'ZDIF'.
        wa_billinglines-roundoff                = wa_price4-ConditionAmount.
        CLEAR wa_price4.

        READ TABLE it_price INTO DATA(wa_price5) WITH KEY BillingDocument = waheader-BillingDocument
                                                     BillingDocumentItem = walines-BillingDocumentItem
                                                     ConditionType = 'ZMAN'.
        wa_billinglines-manditax                = wa_price5-ConditionAmount.
        CLEAR wa_price5.

        READ TABLE it_price INTO DATA(wa_price6) WITH KEY BillingDocument = waheader-BillingDocument
                                                     BillingDocumentItem = walines-BillingDocumentItem
                                                     ConditionType = 'ZMCS'.
        wa_billinglines-mandicess               = wa_price6-ConditionAmount.
        CLEAR wa_price6.

        READ TABLE it_price INTO DATA(wa_price7) WITH KEY BillingDocument = waheader-BillingDocument
                                                 BillingDocumentItem = walines-BillingDocumentItem
                                                 ConditionType = 'ZDIS'.
        wa_billinglines-discount                = wa_price7-ConditionAmount.
        CLEAR wa_price7.

*        wa_billinglines-itemrate                = walines-YY1_IGSTRate_BDI.
        wa_billinglines-totalamount             = walines-NetAmount + walines-TaxAmount.

        SELECT SINGLE FROM i_productsalestax FIELDS Product
          WHERE Product = @walines-Product AND Country = 'IN' AND TaxClassification = '1'
          INTO @DATA(lv_flag).
        IF lv_flag IS NOT INITIAL.
          wa_billinglines-exempted = 'No'.
        ELSE.
          wa_billinglines-exempted = 'Yes'.
        ENDIF.

        wa_billinglines-discountrate            = 0.
        wa_billinglines-billingqtyinsku         = walines-BillingQuantityInBaseUnit.

        READ TABLE it_price INTO DATA(wa_price8) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'JTC2'.
        wa_billinglines-tcs                     = wa_price8-ConditionAmount.
        wa_billinglines-ratetcs                 = wa_price8-ConditionRateValue.
        CLEAR wa_price8.

        APPEND wa_billinglines TO lt_billinglines.
        CLEAR : wa_billinglines.
      ENDLOOP.
      INSERT zbillinglines FROM TABLE @lt_billinglines.

      wa_billingprocessed-client = SY-MANDT.
      wa_billingprocessed-billingdocument = waheader-BillingDocument.
      wa_billingprocessed-bukrs = waheader-CompanyCode.
      wa_billingprocessed-fiscalyearvalue = waheader-FiscalYear.
      wa_billingprocessed-creationdatetime = lv_timestamp.

      APPEND wa_billingprocessed TO lt_billingprocessed.
      INSERT zbillingproc FROM TABLE @lt_billingprocessed.
      COMMIT WORK.

      CLEAR :  wa_billingprocessed, lt_billingprocessed, lt_billinglines.

    ENDLOOP.


  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    DATA: lt_billinglines TYPE TABLE OF zbillinglines,
          wa_billinglines TYPE zbillinglines,
          lt_billingprocessed TYPE STANDARD TABLE OF zbillingproc,
          wa_billingprocessed TYPE zbillingproc.

    GET TIME STAMP FIELD DATA(lv_timestamp).

delete from zbillingproc.
delete from zbillinglines.
*COMMIT WORK.

    SELECT FROM I_BillingDocument AS header
      FIELDS header~BillingDocument,  header~BillingDocumentType, header~Division, header~BillingDocumentDate, header~BillingDocumentIsCancelled,
              header~CompanyCode, header~FiscalYear, header~AccountingDocument, header~SoldToParty, header~CustomerGroup,header~SalesDistrict,header~SalesOrganization,
              header~DocumentReferenceID
      WHERE NOT EXISTS (
               SELECT BillingDocument FROM zbillingproc
               WHERE header~BillingDocument = zbillingproc~BillingDocument AND
                 header~CompanyCode = zbillingproc~bukrs AND
                 header~FiscalYear = zbillingproc~fiscalyearvalue )
*            AND header~BillingDocument = '0090000103'
      INTO TABLE @DATA(ltheader).

    LOOP AT ltheader INTO DATA(waheader).
      lv_timestamp = cl_abap_tstmp=>add_to_short( tstmp = lv_timestamp secs = 11111 ).

* Delete already processed sales line
      delete from zbillinglines
        Where zbillinglines~bukrs = @waheader-CompanyCode AND
        zbillinglines~fiscalyearvalue = @waheader-FiscalYear AND
        zbillinglines~billingdocument = @waheader-BillingDocument.

      SELECT FROM I_BillingDocItemPrcgElmntBasic FIELDS BillingDocument , BillingDocumentItem, ConditionRateValue, ConditionAmount, ConditionType
        WHERE BillingDocument = @waheader-BillingDocument
        INTO TABLE @DATA(it_price).

      SELECT FROM I_BillingDocumentItemBasic AS item
        join I_ProductDescription as pd on item~Product = pd~Product and pd~LanguageISOCode = 'EN'
        FIELDS item~BillingDocumentItem, item~Plant, item~ProfitCenter, item~Product, item~BillingQuantity, item~BaseUnit, item~BillingQuantityUnit, item~NetAmount,
             item~TaxAmount, item~TransactionCurrency, item~CancelledBillingDocument, item~BillingQuantityinBaseUnit,
             pd~ProductDescription
        WHERE item~BillingDocument = @waheader-BillingDocument
           INTO TABLE @DATA(ltlines).
      LOOP AT ltlines INTO DATA(walines).


        wa_billinglines-client = SY-MANDT.
        wa_billinglines-bukrs = waheader-CompanyCode.
        wa_billinglines-fiscalyearvalue = waheader-FiscalYear.
        wa_billinglines-billingdocument = waheader-BillingDocument.
        wa_billinglines-billingdocumentitem = walines-BillingDocumentItem.
        wa_billinglines-billingdocumentdate = waheader-BillingDocumentDate.
        wa_billinglines-product = walines-Product.

        wa_billinglines-materialdescription  = walines-ProductDescription.
        wa_billinglines-netamount            = walines-NetAmount.
        wa_billinglines-taxamount            = walines-TaxAmount.

        READ TABLE it_price INTO DATA(wa_price) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'ZMRP'.
        wa_billinglines-mrp                  = wa_price-ConditionRateValue.
        CLEAR wa_price.

        READ TABLE it_price INTO DATA(wa_price0) WITH KEY BillingDocument = waheader-BillingDocument
                                                    BillingDocumentItem = walines-BillingDocumentItem
                                                    ConditionType = 'ZR00'.
*        ls_response-BasicAmt = wa_price0-ConditionRateValue.
        CLEAR wa_price0.

        READ TABLE it_price INTO DATA(wa_priceIRD) WITH KEY BillingDocument = waheader-BillingDocument
                                                    BillingDocumentItem = walines-BillingDocumentItem
                                                    ConditionType = 'ZBSP'.
        if wa_priceird is not initial.
            wa_billinglines-itemrate = wa_priceIRD-ConditionRateValue.
        else.
            READ TABLE it_price INTO DATA(wa_priceIRE) WITH KEY BillingDocument = waheader-BillingDocument
                                                    BillingDocumentItem = walines-BillingDocumentItem
                                                    ConditionType = 'ZEXP'.
            wa_billinglines-itemrate = wa_priceIRE-ConditionRateValue.
        endif.
        CLEAR wa_priceIRD.
        CLEAR wa_priceire.



        READ TABLE it_price INTO DATA(wa_price1) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'JOIG'.
        wa_billinglines-igst                    = wa_price1-ConditionAmount.
        wa_billinglines-rateigst                = wa_price1-ConditionRateValue.
        CLEAR wa_price1.

        READ TABLE it_price INTO DATA(wa_price2) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'JOSG'.
        wa_billinglines-sgst                    = wa_price2-ConditionAmount.
        wa_billinglines-cgst                    = wa_price2-ConditionAmount.
        wa_billinglines-ratecgst                = wa_price2-ConditionRateValue.
        wa_billinglines-ratesgst                = wa_price2-ConditionRateValue.
        CLEAR wa_price2.

        READ TABLE it_price INTO DATA(wa_price4) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'ZDIF'.
        wa_billinglines-roundoff                = wa_price4-ConditionAmount.
        CLEAR wa_price4.

        READ TABLE it_price INTO DATA(wa_price5) WITH KEY BillingDocument = waheader-BillingDocument
                                                     BillingDocumentItem = walines-BillingDocumentItem
                                                     ConditionType = 'ZMAN'.
        wa_billinglines-manditax                = wa_price5-ConditionAmount.
        CLEAR wa_price5.

        READ TABLE it_price INTO DATA(wa_price6) WITH KEY BillingDocument = waheader-BillingDocument
                                                     BillingDocumentItem = walines-BillingDocumentItem
                                                     ConditionType = 'ZMCS'.
        wa_billinglines-mandicess               = wa_price6-ConditionAmount.
        CLEAR wa_price6.

        READ TABLE it_price INTO DATA(wa_price7) WITH KEY BillingDocument = waheader-BillingDocument
                                                 BillingDocumentItem = walines-BillingDocumentItem
                                                 ConditionType = 'ZDIS'.
        wa_billinglines-discount                = wa_price7-ConditionAmount.
        CLEAR wa_price7.

*        wa_billinglines-itemrate                = walines-YY1_IGSTRate_BDI.
        wa_billinglines-totalamount             = walines-NetAmount + walines-TaxAmount.

        SELECT SINGLE FROM i_productsalestax FIELDS Product
          WHERE Product = @walines-Product AND Country = 'IN' AND TaxClassification = '1'
          INTO @DATA(lv_flag).
        IF lv_flag IS NOT INITIAL.
          wa_billinglines-exempted = 'No'.
        ELSE.
          wa_billinglines-exempted = 'Yes'.
        ENDIF.

        wa_billinglines-discountrate            = 0.
        wa_billinglines-billingqtyinsku         = walines-BillingQuantityInBaseUnit.

        READ TABLE it_price INTO DATA(wa_price8) WITH KEY BillingDocument = waheader-BillingDocument
                                                         BillingDocumentItem = walines-BillingDocumentItem
                                                         ConditionType = 'JTC2'.
        wa_billinglines-tcs                     = wa_price8-ConditionAmount.
        wa_billinglines-ratetcs                 = wa_price8-ConditionRateValue.
        CLEAR wa_price8.

        APPEND wa_billinglines TO lt_billinglines.
        CLEAR : wa_billinglines.
      ENDLOOP.
      INSERT zbillinglines FROM TABLE @lt_billinglines.

      wa_billingprocessed-client = SY-MANDT.
      wa_billingprocessed-billingdocument = waheader-BillingDocument.
      wa_billingprocessed-bukrs = waheader-CompanyCode.
      wa_billingprocessed-fiscalyearvalue = waheader-FiscalYear.
      wa_billingprocessed-creationdatetime = lv_timestamp.

      APPEND wa_billingprocessed TO lt_billingprocessed.
      INSERT zbillingproc FROM TABLE @lt_billingprocessed.
      COMMIT WORK.

      CLEAR :  wa_billingprocessed, lt_billingprocessed, lt_billinglines.

    ENDLOOP.

*    SELECT * FROM zbillinglines
*               INTO TABLE @DATA(it).
*    LOOP AT it INTO DATA(wa1).
*      out->write( data = 'Data : client -' ) .
*      out->write( data = wa1-client ) .
*      out->write( data = '- bukrs-' ) .
*      out->write( data = wa1-materialdescription ) .
*      out->write( data = '- doc-' ) .
*      out->write( data = wa1-billingdocument ) .
*      out->write( data = '- item -' ) .
*      out->write( data = wa1-billingdocumentitem ) .
*    endloop.

  ENDMETHOD.
ENDCLASS.
