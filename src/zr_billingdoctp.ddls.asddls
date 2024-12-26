@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'CDS view for Billing Documents'
define root view entity ZR_BillingDocTP
  as select from ZBILLINGPROC as BillingDoc
  composition [0..*] of ZR_BillingLinesTP as _BillingLines
{
  key BUKRS as Bukrs,
  key FISCALYEARVALUE as Fiscalyearvalue,
  key BILLINGDOCUMENT as Billingdocument,
  @Semantics.systemDateTime.createdAt: true
  CREATIONDATETIME as Creationdatetime,
  _BillingLines
  
}
