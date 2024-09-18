/*
*@Name: ECM_GetPaymentSummaryDetails
*@description: This is class for fetch required data for VF components "ECM_PaymentSummaryApprovalRequest"
*@History:  
*@AUTHOR                       DATE              DETAIL
*@Anivesh Muppa             13/09/2021        Development for ECM-4343 implement new table and add logic to add few colomns for existing table
*@Anivesh Muppa             13/09/2021        Development for added changes related to ECM-4840
*@T.Manikandan              27/10/2021        Approval Template Null value Bug fix for ECM-4909 
*@Pratap/Subhrojit          06/07/2022        Added brandingTableColNames & productTableColNames
*@Wribhu                    17/08/2022        Added Contract Owner Mail field in getPsDetails() SOQL query (ECM-6033)
*@Saranya                   10/10/2022        Added company name logic for invoice templates (ECM-6233)
*@Wribhu                    26/10/2022        Added decimal formatting (ECM-6270)
*@Anshu						11/01/2023		  ECM-6594 : Addition Info in PS approval mails_SFDC_GLO

*/
Public Class ECM_GetPaymentSummaryDetails {
    Public ID targetObjectId { get; set; }  
    Public String geoCountry { get; set; }     
    Public ECM_Payment_Summary__c paySummary { get; set; } //as part of ECM-4343
    Public Market_Setting__c marketSetting  { get; set; }
    Public boolean enableTarget{ get; set; }
    public decimal ecmTarget{get; set;}
    Public ECM_PaymentSummaryController.brandCalculation paySummaryCal { get; set; } //as part of ECM-4343
    Public List<String> brandingTableColNames {get; set;}
    Public List<String> productTableColNames {get; set;}
    Public String paymentManagementEmail {get;set;}
    Public String companyName {get; set;}
    Public String countryCode {get; set;} //as part of ECM-6702
    Public String totConfAmt {get; set;} //ECM-6270
    Public String addInfo { get; set; } //ECM-6594
    //public String startPeriod{get;set;}  
    //Public String languageCode { get; set; }  
    public void ECM_GetPaymentSummaryDetails(){

    }
    @AuraEnabled
     Public ECM_Payment_Summary__c getPsDetails()
    {
        ECM_Payment_Summary__c ps;
        List<String> companyNames = Label.ECM_Invoice_Mail_Company_Names.split(',');
        //Added ECM_Additional_Info__c,ECM_Budget_types__r.Name for ECM-6594
        List<ECM_Payment_Summary__c>psList = [SELECT Name,ECM_Recommended_IO_Code__c,ECM_Contract__r.ContractNumber,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c,
                                              ECM_Contract__r.ECM_Duration__c,ECM_Contract__r.ECM_ContractCountry__c,ECM_Contract__r.Account.Country__c,ECM_Contract__r.StartDate,
                                              ECM_Contract__r.Contract_End_Date__c,ECM_Contract__r.Account.Country_Code__c,ECM_Contract__r.Account.ECM_Legal_Name__c,ECM_Contract__r.Account.Name,ECM_Contract__r.Account.SAP_Sold_to__c,
                                              ECM_Contract__r.ECM_Select_UoM__c, ECM_SAP_Payment_Date__c, ECM_Type__c, CurrencyIsoCode,ECM_SAP_payment_Reference_Number__c,
                                              ECM_Customer_Name__c,ECM_Start_Period__c, ECM_End_Period__c,ECM_Total_Amount_Confirmed__c,ECM_Total_to_be_Invoiced__c,ECM_Achieved_Leading_Brand__c,
                                              ECM_Achieved_Non_Leading_Brand__c,ECM_Achieved_Overall__c,ECM_Contract__r.Account.Country__r.Code__c,ECM_Contract__r.Owner.Email,ECM_Additional_Info__c,ECM_Budget_types__r.Name,
                                              (SELECT ECM_Confirmed_Amount_Per_Payment__c,ECM_Contract_Item__r.ECM_Product_growth_driver__c,ECM_Contract_Item__r.ECM_UoM__c,
                                               ECM_Contract_Item__r.Name,ECM_Contract_Item__r.ECM_Product_Name__c,ECM_Contract_Item__r.ECM_Lead_Brand__c,ECM_Contract_Item__r.ECM_Volume__c,
                                               ECM_Confirmed_Volume__c FROM Payment_Summary_Item__r)
                                              FROM ECM_Payment_Summary__c
                                              WHERE Id  =: targetObjectId];
        if(psList[0].ECM_Additional_Info__c != Null){
            addInfo = psList[0].ECM_Additional_Info__c;
            addInfo = addInfo.stripHtmlTags();
        }
        if(!psList.isEmpty()){
            geoCountry=psList[0].ECM_Contract__r.Account.Country__c;
            countryCode =psList[0].ECM_Contract__r.Account.Country__r.Code__c;
            System.debug(LoggingLevel.WARN,'@@geoCountry' +geoCountry);
            if(geoCountry!=null){
                Market_Setting__c msList = [SELECT Id, Name__c,ECM_Evidence_email_enabled__c, ECM_Diageo_Entity_Address_for_Invoicing__c, ECM_Payment_Management_Email__c, 
                                            Geography__c, Geography__r.Name,ECM_Enable_Target__c,ECM_Target__c FROM Market_Setting__c WHERE Geography__c =:geoCountry];       
                enableTarget=msList.ECM_Enable_Target__c;
                marketSetting = msList;
                paymentManagementEmail= msList.ECM_Payment_Management_Email__c;
                //changes related to ECM-4840
                ecmTarget=msList?.ECM_Target__c;
                //Company name - ECM-6233
                if(psList[0].ECM_Contract__r.Account.Country_Code__c == 'DE'){
                    companyName = companyNames[0];
                }
                else if(psList[0].ECM_Contract__r.Account.Country_Code__c == 'CH'){
                    companyName = companyNames[1];
                }
                else if(psList[0].ECM_Contract__r.Account.Country_Code__c == 'AT'){
                    companyName = companyNames[2];
                }
                else{
                    companyName = companyNames[3].replace('@countryName@',psList[0].ECM_Contract__r.ECM_ContractCountry__c);
                }
            }
            //ECM-6270 -start
            List<ECM_Invoice_Email_Decimal_Format__mdt> decimalFormat = [SELECT ECM_Locale_Key__c, ECM_Delimiter__c, ECM_Separator__c 
                                                                         FROM ECM_Invoice_Email_Decimal_Format__mdt 
                                                                         WHERE ECM_Locale_Key__c =: psList[0].ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c];
            totConfAmt = psList[0].ECM_Total_Amount_Confirmed__c != null ? (decimalFormat != null ? formatDecimal(psList[0].ECM_Total_Amount_Confirmed__c.toPlainString(), decimalFormat) : psList[0].ECM_Total_Amount_Confirmed__c.toPlainString()) : '';
            //ECM-6270 -end
            paySummary = psList[0];
            //as part of ECM-4343
            if(paySummary!=Null){
                paySummaryCal = ECM_PaymentSummaryController.getBrandCalulation(paySummary);        
            }
            //startPeriod = ((DateTime)psList[0].ECM_Start_Period__c).format('MMMM');
            return psList[0];
        }
        //startPeriod = Null;
        System.debug(LoggingLevel.WARN,'returning null1');        
        return null;
    }
    Public List<ECM_Payment_Summary_Item__c> getPsItemsDetails()
    {
		getPsDetails();
        brandingTableColNames = System.Label.ECM_PSApprovalMailBrandingTableColumns.split(',');
        productTableColNames = System.Label.ECM_PSApprovalMailProductTableColumns.split(',');
        List<ECM_Payment_Summary_Item__c> psItems = [SELECT ECM_Contract_Item__r.Name,ECM_Contract_Item__r.ECM_Product_Name__c,ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c,
                                                     ECM_Payment_Summary__r.Name,ECM_Contract_Item__r.ECM_UoM__c,ECM_Contract_Item__r.ECM_Product_growth_driver__c,
                                                     ECM_Payment_Summary__r.ECM_Achieved_Non_Leading_Brand__c,ECM_Payment_Summary__r.ECM_Type__c,ECM_Confirmed_Amount_Per_Payment__c,
                                                     ECM_Percentage_Target_Achieved__c,ECM_Confirmed_Volume__c,ECM_Contract_Item__r.ECM_Lead_Brand__c,ECM_To_Pay__c,ECM_Updated_Forecasted_Volume__c,
                                                     ECM_Payment_Summary__r.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c
                                                     FROM ECM_Payment_Summary_Item__c 
                                                     WHERE ECM_Payment_Summary__c  =: targetObjectId AND ECM_Confirm__c =True];
        
        for(ECM_Payment_Summary_Item__c psItem:psItems){
            if(enableTarget && psItem.ECM_Payment_Summary__r.ECM_Type__c=='Volume-Based' && !psItem.ECM_Contract_Item__r.ECM_Lead_Brand__c){
                if(ecmTarget!=null) {
                    if(!(ecmTarget<psItem.ECM_Percentage_Target_Achieved__c && ecmTarget<psItem.ECM_Payment_Summary__r.ECM_Achieved_Non_Leading_Brand__c)){                   
                        if(!psItem.ECM_To_Pay__c){
                            psItem.ECM_Confirmed_Amount_Per_Payment__c=0.00;
                        }
                    }
                }else{
                    psItem.ECM_Confirmed_Amount_Per_Payment__c=null;
                }
            }
        }
        
        if(!psItems.isEmpty()){
          System.debug(LoggingLevel.WARN,'@@psItems' +psItems);  
          return psItems;  
        }
        System.debug(LoggingLevel.WARN,'returning null2');
        return null; 
    }
    Public Market_Setting__c getMsDetails(){        
        List<Market_Setting__c> msList;
        //as part of ECM-4343
        if(geoCountry!=Null){
            msList = [SELECT Id, Name__c,ECM_Evidence_email_enabled__c, ECM_Diageo_Entity_Address_for_Invoicing__c, ECM_Payment_Management_Email__c, Geography__c, Geography__r.Name,
                      ECM_Enable_Target__c,ECM_Target__c 
                      FROM Market_Setting__c 
                      WHERE Geography__c =:geoCountry];
        }
        //as part of ECM-4343
        if(paySummary!=Null){
            paySummaryCal = ECM_PaymentSummaryController.getBrandCalulation(paySummary);        
        }
        enableTarget=msList[0].ECM_Enable_Target__c;
        ecmTarget=msList[0].ECM_Target__c;
        if(!msList.isEmpty()){
            return msList[0];
        }
        return null;
    }
    
    //ECM-6270
    //This method is only being used for the VFCs for Payment Summary Invoices, as the decimal values need to be converted to strings for formatting based on market
    Public List<wrapPsItem> getPsItemsInvoiceDetails()
    {
        getPsDetails();
        List<wrapPsItem> psItemsInvoice = new List<wrapPsItem>();
        List<ECM_Payment_Summary_Item__c> psItems = [SELECT ECM_Contract_Item__r.ECM_Product_Name__c,ECM_Contract_Item__r.ECM_UoM__c,ECM_Contract_Item__r.ECM_Product_growth_driver__c,
                                                     ECM_Confirmed_Volume__c,ECM_Confirmed_Amount_Per_Payment__c,ECM_Payment_Summary__r.ECM_Type__c,ECM_Contract_Item__r.ECM_Lead_Brand__c,
                                                     ECM_Percentage_Target_Achieved__c,ECM_Payment_Summary__r.ECM_Achieved_Non_Leading_Brand__c,ECM_To_Pay__c,
                                                     ECM_Payment_Summary__r.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c
                                                     FROM ECM_Payment_Summary_Item__c 
                                                     WHERE ECM_Payment_Summary__c  =: targetObjectId AND ECM_Confirm__c =True];
        
        List<ECM_Invoice_Email_Decimal_Format__mdt> decimalFormat = [SELECT ECM_Locale_Key__c, ECM_Delimiter__c, ECM_Separator__c 
                                                                     FROM ECM_Invoice_Email_Decimal_Format__mdt 
                                                                     WHERE ECM_Locale_Key__c =: psItems[0].ECM_Payment_Summary__r.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c];
        
        for(ECM_Payment_Summary_Item__c psItem:psItems){
            if(enableTarget && psItem.ECM_Payment_Summary__r.ECM_Type__c=='Volume-Based' && !psItem.ECM_Contract_Item__r.ECM_Lead_Brand__c){
                if(ecmTarget!=null) {
                    if(!(ecmTarget<psItem.ECM_Percentage_Target_Achieved__c && ecmTarget<psItem.ECM_Payment_Summary__r.ECM_Achieved_Non_Leading_Brand__c)){                   
                        if(!psItem.ECM_To_Pay__c){
                            psItem.ECM_Confirmed_Amount_Per_Payment__c=0.00;
                        }
                    }
                }else{
                    psItem.ECM_Confirmed_Amount_Per_Payment__c=null;
                }
            }
            wrapPsItem temp = new wrapPsItem(psItem);
            temp.confirmedVolume = psItem.ECM_Confirmed_Volume__c != null ? (decimalFormat != null ? formatDecimal(psItem.ECM_Confirmed_Volume__c.toPlainString(), decimalFormat) : psItem.ECM_Confirmed_Volume__c.toPlainString()) : '';
            temp.confirmedAmt = psItem.ECM_Confirmed_Amount_Per_Payment__c != null ? (decimalFormat != null ? formatDecimal(psItem.ECM_Confirmed_Amount_Per_Payment__c.toPlainString(), decimalFormat) : psItem.ECM_Confirmed_Amount_Per_Payment__c.toPlainString()) : '';
            psItemsInvoice.add(temp);
        }
        
        if(!psItemsInvoice.isEmpty()){
            System.debug(LoggingLevel.WARN,'@@psItems' +psItemsInvoice);  
            return psItemsInvoice;  
        }
        System.debug(LoggingLevel.WARN,'returning null2');
        return null; 
    }
    
    //ECM-6270
    //This method accepts an amount as a String converted from Decimal and the details of the format needed and returns the formatted string
    Public String formatDecimal(String convertedAmt, List<ECM_Invoice_Email_Decimal_Format__mdt> decimalFormat) {
        if(!decimalFormat.isEmpty()) {
            if(convertedAmt.contains(decimalFormat[0].ECM_Delimiter__c)){ //1,234.00 -> delim wanted is , and sep is . -> 1.234,00
                convertedAmt = convertedAmt.replace(decimalFormat[0].ECM_Delimiter__c,'#'); //1#234.00
                convertedAmt = convertedAmt.replace('.',decimalFormat[0].ECM_Delimiter__c); //1#234,00
                convertedAmt = convertedAmt.replace('#',decimalFormat[0].ECM_Separator__c); //1.234,00
            } else {
                convertedAmt = convertedAmt.replace('.',decimalFormat[0].ECM_Delimiter__c);
            }
        }
        return convertedAmt;
    }
    
    //ECM-6270
    //Wrapper class for PS Invoice VFCs
    Public class wrapPsItem {
        Public String productName {get; set;}
        Public String uom {get; set;}
        Public String productGrowthDriver {get; set;}
        Public String confirmedVolume {get; set;}
        Public String confirmedAmt {get; set;}
 
        public wrapPsItem(ECM_Payment_Summary_Item__c psItem) {
            productName = psItem.ECM_Contract_Item__r.ECM_Product_Name__c;
            uom = psItem.ECM_Contract_Item__r.ECM_UoM__c;
            productGrowthDriver = psItem.ECM_Contract_Item__r.ECM_Product_growth_driver__c;
            confirmedVolume = '0.00';
            confirmedAmt = '0.00';
        }
    }

}