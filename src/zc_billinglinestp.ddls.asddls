@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Billing Lines Projection Views'
@ObjectModel.semanticKey: [ 'Billingdocumentitem' ]
@Search.searchable: true
define view entity ZC_BillingLinesTP
  as projection on ZR_BillingLinesTP as BillingLines
{
  @Search.defaultSearchElement: true
  @Search.fuzzinessThreshold: 0.90 
  key Bukrs,
  @Search.defaultSearchElement: true
  @Search.fuzzinessThreshold: 0.90 
  key Fiscalyearvalue,
  @Search.defaultSearchElement: true
  @Search.fuzzinessThreshold: 0.90 
  key Billingdocument,
  @Search.defaultSearchElement: true
  @Search.fuzzinessThreshold: 0.90 
  key Billingdocumentitem,
  Billingdocumentdate,
  Product,
  Materialdescription,
  Netamount,
  Taxamount,
  Mrp,
  Itemrate,
  Igst,
  Sgst,
  Cgst,
  Roundoff,
  Manditax,
  Mandicess,
  Discount,
  Totalamount,
  Exempted,
  Rateigst,
  Ratecgst,
  Ratesgst,
  Discountrate,
  Billingqtyinsku,
  Ratetcs,
  Tcs,
  _BillingDoc : redirected to parent ZC_BillingDocTP
  
}
