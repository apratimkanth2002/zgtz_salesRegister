@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Billing Docs Projection Views'
@ObjectModel.semanticKey: [ 'Bukrs' ]
@Search.searchable: true
define root view entity ZC_BillingDocTP
  provider contract transactional_query
  as projection on ZR_BillingDocTP as BillingDoc
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
  Creationdatetime,
  _BillingLines : redirected to composition child ZC_BillingLinesTP
  
}
