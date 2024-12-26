@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Billing Lines CDS View'
define view entity ZR_BillingLinesTP
  as select from ZBILLINGLINES as BillingLines
  association to parent ZR_BillingDocTP as _BillingDoc on $projection.Bukrs = _BillingDoc.Bukrs and $projection.Fiscalyearvalue = _BillingDoc.Fiscalyearvalue and $projection.Billingdocument = _BillingDoc.Billingdocument
{
  key BUKRS as Bukrs,
  key FISCALYEARVALUE as Fiscalyearvalue,
  key BILLINGDOCUMENT as Billingdocument,
  key BILLINGDOCUMENTITEM as Billingdocumentitem,
  BILLINGDOCUMENTDATE as Billingdocumentdate,
  PRODUCT as Product,
  MATERIALDESCRIPTION as Materialdescription,
  NETAMOUNT as Netamount,
  TAXAMOUNT as Taxamount,
  MRP as Mrp,
  ITEMRATE as Itemrate,
  IGST as Igst,
  SGST as Sgst,
  CGST as Cgst,
  ROUNDOFF as Roundoff,
  MANDITAX as Manditax,
  MANDICESS as Mandicess,
  DISCOUNT as Discount,
  TOTALAMOUNT as Totalamount,
  EXEMPTED as Exempted,
  RATEIGST as Rateigst,
  RATECGST as Ratecgst,
  RATESGST as Ratesgst,
  DISCOUNTRATE as Discountrate,
  BILLINGQTYINSKU as Billingqtyinsku,
  RATETCS as Ratetcs,
  TCS as Tcs,
  _BillingDoc
  
}
