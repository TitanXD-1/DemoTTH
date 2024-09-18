/**
 * @name : D1_CheckoutSimulation
 * @description : Wrapper Container Class for Checkout Simulation
 * @author : Dipanjan Das
 * @history :
 * VERSION              AUTHOR                          DATE                DETAIL
 * 1.0                  Dipanjan Das                    01/10/2021          NCP-1834
 * 2.0                  Kapil Baliyan                   01/12/2022          NCP-7580
 */
public class D1_CheckoutSimulation {
    
    public class CartWrapper {
        @AuraEnabled public Id cartId {get; set;}
        @AuraEnabled public WebCart userCart {get; set;}
        @AuraEnabled public Boolean isSimulated {get; set;}
        @AuraEnabled public Boolean isError {get; set;}
        @AuraEnabled public String errorMessage {get; set;}
        @AuraEnabled public String simulationMsg {get; set;}
        @AuraEnabled public Boolean isOutsideATP {get; set;} 
        @AuraEnabled public Integer ATPDays {get; set;}
        @AuraEnabled public Boolean isCreditBlock {get; set;} 
        @AuraEnabled public String creditBlockMsg {get; set;}
        @AuraEnabled public Boolean isProductOutofStock {get; set;}
        @AuraEnabled public String productOutofStockMsg {get; set;}
        @AuraEnabled public Boolean isProductPriceUnavailable {get; set;}
        @AuraEnabled public Boolean isProductBelowMin {get; set;}
        @AuraEnabled public CartTotalWrapper cartTotals {get; set;}
        @AuraEnabled public List<CartItemWrapper> splitcartItems {get; set;}
    }

    public class CartTotalWrapper {
        @AuraEnabled public String splitName {get; set;}
        @AuraEnabled public Decimal splitSubTotal {get; set;}
        @AuraEnabled public Decimal splitTax {get; set;}
        @AuraEnabled public Decimal splitOrderTotal {get; set;}
        @AuraEnabled public Boolean orderBelowMinimum {get; set;} 
        @AuraEnabled public Decimal minThreshold {get; set;}
        @AuraEnabled public Decimal belowThresholdByAmount {get; set;}
        @AuraEnabled public Boolean orderAboveMaximum {get; set;} 
        @AuraEnabled public Decimal maxThreshold {get; set;}
        @AuraEnabled public Decimal aboveThresholdByAmount {get; set;}
        @AuraEnabled public Boolean isHardWarning {get; set;}
    }

    public class CartItemWrapper {
        @AuraEnabled public ConnectApi.AbstractCartItem cartApiData {get;set;}
        @AuraEnabled public String productId {get;set;}
        @AuraEnabled public String brandName {get;set;}
        @AuraEnabled public String productCardTitle {get;set;} //NCP-2309
        @AuraEnabled public String prodSize {get;set;}
        @AuraEnabled public String brandVariantName {get;set;}
        @AuraEnabled public String skuData {get;set;}
        @AuraEnabled public String imageURL {get;set;}
        @AuraEnabled public String currencyCode {get;set;}
        @AuraEnabled public String splitValue {get;set;} 
        @AuraEnabled public String orderedQuantity {get; set;} 
        @AuraEnabled public String confirmedQuantity {get; set;}
        @AuraEnabled public String itemPrice {get; set;}
        @AuraEnabled public String itemTax {get; set;}
        @AuraEnabled public Boolean priceError {get; set;}
        @AuraEnabled public Boolean quantityError {get; set;}
        @AuraEnabled public Boolean belowMinimumError {get; set;}
        @AuraEnabled public Boolean isOutofStock {get; set;} 
        @AuraEnabled public Boolean isPartialOutofStock {get; set;}
        @AuraEnabled public String listPrice {get;set;}
        @AuraEnabled public String unitaryRebate {get;set;}
        @AuraEnabled public String commercialDiscount {get;set;}
        @AuraEnabled public String logisticDiscount {get;set;}
        @AuraEnabled public String otherDiscount {get;set;}
        @AuraEnabled public String discountCurrMark {get;set;}
        @AuraEnabled public String specialTaxDuty {get;set;}
        @AuraEnabled public String netValueUnit {get;set;}
        @AuraEnabled public String vat {get;set;}
    }    
}