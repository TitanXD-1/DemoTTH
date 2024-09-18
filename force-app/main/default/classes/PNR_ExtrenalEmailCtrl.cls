/**********************************************************************
@name PNR_ExternalEmailCtrl

@description This is the Controller class for PNR_ExternalEmailVF page

                                                           
VERSION    AUTHOR            DATE              DETAIL
1.0        Sai Kiran     12-11-2021        Initial Development

***********************************************************************/
public class PNR_ExtrenalEmailCtrl {
    
    
    //Variable declaration starts
    public string documentTypeWithDes{get;set;}
    public boolean docType{get;set;}
    public boolean ceDgt1Var{get;set;}
    public boolean rechargeMeterialEligible{get;set;}
    public string accName{get;set;}
    public string reasonCode{get;set;}
    public string invoiceNumber{get;set;}
    public string refType{get;set;}
    public case csRec{get;set;}
    public Correction_Document__c correctionDoc{get;set;}
    public list<PNR_CorrectionDocumentMapping__c> lineItemsForAll{get;set;}  
    public String multipleRefInvoiceNumbers {get; set;} //PION-1670 : declaring variable to store invoice numbers of multiple reference CD
    //Variable declaration ends
    
    /*
     * @description we are getting correction document details and invoice line items.
     * */
    public PNR_ExtrenalEmailCtrl(){
        docType = false;
        ceDgt1Var = false;
        rechargeMeterialEligible = false;
        lineItemsForAll = new list<PNR_CorrectionDocumentMapping__c>();
        correctionDoc = new Correction_Document__c();
        string recordId  = ApexPages.CurrentPage().getparameters().get('Id');
        Correction_Document__c correctionDoc  =   PNR_OutboundEmailIntegration.getCorrectionInfoDetails(recordId);
        accName= correctionDoc.Sold_To__r.Name;
        reasonCode = correctionDoc.Reason_Code__c;
        invoiceNumber = correctionDoc.Reference_invoice__r.SAP_Invoice_Number__c;
        refType = correctionDoc.Type_of_Reference__c;
        //PION-1670 : Storing invoice number for multiple reference CD
        multipleRefInvoiceNumbers = correctionDoc.Invoices_Affected__c;
        
        if(correctionDoc.Document_Type__c=='YCR' || correctionDoc.Document_Type__c=='YDR' /*|| correctionDoc.Sales_Org__c=='CE01'|| correctionDoc.Sales_Org__c=='DGT1' */){
            docType = True;
        }
        
        if(correctionDoc.Document_Type__c=='YCR'){
            documentTypeWithDes='YCR - Credit Note';
        }
        else if(correctionDoc.Document_Type__c=='YDR'){
            documentTypeWithDes='YDR - Debit Note';
        }
        else if(correctionDoc.Document_Type__c=='YVCR'){ 
            documentTypeWithDes='YVCR - Value Credit';
        }
        else if(correctionDoc.Document_Type__c=='YVDR'){
            documentTypeWithDes='YVDR - Value Debit';
        }
        else if(correctionDoc.Document_Type__c=='YRET'){
            documentTypeWithDes='YRET - Return Credit';
        }
        csRec = [select id,Dispute_Breakdown__c,Dispute_Sub_type__c,CurrencyIsoCode,Claimed_Amount__c  from case where id =: correctionDoc.Case__c];
        lineItemsForAll =  PNR_OutboundEmailIntegration.fetchInvoiceLineItemsForAll(recordId);
        if(correctionDoc.Sales_Org__c == 'CE01' || correctionDoc.Sales_Org__c == 'PE01'){
            for(PNR_CorrectionDocumentMapping__c cdm : lineItemsForAll){
                if(cdm.PNR_Recharge_Material__c !=null){
                    rechargeMeterialEligible = true;
                    break;
                }
            }
        }
        if(correctionDoc.Sales_Org__c == 'CE01' || correctionDoc.Sales_Org__c == 'DGT1'){
                ceDgt1Var = true;
            }
        
    }
}