@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Billing Lines Projection View'
define view entity ZI_BillingLinesTP
  as projection on ZR_BillingLinesTP as BillingLines
{
  key Bukrs,
  key Fiscalyearvalue,
  key Billingdocument,
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
  _BillingDoc : redirected to parent ZI_BillingDocTP
  
}
