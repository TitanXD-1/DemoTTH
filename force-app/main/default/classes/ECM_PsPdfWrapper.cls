/*
*@Name: ECM_PsPdfWrapper
*@Description: This Wrapper Class used to store data to display in pdf.
*@History                                                                                                                       

VERSION			AUTHOR					DATE				DETAIL
*1.0		Rajarshi Lahiri			21/02/2023			ECM-6746 : Payment Summary Document_Templates_SFDC
*1.1		Anshu Prakash			24/02/2023		 	ECM-6768 : Payment Summary Document_Product Table_SFDC
*1.3		Rajarshi Lahiri			06/02/2023		 ECM-6792: Payment Summary Document_Text Update_SFDC 
*/

public class ECM_PsPdfWrapper {
    
    public HeaderWrapper headerWrapperValue;
    public BodyWrapper bodyWrapperValue;
    public ProductTableHeaderWrapper productHeaderWrapperValue;
    public List<PsiWrapperTable> psiWrapperValue;
    public DynamicFields dynamicFieldsValue;
    
    public class DynamicFields{
        
        public String conOwnrName{get; set;}
        public String conOwnrEmail{get; set;}
        public String cusLegalName{get; set;}
        public String taxNumber{get; set;}
        public String customerNumber{get; set;}
        public String telephoneNo{get; set;}
        public String conName{get; set;}
        public String conNumber{get; set;}
        public String conStrtDt{get; set;}
        public String paySumStrtDt{get; set;}
        public String paySumEndDt{get; set;}
        public String paySumNumber{get; set;}
        public String contactName{get; set;}
        public String accBillStrt{get; set;}
        public String accBillPostCode{get; set;}
        public String accBillCity{get; set;}
    }
    public class BodyWrapper{
        public String pdfHeading{get;set;}
        public String psPDFHeaderSec{get;set;}
        public String billingDetails{get;set;} 
        public String tableHeading{get; set;}
        public String totalConfAmt{get; set;}
        public String totalConfVol{get; set;}
        public String endContent{get; set;}
        //ECM-6792
        public String conDetStart{get; set;}
        public String conDetEnd{get; set;}
        public String paySumDetailStart{get; set;}
        public String paySumDetailEnd{get; set;}
    }
    public class HeaderWrapper {

        public String newVat{get;set;}
        public string legacyFrontOffice{get;set;}
        public string accountPhone{get;set;}
        public string bank{get;set;}
        public string iban{get;set;}
        public string bic{get;set;}
    }
    Public class ProductTableHeaderWrapper {

        Public String brandName{get;set;}
        Public String productName{get;set;}
        Public String quantity{get;set;}
        Public String bonusPerBottle{get;set;}
        Public String totalBonus{get;set;}
        Public String totalsLabel{get;set;}
    }
    
    
    Public class PsiWrapperTable{
        Public String prodBrandName{get; set;}
        Public String prodName{get;set;}
        Public String prodquantity{get;set;}
        Public String prodBonusPerBottle{get;set;}
        Public String prodTotalBonus{get;set;}                
        
        public psiWrapperTable(ECM_Payment_Summary_Item__c psItem){
            prodBrandName = psItem.ECM_Contract_Item__r.ECM_Brand__c!=null?psItem.ECM_Contract_Item__r.ECM_Brand__c:'';
            prodName = psItem.ECM_Contract_Item__r.ECM_Product_Name__c!=null?psItem.ECM_Contract_Item__r.ECM_Product_Name__c:'';
            prodquantity = psItem.ECM_Confirmed_Volume__c!=null?psItem.ECM_Confirmed_Volume__c.setScale(2).format():'';
            prodBonusPerBottle = (psItem.ECM_Contract_Item__r.ECM_UoM__c!=null)?decimal.valueOf(psItem.ECM_Contract_Item__r.ECM_UoM__c).setScale(2).format():'';
            prodTotalBonus = psItem.ECM_Confirmed_Amount_Per_Payment__c!=null?psItem.ECM_Confirmed_Amount_Per_Payment__c.setScale(2).format():'';
        }
    }
}