/**********************************************************************
Name: PNR_CreditDebitRetWrapper
=======================================================================
Purpose: This Class is used to create wrapper Data
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0      	Saurav Paul    	  11/08/2019        Wrapper for Correction Document and Line Items
2.0 	    Jayashree R		  26/11/2021		Modified
3.0         Kumar Gaurav      27/05/2022        Modified as of PION-2529(introducing 'Greek Reason Code' for Sales Org GR01)
***********************************************************************/
public class PNR_CreditDebitRetWrapper {
    public String documentType,refInvoice,
    salesOrg,distrChannel,division,poNumber,
    soldTo,shipTo,payer,reasonCode,billingNotes;
    public Integer billTo;
    public String correctionDocumentId, shippingInstructions,
    uSOCFDI,referenceDocuments,requestedDeliveryDate;  // PION-2371  
    public String greekReasonCode;  //PION-2529
    public ChildRecord [] item;
    // PION-2529  
    public PNR_CreditDebitRetWrapper (String documentType,String refInvoice,String salesOrg,
                                        String distrChannel,String division, String poNumber,
                                        String soldTo, String shipTo,Integer billTo,
                                        String payer,String reasonCode,
                                        String billingNotes,String correctionDocumentId,
                                     	String shippingInstructions,String uSOCFDI,// PION-2371 added four fields
                                        String referenceDocuments,String requestedDeliveryDate, String greekReasonCode){
        this.documentType = documentType;
        this.refInvoice = refInvoice;
        this.salesOrg = salesOrg;
        this.distrChannel = distrChannel;
        this.division = division;
        this.poNumber = poNumber;
        this.soldTo = soldTo;
        this.shipTo = shipTo;
        this.billTo = billTo;
        this.payer = payer;
        this.reasonCode = reasonCode;
        this.billingNotes = billingNotes;
        this.correctionDocumentId = correctionDocumentId;  //PION-1668 : created variable 'correctionDocumentId' to include CD Id in the request 
        this.shippingInstructions = shippingInstructions;// PION-2371
        this.uSOCFDI = uSOCFDI;// PION-2371
        this.referenceDocuments = referenceDocuments;// PION-2371
        this.requestedDeliveryDate = requestedDeliveryDate;// PION-2371
        this.greekReasonCode=greekReasonCode; //PION-2529
        item = new ChildRecord [0];
    }
     public PNR_CreditDebitRetWrapper (String documentType,String refInvoice,String salesOrg,
                                        String distrChannel,String division, String poNumber,
                                        String soldTo, String shipTo,Integer billTo,
                                        String payer,String reasonCode,
                                        String billingNotes,String correctionDocumentId,
                                     	String shippingInstructions,String uSOCFDI,// PION-2371 added four fields
                                        String referenceDocuments,String requestedDeliveryDate){
        this.documentType = documentType;
        this.refInvoice = refInvoice;
        this.salesOrg = salesOrg;
        this.distrChannel = distrChannel;
        this.division = division;
        this.poNumber = poNumber;
        this.soldTo = soldTo;
        this.shipTo = shipTo;
        this.billTo = billTo;
        this.payer = payer;
        this.reasonCode = reasonCode;
        this.billingNotes = billingNotes;
        this.correctionDocumentId = correctionDocumentId;  //PION-1668 : created variable 'correctionDocumentId' to include CD Id in the request 
        this.shippingInstructions = shippingInstructions;// PION-2371
        this.uSOCFDI = uSOCFDI;// PION-2371
        this.referenceDocuments = referenceDocuments;// PION-2371
        this.requestedDeliveryDate = requestedDeliveryDate;// PION-2371
        item = new ChildRecord [0];
    }
    
    //Wrapper Class for Line Items
    public class ChildRecord {
        public String productNumber,invoiceMeasure,currencyIsoCode,pricingCondition,plant,batch,claimedNetAmount;
        public Integer invoiceQuantity;
        public ChildRecord (String productNumber,Integer invoiceQuantity,String invoiceMeasure,
                            String currencyIsoCode, String pricingCondition, String plant,
                            String batch, String claimedNetAmount){
            this.productNumber = productNumber;
            this.invoiceQuantity = invoiceQuantity;
            this.invoiceMeasure = invoiceMeasure;
            this.currencyIsoCode = currencyIsoCode;
            this.pricingCondition = pricingCondition;
            this.plant = plant;
            this.batch = batch;
            this.claimedNetAmount = claimedNetAmount;
        }
    }
}