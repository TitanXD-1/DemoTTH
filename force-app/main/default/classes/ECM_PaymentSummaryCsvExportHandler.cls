/*
* Class Name: ECM_PaymentSummaryCsvExportHandler
* Author: Keshava Murthy M
* Brief Description: This class is used to send Email with Payment Summary details when Payment Summary is Approved using "ECM Payment Summary Process" Process.
* Created Date: 16/04/2020
* History: 
*
VERSION		AUTHOR           DATE              DETAIL
1.0			Keshav			16/04/2020		ECM-99 SFDC_GLO_Logic: Payment CSV_template.
1.1			Keshav			18/06/2020		ECM-1501 SFDC_GLO_Logic: Internal orders pick-up and amount per product split for multi-fiscal years in CSV.
1.2			Keshav			22/06/2021		ECM-4556 Global Stop sending PS CSV_Logic_GLO_Payment management.
1.3		Saurav Prasad		11/07/2021		ECM-4586 Must Go_Budget Type hard coding in Classes_SFDC_Tech debt
1.4		Saurav Prasad		15/07/2021		ECM-4659 QA defect- As a CIO unable to generate Payment CSV file
.
*/

public class ECM_PaymentSummaryCsvExportHandler {
    @InvocableMethod(label='Payment Summary CSV Export Apex Class' description='Sends an email with PS csv file')
    public static void sendEmail(List<Id> paySumId)
    {   system.debug('Class called'+paySumId);
     try{			
         String body = '';
         String subject;
         String orderReason;
         String pricingCondition;
         String poDate;
         String sapOrderType;
         String currencyIsoCode;
         Boolean materialVal = false;
         Boolean internOrderMapVal = false;
         Boolean conditionVal = false;
         
         List<ECM_Payment_Summary__c> paySumIds = new List<ECM_Payment_Summary__c>();
         List<ECM_Payment_Summary_Item__c> paySumItemIds = new List<ECM_Payment_Summary_Item__c>();
         List<Market_Setting__c> marketObj = new List<Market_Setting__c>();
         List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
         List<String> countryLst = new List<String>();
         List<String> prodIdLst = new List<String>();
         List<ECM_Internal_Order__c> interOrderLst = new List<ECM_Internal_Order__c>();
         List<String> budgetTypeLst = new List<String>();
         List<String> psFisYearLst = new List<String>();
         List<ECM_Internal_Order__c> intOrdDupLst = new List<ECM_Internal_Order__c>();
         List<ECM_Internal_Order__c> intOrdNoDupLst = new List<ECM_Internal_Order__c>();
         
         Map<Id,List<Market_Setting__c>> marSettingMap = new Map<Id,List<Market_Setting__c>>();
         Map<Id,List<ECM_Payment_Summary_Item__c>> paySumItemMap = new Map<Id,List<ECM_Payment_Summary_Item__c>>();
         Map<Id,List<ECM_Internal_Order__c>> internOrderMap = new Map<Id,List<ECM_Internal_Order__c>>();
         Map<Id,Decimal> totMonthIoMap = new Map<Id,Decimal>();
         Map<String,Decimal> IoConAmtMap = new Map<String,Decimal>();
         Map<Id,Decimal> psItemConAmtMap = new Map<Id,Decimal>();
         
         //Payment Summary List
         paySumIds = [SELECT id, Name, ECM_Type__c, ECM_Payment_Summary_Status__c, ECM_Email_Sent__c, ECM_SAP_payment_Reference_Number__c, ECM_Contract__r.Name, ECM_Contract__r.AccountId, ECM_Contract__r.Account.Country__c, ECM_Material_Tax_Classification__c, ECM_Contract__r.Account.Sales_Org__c, ECM_Contract__r.Account.SAP_Sold_to__c, ECM_Invoice_Receival_Date__c,ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c,ECM_Budget_types__c,ECM_Fiscal_Years__c,ECM_Fiscal_Months__c,ECM_Start_Period__c,ECM_End_Period__c,ECM_Budget_types__r.Name,ECM_Budget_types__r.ECM_SAP_Order_reason__c,ECM_Budget_types__r.ECM_SAP_Pricing_condition__c,ECM_Contract__r.Account.Country__r.name,ECM_Recommended_IO_Code__c,ECM_Total_Amount_Confirmed__c,ECM_Total_to_be_Invoiced__c FROM ECM_Payment_Summary__c where id IN:paySumId];
         system.debug('paySumIds-->'+paySumIds);
         //Payment Summary Country List
         for(ECM_Payment_Summary__c paySumLst: paySumIds)
         {
             if(!String.isBlank(paySumLst.ECM_Contract__r.Account.Country__c))
             {
                 countryLst.add(paySumLst.ECM_Contract__r.Account.Country__c);
             }
             
             if(!String.isBlank(paySumLst.ECM_Budget_types__c))
             {
                 budgetTypeLst.add(paySumLst.ECM_Budget_types__c);
             }
             
             if(!String.isBlank(paySumLst.ECM_Fiscal_Years__c))
             {
                 psFisYearLst = (paySumLst.ECM_Fiscal_Years__c).split('/');
             }
         }
         
         Date StartPeriodDate = paySumIds[0].ECM_Start_Period__c;
         Date EndPeriodDate = paySumIds[0].ECM_End_Period__c;
         Date StartPeriod = StartPeriodDate;
         integer noOfMonths = integer.valueOf(paySumIds[0].ECM_Fiscal_Months__c);
         Map<String, Integer> mapFYCount = new Map<String, Integer>();
         for(integer i=0; i<noOfMonths;i++){
             if(StartPeriod.addMonths(i).month()<7){
                 if(mapFYCount.containskey('FY'+string.valueof(StartPeriod.addMonths(i).year()).right(2))){
                     integer count=mapFYCount.get('FY'+string.valueof(StartPeriod.addMonths(i).year()).right(2))+1;
                     mapFYCount.put('FY'+string.valueof(StartPeriod.addMonths(i).year()).right(2),count); 
                 }
                 else{            
                     mapFYCount.put('FY'+string.valueof(StartPeriod.addMonths(i).year()).right(2),1);
                 }
             }   
             else{
                 if(mapFYCount.containskey('FY'+string.valueof(StartPeriod.addMonths(i).year()+1).right(2))){
                     integer count=mapFYCount.get('FY'+string.valueof(StartPeriod.addMonths(i).year()+1).right(2))+1;
                     mapFYCount.put('FY'+string.valueof(StartPeriod.addMonths(i).year()+1).right(2),count);
                 }
                 else{    
                     mapFYCount.put('FY'+string.valueof(StartPeriod.addMonths(i).year()+1).right(2),1);
                 }
             }
         }
         
         //Payment Summary Item List
         if(ECM_Payment_Summary_Item__c.SObjectType.getDescribe().isAccessible()){
            paySumItemIds = [SELECT CurrencyIsoCode,ECM_Confirmed_Amount_Per_Payment__c,ECM_Confirm__c,ECM_Contract_Item__c,ECM_End_Period__c,ECM_Payment_Summary__c,ECM_Planned_Amount_Per_Payment__c,ECM_Reject__c,ECM_Roll_Over__c,Id,Name,Start_Period__c, ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__c,ECM_Payment_Summary__r.ECM_Contract__r.Account.Sales_Org__c, ECM_Payment_Summary__r.ECM_Contract__r.Account.SAP_Sold_to__c, ECM_Payment_Summary__r.Name, ECM_Payment_Summary__r.ECM_Invoice_Receival_Date__c,ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c,ECM_Payment_Summary__r.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c,ECM_Payment_Summary__r.ECM_Tax_Rate__c,ECM_Contract_Item__r.ECM_Product__r.Product__c,ECM_Total_Rebate__c, ECM_Internal_Order__c,  ECM_Internal_Order__r.Name, ECM_Internal_Order__r.ECM_Product__c, ECM_Internal_Order__r.ECM_Fiscal_Year__c FROM ECM_Payment_Summary_Item__c WHERE ECM_Payment_Summary__c IN:paySumIds AND ECM_Confirm__c = true];
         }
         if(paySumItemIds.size()>0){
             for(ECM_Payment_Summary_Item__c paySumObj: paySumItemIds)
             {
                 prodIdLst.add(paySumObj.ECM_Contract_Item__r.ECM_Product__r.Product__c);//Payment Summary Product List			
                 //Payment Summary Item Map
                 if(!paySumItemMap.containsKey(paySumObj.ECM_Payment_Summary__c)){
                     paySumItemMap.put(paySumObj.ECM_Payment_Summary__c,new List<ECM_Payment_Summary_Item__c>{paySumObj});
                 }
                 else{
                     paySumItemMap.get(paySumObj.ECM_Payment_Summary__c).add(paySumObj);
                 }
                 //Confirmed Amount per Payment Summary Item Map
                 psItemConAmtMap.put(paySumObj.ECM_Contract_Item__r.ECM_Product__r.Product__c,paySumObj.ECM_Confirmed_Amount_Per_Payment__c);
             }	
         }
         
         // Market Setting Related to Payment Summary
         marketObj = [SELECT Id, Name__c, ECM_Email_to_Send_Payment_CSV__c, Geography__c, Geography__r.Name, ECM_SAP_Order_Type__c, CurrencyIsoCode FROM Market_Setting__c WHERE Geography__c IN: countryLst ];
         
         // Market Setting Email Map
         if(marketObj.size()>0){
             for(Market_Setting__c marketEmail : marketObj){
                 if(!marSettingMap.containsKey(marketEmail.Geography__c)){
                     marSettingMap.put(marketEmail.Geography__c,new List<Market_Setting__c>{marketEmail});
                 }
                 else{
                     marSettingMap.get(marketEmail.Geography__c).add(marketEmail);
                 }					
             }
         }
         
         // Internal Order Records
         if(ECM_Internal_Order__c.SObjectType.getDescribe().isAccessible()){
            interOrderLst = [ SELECT Id,Name,ECM_Active__c,ECM_Budget_Amount__c,ECM_End_Date__c,ECM_Fiscal_Year__c,ECM_Product__c,ECM_Start_Date__c,ECM_Auto_Assignment__c,ECM_Budget_Type_Pickup_Option__c,LastModifiedDate FROM ECM_Internal_Order__c WHERE ECM_Product__c IN : prodIdLst AND ECM_Budget_Type_Pickup_Option__c IN :budgetTypeLst AND ECM_Fiscal_Year__c IN:psFisYearLst AND ECM_Active__c=true AND ECM_Auto_Assignment__c=true ORDER BY LastModifiedDate DESC NULLS FIRST];
        }
         if(interOrderLst.size()>0){
             //Fileter duplicates based on Fiscal Year
             for(ECM_Internal_Order__c ioLst1 : interOrderLst)
             {
                 Integer count = 0;
                 for(ECM_Internal_Order__c ioLst2 : interOrderLst)
                 {
                     if(ioLst1.ECM_Product__c == ioLst2.ECM_Product__c && ioLst1.ECM_Fiscal_Year__c == ioLst2.ECM_Fiscal_Year__c && ioLst1.ECM_Budget_Type_Pickup_Option__c == ioLst2.ECM_Budget_Type_Pickup_Option__c)
                     {
                         count++;
                         if(count > 1 && ioLst1.Id == ioLst2.Id )
                         {
                             intOrdDupLst.add(ioLst2);
                         }
                     }
                 }
             }
             
             //Internal Order list without duplicate
             intOrdNoDupLst = [ SELECT Id,Name,ECM_Active__c,ECM_Budget_Amount__c,ECM_End_Date__c,ECM_Fiscal_Year__c,ECM_Product__c,ECM_Start_Date__c,ECM_Auto_Assignment__c,ECM_Budget_Type_Pickup_Option__c,LastModifiedDate FROM ECM_Internal_Order__c WHERE ECM_Product__c IN : prodIdLst AND ECM_Budget_Type_Pickup_Option__c IN :budgetTypeLst AND ECM_Fiscal_Year__c IN:psFisYearLst AND ECM_Active__c=true AND ECM_Auto_Assignment__c=true AND Id NOT IN: intOrdDupLst ORDER BY LastModifiedDate DESC NULLS FIRST];
             
             for(ECM_Internal_Order__c inOrdObj : intOrdNoDupLst){
                 //Internal order Map
                 if(!internOrderMap.containsKey(inOrdObj.ECM_Product__c)){
                     internOrderMap.put(inOrdObj.ECM_Product__c,new List<ECM_Internal_Order__c>{inOrdObj});
                 }
                 else{
                     internOrderMap.get(inOrdObj.ECM_Product__c).add(inOrdObj);
                 }                    
             }	
         }
         
         if(psItemConAmtMap!= null && intOrdNoDupLst.size()>0 && mapFYCount.size()>0)
         {
             for(ECM_Internal_Order__c intOrdObj : intOrdNoDupLst){
                 //Months for each IO product and its Fiscal Year
                 IoConAmtMap.put(intOrdObj.ECM_Product__c+intOrdObj.ECM_Fiscal_Year__c,(
                     ( psItemConAmtMap.get(intOrdObj.ECM_Product__c)/paySumIds[0].ECM_Fiscal_Months__c)*mapFYCount.get(intOrdObj.ECM_Fiscal_Year__c)).setScale(2));
             }
         }
         
         //Logic to fetch to address from custom label
         String toaddress = Label.ECM_PS_Error_ToAddress;
         List<String> toAddressLst = toaddress.split(',');
         
         // From Address Org Wide Email 
         OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress where Address =: Label.ECM_OrgWideEmailAddress limit 1];
         
         //Logic to send email
         String recordString;
         string header = 'Order Type, Sales Org, Division, Channel, Sold-to, Ship-to, Bill-to, Payer, PO Number, PO Date, RDD, Pricing Date, Order Reason, Text/Billing Notes for printing, Shipping Instructions, Material, Quantity, UOM, Item Category, Plant, Batch, Material Tax Classification, Internal Order, Cost Center, Fixed Value Date, Pricing Condition, Amount, Currency, Per, Unit, Condition Value, Text/Billing Notes for printing \n';
         string finalstr = header ;
         
         for(ECM_Payment_Summary__c paySumObj: paySumIds){
             
             if(paySumObj.ECM_Invoice_Receival_Date__c != null)
             {
                 DateTime psRecdate = paySumObj.ECM_Invoice_Receival_Date__c;
                 Date psRecdateFormat = date.newinstance(psRecdate.year(), psRecdate.month(), psRecdate.day());
                 poDate = (psRecdateFormat).format();  
             }
             if(paySumObj.ECM_Budget_types__c!=null){
                 // changes applied for ECM-4586
                 orderReason = paySumObj.ECM_Budget_types__r.ECM_SAP_Order_reason__c != Null?paySumObj.ECM_Budget_types__r.ECM_SAP_Order_reason__c:Null;
                 pricingCondition = paySumObj.ECM_Budget_types__r.ECM_SAP_Pricing_condition__c != Null?paySumObj.ECM_Budget_types__r.ECM_SAP_Pricing_condition__c:Null;
                 //end of ECM-4586
             }   
             
             if(marSettingMap.keySet().size()>0){
                 sapOrderType = marSettingMap.get(paySumObj.ECM_Contract__r.Account.Country__c)[0].ECM_SAP_Order_Type__c;
                 currencyIsoCode = marSettingMap.get(paySumObj.ECM_Contract__r.Account.Country__c)[0].CurrencyIsoCode;
             }
			//ECM-4556
             if(paySumItemMap.keySet().size()>0 && internOrderMap.keySet().size()>0){
                 
                 for(ECM_Payment_Summary_Item__c psItem: paySumItemMap.get(paySumObj.id))
                 {	 
                     //Added to check the internOrderMap contains the product - ECM-4659
                     if(sapOrderType!=null && paySumObj.ECM_Contract__r.Account.Sales_Org__c!=null && paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c!=null && paySumObj.Name!=null && poDate!=null && orderReason!=null && psItem.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c!=null && paySumObj.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c!=null && paySumObj.ECM_Material_Tax_Classification__c!=null && internOrderMap.containsKey(psItem.ECM_Contract_Item__r.ECM_Product__r.Product__c) && (psFisYearLst.size() == internOrderMap.get(psItem.ECM_Contract_Item__r.ECM_Product__r.Product__c).size()) && pricingCondition!=null && currencyIsoCode!=null && psItem.ECM_Confirmed_Amount_Per_Payment__c!=null ){
                         
                         for(ECM_Internal_Order__c interOrdObj : internOrderMap.get(psItem.ECM_Contract_Item__r.ECM_Product__r.Product__c)){	
                             if(psItem.ECM_Internal_Order__c != null){
                                recordString = '"'+sapOrderType+'","'+paySumObj.ECM_Contract__r.Account.Sales_Org__c+'","'+'10'+'","'+'10'+'","'+paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c+'","'+paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c+'","'+' '+'","'+' '+'","'+paySumObj.Name+'","'+poDate+'","'+' '+'","'+' '+'","'+orderReason+'","'+' '+'","'+' '+'","'+psItem.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c+'","'+'1'+'","'+'BTL'+'","'+' '+'","'+paySumObj.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c+'","'+' '+'","'+paySumObj.ECM_Material_Tax_Classification__c+'","'+psItem.ECM_Internal_Order__r.Name+'","'+' '+'","'+' '+'","'+pricingCondition+'","'+' '+'","'+currencyIsoCode+'","'+' '+'","'+' '+'","'+IoConAmtMap.get(psItem.ECM_Internal_Order__r.ECM_Product__c+psItem.ECM_Internal_Order__r.ECM_Fiscal_Year__c)+'","'+' ' +'"\n';
                                finalstr = finalstr +recordString;
                             }else{	
                                recordString = '"'+sapOrderType+'","'+paySumObj.ECM_Contract__r.Account.Sales_Org__c+'","'+'10'+'","'+'10'+'","'+paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c+'","'+paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c+'","'+' '+'","'+' '+'","'+paySumObj.Name+'","'+poDate+'","'+' '+'","'+' '+'","'+orderReason+'","'+' '+'","'+' '+'","'+psItem.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c+'","'+'1'+'","'+'BTL'+'","'+' '+'","'+paySumObj.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c+'","'+' '+'","'+paySumObj.ECM_Material_Tax_Classification__c+'","'+interOrdObj.Name+'","'+' '+'","'+' '+'","'+pricingCondition+'","'+' '+'","'+currencyIsoCode+'","'+' '+'","'+' '+'","'+IoConAmtMap.get(interOrdObj.ECM_Product__c+interOrdObj.ECM_Fiscal_Year__c)+'","'+' ' +'"\n';
                                finalstr = finalstr +recordString;	
                             }				
                         }							
                     }
                     else{
                         if(psItem.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c == null)
                         {
                             materialVal = true;
                         }
                         //Added to check the internOrderMap contains the product - ECM-4659
                         if(!internOrderMap.containsKey(psItem.ECM_Contract_Item__r.ECM_Product__r.Product__c) || psFisYearLst.size() != internOrderMap.get(psItem.ECM_Contract_Item__r.ECM_Product__r.Product__c).size())
                         {
                             internOrderMapVal = true;
                         }
                         if(psItem.ECM_Confirmed_Amount_Per_Payment__c == null)
                         {
                             conditionVal = true;
                         }
                         
                     }
                 }
             }else if(paySumItemMap.keySet().size()>0 && paySumObj.ECM_Contract__r.Account.Country__r.name == 'Australia' && paySumObj.ECM_Type__c!='Non-Volume')
            {   
                 for(ECM_Payment_Summary_Item__c psItem: paySumItemMap.get(paySumObj.id))
                 {
                     if(sapOrderType!=null && paySumObj.ECM_Contract__r.Account.Sales_Org__c!=null && paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c!=null && paySumObj.Name!=null && poDate!=null && orderReason!=null && psItem.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c!=null && paySumObj.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c!=null && paySumObj.ECM_Material_Tax_Classification__c!=null && pricingCondition!=null && currencyIsoCode!=null && psItem.ECM_Total_Rebate__c !=null && paySumObj.ECM_Recommended_IO_Code__c!=null ){
                         
                         recordString = '"'+sapOrderType+'","'+paySumObj.ECM_Contract__r.Account.Sales_Org__c+'","'+'10'+'","'+'10'+'","'+paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c+'","'+paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c+'","'+' '+'","'+' '+'","'+paySumObj.Name+'","'+poDate+'","'+' '+'","'+' '+'","'+orderReason+'","'+' '+'","'+' '+'","'+psItem.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c+'","'+'1'+'","'+'BTL'+'","'+' '+'","'+paySumObj.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c+'","'+' '+'","'+paySumObj.ECM_Material_Tax_Classification__c+'","'+paySumObj.ECM_Recommended_IO_Code__c+'","'+' '+'","'+' '+'","'+pricingCondition+'","'+' '+'","'+currencyIsoCode+'","'+' '+'","'+' '+'","'+psItem.ECM_Total_Rebate__c+'","'+' ' +'"\n';
                         finalstr = finalstr +recordString;					
                         
                     }
                     else{
                         if(psItem.ECM_Contract_Item__r.ECM_Product__r.ECM_INTO_Material__c == null)
                         {
                             materialVal = true;
                         }
                         if(psItem.ECM_Total_Rebate__c == null)
                         {
                             conditionVal = true;
                         }
                         
                    }
                }                
                 if(paySumObj.ECM_Recommended_IO_Code__c==null)
                 {
                     body += 'Recommended IO Code Value is Missing.'+'<br/>';
                 }
            }else if(paySumObj.ECM_Contract__r.Account.Country__r.name == 'Australia' && paySumObj.ECM_Type__c=='Non-Volume')
            {   
				system.debug('Inside Non Volume');	
				 //Non-Volume Type CSV ECM-2448
				 if(sapOrderType!=null && paySumObj.ECM_Contract__r.Account.Sales_Org__c!=null && paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c!=null && paySumObj.Name!=null && poDate!=null && orderReason!=null && paySumObj.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c!=null && paySumObj.ECM_Material_Tax_Classification__c!=null && pricingCondition!=null && currencyIsoCode!=null && paySumObj.ECM_Recommended_IO_Code__c!=null && paySumObj.ECM_Total_to_be_Invoiced__c!=null ){
					 
					 recordString = '"'+sapOrderType+'","'+paySumObj.ECM_Contract__r.Account.Sales_Org__c+'","'+'10'+'","'+'10'+'","'+paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c+'","'+paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c+'","'+' '+'","'+' '+'","'+paySumObj.Name+'","'+poDate+'","'+' '+'","'+' '+'","'+orderReason+'","'+' '+'","'+' '+'","'+'125469'+'","'+'1'+'","'+'BTL'+'","'+' '+'","'+paySumObj.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c+'","'+' '+'","'+paySumObj.ECM_Material_Tax_Classification__c+'","'+paySumObj.ECM_Recommended_IO_Code__c+'","'+' '+'","'+' '+'","'+pricingCondition+'","'+' '+'","'+currencyIsoCode+'","'+' '+'","'+' '+'","'+paySumObj.ECM_Total_to_be_Invoiced__c+'","'+' ' +'"\n';
					 finalstr = finalstr +recordString;					
					 
				}
				else{
					if(paySumObj.ECM_Total_to_be_Invoiced__c == null)
					{
						 conditionVal = true;
					}                
					if(paySumObj.ECM_Recommended_IO_Code__c==null)
					{
						 body += 'Recommended IO Code Value is Missing.'+'<br/>';
					}				 
				}
             }
             if(sapOrderType == null){
                 body = 'Order Type value is Missing.'+'<br/>';
             }
             if(paySumObj.ECM_Contract__r.Account.Sales_Org__c == null)
             {
                 body += 'Sales Org value is Missing.'+'<br/>';
             }
             if(paySumObj.ECM_Contract__r.Account.SAP_Sold_to__c == null)
             {
                 body += 'Sold-to value is Missing.'+'<br/>';
             }
             if(paySumObj.Name == null)
             {
                 body += 'PO Number value is Missing.'+'<br/>';
             }
             if(poDate == null)
             {
                 body += 'PO Date value is Missing.'+'<br/>';
             }
             if(orderReason == null)
             {
                 body += 'Order Reason value is Missing.'+'<br/>';
             }
             if(materialVal)
             {
                 body += 'Material value is Missing.'+'<br/>';
             }
             if(paySumObj.ECM_Contract__r.Account.Country__r.ECM_SAP_Plant_for_Payment_File__c == null)
             {
                 body += 'Plant value is Missing.'+'<br/>';
             }
             if(paySumObj.ECM_Material_Tax_Classification__c == null)
             {
                 body += 'Material Tax Classification value is Missing.'+'<br/>';
             }
			 //ECM-4556
             if(internOrderMapVal || (internOrderMap.isEmpty() && paySumObj.ECM_Contract__r.Account.Country__r.name != 'Australia'))
             {
                 body += 'Internal Order value is Missing.'+'<br/>';
             }
             if(pricingCondition == null)
             {
                 body += 'Pricing Condition value is Missing.'+'<br/>';
             }
             if(currencyIsoCode == null)
             {
                 body += 'Currency value is Missing.'+'<br/>';
             }
             if(conditionVal)
             {
                 body += 'Condition Value is Missing.'+'<br/>';
             }
             
             Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
             blob csvBlob;
              Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();	
              email.setOrgWideEmailAddressId(owa.id);
             if(String.isBlank(body)){
                 csvBlob = Blob.valueOf(finalstr);
                // string csvname= 'Payment Summary.csv';
               //  csvAttc.setFileName(csvname);
                // csvAttc.setBody(csvBlob);
             }
            
              /*String[] toAddresses = new list<string> {marSettingMap.get(paySumObj.ECM_Contract__r.Account.Country__c)[0].ECM_Email_to_Send_Payment_CSV__c};
                
            if(String.isBlank(body)){
                 subject ='Payment template for '+paySumObj.Name;
                // email.setHtmlBody('Payment template CSV Attached ');
                // email.setToAddresses(toAddresses);
                // email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
}*/ else{
                        system.debug('I am inside body not blank '+body );
                        subject ='Payment template Error Mail for '+paySumObj.Name;
                        email.setHtmlBody(body);
                        email.setToAddresses(toAddressLst);
                        email.setSubject(subject);
                        allmsg.add(email);
                        Messaging.sendEmail(allmsg); 
                    }
             
             
             if(String.isBlank(body) || Test.isrunningTest()){
                 ContentVersion contentVersion = new ContentVersion();
                 contentVersion.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Payments').getRecordTypeId();
                 contentVersion.Content_Type__c = 'Contracts';
                 contentVersion.Title = paySumObj.Name;
                 contentVersion.VersionData = csvBlob;
                 contentVersion.PathOnClient = 'PaySumExcel.csv';
                 insert contentVersion;
                 
                 ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion where Id = :contentVersion.Id];
                 
                 ContentDocumentLink contentlink=new ContentDocumentLink();
                 contentlink.LinkedEntityId= paySumObj.Id;
                 contentlink.ShareType= 'V';
                 contentlink.ContentDocumentId=testcontent.ContentDocumentId;
                 contentlink.Visibility = 'AllUsers';
                 insert contentlink;
             }
             
         }
     }catch(Exception e){
         System.debug('Exception Caught in ECM_PaymentSummaryCsvExportHandler class at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
     }
    }    
}