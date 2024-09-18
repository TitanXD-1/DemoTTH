/*
@Name: EDGE_SAPWrapper
@Description: This class is used to build the JSON Wrapper for class: EDGE_FreeGoodsOrderToSAPCallout
@History                                                            

VERSION			AUTHOR					DATE				DETAIL
1.0			Saurav Prasad			30/10/2023			Initial Development: 147473 - Salesforce Attribute mapping with corresponding Mulesoft Attribute in JSON file for sending Free Goods Order to SAP
*/
public with sharing class EDGE_SAPWrapper {
    
    public String sapBillTo{get;set;}
    public String sapShippingInstructions{get;set;}
    public String sapFixedValueDate{get;set;}
    public String sapSalesUnit{get;set;}
    public String sapSfdcIn{get;set;}
    public String sapDistrChan{get;set;}
    public String sapTargetQty{get;set;}
    public String sapBatch{get;set;}
    public String sapCostCenter{get;set;}
    public String sapMaterialTaxClassification{get;set;}
    public String sapPurchNoC{get;set;}
    public String sapOrdReason{get;set;}
    public String sapPlant{get;set;}
    public String sapCurrencyValue{get;set;}
    public String sapSalesOrg{get;set;}
    public String sapPoDateS{get;set;}
    public String sapPriceDate{get;set;}
    public String sapDivision{get;set;}
    public String sapCondType{get;set;}
    public String sapPoMethS{get;set;}
    public String sapUnit{get;set;}
    public String sapItemCategory{get;set;}
    public String sapItmNumber{get;set;}
    public String sapAmount{get;set;}
    public String sapBillNote{get;set;}
    public String sapMaterial{get;set;}
    public String sapOrderId{get;set;}
    public String sapPer{get;set;}
    public String sapShipto{get;set;}
    public String sapDocType{get;set;}
    public String sapPayer{get;set;}
    public String sapReqDateH{get;set;}
    public String sapCondValue{get;set;}
    public String sapKunnrSo{get;set;}
    public String sapTaxClass1{get;set;}
    
}