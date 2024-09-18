/*
*@Name: ECM_CreatePaymtSummaryUtility
*@Description: Utility class for creation of payment summaries ECM-3600
*@History                                                                                                                       

VERSION     AUTHOR                      DATE                DETAIL
*1.0        Manikandan                  14/03/2021          Initial Development
*1.1        Saurav Prasad               15/03/2021          ECM-4116
*1.2        Veerendra                   15/03/2021          ECM-3600
*1.3        Chandrakanth                15/03/2021          ECM-4115
*1.4        Veerendra                   23/03/2021          ECM-3599 - Added ECM_createPromoPrepaymentSummaries method
*1.5        Keshav                      23/03/2021          ECM-3597 - Added ECM_createVolBasedRecurringPS method
*1.6        Saurav Prasad               11/05/2021          ECM-4405 (Bug Fix) - Made future methods due to Too many query Exception
*1.7        Manikandan.T                04/06/2021          ECM-4475 - Modified the ECM_createVolBasedRecurringPS method to make the planned amount field null
*1.8        Manikandan.T                16/07/2021          ECM-4663 - Production Fix - Modified the ECM_createVolBasedRecurringPS method and ECM_createPromStandardAfteractivationPS method to insert valid Keys for PS Generation
*1.9        Anivesh Muppa               26/10/2021          ECM-4883 - Logic for PS generation
*1.10       Anivesh Muppa               26/10/2021          ECM-4927 - fix for ECM-4883
*2.0        Subhrojit Majumdar          06/12/2021          ECM-5035 - Bug Fix: Confirmed amount not adding up for Single Yearly Payments.
*2.1        Pratap Sen                  23/03/2022          ECM-5164 - Added payment Frequency(ECM_Payment_Frequency__c) in all PS generation methods & in insertPaymentSummaryandItems()
*2.2        Subhrojit Majumdar          23/03/2022          ECM-5350 - Change in start and end date logic for Promo-Standard PS in ECM_createPromStandardEndofContract()
*2.3        Pratap/Subhrojit            02/08/2022          ECM-5964 - Volume Based PS generation Logic for Addendum in ECM_createVolBasedRecurringPS
*2.4        Pratap/Subhrojit            11/08/2022          ECM-6029 - Non-recurring Promo-Standard & Promo-Prepayment PS generation Logic for Addendum
*2.5        Abhishek S.                 16/08/2022          ECM-5966 - PS generation Logic for Sales Driver-Recurring PF_creen_SFDC_EU
*2.6        Saurav Prasad               10/10/2022          ECM-6214 - Logic for Promo-Std (with rec PF) PS generation_Addendum_SFDC_EU
*2.7        Vinay Tummala               13/10/2022          ECM-6213 - Logic for Volume Based PS generation_Addendum_SFDC_EU
*2.8        Abhishek Shivam             12/10/2022          ECM-6196 - PS Generation on selection of new PF type_Payment by Activation
*2.9        Tanishq Banerjee            23/10/2022          ECM-6216 - Logic for Promo-Std & Pre payment (with non-rec PF) PS generation_Addendum_SFDC_EU
*3.0        Tanishq Banerjee            31/10/2022          ECM-6273 - Overall amount for which PS is generated in child contract is not coming as expected
*4.0        Tanishq Banerjee            10/11/2022          ECM-6316 - CTD KPI Testing
*4.1        Tanishq Banerjee            30/12/2022          ECM-6634 - PROD PDF Generation Issue For Sales Manager and Amendment PS Issue
*4.2        Abhishek Shivam             30/12/2022          ECM-6600 - Payment summary generation in Activation Spend Screen_SFDC_EU

*/
public class ECM_CreatePaymtSummaryUtility {
    /*
    *@ Method name : ECM_createPromoStandardPrePaymentPS
    *@ description  : Generates Promo-Standard PS for Sales-Drivers with Partial-PrePayment Payment Frequency
    *@ return : void
    *@ param : set<Id> setOfSDI - Set of Sales Driver Item Ids, 
    *@         Map<Id,Id> conWithAddendum - Map with Contract Id as Key & related Approved Addendum Id as value
    */
    @future
    public static void ECM_createPromoStandardPrePaymentPS(Set<Id> setOfSDI, Map<Id,Id> conWithAddendum) {
        List < ECM_Sales_Driver_Item__c > lstOfSDI = new List < ECM_Sales_Driver_Item__c >();
        Map<String,paymetWrapper>paymentSumaryListMap= new  Map<String,paymetWrapper>();
        Map<String,wrapperPaymentItem>payItemBudgetMap= new Map<String,wrapperPaymentItem>();
        Map<String,paymetWrapper>paymentSumaryMap= new Map<String,paymetWrapper>();   
        Boolean isAddendum = (conWithAddendum != null);
        String keyStr;
        String productBudgetTypeKey;
        Decimal cal;
        //ECM-6216
        Map<Id,Id> amendedParentId = new Map<Id,Id>();
        Map<String,Decimal> parentConPSIMap = new Map<String,Decimal>();
        String key;
        String getKey;
        Decimal plannedCal;
        
        if(!isAddendum){
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,ECM_1st_Prepayment_Date__c,
                        ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,
                        contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,Contract__r.ECM_Amended__c,Contract__r.ECM_Parent_Contract__c,ECM_Payment_Via_SAP__c, //Added for ECM-6600
                            (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,ECM_Product__r.ECM_Product__c,
                             ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                             ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,
                             ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                             ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,
                             ECM_Sales_Driver_Item__r.Contract__c 
                             FROM Sales_Driver_Item_Details__r) 
                        FROM ECM_Sales_Driver_Item__c 
                        WHERE Id IN: setOfSDI];
            //ECM-6216
            for(ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
                if(sdi.Contract__r.ECM_Amended__c){
                    amendedParentId.put(sdi.Contract__c,sdi.Contract__r.ECM_Parent_Contract__c);
                }
            }
            for(ECM_Payment_Summary__c paySum:
                [SELECT Id,ECM_Start_Period__c,ECM_End_Period__c,ECM_Budget_types__c,
                 ECM_Contract__c,ECM_Payment_Summary_Status__c,ECM_Type__c,ECM_Payment_Frequency__c,ECM_PaymentPSVia_SAP__c,  //Added for ECM-6600
                 (SELECT Id,ECM_Confirmed_Amount_Per_Payment__c,ECM_Contract_Item__r.ECM_Product__c,
                  ECM_Planned_Amount_Per_Payment__c 
                  FROM Payment_Summary_Item__r
                  ORDER BY ECM_End_Period__c DESC)
                 FROM ECM_Payment_Summary__c
                 WHERE ECM_Type__c =: Label.ECM_PSType_PromoStandard
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[0]
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[1]
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[2]
                 AND ECM_Contract__c IN:amendedParentId.values()
                 ORDER BY ECM_End_Period__c DESC]){
                     if(paySum.ECM_Start_Period__c == paySum.ECM_End_Period__c){
                         for(ECM_Payment_Summary_Item__c psItem : paySum.Payment_Summary_Item__r){
                             key = paySum.ECM_Contract__c +'_'+ paySum.ECM_Payment_Frequency__c +'_'
                                 + paySum.ECM_Budget_types__c +'_'+ psItem.ECM_Contract_Item__r.ECM_Product__c +'_'
                                 + paySum.ECM_Start_Period__c+'_'+paySum.ECM_End_Period__c+'_'+paySum.ECM_Type__c+'_'+paySum.ECM_PaymentPSVia_SAP__c;    //Added for ECM-6600
                             parentConPSIMap.put(key,psItem.ECM_Confirmed_Amount_Per_Payment__c);
                         }
                     }
                 }
        } else {
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,ECM_1st_Prepayment_Date__c,
                        ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,
                        contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,ECM_Payment_Via_SAP__c, //Added for ECM-6600
                            (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,ECM_Addendum__c,
                             ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                             ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,
                             ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                             ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,
                             ECM_Sales_Driver_Item__r.Contract__c 
                             FROM Sales_Driver_Item_Details__r
                             WHERE ECM_Addendum__c IN: conWithAddendum.values()) 
                        FROM ECM_Sales_Driver_Item__c 
                        WHERE Id IN: setOfSDI];
        }
        
        for (ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
            paymetWrapper paymentSummary;
            if (sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c != null && !sdi.Sales_Driver_Item_Details__r.isEmpty()) {
                keyStr = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c + '-' + sdi.ECM_Remaining_Payment_Date__c+ '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600
                paymentSummary = (paymentSumaryMap.get(keyStr) == null) ? new paymetWrapper() : paymentSumaryMap.get(keyStr);
                paymentSummary.startPeriod=sdi.ECM_Remaining_Payment_Date__c;
                paymentSummary.endPeriod=paymentSummary.startPeriod;
                paymentSummary.contract=sdi.Contract__c;
                if(isAddendum) {
                    paymentSummary.addendum = conWithAddendum.containsKey(sdi.Contract__c) ? conWithAddendum.get(sdi.Contract__c) : null;
                }
                paymentSummary.PaymentViaSAPCheckbox = sdi.ECM_Payment_Via_SAP__c;//Added for ECM-6600
                paymentSummary.budgetType=sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c;
                paymentSummary.paymentFreq=sdi.ECM_Payment_Frequency__c;
                paymentSummary.type='Promo-Standard';
                paymentSummary.status='Provisional';
                paymentSummary.key = keyStr;
                paymentSumaryMap.put(keyStr,paymentSummary);
                
                List<wrapperPaymentItem> payItemList= new list<wrapperPaymentItem>();
                if (!(sdi.Sales_Driver_Item_Details__r.isEmpty())) {
                    for (ECM_Sales_Driver_Item_Detail__c sdid: sdi.Sales_Driver_Item_Details__r) {
                        //ECM-6216
                        if(!parentConPSIMap.isEmpty()){
                            getKey = sdi.Contract__r.ECM_Parent_Contract__c+'_'+sdi.ECM_Payment_Frequency__c+'_'+sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c
                                +'_'+sdid.ECM_Product__r.ECM_Product__c+'_'+sdi.ECM_Remaining_Payment_Date__c+'_'+sdi.ECM_Remaining_Payment_Date__c+'_'+Label.ECM_PSType_PromoStandard+'_'+sdi.ECM_Payment_Via_SAP__c;   // Added for ECM-6600                 
                        }                                      
                        cal = sdid.ECM_Investment_Amount__c;
                        if (sdid.ECM_Sales_Driver_Item__r.ECM_Prepayment__c != null) {
                            /*
                            if (sdid.ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c == System.today()) {
                                cal = (cal * sdid.ECM_Sales_Driver_Item__r.ECM_Prepayment__c) / 100;
                            }
                            else{
                                cal = cal - ((cal * sdid.ECM_Sales_Driver_Item__r.ECM_Prepayment__c) / 100);
                            }
							*/
                            //Commented the above code since the execution never goes into IF condition.  
                            cal = cal - ((cal * sdid.ECM_Sales_Driver_Item__r.ECM_Prepayment__c) / 100);
                        }
                        //ECM-6216
                        plannedCal = cal;
                        if(!parentConPSIMap.isEmpty() && parentConPSIMap.containsKey(getKey)){
                            cal = cal-parentConPSIMap.get(getKey);
                            parentConPSIMap.remove(getKey);
                        }                        
                        productBudgetTypeKey = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c + '-' + sdi.ECM_Remaining_Payment_Date__c
                                                + '-' + sdid.ECM_Product__c+ '-' + sdi.ECM_Payment_Via_SAP__c;//Added for ECM-6600;
                        wrapperPaymentItem payItem = (payItemBudgetMap.get(productBudgetTypeKey)!=null) ? payItemBudgetMap.get(productBudgetTypeKey) : new wrapperPaymentItem();  
                        payItem.ConfirmedAmountPerPayment = (payItem.ConfirmedAmountPerPayment != null) ? payItem.ConfirmedAmountPerPayment+cal : cal;
                        payItem.PlannedAmountperPayment = (payItem.PlannedAmountperPayment!=null) ? payItem.PlannedAmountperPayment+plannedCal : plannedCal;
                        payItem.contractItem=sdid.ECM_Product__c;
                        payItem.confirm=true;
                        payItem.key = keyStr;
                        
                        if(payItemBudgetMap.get(productBudgetTypeKey)==null){
                            payItemBudgetMap.put(productBudgetTypeKey,payItem);
                            payItemList.add(payItem);
                            /*
                            List<wrapperPaymentItem> promoPayItemList= new list<wrapperPaymentItem>();
                            promoPayItemList=paymentSummary.paytemItemList;
                            promoPayItemList.add(payItem);
                            paymentSummary.paytemItemList=promoPayItemList;
							*/
                            paymentSummary.paytemItemList.add(payItem);
                        }
                        system.debug('paymentSummary-->'+paymentSummary);
                        system.debug('cal-->'+cal);
                        system.debug('cal-->'+paymentSummary.AmountConfirmed);
                        system.debug('cal-->'+paymentSummary.AmountForecasted);
                        paymentSummary.AmountConfirmed+=cal;
                        paymentSummary.AmountForecasted+=plannedCal;       
                    }
                    
                }   
            }
            if(!sdi.Sales_Driver_Item_Details__r.isEmpty() && paymentSummary != null && paymentSumaryListMap.get(paymentSummary.key) == null){
                paymentSumaryListMap.put(paymentSummary.key,paymentSummary);
            }
        }
        // Call generic method for Paymemt Summary creation and Payment summary Line item creation
        insertPaymentSummaryandItems(paymentSumaryListMap.values());
    }
    
    /*
    *@ Method name : ECM_createPromStandardRecurringPS
    *@ description  : Generates Promo-Standard PS for Sales-Drivers with 'Monthly, Quarterly, Half-yearly, Yearly, Monthly Retrospective, Quarterly Retrospective, Half-yearly Retrospective, Yearly Retrospective' Payment Frequency.
    *@ return : void
    *@ param : set<Id> setOfSDI - Set of Sales Driver Item Ids, 
    *@         Map<Id,Id> conWithAddendum - Map with Contract Id as Key & related Approved Addendum Id as value
    */
    @future
    public static void ECM_createPromStandardRecurringPS(set < Id > setOfSDI,  Map<Id,Id> conWithAddendum) {
        List < ECM_Sales_Driver_Item__c > lstOfSDI = new List < ECM_Sales_Driver_Item__c >();
        Map<String,paymetWrapper>paymentSumaryListMap= new  Map<String,paymetWrapper>();
        Map<String,wrapperPaymentItem>payItemBudgetMap= new Map<String,wrapperPaymentItem>();
        Map<String,paymetWrapper>paymentSumaryMap= new Map<String,paymetWrapper>();  
        Map<Id,Date> addendumDates = new Map<Id,Date>();
        Boolean isAddendum = (conWithAddendum != null);
        String keyStr;
        String productBudgetTypeKey;
        Decimal cal;
        Id addendumId;
        Set<Id> conIdSet = new Set<Id>();
        List<ECM_Contract_Item__c> conItems = new List<ECM_Contract_Item__c>();
        Integer addmonths;
        //ECM-6214
        map<Id,Id> amendedParentId = new map<Id,Id>();
        //map<Id,Date> parentContractPaySumDate = new map<Id,Date>();
        map<String,Date> parentContractPaySumDate = new map<String,Date>();
        map<String,Decimal> parentContractPayItemConfirmedAmount = new map<String,Decimal>();
        map<String,Decimal> parentContractPayItemPlannedAmount = new map<String,Decimal>();
        Set<Id> conIds = new Set<Id>();
        Decimal plannedCal;
        Map<String,Decimal> newPSIConfAmt = new Map<String,Decimal>();
        
        if(!isAddendum){
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,ECM_1st_Prepayment_Date__c,
                        ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,
                        contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,
                        Contract__r.ECM_Amended__c,Contract__r.ECM_Parent_Contract__c,Contract__r.CreatedDate,ECM_Payment_Via_SAP__c, //Added for ECM-6600
                        (SELECT Id,ECM_Product__c,ECM_Product__r.ECM_Product__c,ECM_Investment_Amount__c,
                         ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                         ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,
                         ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                         ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,
                         ECM_Sales_Driver_Item__r.Contract__c
                         FROM Sales_Driver_Item_Details__r)
                        FROM ECM_Sales_Driver_Item__c
                        WHERE Id IN: setOfSDI];
            
            //ECM-6214
            for(ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
                if(sdi.Contract__r.ECM_Amended__c){
                    amendedParentId.put(sdi.Contract__c,sdi.Contract__r.ECM_Parent_Contract__c);
                }
                conIds.add(sdi.Contract__c);
            }
            
            for(ECM_Payment_Summary__c paySum:
                [SELECT Id,ECM_Start_Period__c,ECM_End_Period__c,ECM_Budget_types__c,
                 ECM_Contract__c,ECM_Payment_Summary_Status__c,ECM_Type__c,ECM_Payment_Frequency__c,
                 ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,ECM_PaymentPSVia_SAP__c,  //Added for ECM-6600
                 (SELECT Id,ECM_Confirmed_Amount_Per_Payment__c,ECM_Contract_Item__r.ECM_Product__c,
                  ECM_Planned_Amount_Per_Payment__c 
                  FROM Payment_Summary_Item__r
                  ORDER BY ECM_End_Period__c DESC)
                 FROM ECM_Payment_Summary__c
                 WHERE ECM_Type__c =: System.Label.ECM_PSType_PromoStandard
                 AND ECM_Payment_Summary_Status__c !=: System.Label.ECM_PaymentSummaryStatusForAmended.split(';')[0]
                 AND ECM_Payment_Summary_Status__c !=: System.Label.ECM_PaymentSummaryStatusForAmended.split(';')[1]
                 AND ECM_Payment_Summary_Status__c !=: System.Label.ECM_PaymentSummaryStatusForAmended.split(';')[2]
                 AND ECM_Contract__c IN:amendedParentId.values()
                 ORDER BY ECM_End_Period__c DESC]){
                     //ECM-6316 changes added budget type key for amended date check
                     //ECM-6634 
                     String keyForPS = paySum.ECM_Contract__c + '_' + paySum.ECM_Budget_types__c+ '_'+paySum.ECM_Payment_Frequency__c+'_'+paySum.ECM_PaymentPSVia_SAP__c;    //Added for ECM-6600
                     if(!parentContractPaySumDate.containsKey(keyForPS)){
                         parentContractPaySumDate.put(keyForPS,paySum.ECM_End_Period__c);
                     }

                     System.debug('Status@'+paySum.ECM_Payment_Summary_Status__c);
                     if(paySum.ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c != Null){
                         for(ECM_Payment_Summary_Item__c payItem:paySum.Payment_Summary_Item__r){
                             
                             //ECM-6273
                             String temp1 = paySum.ECM_Contract__c+'-'+paySum.ECM_Payment_Frequency__c+'-'+paySum.ECM_Budget_types__c+'-'+
                            	 payItem.ECM_Contract_Item__r.ECM_Product__c+'-'+paySum.ECM_PaymentPSVia_SAP__c;    //Added for ECM-6600
                             if(newPSIConfAmt.containsKey(temp1)){
                                 newPSIConfAmt.put(temp1,newPSIConfAmt.get(temp1) + payItem.ECM_Confirmed_Amount_Per_Payment__c);
                             }else{
                                 newPSIConfAmt.put(temp1,payItem.ECM_Confirmed_Amount_Per_Payment__c);
                             }
                             //confirmed amount per payment
                         }
                     }
                     
                 }
            
        } else {
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,ECM_1st_Prepayment_Date__c,
                        ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,
                        contract__r.Contract_End_Date__c,Contract__r.ECM_Amended__c,Contract__r.CreatedDate,contract__r.ECM_Duration__c,ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,ECM_Payment_Via_SAP__c, //Added for ECM-6600
                        (SELECT Id,ECM_Product__c,ECM_Product__r.ECM_Product__c,ECM_Investment_Amount__c,ECM_Addendum__c,
                         ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                         ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,
                         ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                         ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,
                         ECM_Sales_Driver_Item__r.Contract__c
                         FROM Sales_Driver_Item_Details__r
                         WHERE ECM_Addendum__c IN: conWithAddendum.values())
                        FROM ECM_Sales_Driver_Item__c
                        WHERE Id IN: setOfSDI];
            
            for(ECM_Addendum__c admRec : [SELECT Id,Name,CreatedDate,ECM_Contract__c,
                                          (SELECT Id,Name,ECM_Product__c FROM ECM_Contract_Items__r)
                                          FROM ECM_Addendum__c WHERE Id IN: conWithAddendum.values()]) {
                                              addendumDates.put(admRec.ECM_Contract__c,admRec.CreatedDate.date().toStartOfMonth());
                                              conIds.add(admRec.ECM_Contract__c);
                                          }
        }
        //Record Lock 
        //Identified on ECM-6214 Testing
        List<Contract> conRecords = [SELECT Id FROM Contract WHERE Id IN:conIds FOR UPDATE];
        
        for (ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
            if(!sdi.Sales_Driver_Item_Details__r.isEmpty()){
            addmonths = Integer.valueOf(sdi.ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c);
                //System.debug('Created Date@'+sdi.Contract__r.CreatedDate);
                Date contractCreatedDate = Date.newInstance(sdi.Contract__r.CreatedDate.year(), sdi.Contract__r.CreatedDate.month(),sdi.Contract__r.CreatedDate.day());
                System.debug('contractCreatedDate@'+contractCreatedDate);
                System.debug('End Period@'+parentContractPaySumDate.get(amendedParentId.get(sdi.Contract__c)));
                //ECM-6316 changes added budget type key for amended date check
                //ECM-6634
                String getKeyForPS;
                if(amendedParentId.containskey(sdi.Contract__c)){
                	getKeyForPS =  amendedParentId.get(sdi.Contract__c) + '_'+ sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c+ '_'+sdi.ECM_Payment_Frequency__c+ '_' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600;
                }
                
                date findDate = amendedParentId.containsKey(sdi.Contract__c) && 
                    parentContractPaySumDate.containsKey(getKeyForPS) ? 
                    parentContractPaySumDate.get(getKeyForPS) < contractCreatedDate?
                    parentContractPaySumDate.get(getKeyForPS).addMonths(1).toStartOfMonth():
                contractCreatedDate.toStartOfMonth():sdi.contract__r.StartDate;
                
                //ECM-6273
                Set<String> deleteUniqKey = new Set<String>();      
                Decimal countPS = 0;
                for(date psDate = findDate; psDate < sdi.contract__r.Contract_End_Date__c && psDate != null; psDate=psDate.addmonths(addmonths)){
                    countPS++;
                }
                
                for(date psDate = findDate; psDate < sdi.contract__r.Contract_End_Date__c && psDate != null; psDate=psDate.addmonths(addmonths)){  
                    if(!isAddendum || (isAddendum && addendumDates.containsKey(sdi.contract__r.Id) && psDate.addMonths(addmonths-1) >= addendumDates.get(sdi.contract__r.Id))){ 
                        paymetWrapper paymentSummary;
                        Decimal calculation = 0;
                        if (sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c != null) {
                            keystr = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c+'-'+psDate+'-'+sdi.ECM_Payment_Frequency__c+ '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600;
                            /*if(System.Label.ECM_RetrospectivePFTypes.replace('\r\n','').split(',').contains(sdi.ECM_Payment_Frequency__r.ECM_Type__c)){
                                //Adding PF in the key not to merge two retrospective PF into single PS - ECM-5164
                                keystr = keystr + '-' + sdi.ECM_Payment_Frequency__c;
                            }*/
                            paymentSummary = (paymentSumaryMap.get(keyStr) == null) ? new paymetWrapper() : paymentSumaryMap.get(keyStr);
                            paymentSummary.startPeriod=psDate;
                            paymentSummary.endPeriod=(psDate.addmonths(addmonths)-1) < sdi.contract__r.Contract_End_Date__c ? psDate.addmonths(addmonths)-1:sdi.contract__r.Contract_End_Date__c ;
                            paymentSummary.contract=sdi.Contract__c;
                            if(isAddendum) {
                                paymentSummary.addendum = conWithAddendum.containsKey(sdi.Contract__c) ? conWithAddendum.get(sdi.Contract__c) : null;
                            }
                            paymentSummary.PaymentViaSAPCheckbox = sdi.ECM_Payment_Via_SAP__c;//Added for ECM-6600
                            paymentSummary.budgetType=sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c;
                            paymentSummary.paymentFreq=sdi.ECM_Payment_Frequency__c;
                            paymentSummary.type='Promo-Standard';
                            paymentSummary.status='Provisional';
                            paymentSummary.key=keystr;
                            List<wrapperPaymentItem> payItemList= new list<wrapperPaymentItem>();
                            paymentSumaryMap.put(keystr,paymentSummary);
                            
                            //Double size= Math.ceil(sdi.contract__r.ECM_Duration__c/addmonths);
                            if (!(sdi.Sales_Driver_Item_Details__r.isEmpty())) {
                                for (ECM_Sales_Driver_Item_Detail__c sdid: sdi.Sales_Driver_Item_Details__r) {
                                    
                                    //wrapperPaymentItem payItem= new wrapperPaymentItem();
                                    cal = sdid.ECM_Investment_Amount__c;
                                    if(cal == null){
                                        cal=0;
                                    }
                                    //ECM-6273
                                    cal=cal/countPS; 
                                    plannedCal = cal;
                                    System.debug('cal @'+cal);
                                    
                                    //ECM-6273
                                    if(!newPSIConfAmt.isEmpty()){
                                        String amendString1 = sdi.Contract__r.ECM_Parent_Contract__c+'-'+sdi.ECM_Payment_Frequency__c+'-'+sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c+'-'+
                                        					sdid.ECM_Product__r.ECM_Product__c+ '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600
                                        if(newPSIConfAmt.containsKey(amendString1)){
                                            cal = cal - newPSIConfAmt.get(amendString1)/countPS;
                                            deleteUniqKey.add(amendString1);
                                        }
                                    } 
                                    
                                    //ECM-6214
                                    
                                    System.debug('cal After@'+cal);
                                    productBudgetTypeKey=sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c+'-'+psDate+'-'+sdid.ECM_Product__c+'-'+sdi.ECM_Payment_Frequency__c+ '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600;
                                    /*if(System.Label.ECM_RetrospectivePFTypes.replace('\r\n','').split(',').contains(sdi.ECM_Payment_Frequency__r.ECM_Type__c)){
                                        //Adding PF in the key not to merge two retrospective PF into single PS - ECM-5164
                                        productBudgetTypeKey = productBudgetTypeKey + '-' + sdi.ECM_Payment_Frequency__c;
                                    }*/
                                    wrapperPaymentItem payItem;
                                    if(payItemBudgetMap.get(productBudgetTypeKey)!=null){
                                        //cal=cal+payItemBudgetMap.get(productBudgetTypeKey).ConfirmedAmountPayment;
                                        payItem=payItemBudgetMap.get(productBudgetTypeKey);
                                    }else{
                                        payItem= new wrapperPaymentItem();
                                    }   
                                    if(payItem.ConfirmedAmountPerPayment!=null){
                                        payItem.ConfirmedAmountPerPayment=payItem.ConfirmedAmountPerPayment+cal;
                                    }else{
                                        payItem.ConfirmedAmountPerPayment=cal;
                                    }
                                    if(payItem.PlannedAmountperPayment!=null){
                                        payItem.PlannedAmountperPayment=payItem.PlannedAmountperPayment+plannedCal;
                                    }else{
                                        payItem.PlannedAmountperPayment=plannedCal;
                                    }
                                    payItem.contractItem=sdid.ECM_Product__c;
                                    payItem.confirm=true;
                                    payItem.key=keystr;
                                    
                                    if(payItemBudgetMap.get(productBudgetTypeKey)==null){
                                        payItemBudgetMap.put(productBudgetTypeKey,payItem);
                                        payItemList.add(payItem);
                                        /*
                                        List<wrapperPaymentItem> promoPayItemList= new list<wrapperPaymentItem>();
                                        promoPayItemList=paymentSummary.paytemItemList;
                                        promoPayItemList.add(payItem);
                                        paymentSummary.paytemItemList=promoPayItemList;
										*/
                                        paymentSummary.paytemItemList.add(payItem);
                                    }
                                    system.debug('paymentSummary-->'+paymentSummary);
                                    system.debug('cal-->'+cal);
                                    system.debug('cal-->'+paymentSummary.AmountConfirmed);
                                    system.debug('plannedCal-->'+paymentSummary.AmountForecasted);
                                    paymentSummary.AmountConfirmed+=cal;
                                    paymentSummary.AmountForecasted+=plannedCal;
                                    calculation =  sdi.Contract__r.ECM_Amended__c?paymentSummary.AmountConfirmed:0;
                                }                        
                            }   
                        }
                        if(paymentSummary != null && paymentSumaryListMap.get(paymentSummary.key)==null && calculation >=0){
                            paymentSumaryListMap.put(paymentSummary.key,paymentSummary);
                        }
                    }
                }
                //ECM-6273 
                if(!deleteUniqKey.isEmpty()){
                    for(String key:deleteUniqKey){
                        if(!newPSIConfAmt.isEmpty() && newPSIConfAmt.containsKey(key)){
                            newPSIConfAmt.remove(key);
                        }
                    }
                }                
            } 
        }
        // Call generic method for Paymemt Summary creation and Payment summary Line item creation
        insertPaymentSummaryandItems(paymentSumaryListMap.values());
    }
    
    /*
    *@ Method name : ECM_createVolBasedRecurringPS
    *@ User story  : ECM-3597 PS remodelling_EU_Logic_Volume-based PS generation
    *@ Modification Log :
    *@ VERSION      AUTHOR           DATE                   DETAIL
    *@  1.1     Pratap/Subhrojit   02/08/2022    ECM-5964 - Volume Based PS generation Logic for Addendum
    */ 
    @future
    public static void ECM_createVolBasedRecurringPS(set<id> setOfConId, Map<Id,Id> conWithAddendum) {
        Map<String,paymetWrapper> paymentSumaryListMap = new  Map<String,paymetWrapper>();        
        Map<String,wrapperPaymentItem> payItemBudgetMap = new Map<String,wrapperPaymentItem>();
        Map<String,paymetWrapper> paymentSumaryMap = new Map<String,paymetWrapper>();
        Set<Id> conIdAmendedSet = new Set<Id>();
        Map<Id,Date> addendumDates = new Map<Id,Date>();
        Map<Id,List<ECM_Contract_Item__c>> addendumProducts = new Map<Id,List<ECM_Contract_Item__c>>();
        Map<Id,List<ECM_Payment_Summary__c>> conToPs = new Map<Id,List<ECM_Payment_Summary__c>>();
        Set<Id> conIdSet = new Set<Id>();
        List<ECM_Contract_Item__c> conItems = new List<ECM_Contract_Item__c>();
        Integer addmonths;
        Date startPeriod;
        Id addendumId;
        Boolean isAddendum = (setOfConId == null && conWithAddendum != null);
        try{
            if(isAddendum){
                conIdSet = conWithAddendum.keySet();
                for(ECM_Addendum__c admRec : [SELECT Id,Name,CreatedDate,ECM_Contract__c,(SELECT Id,Name,ECM_Product__c FROM ECM_Contract_Items__r)
                                              FROM ECM_Addendum__c
                                              WHERE Id IN: conWithAddendum.values()])
                {
                    addendumDates.put(admRec.ECM_Contract__c,admRec.CreatedDate.date().toStartOfMonth());
                    addendumProducts.put(admRec.ECM_Contract__c,admRec.ECM_Contract_Items__r);
                }
            }
            else{
                //ECM-6213
                for(Contract con: [Select Id,ECM_Parent_Contract__c,ECM_Amended__c from Contract where Id in:setOfConId]){
                    if(con.ECM_Amended__c){
                        conIdAmendedSet.add(con.ECM_Parent_Contract__c);
                    }
                }
                conIdSet = setOfConId;  
                List<Contract> conPs = ([SELECT Id,(SELECT Id,ECM_End_Period__c,ECM_Payment_Summary_Status__c,ECM_Type__c FROM payment_summary__r 
                                                    WHERE ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[0]
                                                    AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[1]
                                                    AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[2]
                                                    AND ECM_Type__c =: Label.ECM_PSType_VolumeBased
                                                    ORDER BY ECM_End_Period__c DESC) from Contract WHERE Id IN:conIdAmendedSet]);
                for(Contract con: conPs){
                    conToPs.put(con.Id,con.payment_summary__r);
                }
                System.debug('%%%'+conToPs);
                //ECM-6213
                //conIdSet = setOfConId;
            }
            for (Contract conObj: [SELECT Id,ECM_Amended__c,ECM_Parent_Contract__c,ECM_Payment_Frequency_type__c,StartDate,Contract_End_Date__c,
                                   ECM_Payment_Frequency_type__r.ECM_Volume_target__c,
                                   ECM_Payment_Frequency_type__r.ECM_End_Date__c,
                                   ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c,
                                   ECM_Payment_Frequency_type__r.ECM_From_When_Starts__c,CreatedDate,
                                   (SELECT Id,Name,ECM_Product__c FROM Contract_Items__r) 
                                   FROM Contract 
                                   WHERE Id IN : conIdSet AND ECM_Payment_Frequency_type__c != null AND 
                                   ECM_Payment_Frequency_type__r.ECM_Volume_target__c = true]) 
            {
                addendumId = (isAddendum && conWithAddendum.containsKey(conObj.Id))? conWithAddendum.get(conObj.Id) : null;
                if(conObj.ECM_Payment_Frequency_type__r.ECM_End_Date__c){                
                    paymetWrapper paymentSummary = new paymetWrapper();
                    paymentSummary.startPeriod = (isAddendum && addendumDates.containsKey(conObj.Id) && addendumDates.get(conObj.Id) > conObj.StartDate) ?
                                                  addendumDates.get(conObj.Id) : conObj.StartDate;//ECM-6213
                    paymentSummary.endPeriod = conObj.Contract_End_Date__c ;
                    paymentSummary.contract = conObj.Id;
                    paymentSummary.paymentFreq = conObj.ECM_Payment_Frequency_type__c;
                    paymentSummary.PaymentViaSAPCheckbox = False; // ECM-6600 -- NOTI
                    if(isAddendum){
                        paymentSummary.addendum = addendumId;
                    }
                    paymentSummary.type = 'Volume-Based';
                    paymentSummary.status = 'Provisional';
                    paymentSummary.key = conObj.Id; //Production Fix as part of ECM-4663- Insert Key for Volume Based PS
                    
                    List<wrapperPaymentItem> payItemList = new list<wrapperPaymentItem>();
                    conItems = (isAddendum && addendumProducts.containsKey(conObj.Id)) ? addendumProducts.get(conObj.Id) : conObj.Contract_Items__r;
                    
                    if (!conItems.isEmpty()) {                    
                        for (ECM_Contract_Item__c conItm: conItems) {
                            wrapperPaymentItem payItem = new wrapperPaymentItem();
                            payItem.contractItem = conItm.Id;
                            payItem.ConfirmedVolume = 0; 
                            payItem.PlannedAmountperPayment=null; //added for ECM-4475
                            payItem.ConfirmedAmountPerPayment = 0;
                            payItem.confirm = true; 
                            payItem.key = conObj.Id; //Production Fix as part of ECM-4663- Insert Key for Volume Based PS
                            payItemList.add(payItem);     
                        }
                        paymentSummary.paytemItemList = payItemList;                         
                    }                
                    if(paymentSumaryListMap.get(paymentSummary.key) == null){
                        paymentSumaryListMap.put(paymentSummary.key,paymentSummary);
                    }                   
                }
                else if(conObj.ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c != null 
                        && conObj.ECM_Payment_Frequency_type__r.ECM_From_When_Starts__c=='Contract Start Date') {
                            addmonths = Integer.valueOf(conObj.ECM_Payment_Frequency_type__r.ECM_Number_of_months_for_recurrence__c);
                            //ECM-6273
                            startPeriod = (conObj.ECM_Amended__c && conToPs.containsKey(conobj.ECM_Parent_Contract__c) && !conToPs.get(conobj.ECM_Parent_Contract__c).isEmpty()) ?((conObj.CreatedDate.date())<(conToPs.get(conobj.ECM_Parent_Contract__c)[0].ECM_End_Period__c)?
                                                                  conObj.CreatedDate.date().toStartOfMonth()  : conToPs.get(conobj.ECM_Parent_Contract__c)[0].ECM_End_Period__c.addMonths(1).toStartOfMonth()):conObj.StartDate;//ECM-6213
                            for(Date psDate = startPeriod; psDate < conObj.Contract_End_Date__c && psDate != null; psDate = psDate.addmonths(addmonths)) {
                                if(!isAddendum || (isAddendum && addendumDates.containsKey(conObj.Id) && psDate.addMonths(addmonths-1) >= addendumDates.get(conObj.Id))||(conObj.ECM_Amended__c && psDate.addMonths(addmonths-1) >= conObj.CreatedDate.date())){
                                paymetWrapper paymentSummary;
                                string keystr = conObj.Id + '-' + psDate;                
                                if(paymentSumaryMap.get(keystr) == null){
                                    paymentSummary = new paymetWrapper();
                                }
                                else{
                                    paymentSummary = paymentSumaryMap.get(keystr);
                                }
                                paymentSummary.startPeriod = psDate;
                                paymentSummary.endPeriod = (psDate.addmonths(addmonths)-1) < conObj.Contract_End_Date__c ? psDate.addmonths(addmonths)-1:conObj.Contract_End_Date__c ;
                                paymentSummary.contract = conObj.Id;
                                paymentSummary.paymentFreq = conObj.ECM_Payment_Frequency_type__c;
                                if(isAddendum){
                                    paymentSummary.addendum = addendumId;
                                }
                                paymentSummary.type = 'Volume-Based';
                                paymentSummary.status = 'Provisional';
                                paymentSummary.key = keystr;
                                paymentSummary.PaymentViaSAPCheckbox = False; // ECM-6600 -- NOTI
                                paymentSumaryMap.put(keystr,paymentSummary);
                                
                                List<wrapperPaymentItem> payItemList = new list<wrapperPaymentItem>();
                                conItems = (isAddendum && addendumProducts.containsKey(conObj.Id)) ? addendumProducts.get(conObj.Id) : conObj.Contract_Items__r;
                                if (!conItems.isEmpty()) {
                                    for (ECM_Contract_Item__c conItm: conItems) {                       
                                        string productBudgetTypeKey = conObj.Id + '-' + psDate + '-' + conItm.Id;
                                        wrapperPaymentItem payItem;
                                        if(payItemBudgetMap.get(productBudgetTypeKey)!=null){
                                            payItem=payItemBudgetMap.get(productBudgetTypeKey);
                                        }else{
                                            payItem= new wrapperPaymentItem();
                                        }   
                                        payItem.contractItem = conItm.Id;
                                        payItem.ConfirmedVolume = 0; 
                                        payItem.PlannedAmountperPayment = null; //added for ECM-4475
                                        payItem.ConfirmedAmountPerPayment = 0;
                                        payItem.confirm = true;
                                        payItem.key = keystr;
                                        
                                        if(payItemBudgetMap.get(productBudgetTypeKey) == null){
                                            payItemBudgetMap.put(productBudgetTypeKey,payItem);
                                            payItemList.add(payItem);
                                            List<wrapperPaymentItem> promoPayItemList= new list<wrapperPaymentItem>();
                                            promoPayItemList=paymentSummary.paytemItemList;
                                            promoPayItemList.add(payItem);
                                            paymentSummary.paytemItemList=promoPayItemList;
                                        }
                                        
                                    }                        
                                }
                                if(paymentSumaryListMap.get(paymentSummary.key) == null){
                                    paymentSumaryListMap.put(paymentSummary.key,paymentSummary);
                                }
                            }
                }
            }
            }
            // Call generic method for Paymemt Summary creation and Payment summary Line item creation
            if(paymentSumaryListMap.size()>0){
                insertPaymentSummaryandItems(paymentSumaryListMap.values());
            }
        } 
        catch (Exception contractException) {
            System.debug('Class:ECM_CreatePaymtSummaryUtility\nmethod:ECM_createVolBasedRecurringPS\nException:::' + contractException.getLineNumber() +'\n'+ contractException.getMessage() +'\n'+ contractException.getCause());
        }
        }
        
    /*
    *@ Method name : ECM_createPromStandardAfteractivationPS
    *@ description  : Generates Promo-Standard PS for Sales-Drivers with 'Payment After Activation' Payment Frequency
    *@ return : void
    *@ param : set<Id> setOfSDI - Set of Sales Driver Item Ids, 
    *@         Map<Id,Id> conWithAddendum - Map with Contract Id as Key & related Approved Addendum Id as value
    */
    @future
    public static void ECM_createPromStandardAfteractivationPS(Set<Id> setOfSDI, Map<Id,Id> conWithAddendum) {
        List < ECM_Sales_Driver_Item__c > lstOfSDI = new List < ECM_Sales_Driver_Item__c >();
        Map<String,paymetWrapper> paymentSumaryListMap = new  Map<String,paymetWrapper>();
        Map<String,wrapperPaymentItem> payItemBudgetMap = new Map<String,wrapperPaymentItem>();
        Map<String,paymetWrapper> paymentSumaryMap = new Map<String,paymetWrapper>();
        Boolean isAddendum = (conWithAddendum != null);
        String keyStr;
        String productBudgetTypeKey;
        Decimal cal;
        //ECM-6216
        Map<Id,Id> amendedParentId = new Map<Id,Id>();
        Map<String,Decimal> parentConPSIMap = new Map<String,Decimal>();
        String key;
        String getKey;
        
        if(!isAddendum){
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,ECM_1st_Prepayment_Date__c,
                        ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,ECM_Payment_Frequency__r.ECM_Type__c,
                        contract__r.StartDate,contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,Contract__r.ECM_Parent_Contract__c,
                        ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,Contract__r.ECM_Amended__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,ECM_Payment_Via_SAP__c,//Added for ECM-6600
                    (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,ECM_Product__r.ECM_Product__c,
                     ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                     ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                     ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,ECM_Sales_Driver_Item__r.Contract__c
                     FROM Sales_Driver_Item_Details__r) 
                        FROM ECM_Sales_Driver_Item__c WHERE Id IN: setOfSDI];
            //ECM-6216
            for(ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
                if(sdi.Contract__r.ECM_Amended__c){
                    amendedParentId.put(sdi.Contract__c,sdi.Contract__r.ECM_Parent_Contract__c);
                }
            }
            for(ECM_Payment_Summary__c paySum:
                [SELECT Id,ECM_Start_Period__c,ECM_End_Period__c,ECM_Budget_types__c,
                 ECM_Contract__c,ECM_Payment_Summary_Status__c,ECM_Type__c,ECM_Payment_Frequency__c,ECM_PaymentPSVia_SAP__c,    //Added for ECM-6600
                 (SELECT Id,ECM_Confirmed_Amount_Per_Payment__c,ECM_Contract_Item__r.ECM_Product__c,
                  ECM_Planned_Amount_Per_Payment__c 
                  FROM Payment_Summary_Item__r
                  ORDER BY ECM_End_Period__c DESC)
                 FROM ECM_Payment_Summary__c
                 WHERE ECM_Type__c =: Label.ECM_PSType_PromoStandard
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[0]
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[1]
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[2]
                 AND ECM_Contract__c IN:amendedParentId.values()
                 ORDER BY ECM_End_Period__c DESC]){
                    if(paySum.ECM_Start_Period__c == paySum.ECM_End_Period__c){
                        for(ECM_Payment_Summary_Item__c psItem : paySum.Payment_Summary_Item__r){
                            key = paySum.ECM_Contract__c +'_'+ paySum.ECM_Payment_Frequency__c +'_'
                            + paySum.ECM_Budget_types__c +'_'+ psItem.ECM_Contract_Item__r.ECM_Product__c +'_'
                            + paySum.ECM_Start_Period__c+'_'+paySum.ECM_End_Period__c+'_'+paySum.ECM_Type__c+'_'+paySum.ECM_PaymentPSVia_SAP__c;    //Added for ECM-6600;
                            parentConPSIMap.put(key,psItem.ECM_Confirmed_Amount_Per_Payment__c);
                        }                        
                    }
                 }
			}
            else{
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,ECM_1st_Prepayment_Date__c,
                        ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,ECM_Payment_Frequency__r.ECM_Type__c,
                        contract__r.StartDate,contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,
                        ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,ECM_Payment_Via_SAP__c,//Added for ECM-6600
                            (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,ECM_Addendum__c,
                             ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                             ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                             ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,ECM_Sales_Driver_Item__r.Contract__c
                             FROM Sales_Driver_Item_Details__r
                             WHERE ECM_Addendum__c IN: conWithAddendum.values()) 
                        FROM ECM_Sales_Driver_Item__c WHERE Id IN: setOfSDI];
                }
        for(ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
            paymetWrapper paymentSummary;
            if (sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c != null && !sdi.Sales_Driver_Item_Details__r.isEmpty()) {
                keyStr = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c + '-' + sdi.ECM_Payment_Date__c+ '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600
                paymentSummary = (paymentSumaryMap.get(keyStr) == null) ? new paymetWrapper() : paymentSumaryMap.get(keyStr);
                paymentSummary.startPeriod=sdi.ECM_Payment_Date__c;
                paymentSummary.endPeriod=paymentSummary.startPeriod;
                paymentSummary.contract=sdi.Contract__c;
                if(isAddendum) {
                    paymentSummary.addendum = conWithAddendum.containsKey(sdi.Contract__c) ? conWithAddendum.get(sdi.Contract__c) : null;
                }
                paymentSummary.paymentFreq=sdi.ECM_Payment_Frequency__c;
                paymentSummary.PaymentViaSAPCheckbox = sdi.ECM_Payment_Via_SAP__c;//Added for ECM-6600
                paymentSummary.budgetType=sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c;
                paymentSummary.type='Promo-Standard';
                paymentSummary.status='Provisional';
                paymentSummary.key = keyStr;
                paymentSumaryMap.put(keyStr,paymentSummary);
                
                List<wrapperPaymentItem> payItemList= new list<wrapperPaymentItem>();
                if (!(sdi.Sales_Driver_Item_Details__r.isEmpty())) {
                    for (ECM_Sales_Driver_Item_Detail__c sdid: sdi.Sales_Driver_Item_Details__r) {
                        //ECM-6216
                        if(!parentConPSIMap.isEmpty()){
                            getKey = sdi.Contract__r.ECM_Parent_Contract__c+'_'+sdi.ECM_Payment_Frequency__c+'_'+sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c
                                +'_'+sdid.ECM_Product__r.ECM_Product__c+'_'+sdi.ECM_Payment_Date__c+'_'+sdi.ECM_Payment_Date__c+'_'+Label.ECM_PSType_PromoStandard+ '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600              
                        }              
                        if(!parentConPSIMap.isEmpty() && parentConPSIMap.containsKey(getKey)){
                            cal = sdid.ECM_Investment_Amount__c-parentConPSIMap.get(getKey);
                            parentConPSIMap.remove(getKey);
                        }else{                       
                            cal = sdid.ECM_Investment_Amount__c;
                        }
                        //cal = sdid.ECM_Investment_Amount__c;
                        productBudgetTypeKey = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c + '-' + sdi.ECM_Payment_Date__c
                                                + '-' + sdid.ECM_Product__c+ '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600 ; //Production Fix as part of ECM-4663
                        wrapperPaymentItem payItem;
                        payItem = (payItemBudgetMap.get(productBudgetTypeKey) != null) ? payItemBudgetMap.get(productBudgetTypeKey) : new wrapperPaymentItem();   
                        payItem.ConfirmedAmountPerPayment = (payItem.ConfirmedAmountPerPayment != null) ? payItem.ConfirmedAmountPerPayment+cal : cal;
                        payItem.PlannedAmountperPayment = (payItem.PlannedAmountperPayment != null) ? payItem.PlannedAmountperPayment+sdid.ECM_Investment_Amount__c : sdid.ECM_Investment_Amount__c;
                        payItem.contractItem=sdid.ECM_Product__c;
                        payItem.confirm=true;
                        payItem.key = keyStr;
                        
                        if(payItemBudgetMap.get(productBudgetTypeKey)==null){
                            payItemBudgetMap.put(productBudgetTypeKey,payItem);
                            payItemList.add(payItem);
                            /*
                            List<wrapperPaymentItem> promoPayItemList= new list<wrapperPaymentItem>();
                            promoPayItemList=paymentSummary.paytemItemList;
                            promoPayItemList.add(payItem);
                            paymentSummary.paytemItemList=promoPayItemList;
							*/
                            paymentSummary.paytemItemList.add(payItem);
                        }
                        system.debug('paymentSummary-->'+paymentSummary);
                        system.debug('cal-->'+cal);
                        system.debug('cal-->'+paymentSummary.AmountConfirmed);
                        system.debug('cal-->'+paymentSummary.AmountForecasted);
                        paymentSummary.AmountConfirmed+=cal;
                        paymentSummary.AmountForecasted+=sdid.ECM_Investment_Amount__c;       
                    }
                }   
            }
            if(!sdi.Sales_Driver_Item_Details__r.isEmpty() && paymentSummary != null && paymentSumaryListMap.get(paymentSummary.key) == null){
                paymentSumaryListMap.put(paymentSummary.key,paymentSummary);
            }
        }
        // Call generic method for Paymemt Summary creation and Payment summary Line item creation
        insertPaymentSummaryandItems(paymentSumaryListMap.values());
    }
    
    /*
    *@ Method name : ECM_createPromStandardEndofContract
    *@ description  : Generates Promo-Standard PS for Sales-Drivers with 'At the end of the contract' Payment Frequency
    *@ return : void
    *@ param : set<Id> setOfSDI - Set of Sales Driver Item Ids, 
    *@         Map<Id,Id> conWithAddendum - Map with Contract Id as Key & related Approved Addendum Id as value
    */
    @future
    public static void ECM_createPromStandardEndofContract (Set<Id> setOfSDI, Map<Id,Id> conWithAddendum) {
        List < ECM_Sales_Driver_Item__c > lstOfSDI = new List < ECM_Sales_Driver_Item__c >();
        Map<String,paymetWrapper> paymentSumaryListMap = new  Map<String,paymetWrapper>();
        Map<String,wrapperPaymentItem> payItemBudgetMap = new Map<String,wrapperPaymentItem>();
        Map<String,paymetWrapper> paymentSumaryMap = new Map<String,paymetWrapper>();
        Boolean isAddendum = (conWithAddendum != null);
        String keyStr;
        String productBudgetTypeKey;
        Decimal cal;
        //ECM-6216
        Map<Id,Id> amendedParentId = new Map<Id,Id>();
        Map<String,Decimal> parentConPSIMap = new Map<String,Decimal>();
        String key;
        String getKey;
        
        if(!isAddendum){
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,
                        ECM_1st_Prepayment_Date__c,ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,
                        ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,Contract__r.ECM_Amended__c,
                        contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,Contract__r.ECM_Parent_Contract__c,
                        ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,ECM_Payment_Via_SAP__c,//Added for ECM-6600
                    (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,ECM_Product__r.ECM_Product__c,
                     ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                     ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                     ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,ECM_Sales_Driver_Item__r.Contract__c
                     FROM Sales_Driver_Item_Details__r) 
                        FROM ECM_Sales_Driver_Item__c WHERE Id IN: setOfSDI];
           //ECM-6216 
			for(ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
                if(sdi.Contract__r.ECM_Amended__c){
                    amendedParentId.put(sdi.Contract__c,sdi.Contract__r.ECM_Parent_Contract__c);
                }
            }
            for(ECM_Payment_Summary__c paySum:
                [SELECT Id,ECM_Start_Period__c,ECM_End_Period__c,ECM_Budget_types__c,
                 ECM_Contract__c,ECM_Payment_Summary_Status__c,ECM_Type__c,ECM_Payment_Frequency__c,
                 ECM_Contract__r.StartDate,ECM_Contract__r.Contract_End_Date__c,ECM_PaymentPSVia_SAP__c,  //Added for ECM-6600
                 (SELECT Id,ECM_Confirmed_Amount_Per_Payment__c,ECM_Contract_Item__r.ECM_Product__c,
                  ECM_Planned_Amount_Per_Payment__c 
                  FROM Payment_Summary_Item__r
                  ORDER BY ECM_End_Period__c DESC)
                 FROM ECM_Payment_Summary__c
                 WHERE ECM_Type__c =: Label.ECM_PSType_PromoStandard
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[0]
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[1]
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[2]
                 AND ECM_Contract__c IN:amendedParentId.values()
                 ORDER BY ECM_End_Period__c DESC]){
                    if(paySum.ECM_Start_Period__c == paySum.ECM_Contract__r.StartDate && 
                    paySum.ECM_End_Period__c == paySum.ECM_Contract__r.Contract_End_Date__c){
                        for(ECM_Payment_Summary_Item__c psItem : paySum.Payment_Summary_Item__r){
                            key = paySum.ECM_Contract__c +'_'+ paySum.ECM_Payment_Frequency__c +'_'
                            + paySum.ECM_Budget_types__c +'_'+ psItem.ECM_Contract_Item__r.ECM_Product__c +'_'
                            + paySum.ECM_Start_Period__c+'_'+paySum.ECM_Type__c+'_'+paySum.ECM_PaymentPSVia_SAP__c;    //Added for ECM-6600
                            parentConPSIMap.put(key,psItem.ECM_Confirmed_Amount_Per_Payment__c);
                        }
                    }
             }
        }
        else{
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,
                        ECM_1st_Prepayment_Date__c,ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,
                        ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,
                        contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,
                        ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,RecordTypeId,ECM_Payment_Via_SAP__c, //Added for ECM-6600
                            (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,ECM_Addendum__c,
                             ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                             ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                             ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,ECM_Sales_Driver_Item__r.Contract__c
                             FROM Sales_Driver_Item_Details__r
                             WHERE ECM_Addendum__c IN: conWithAddendum.values()) 
                        FROM ECM_Sales_Driver_Item__c WHERE Id IN: setOfSDI];
                }
        
        for (ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
            paymetWrapper paymentSummary;
            if (sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c != null && !sdi.Sales_Driver_Item_Details__r.isEmpty()) {
                keyStr = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c + '-' + sdi.ECM_Payment_Frequency__c + '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600
                paymentSummary = (paymentSumaryMap.get(keyStr) == null) ? new paymetWrapper() : paymentSumaryMap.get(keyStr);
                paymentSummary.startPeriod=sdi.contract__r.StartDate;//ECM-5350
                paymentSummary.endPeriod=sdi.contract__r.Contract_End_Date__c;//ECM-5350
                paymentSummary.contract=sdi.Contract__c;
                if(isAddendum) {
                    paymentSummary.addendum = conWithAddendum.containsKey(sdi.Contract__c) ? conWithAddendum.get(sdi.Contract__c) : null;
                }
                paymentSummary.PaymentViaSAPCheckbox = sdi.ECM_Payment_Via_SAP__c;//Added for ECM-6600
               // sdi.RecordTypeId.equals(System.label.ECM_Activation_Spend)? paymentSummary.PaymentViaSAPCheckbox = sdi.ECM_Payment_Via_SAP__c : paymentSummary.PaymentViaSAPCheckbox = false;
                paymentSummary.budgetType=sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c;
                paymentSummary.paymentFreq=sdi.ECM_Payment_Frequency__c;
                paymentSummary.type='Promo-Standard';
                paymentSummary.status='Provisional';
                paymentSummary.key = keyStr;
                paymentSumaryMap.put(keyStr,paymentSummary);
                
                List<wrapperPaymentItem> payItemList= new list<wrapperPaymentItem>();
                if (!(sdi.Sales_Driver_Item_Details__r.isEmpty())) {
                    for (ECM_Sales_Driver_Item_Detail__c sdid: sdi.Sales_Driver_Item_Details__r) {
                        //ECM-6216
                        if(!parentConPSIMap.isEmpty()){
                            getKey = sdi.Contract__r.ECM_Parent_Contract__c+'_'+sdi.ECM_Payment_Frequency__c+'_'+sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c
                                +'_'+sdid.ECM_Product__r.ECM_Product__c+'_'+sdi.contract__r.StartDate+'_'+Label.ECM_PSType_PromoStandard+'_'+sdi.ECM_Payment_Via_SAP__c;   // Added for ECM-6600          
                        }
                        if(!parentConPSIMap.isEmpty() && parentConPSIMap.containsKey(getKey)){
                            cal = sdid.ECM_Investment_Amount__c-parentConPSIMap.get(getKey);
                            parentConPSIMap.remove(getKey);
                        }else{                       
                            cal = sdid.ECM_Investment_Amount__c;
                        }                        
                        productBudgetTypeKey = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c + '-' + sdid.ECM_Product__c + '-' + sdi.ECM_Payment_Frequency__c + '-' + sdi.ECM_Payment_Via_SAP__c;//Added for ECM-6600
                        
                        wrapperPaymentItem payItem;
                        payItem = (payItemBudgetMap.get(productBudgetTypeKey) != null) ? payItemBudgetMap.get(productBudgetTypeKey) : new wrapperPaymentItem();
                        payItem.ConfirmedAmountPerPayment = (payItem.ConfirmedAmountPerPayment != null) ? payItem.ConfirmedAmountPerPayment+cal : cal;
                        payItem.PlannedAmountperPayment = (payItem.PlannedAmountperPayment != null) ? payItem.PlannedAmountperPayment+cal : cal;//ECM-6600
                        payItem.contractItem=sdid.ECM_Product__c;
                        payItem.confirm=true;
                        payItem.key = keyStr;
                        
                        if(payItemBudgetMap.get(productBudgetTypeKey)==null){
                            payItemBudgetMap.put(productBudgetTypeKey,payItem);
                            payItemList.add(payItem);
                            List<wrapperPaymentItem> promoPayItemList= new list<wrapperPaymentItem>();
                            promoPayItemList=paymentSummary.paytemItemList;
                            promoPayItemList.add(payItem);
                            paymentSummary.paytemItemList=promoPayItemList;
                        }
                        paymentSummary.AmountConfirmed+=cal;
                        paymentSummary.AmountForecasted+=cal;//ECM-6600      
                    }
                }   
            }
            if(!sdi.Sales_Driver_Item_Details__r.isEmpty() && paymentSummary != null && paymentSumaryListMap.get(paymentSummary.key) == null){
                paymentSumaryListMap.put(paymentSummary.key,paymentSummary);
            }
        }
        // Call generic method for Paymemt Summary creation and Payment summary Line item creation
        insertPaymentSummaryandItems(paymentSumaryListMap.values());
    }
    
/*
*@Method name : ECM_createPromoPrepaymentSummaries
*@User story  :ECM-3599 PS remodelling_EU_Logic_Promo-Prepayment PS generation
    *@ description  : Generates Promo-Prepayment PS for Sales-Drivers with Payment Frequency
    *@                where 'Prepayment' is checked i.e. for 'partial prepayment' & '100% prepayment' Payment Frequency
    *@ return : void
    *@ param : set<Id> setOfSDI - Set of Sales Driver Item Ids, 
    *@         Map<Id,Id> conWithAddendum - Map with Contract Id as Key & related Approved Addendum Id as value
*/
    @future
    public static void ECM_createPromoPrepaymentSummaries(Set<Id> setOfSDI, Map<Id,Id> conWithAddendum) {
        List < ECM_Sales_Driver_Item__c > lstOfSDI = new List < ECM_Sales_Driver_Item__c >();
        Map<String,paymetWrapper> paymentSumaryListMap = new Map<String,paymetWrapper>();
        Map<String,wrapperPaymentItem> payItemBudgetMap = new Map<String,wrapperPaymentItem>();
        Map<String,paymetWrapper> paymentSumaryMap = new Map<String,paymetWrapper>();
        Boolean isAddendum = (conWithAddendum != null);
        String keyStr;
        String productBudgetTypeKey;
        Decimal cal;
        //ECM-6216
        Map<Id,Id> amendedParentId = new Map<Id,Id>();
        Map<String,Decimal> parentConPSIMap = new Map<String,Decimal>();
        String key;
        String getKey;
        Decimal plannedCal;
        
        if(!isAddendum){
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,
                        ECM_1st_Prepayment_Date__c,ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,
                        ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,Contract__r.ECM_Amended__c,
                        contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,Contract__r.ECM_Parent_Contract__c,
                        ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,ECM_Payment_Via_SAP__c,//Added for ECM-6600
                    (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,ECM_Product__r.ECM_Product__c,
                     ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                     ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                     ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,ECM_Sales_Driver_Item__r.Contract__c
                     FROM Sales_Driver_Item_Details__r) 
                        FROM ECM_Sales_Driver_Item__c WHERE Id IN: setOfSDI];
            //ECM-6216
            for(ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
                if(sdi.Contract__r.ECM_Amended__c){
                    amendedParentId.put(sdi.Contract__c,sdi.Contract__r.ECM_Parent_Contract__c);
                }
            }
            for(ECM_Payment_Summary__c paySum:
                [SELECT Id,ECM_Start_Period__c,ECM_End_Period__c,ECM_Budget_types__c,
                 ECM_Contract__c,ECM_Payment_Summary_Status__c,ECM_Type__c,ECM_Payment_Frequency__c,
                 ECM_Contract__r.StartDate,ECM_Contract__r.Contract_End_Date__c,ECM_PaymentPSVia_SAP__c,   //Added for ECM-6600
                 (SELECT Id,ECM_Confirmed_Amount_Per_Payment__c,ECM_Contract_Item__r.ECM_Product__c,
                  ECM_Planned_Amount_Per_Payment__c 
                  FROM Payment_Summary_Item__r
                  ORDER BY ECM_End_Period__c DESC)
                 FROM ECM_Payment_Summary__c
                 WHERE ECM_Type__c =: Label.ECM_PromoPrepayment
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[0]
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[1]
                 AND ECM_Payment_Summary_Status__c !=: Label.ECM_PaymentSummaryStatusForAmended.split(';')[2]
                 AND ECM_Contract__c IN:amendedParentId.values()
                 ORDER BY ECM_End_Period__c DESC]){
                    for(ECM_Payment_Summary_Item__c psItem : paySum.Payment_Summary_Item__r){
                        key = paySum.ECM_Contract__c +'_'+ paySum.ECM_Payment_Frequency__c +'_'
                        + paySum.ECM_Budget_types__c +'_'+ psItem.ECM_Contract_Item__r.ECM_Product__c +'_'
                        +paySum.ECM_Type__c+'_'+ paySum.ECM_Start_Period__c+'_'+paySum.ECM_PaymentPSVia_SAP__c;    //Added for ECM-6600
                        parentConPSIMap.put(key,psItem.ECM_Confirmed_Amount_Per_Payment__c);
                    }
                 }
        }
        else{
            lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,
                        ECM_1st_Prepayment_Date__c,ECM_Payment_Frequency__c,ECM_Remaining_Payment_Date__c,
                        ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,
                        contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,
                        ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,
                        ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,ECM_Payment_Via_SAP__c,//Added for ECM-6600
                            (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,
                             ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,
                             ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,ECM_Sales_Driver_Item__r.ECM_Prepayment__c,
                             ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,ECM_Sales_Driver_Item__r.Contract__c
                             FROM Sales_Driver_Item_Details__r
                             WHERE ECM_Addendum__c IN: conWithAddendum.values()) 
                        FROM ECM_Sales_Driver_Item__c WHERE Id IN: setOfSDI];
        }
        
        for (ECM_Sales_Driver_Item__c sdi: lstOfSDI) {
            paymetWrapper paymentSummary;
            if (sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c != null && !sdi.Sales_Driver_Item_Details__r.isEmpty()) {
                keyStr = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c+ '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600
                keyStr = (sdi.ECM_Payment_Date__c!=null) ? keyStr + '-' + sdi.ECM_Payment_Date__c : keyStr + '-' + sdi.ECM_1st_Prepayment_Date__c;
                paymentSummary = (paymentSumaryMap.get(keystr) == null) ? new paymetWrapper() : paymentSumaryMap.get(keystr);
                paymentSummary.startPeriod = (sdi.ECM_Payment_Date__c != null) ? sdi.ECM_Payment_Date__c : sdi.ECM_1st_Prepayment_Date__c;
                paymentSummary.endPeriod=paymentSummary.startPeriod;
                paymentSummary.contract=sdi.Contract__c;
                if(isAddendum) {
                    paymentSummary.addendum = conWithAddendum.containsKey(sdi.Contract__c) ? conWithAddendum.get(sdi.Contract__c) : null;
                }
                paymentSummary.budgetType=sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c;
                paymentSummary.paymentFreq=sdi.ECM_Payment_Frequency__c;
                paymentSummary.PaymentViaSAPCheckbox = sdi.ECM_Payment_Via_SAP__c;//Added for ECM-6600
                paymentSummary.type='Promo-PrePayment';
                paymentSummary.status='Provisional';
                paymentSummary.key = keyStr;
                paymentSumaryMap.put(keystr,paymentSummary);
                
                List<wrapperPaymentItem> payItemList = new list<wrapperPaymentItem>();
                if (!(sdi.Sales_Driver_Item_Details__r.isEmpty())) {
                    for (ECM_Sales_Driver_Item_Detail__c sdid: sdi.Sales_Driver_Item_Details__r) {
                        //ECM-6216
                        if(!parentConPSIMap.isEmpty()){
                            getKey = sdi.Contract__r.ECM_Parent_Contract__c+'_'+sdi.ECM_Payment_Frequency__c+'_'+sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c
                                +'_'+sdid.ECM_Product__r.ECM_Product__c+'_'+Label.ECM_PromoPrepayment+'_'+ sdi.ECM_Payment_Via_SAP__c+'_';  //Added for ECM-6600
                            getKey += (sdi.ECM_Payment_Date__c != null)? sdi.ECM_Payment_Date__c : sdi.ECM_1st_Prepayment_Date__c;           
                        }
                        cal = sdid.ECM_Investment_Amount__c;
                        if (sdid.ECM_Sales_Driver_Item__r.ECM_Prepayment__c != null) {
                            if (sdid.ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c!=null) {
                                cal = (cal * sdid.ECM_Sales_Driver_Item__r.ECM_Prepayment__c) / 100;
                            } /*else {
                                cal = cal - ((cal * sdid.ECM_Sales_Driver_Item__r.ECM_Prepayment__c) / 100);
                            }*/
                            //Commented the above since execution never goes into ELSE condition
                        }
                        //ECM-6216
                        plannedCal=cal;
                        if(!parentConPSIMap.isEmpty() && parentConPSIMap.containsKey(getKey)){
                            cal = cal-parentConPSIMap.get(getKey);
                            parentConPSIMap.remove(getKey);
                        }
                        productBudgetTypeKey = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c + '-' + paymentSummary.startPeriod
                            + '-' + sdid.ECM_Product__c+ '-' + sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600
                        wrapperPaymentItem payItem;
                        payItem = (payItemBudgetMap.get(productBudgetTypeKey) != null) ? payItemBudgetMap.get(productBudgetTypeKey) : new wrapperPaymentItem(); 
                        payItem.ConfirmedAmountPerPayment = (payItem.ConfirmedAmountPerPayment != null) ? payItem.ConfirmedAmountPerPayment+cal : cal;
                        payItem.PlannedAmountperPayment = (payItem.PlannedAmountperPayment!=null) ? payItem.PlannedAmountperPayment+plannedCal : plannedCal;
                        payItem.contractItem=sdid.ECM_Product__c;
                        payItem.confirm=true;
                        payItem.key = keyStr;
                        
                        if(payItemBudgetMap.get(productBudgetTypeKey)==null){
                            payItemBudgetMap.put(productBudgetTypeKey,payItem);
                            payItemList.add(payItem);
                            /*
                            List<wrapperPaymentItem> promoPayItemList= new list<wrapperPaymentItem>();
                            promoPayItemList=paymentSummary.paytemItemList;
                            promoPayItemList.add(payItem);
                            paymentSummary.paytemItemList=promoPayItemList;
							*/
                            paymentSummary.paytemItemList.add(payItem);
                        }
                        
                        paymentSummary.AmountConfirmed+=cal;
                        paymentSummary.AmountForecasted+=plannedCal;       
                    }
                }   
            }
            if(!sdi.Sales_Driver_Item_Details__r.isEmpty() && paymentSummary != null && paymentSumaryListMap.get(paymentSummary.key) == null){
                paymentSumaryListMap.put(paymentSummary.key,paymentSummary);
            }
        }
        // Call generic method for Paymemt Summary creation and Payment summary Line item creation
        insertPaymentSummaryandItems(paymentSumaryListMap.values());
    }

    public static void insertPaymentSummaryandItems(List<paymetWrapper> paymentSummaryList){
        Map<String,ECM_Payment_Summary__c>paymentSummaryMap= new Map<String,ECM_Payment_Summary__c>();
        Map<String,List<ECM_Payment_Summary_Item__c>>insertPSiMap= new Map<String,List<ECM_Payment_Summary_Item__c>>();
        List<ECM_Payment_Summary_Item__c>pItemlist=new List<ECM_Payment_Summary_Item__c>();
        for(paymetWrapper p:paymentSummaryList){
            ECM_Payment_Summary__c ps = New ECM_Payment_Summary__c();
            ps.ECM_Budget_types__c = p.BudgetType;
            ps.ECM_Payment_Frequency__c = p.paymentFreq;
            ps.ECM_Addendum__c = p.addendum;
            ps.ECM_Start_Period__c = p.startPeriod;
            ps.ECM_End_Period__c = p.endPeriod;
            ps.ECM_Contract__c = p.Contract;
            ps.ECM_Total_Amount_Confirmed__c = p.AmountConfirmed.setScale(2);
            ps.ECM_Total_Amount_Forecasted__c = p.AmountForecasted.setScale(2);
            ps.ECM_Type__c = p.type;
            ps.ECM_PaymentPSVia_SAP__c = p.PaymentViaSAPCheckbox; //Added for ECM-6600
            ps.ECM_Payment_Summary_Status__c = p.status;
            paymentSummarymap.put(p.key,ps);
            for(wrapperPaymentItem pItem:p.paytemItemList){
                ECM_Payment_Summary_Item__c psi = new ECM_Payment_Summary_Item__c();
                psi.ECM_Contract_Item__c = pItem.ContractItem;
                // start added for ECM-4475
                if(pItem.PlannedAmountperPayment!=null){
                    psi.ECM_Planned_Amount_Per_Payment__c = pItem.PlannedAmountperPayment.setScale(2);
                }
                // end added for ECM-4475
                psi.ECM_Confirmed_Amount_Per_Payment__c = pItem.ConfirmedAmountPerPayment.setScale(2);
                psi.ECM_Confirmed_Volume__c = pItem.ConfirmedVolume;
                psi.ECM_Confirm__c = true;
                if(insertPSiMap.get(pItem.key)!=null){
                    insertPSiMap.get(pItem.key).add(psi);
                }else{
                    insertPSiMap.put(pItem.key,new list<ECM_Payment_Summary_Item__c>{psi});
                }
                
            }
        }
        if(!paymentSummarymap.isEmpty()){
            database.Insert(paymentSummarymap.Values());
        }
        for(String  pItemKey:insertPSiMap.KeySet()){
            for(ECM_Payment_Summary_Item__c pItem:insertPSiMap.get(pItemKey)){
                pItem.ECM_Payment_Summary__c=paymentSummarymap.get(pItemKey).Id;
                pItemlist.add(pItem);
            }
        }
        if(!pItemlist.isEmpty()){
            database.Insert(pItemlist);
        }
    }
    
    public class paymetWrapper {
        public decimal AmountForecasted;
        public decimal AmountConfirmed;
        public string BudgetType;
        public string paymentFreq;//Added for ECM-5164
        public string addendum;//Added for ECM-5964,ECM-5966,ECM-6029
        public boolean PaymentViaSAPCheckbox; //Added for ECM-6600
        public id Contract;
        public date startPeriod;
        public date endPeriod;
        public string Status;
        public String Type;
        Public String key;
        public List<wrapperPaymentItem> paytemItemList;
        
        public  paymetWrapper( ){
            this.paytemItemList= new List<wrapperPaymentItem>();
            this.AmountForecasted=0.00;
            this.AmountConfirmed=0.00;
        }
    }
    
/*
*@Method name : ECM_createPromStandardRecurringPSSingleYearPF
*@User story  : ECM-4883 to create PS of single yearly payments 
*/
     @future
    public static void ECM_createPromStandardRecurringPSSingleYearPF(set < Id > setOfSDI) {
        List < ECM_Sales_Driver_Item__c > lstOfSDI = new List < ECM_Sales_Driver_Item__c >();
        lstOfSDI = [SELECT Id,ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Payment_Date__c,Contract__c,ECM_1st_Prepayment_Date__c,ECM_Investment_Yr1__c,ECM_Investment_Yr2__c,ECM_Investment_Yr3__c,ECM_Payment_Frequency__c,
                    ECM_Remaining_Payment_Date__c,ECM_Payment_Frequency__r.ECM_Type__c,contract__r.StartDate,contract__r.Contract_End_Date__c,contract__r.ECM_Duration__c,ECM_Payment_Date_Yr1__c,ECM_Payment_Date_Yr3__c,
                    ECM_Payment_Frequency__r.ECM_Number_of_months_for_recurrence__c,ECM_Payment_Frequency__r.ECM_Prepayment__c,ECM_Payment_Frequency__r.ECM_End_Date__c,ECM_Payment_Date_Yr2__c,ECM_Total_Investment_Amount__c,ECM_Payment_Via_SAP__c,//Added for ECM-6600
                    (SELECT Id,ECM_Product__c,ECM_Investment_Amount__c,
                     ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__c,ECM_Sales_Driver_Item__r.ECM_Total_Investment_Amount__c,
                     ECM_Sales_Driver_Item__r.ECM_Payment_Date__c,ECM_Sales_Driver_Item__r.ECM_Prepayment__c, 
                     ECM_Sales_Driver_Item__r.ECM_1st_Prepayment_Date__c,ECM_Sales_Driver_Item__r.Contract__c
                     FROM Sales_Driver_Item_Details__r) 
                    FROM ECM_Sales_Driver_Item__c where Id IN:setOfSDI AND ECM_Sales_Driver__r.ECM_Budget_Type__c!=Null];
        Map<String,paymetWrapper>paymentSumaryListMap= new  Map<String,paymetWrapper>();       
        Map<String,wrapperPaymentItem>payItemBudgetMap= new Map<String,wrapperPaymentItem>();
        Map<String,paymetWrapper>paymentSumaryMap= new Map<String,paymetWrapper>();  
        
        for (ECM_Sales_Driver_Item__c sdi: lstOfSDI) {            
            if(sdi.ECM_Investment_Yr1__c!=Null && sdi.ECM_Payment_Date_Yr1__c!=Null){                
                paymentSumaryListMap.putAll(paymentSummaryWrapper(sdi,paymentSumaryMap,sdi.ECM_Payment_Date_Yr1__c,sdi.ECM_Investment_Yr1__c,paymentSumaryListMap,payItemBudgetMap));
            }
            if(sdi.ECM_Investment_Yr2__c!=Null && sdi.ECM_Payment_Date_Yr2__c!=Null){
                 paymentSumaryListMap.putAll(paymentSummaryWrapper(sdi,paymentSumaryMap,sdi.ECM_Payment_Date_Yr2__c,sdi.ECM_Investment_Yr2__c,paymentSumaryListMap,payItemBudgetMap));                
            }
            if(sdi.ECM_Investment_Yr3__c!=Null && sdi.ECM_Payment_Date_Yr3__c!=Null){
                 paymentSumaryListMap.putAll(paymentSummaryWrapper(sdi,paymentSumaryMap,sdi.ECM_Payment_Date_Yr3__c,sdi.ECM_Investment_Yr3__c,paymentSumaryListMap,payItemBudgetMap));                
            }
        }
      
        // Call generic method for Paymemt Summary creation and Payment summary Line item creation
        try{
            if(paymentSumaryListMap.size()>0)
                insertPaymentSummaryandItems(paymentSumaryListMap.values());
        }catch(Exception e){
            system.debug('Excepion insert of PS'+e.getMessage());
        } 
    }//end of ECM-4883
     //added by anivesh for ECM-4883  
    public static Map<String,paymetWrapper> paymentSummaryWrapper(ECM_Sales_Driver_Item__c sdi, 
                                                                  Map<String,paymetWrapper> paymentSumaryMap,
                                                                  Date paymentDate,Decimal investAmount,
                                                                  Map<String,paymetWrapper> paymentSumaryListMap,
                                                                  Map<String,wrapperPaymentItem> payItemBudgetMap)
    {
        paymetWrapper paymentSummary;
        string keystr;
        if (sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c != null ) {
            system.debug('called ===');
            if(paymentDate!=null){
                keystr = sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c+'-'+paymentDate+'-'+ sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600   
            }           
            
            if(paymentSumaryMap.get(keystr)==null){
                paymentSummary= new paymetWrapper();
            }
            else{
                paymentSummary=paymentSumaryMap.get(keystr);
            }
            paymentSummary.startPeriod = paymentDate;
            paymentSummary.endPeriod=paymentDate;
            paymentSummary.contract=sdi.Contract__c;
            paymentSummary.budgetType=sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c;
            paymentSummary.paymentFreq=sdi.ECM_Payment_Frequency__c;
            paymentSummary.type='Promo-Standard';
            paymentSummary.status='Provisional';
            paymentSummary.PaymentViaSAPCheckbox = sdi.ECM_Payment_Via_SAP__c;//Added for ECM-6600
            paymentSummary.key=keystr;
            List<wrapperPaymentItem> payItemList= new list<wrapperPaymentItem>();
            paymentSumaryMap.put(keystr,paymentSummary);
            if (!(sdi.Sales_Driver_Item_Details__r.isEmpty())) {
                for (ECM_Sales_Driver_Item_Detail__c sdid: sdi.Sales_Driver_Item_Details__r) {                       
                    decimal cal = sdid.ECM_Investment_Amount__c;
                    if (sdid.ECM_Sales_Driver_Item__r.ECM_Total_Investment_Amount__c != null) {
                        if (investAmount!=null) {
                            cal = ((investAmount/sdid.ECM_Sales_Driver_Item__r.ECM_Total_Investment_Amount__c)*cal);
                        }
                    }
                    string productBudgetTypeKey=sdi.Contract__c + '-' + sdi.ECM_Sales_Driver__r.ECM_Budget_Type__c+'-'+sdid.ECM_Product__c+'-'+paymentDate+'-'+ sdi.ECM_Payment_Via_SAP__c; //Added for ECM-6600
                    wrapperPaymentItem payItem;
                    if(payItemBudgetMap.get(productBudgetTypeKey)!=null){                        
                        payItem=payItemBudgetMap.get(productBudgetTypeKey);
                    }else{
                        payItem= new wrapperPaymentItem();
                    }   
                    if(payItem.ConfirmedAmountPerPayment!=null){
                        payItem.ConfirmedAmountPerPayment=payItem.ConfirmedAmountPerPayment+cal;////ECM-4927 bug---sdid.ECM_Investment_Amount__c;
                    }else{
                        payItem.ConfirmedAmountPerPayment=+cal;////ECM-4927 bug---sdid.ECM_Investment_Amount__c;
                    }
                    if(payItem.PlannedAmountperPayment!=null){
                        payItem.PlannedAmountperPayment=payItem.PlannedAmountperPayment+cal;
                    }else{
                        payItem.PlannedAmountperPayment=cal;                            
                    }
                    payItem.contractItem=sdid.ECM_Product__c;
                    payItem.confirm=true;
                    payItem.key=keystr;
                    if(payItemBudgetMap.get(productBudgetTypeKey)==null){
                        payItemBudgetMap.put(productBudgetTypeKey,payItem);
                        payItemList.add(payItem);
                        List<wrapperPaymentItem> promoPayItemList= new list<wrapperPaymentItem>();
                        promoPayItemList=paymentSummary.paytemItemList;
                        promoPayItemList.add(payItem);
                        paymentSummary.paytemItemList=promoPayItemList;
                    }
                    paymentSummary.AmountConfirmed += cal;//ECM-4927 and 5035 bug
                    paymentSummary.AmountForecasted += cal;//ECM-4927 and 5035 bug      
                }
                
            }   
        }
        if(paymentSumaryListMap.get(paymentSummary.key)==null){
            paymentSumaryListMap.put(paymentSummary.key,paymentSummary);
        }
        return paymentSumaryListMap;
    }
    //End of ECM-4883
    public class wrapperPaymentItem{
        public String ContractItem;     
        public decimal PlannedAmountperPayment;
        public decimal ConfirmedAmountPerPayment;
        public decimal ConfirmedVolume;
        public boolean confirm;
        Public String key;
        public  wrapperPaymentItem(){
            this.PlannedAmountperPayment=0.00;
            this.ConfirmedAmountPerPayment=0.00;
            this.ConfirmedVolume=0.00;
        }
    }
    
}