/**********************************************************************
@name: PNR_ExternalEmailCtrlTest

@description This is Test class for PNR_ExternalEmailCtrl
                                                                                                                      
VERSION    AUTHOR            DATE              DETAIL
1.0        Sai Kiran     12-11-2021        Initial Development(PION-1631)

***********************************************************************/
@isTest
public class PNR_ExtrenalEmailCtrlTest {
    @testSetup static void setup() {
        
        Id countryId = PNR_TestDataUtility.setupCountry('AUS');
        Account cust= PNR_TestDataUtility.getDirectCustomerRec();
        cust.Country__c=countryId;
        // DML operation here
        insert cust;
        
        Invoice__c inv =PNR_TestDataUtility.getPNRInvoiceData();
        inv.Account__c=cust.Id;
        inv.Sales_Org__c='SE01';
        // DML operation here
        insert inv;
        
        Case cse =PNR_TestDataUtility.getCaseData();
        cse.AccountId=cust.Id;
        cse.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        cse.Reference_Invoice__c=inv.Id;
        // DML operation here
        insert cse;
        
        Correction_Document__c crd =PNR_TestDataUtility.getCorrectionDocData();
        crd.Type_of_Reference__c='Single';
        crd.Reference_invoice__c =inv.Id;
        crd.Correction_Of__c = 'List Price Adjustments Paid On Invoice - YZ81/82';
        crd.Case__c = cse.Id;
        crd.Document_Type__c= 'YCR';
        // DML operation here
        insert crd;
        
        PNR_CorrectionDocumentMapping__c inserInv = new PNR_CorrectionDocumentMapping__c();
        inserInv.Invoice__c = inv.Id;
        inserInv.Product_Number__c = 'Test01';
        inserInv.SAP_Line_Item_Number__c = 'Test01';
        inserInv.Correction_Document__c=crd.Id;
        // DML operation here
        insert inserInv;
    }
    @isTest static void emailBodyTest(){
        Correction_Document__c crd = [select id from Correction_Document__c limit 1]; 
        ApexPages.CurrentPage().getParameters().put('Id',crd.Id);
        PNR_ExtrenalEmailCtrl externalEmailCtrlVar = new PNR_ExtrenalEmailCtrl();
    }
    @isTest static void docTypeIsYDR(){
        Correction_Document__c crd = [select id from Correction_Document__c limit 1];  
        crd.Document_Type__c= 'YDR';
        update crd;        
        ApexPages.CurrentPage().getParameters().put('Id',crd.Id);
        PNR_ExtrenalEmailCtrl externalEmailCtrlVar = new PNR_ExtrenalEmailCtrl();
    }
    @isTest static void docTypeIsYVCR(){ 
        Correction_Document__c crd = [select id from Correction_Document__c limit 1];  
        crd.Document_Type__c= 'YVCR';
        update crd;           
        ApexPages.CurrentPage().getParameters().put('Id',crd.Id);
        PNR_ExtrenalEmailCtrl externalEmailCtrlVar = new PNR_ExtrenalEmailCtrl();
    }
    @isTest static void docTypeIsYVDR(){    
        Correction_Document__c crd = [select id from Correction_Document__c limit 1];  
        crd.Document_Type__c= 'YVDR';
        update crd;           
        ApexPages.CurrentPage().getParameters().put('Id',crd.Id);
        PNR_ExtrenalEmailCtrl externalEmailCtrlVar = new PNR_ExtrenalEmailCtrl();
    }
    @isTest static void docTypeIsYRET(){    
        Correction_Document__c crd = [select id from Correction_Document__c limit 1];  
        crd.Document_Type__c= 'YRET';
        update crd;           
        ApexPages.CurrentPage().getParameters().put('Id',crd.Id);
        PNR_ExtrenalEmailCtrl externalEmailCtrlVar = new PNR_ExtrenalEmailCtrl();
    }
}