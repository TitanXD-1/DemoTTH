/*
 * Class Name : ECM_PaymentSummaryHandler
 * @description: Class with all handler methods of ECM_PaymentSummaryTrigger.
 * @history
 * AUTHOR            DATE              	DETAIL
 * Keshav         	08/04/2020      	ECM-1055 : SFDC_GLO_Logic: Promo-prepayment payment summary status change flow
 * Saurav Prasad  	01/06/2020      	ECM-1722 : SFDC_GLO_Object: Territory budget_Spent amount calculation 
 * Keshav         	01/06/2020      	ECM-1720 : SFDC_GLO_Logic: Internal order_Spent amount calculation    
 * Keshav         	18/06/2020      	ECM-2242 : SFDC_GLO_Logic: Fiscal year auto-determination for Payment summary
 * veerendra      	08/02/2021      	ECM-3803 : Missing table in the Evidence request email
 * veerendra      	05/03/2021      	ECM-4070 : CM Spain - INC19720170 Promotional Payment Summary creation  - from CI to SDI items 
 * Saurav Prasad  	02/06/2021      	ECM-4490 : UAT_Defect : Mail not getting trigerred to email address from the field "email for contracts/payments" on outlet and  in the field "Payment Management Email" of the market settings
 * Anivesh Muppa  	16/06/2021	   		ECM-4516 : Before Insert Update the Approver fields 
 * Saurav Prasad  	21/06/2021	   		ECM-4515 : Update status to rejected for Promo-PrePayment
 * Manikandan.T   	28/07/2021      	ECM-4569 : Initaite Approval process for Extra Approvers and CIO Approvers
*/
public class ECM_PaymentSummaryHandler {
    //Global Static variable part of ECM-4490
    public static Boolean afterUpdate = true;
    public static Boolean beforeUpdate = true;
    
    public void OnBeforeInsert( List<ECM_Payment_Summary__c> newPaySum) {  
        Set<Id> psIdSet = new Set<Id>();
        Set<Id> psContractId = new Set<Id>();
        if(newPaySum.size()>0){
            /*
            * ECM-1881
            * Will call to update Recommended IO Code on the Payment Summary Record when ever a new record is created
            * Criteria : Contract - 
            * Geography :Australia 
            * Record Type - A&P,Outlet,Group
            */
            ECM_PaymentSummaryHelper.ECM_Update_IO_Code(newPaySum);
            //added updateCurrencyCode method against 4490 to remove the action from process builder to trigger
            ECM_PaymentSummaryHelper.updateCurrencyCode(newPaySum,false);
            //Fiscal Year calculation on Payment Summary.        
            for(ECM_Payment_Summary__c paySumObj: newPaySum)
            {
                psContractId.add(paySumObj.ECM_Contract__c);
                if(paySumObj.ECM_Start_Period__c!=null && paySumObj.ECM_End_Period__c!=null){
                    fiscalYearCalculate(paySumObj);                    
                    //paySumObj.CurrencyIsoCode = paySumObj.ECM_Contract__r.ECM_Agreement_Type__r.CurrencyIsoCode;
                }
            }
            //logic for ECM-4516
            /*ECM_PaymentSummaryHelper.*/updateApprover(newPaySum, psContractId);
        }
    }
    
    public void OnBeforeUpdate(List<ECM_Payment_Summary__c> oldPaySum, List<ECM_Payment_Summary__c> newPaySum,Map<Id, ECM_Payment_Summary__c>  newPaySumMap) {  
        try{
            if(beforeUpdate){// Added Static variable as a part of ECM-4490
                Set<Id> psIdSet = new Set<Id>();
                List<Id> psIdList = new List<Id>();
                   Profile p = [SELECT Id,Name FROM Profile WHERE Name='CIO User'];
                //added updateCurrencyCode method against 4490 to remove the action from process builder to trigger

                ECM_PaymentSummaryHelper.updateCurrencyCode(newPaySum,true);
                if(!oldPaySum.isEmpty()){
                    list<ECM_Payment_Summary__c> psList = new List<ECM_Payment_Summary__c>();
                    List<ECM_Payment_Summary__c> extraApprovalList = new  List<ECM_Payment_Summary__c>();
                    List<ECM_Payment_Summary__c> cioApprovalList = new  List<ECM_Payment_Summary__c>();
                    List<ECM_Payment_Summary__c> autoApprovalOrRejectList = new  List<ECM_Payment_Summary__c>();
                    for(Integer i=0; i<oldPaySum.size(); i++)
                    { 
                        
   
                        //Added as a part of ECM-4490
                        //sendEmail to remove the action from process builder to trigger
                        //Innvocable method action removed for this specific criteria.
                        if(oldPaySum[i].ECM_Payment_Summary_Status__c != newPaySum[i].ECM_Payment_Summary_Status__c && 
                          newPaySum[i].ECM_Payment_Summary_Status__c == 'Approved' && 
                          newPaySum[i].ECM_Type__c == 'Non-Volume'){
                              if(newPaySum[i].ECM_No_Invoice_Required__c == false){
                                  psIdList.add(newPaySum[i].Id);
                                  newPaySum[i].ECM_Total_Amount_Confirmed__c =  newPaySum[i].ECM_Total_to_be_Invoiced__c;
                                      }else{
                                          newPaySum[i].ECM_Total_Amount_Confirmed__c =  newPaySum[i].ECM_Total_to_be_Invoiced__c;
                                      }
                        }
                        //End of ECM-4490
                        if( newPaySumMap.get(oldpaySum[i].Id).ECM_Type__c==system.label.ECM_PromoPrepayment_Type && newPaySumMap.get(oldpaySum[i].Id).ECM_Payment_Summary_Status__c==system.label.ECM_Open_Status){
                            newPaySumMap.get(oldpaySum[i].Id).ECM_Payment_Summary_Status__c=system.label.ECM_Payment_Summary_Rejected;
                        }
                        if(oldPaySum[i].ECM_SAP_payment_Reference_Number__c==null && newPaySum[i].ECM_SAP_payment_Reference_Number__c==0){
                            newPaySum[i].ECM_SAP_payment_Reference_Number__c=null;
                        }
                        if( oldPaySum[i].ECM_Invoice_Status__c !='Approved' && newPaySum[i].ECM_Payment_Summary_Status__c =='Approved' && newPaySum[i].ECM_Type__c!='Non-Volume')
                        {
                            newPaySum[i].addError('Payment Summary cannot be Approved if Invoice Status is not Approved');
                        }
                        
                     
                        if( oldPaySum[i].ECM_Payment_Summary_Status__c =='Approved' && p.Id == UserInfo.getProfileId())
                        {	
                            if(oldPaySum[i].ECM_Tax_Rate__c != newPaySum[i].ECM_Tax_Rate__c
                               ||oldPaySum[i].ECM_Invoice_Receival_Date__c != newPaySum[i].ECM_Invoice_Receival_Date__c
                               ||oldPaySum[i].ECM_Invoice_Status__c != newPaySum[i].ECM_Invoice_Status__c
                               ||oldPaySum[i].ECM_Total_to_be_Invoiced__c != newPaySum[i].ECM_Total_to_be_Invoiced__c
                               ||oldPaySum[i].ECM_UoS_Total__c != newPaySum[i].ECM_UoS_Total__c
                               ||oldPaySum[i].CurrencyIsoCode != newPaySum[i].CurrencyIsoCode
                               /*||oldPaySum[i].ECM_Error_message__c != newPaySum[i].ECM_Error_message__c
||oldPaySum[i].ECM_Transmission_Status__c != newPaySum[i].ECM_Transmission_Status__c*/
                           ||oldPaySum[i].ECM_No_Invoice_Required__c != newPaySum[i].ECM_No_Invoice_Required__c ){
                                   newPaySum[i].addError('Payment Summary values cannot be changed if Payment Summary Status is Approved');
                               } 
                        }
                        //Fiscal Year calculation on Payment Summary.
                        if( oldPaySum[i].ECM_Start_Period__c!=newPaySum[i].ECM_Start_Period__c || oldPaySum[i].ECM_End_Period__c!=newPaySum[i].ECM_End_Period__c)
                        {
                            fiscalYearCalculate(newPaySum[i]);
                        }
                        if(oldPaySum[i].ECM_Budget_types__c!=newPaySum[i].ECM_Budget_types__c){
                            psList.add(newPaySum[i]);
                        }
                        if(oldPaySum[i].ECM_Approval_Sub_Status__c!=newPaySum[i].ECM_Approval_Sub_Status__c && newPaySum[i].ECM_Approval_Sub_Status__c==label.ECM_In_Extra_Approval){
                            extraApprovalList.add(newPaySum[i]);
                        }else if(oldPaySum[i].ECM_Approval_Sub_Status__c!=newPaySum[i].ECM_Approval_Sub_Status__c && newPaySum[i].ECM_Approval_Sub_Status__c==label.ECM_CIO_Approval){                         
                            cioApprovalList.add(newPaySum[i]);
                        }else if(oldPaySum[i].ECM_Approval_Sub_Status__c!=newPaySum[i].ECM_Approval_Sub_Status__c && String.isBlank(newPaySum[i].ECM_Approval_Sub_Status__c) && (oldPaySum[i].ECM_Approval_Sub_Status__c==label.ECM_CIO_Approval || oldPaySum[i].ECM_Approval_Sub_Status__c==label.ECM_In_Extra_Approval) ){
                            autoApprovalOrRejectList.add(newPaySum[i]);
                        }
                    }
                 
                    if(psList.size()>0){
                        ECM_PaymentSummaryHelper.ECM_Update_IO_Code(psList);
                    }
                    //Added as a part of ECM-4490
                    //triggering sendEmail (Australia) (Non-Volume) 
                    if(psIdList.size()>0){
                        ECM_PaymentSummaryEmailHandler.sendEmail(psIdList);
                    }
                    //End of ECM-4490
                    if(extraApprovalList.size()>0){
                        ECM_PaymentSummaryHelper.checkForExtraApproval(extraApprovalList);
                    }
                    if(cioApprovalList.size()>0){
                        ECM_PaymentSummaryHelper.checkForCIOApproval(cioApprovalList);
                    }
                    if(autoApprovalOrRejectList.size()>0){                      
						ECM_PaymentSummaryHelper.updateCIOApproval(autoApprovalOrRejectList);                        
                    }
                }
                beforeUpdate = false;
            }
            //part of ECM-4515
            //Need to evaluated again
            /*ECM_PaymentSummaryHelper.*/updateRejectedForPre_Payment(oldPaySum,newPaySum);
        }catch(Exception e){
            System.debug('Exception Caught in OnBeforeUpdate method of ECM_PaymentSummaryHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }
    
    public void OnAfterInsert(List<ECM_Payment_Summary__c> newPaySum,Map<Id, ECM_Payment_Summary__c>  newPaySumMap) {  
        
        ECM_PaymentSummaryHelper.ECM_Update_PS_BudgetType(newPaySum);
        try{
            Set<String> geoCountryName=new Set<String>();
            Set<Id> pSIds = new Set<Id>();
            Set<Id> contractIds = new Set<Id>();
            Map<Id,Id> paymentWithContractId = new Map<Id,Id>();
            Map<Id,String> paymentWithbudgetType = new Map<Id,String>();
            Map<Id,String> pstypeMap = new Map<Id,String>();
            for(Integer i=0; i<newPaySum.size(); i++)
            {
                contractIds.add(newPaySum[i].ECM_Contract__c);
                paymentWithContractId.put(newPaySum[i].Id,newPaySum[i].ECM_Contract__c);
                paymentWithbudgetType.put(newPaySum[i].Id,newPaySum[i].ECM_Budget_types__c);
                pstypeMap.put(newPaySum[i].Id,newPaySum[i].ECM_Type__c);
                
                if(newPaySum[i].ECM_Payment_Summary_Status__c == 'Approved')
                {
                    pSIds.add(newPaySum[i].Id);
                }
            }
            Map<Id,List<ECM_Contract_Item__c>> ContractWithConItems = new Map<Id,List<ECM_Contract_Item__c>>();
            for(ECM_Contract_Item__c contractItemList : [SELECT Id, ECM_Contract__c, ECM_Product__c, ECM_Actual_Volume_YTD__c, ECM_Contract__r.Account.Country__c,
                                                         ECM_Contract__r.Account.Country__r.Name, ECM_UoM__c FROM ECM_Contract_Item__c 
                                                         WHERE ECM_Contract__c IN: contractIds]){
                                                             if(ContractWithConItems.containsKey(contractItemList.ECM_Contract__c)){
                                                                 List<ECM_Contract_Item__c> addItems = ContractWithConItems.get(contractItemList.ECM_Contract__c);
                                                                 addItems.add(contractItemList);
                                                                 ContractWithConItems.put(contractItemList.ECM_Contract__c, addItems);
                                                                 geoCountryName.add(contractItemList.ECM_Contract__r.Account.Country__r.Name);
                                                             }else{
                                                                 ContractWithConItems.put(contractItemList.ECM_Contract__c, new List<ECM_Contract_Item__c>{contractItemList});
                                                                 geoCountryName.add(contractItemList.ECM_Contract__r.Account.Country__r.Name);
                                                             }
                                                         }
            List<ECM_Payment_Summary_Item__c> newPSItemList = new list<ECM_Payment_Summary_Item__c>();
            Map<string,decimal> prodInvestmentmap=New Map<String,decimal>();   
            for(id PsID :paymentWithContractId.keySet()){
                if((pstypeMap.get(PsID)== 'Non-Volume')|| ((pstypeMap.get(PsID)== 'Volume-Based') && geoCountryName.contains('Australia'))){
                    if(ContractWithConItems.containskey(paymentWithContractId.get(PsID)) && ContractWithConItems.get(paymentWithContractId.get(PsID)).size()>0 ){
                        for(ECM_Contract_Item__c ci :ContractWithConItems.get(paymentWithContractId.get(PsID))){ 
                            system.debug('pstypeMapss'+pstypeMap.get(PsID));
                            ECM_Payment_Summary_Item__c newPSI = new ECM_Payment_Summary_Item__c();
                            newPSI.ECM_Payment_Summary__c = PsID;
                            newPSI.ECM_Contract_Item__c = ci.Id;                        
                            if(ci.ECM_UoM__c == null){
                                ci.ECM_UoM__c = '0';
                            }
                            if(ci.ECM_Actual_Volume_YTD__c == null){
                                ci.ECM_Actual_Volume_YTD__c = 0;
                            }
                            newPSI.ECM_Confirmed_Volume__c = 0; 
                            newPSI.ECM_Confirm__c= true;     
                            newPSI.ECM_Confirmed_Amount_Per_Payment__c =  newPSI.ECM_Confirmed_Volume__c * decimal.valueOf(ci.ECM_UoM__c);                        
                            newPSItemList.add(newPSI);
                        }
                    }
                    
                }
            }
            if(newPSItemList.size()>0){
                insert newPSItemList;
            }
            
            if(pSIds.size()>0)
            {
                territoryBudgetSpentAmt(pSIds);
                internalOrderSpentAmt(pSIds);
            }
        }catch(Exception e){
            System.debug('Exception Caught in OnAfterInsert method of ECM_PaymentSummaryHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }
    
    public void OnAfterUpdate(List<ECM_Payment_Summary__c> oldPaySum, List<ECM_Payment_Summary__c> newPaySum,Map<Id, ECM_Payment_Summary__c>  newPaySumMap,Map<Id, ECM_Payment_Summary__c>  OldPaySumMap) {  
        try{
            System.debug('@@afterUpdate' +afterUpdate);
            if(afterUpdate){// Added Static variable as a part of ECM-4490 
                List<Contract> contractUpdateLst = new List<Contract>();
                List<Contract> contLst = new List<Contract>();
                /*
				* Story : ECM-1558
				*ECM_PaymentSummaryHelper.ECM_Update_UpfrontLastPaymentdate(newPaySumMap,OldPaySumMap);
                * Story : ECM-2204
				*/
                ECM_PaymentSummaryHelper.ECM_Update_Payment_Summary_Conformed_Amount_On_Contracts(newPaySumMap,OldPaySumMap);
                ECM_PaymentSummaryHelper.sendPushNotificationForPF(newPaySum, OldPaySumMap);
                
                List<ECM_Payment_Summary__c> paymentSummaryList = new List<ECM_Payment_Summary__c> ();
                
                Set<Id> contractIdsSet = new Set<Id>();
                Set<Id> budgetIdsSet = new Set<Id>();
                decimal val = 0;
                decimal valAP = 0;
                decimal valOther = 0;
                decimal valTraining = 0;
                for ( ECM_Payment_Summary__c PS : oldPaySum) {
                    if (PS.ECM_Contract__c != null ){
                        contractIdsSet.add(PS.ECM_Contract__c);
                    }
                    ECM_Payment_Summary__c oldsummary = (ECM_Payment_Summary__c)newPaySumMap.get(PS.Id); // Map<Id, sObject>
                    if ( oldsummary.ECM_Contract__c != PS.ECM_Contract__c ) {
                        contractIdsSet.add(oldsummary.ECM_Contract__c);
                    }                
                }
                if(contractIdsSet.size()>0){
                    List<Contract> contractLst = [Select id, name,ECM_Total_amount_summary__c,AP_Spent__c,ECM_Contract_Other_Spent__c,ECM_Contract_Payment_Spent__c,(select id,ECM_Payment_Summary_Status__c,ECM_Total_Amount_Confirmed__c,ECM_Contract__r.Account.Country__r.name,ECM_Budget_types__r.Name from Payment_Summary__r) from Contract
                                                  Where Contract.Id IN : contractIdsSet];
                    
                    for (Contract acc : contractLst) {                    
                        List<ECM_Payment_Summary__c> relatedContacts = acc.Payment_Summary__r;
                        if ( relatedContacts != null ){  
                            for(ECM_Payment_Summary__c pas : acc.Payment_Summary__r){
                                if(pas.ECM_Payment_Summary_Status__c == 'Approved' && pas.ECM_Total_Amount_Confirmed__c!=null){
                                    val += pas.ECM_Total_Amount_Confirmed__c; 
                                }       
                            }
                            acc.ECM_Total_amount_summary__c = val;
                        }
                        else {
                            acc.ECM_Total_amount_summary__c = 0;
                            
                        }
                        contractUpdateLst.add(acc);
                    }
                    /*ECM-2519*/
                    List<Contract> contractPSLst = [Select id, name,ECM_Total_amount_summary__c,AP_Spent__c,ECM_Contract_Other_Spent__c,ECM_Contract_Payment_Spent__c,(select id,ECM_Payment_Summary_Status__c,ECM_Total_Amount_Confirmed__c,ECM_Contract__r.Account.Country__r.name,ECM_Type__c,ECM_Budget_types__c,ECM_Budget_types__r.Name from Payment_Summary__r where ECM_Payment_Summary_Status__c = 'Completed' AND ECM_Type__c='Non-Volume' AND ECM_Budget_types__c!=null AND ECM_Total_Amount_Confirmed__c!=null ) from Contract
                                                    Where Contract.Id IN : contractIdsSet AND Account.Country__r.name = 'Australia' ];
                    if(contractPSLst.size()>0)
                    {
                        for (Contract contr : contractPSLst) {
                            
                            List<ECM_Payment_Summary__c> relatedPS = contr.Payment_Summary__r;
                            if ( relatedPS != null ){  
                                for(ECM_Payment_Summary__c pas : relatedPS){
                                    if(pas.ECM_Budget_types__r.Name.containsIgnoreCase('A&P')){									
                                        valAP += pas.ECM_Total_Amount_Confirmed__c;
                                    }else if(pas.ECM_Budget_types__r.Name.containsIgnoreCase('Other')){									
                                        valOther += pas.ECM_Total_Amount_Confirmed__c;
                                    }else if(pas.ECM_Budget_types__r.Name.containsIgnoreCase('Training')){									
                                        valTraining += pas.ECM_Total_Amount_Confirmed__c;
                                    }					
                                }
                                if(valAP>0){
                                    contr.AP_Spent__c = valAP;
                                }
                                if(valOther>0){
                                    contr.ECM_Contract_Other_Spent__c = valOther;
                                }
                                if(valTraining>0){
                                    contr.ECM_Contract_Payment_Spent__c = valTraining;
                                }							
                            }
                            contLst.add(contr);
                        }
                    }
                    if(contLst.size()>0)
                    {
                        update contLst;
                    }
                }
                Set<Id> pSIds = new Set<Id>();
                Set<Id> conIdList = new Set<Id>();
                for(Integer i=0; i<oldPaySum.size(); i++)
                {
                    if(oldPaySum[i].Id  == newPaySum[i].Id && ((oldPaySum[i].ECM_Payment_Summary_Status__c != 'Approved' && newPaySum[i].ECM_Payment_Summary_Status__c == 'Approved')))
                    {
                        pSIds.add(newPaySum[i].Id);
                        conIdList.add(newPaySum[i].ecm_contract__c);
                    }
                }
                if(pSIds.size()>0)
                {
                    territoryBudgetSpentAmt(pSIds);
                    internalOrderSpentAmt(pSIds);
                    recalculateConfirmedAmount(pSIds,conIdList);
                    //Send Callout to SAP
                    ECM_PaymentSummaryToSAPCallout.getPaymentData(pSIds);
                    ECM_PaymentSummaryToSAPCallout.getPaymentDataNonVolume(pSIds);
                }
                afterUpdate = false;                
            }
            
        }catch(Exception e){
            System.debug('Exception Caught in OnAfterUpdate method of ECM_PaymentSummaryHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }   
    }
    /*
	* Name: Fiscal Yeal Calculator
	* Developer: Keshav
	* Description: Method to calculate Fiscal Year in Payment Summary.
	*/ 
    public void fiscalYearCalculate(ECM_Payment_Summary__c newPaySum){        
        try{
            if(newPaySum.ECM_Start_Period__c!=null && newPaySum.ECM_End_Period__c!=null){    
                Date startDate = newPaySum.ECM_Start_Period__c;
                Date endDate = newPaySum.ECM_End_Period__c;
                Integer startDateMonth = startDate.month();
                Integer endDateMonth = endDate.month();
                Integer startDateYear = startDate.year();
                Integer endDateYear = endDate.year();
                String fiscalYear = '';
                for(integer i=startDateYear; i<= endDateYear; i++){
                    integer dateYear = i;
                    if(i==startDateYear){
                        if(startDateMonth<7){
                            fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                        }
                    }
                    if(i==endDateYear){
                        if(startDateYear == endDateYear){
                            if(startDateMonth<7 && endDateMonth >= 7){
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth >= 7 && endDateMonth >= 7){
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                        }
                        else if(startDateYear+1 == endDateYear){
                            if(startDateMonth < 7 && endDateMonth < 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth >= 7 && endDateMonth < 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth >= 7 && endDateMonth >= 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            if(startDateMonth < 7 && endDateMonth >= 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                        }
                        else{
                            if(endDateMonth >= 7){
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                                dateYear = dateYear+1;
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                            else{
                                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                            }
                        }
                    }
                    if(i != startDateYear && i != endDateYear){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                }
                
                newPaySum.ECM_Fiscal_Years__c = fiscalYear.removeEndIgnoreCase('/');
            }
        }catch(Exception e){
            System.debug('Exception Caught in fiscalYearCalculate method of ECM_PaymentSummaryHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }
    
	/*
	* Name: recalculateConfirmedAmount
	* Developer: Manikandan.T
	* Description: Method to update spend amount in Internal Order Object with Confirmed Amount Per Payment amount in Payment Summary Item.
	*/ 
    public void recalculateConfirmedAmount(Set<Id> newPaySum,Set<Id> conIdList){
        
        	                    for(ECM_Payment_Summary__c paysum:[SELECT Id, ECM_Contract__c, ECM_End_Period__c, ECM_Invoice_Receival_Date__c, ECM_Invoice_Status__c, ECM_Payment_Summary_Status__c,                                                             
                                                       ECM_Sales_Driver__c, ECM_Start_Period__c, ECM_Tax_Rate__c, ECM_Total_Amount_Confirmed__c,ECM_Total_Amount_Forecasted__c, ECM_Type__c, ECM_Budget_types__c,
                                                       ECM_Fiscal_Years__c, ECM_Total_to_be_Invoiced__c, ECM_UoS_Total__c, ECM_No_Invoice_Required__c, ECM_Approval_Date__c, ECM_Payment_Due_Date__c,ECM_Submitted_Date__c,
                                                       ECM_Contract__r.Account.Country__r.Name,ECM_Contract__r.Status,
                                                       (SELECT Id,ECM_Payment_Summary__c,ECM_Payment_Summary__r.ECM_End_Period__c, ECM_Payment_Summary__r.ECM_Start_Period__c, ECM_Confirmed_Amount_Per_Payment__c, ECM_Contract_Item__c,
                                                        ECM_Contract_Item__r.ECM_Product__r.Product__c, ECM_Confirmed_Volume__c, ECM_Actual_Cases__c,ECM_Contract_Item__r.ECM_UoM__c,ECM_Payment_Summary__r.ECM_Contract__c 
                                                        FROM Payment_Summary_Item__r) FROM ECM_Payment_Summary__c 
                                                       Where Ecm_Contract__c IN :conIdList AND ECM_Type__c='Volume-Based' And Id NOT IN:newPaySum]){
                                                       }
    }
    
    /*
	* Name: internalOrderSpentAmt
	* Developer: Keshav
	* Description: Method to update spend amount in Internal Order Object with Confirmed Amount Per Payment amount in Payment Summary Item.
	*/ 
    public void internalOrderSpentAmt(Set<Id> newPaySum){
        
        try{
            Decimal spentAmount;
            
            List<String> prodIdLst = new List<String>();
            //Removed from ECM-4490 check
            //List<ECM_Payment_Summary__c> paySumIds = new List<ECM_Payment_Summary__c>();            
            List<ECM_Payment_Summary_Item__c> paySumItemIds = new List<ECM_Payment_Summary_Item__c>();
            List<ECM_Internal_Order__c> interOrderLst = new List<ECM_Internal_Order__c>();
            List<ECM_Internal_Order__c> interOrderSpentAmtLst = new List<ECM_Internal_Order__c>();
            Map<Id,decimal> paySumItemMap = new Map<Id,decimal>();
            
            
            //Payment Summary List 
            //Removed from ECM-4490 check
            //paySumIds = [SELECT id, Name FROM ECM_Payment_Summary__c where id IN:newPaySum];
            
            //Payment Summary Item List
            paySumItemIds = [SELECT CurrencyIsoCode,ECM_Confirmed_Amount_Per_Payment__c,ECM_Confirm__c,ECM_Contract_Item__c,ECM_Payment_Summary__c,ECM_Planned_Amount_Per_Payment__c,ECM_Reject__c,ECM_Roll_Over__c,Id,Name,ECM_Contract_Item__r.ECM_Product__r.Product__c FROM ECM_Payment_Summary_Item__c WHERE ECM_Payment_Summary__c IN:newPaySum AND ECM_Confirm__c = true];
            if(paySumItemIds.size()>0){
                for(ECM_Payment_Summary_Item__c paySumObj: paySumItemIds)
                {
                    prodIdLst.add(paySumObj.ECM_Contract_Item__r.ECM_Product__r.Product__c);//Payment Summary Product List
                    //Payment Summary Item Map
                    paySumItemMap.put(paySumObj.ECM_Contract_Item__r.ECM_Product__r.Product__c,paySumObj.ECM_Confirmed_Amount_Per_Payment__c);                   
                }	
            }
            
            // Internal Order Records
            interOrderLst = [ SELECT Id,Name,ECM_Active__c,ECM_Product__c,ECM_Spent_Amount__c FROM ECM_Internal_Order__c WHERE ECM_Product__c IN : prodIdLst AND ECM_Active__c=true ];
            
            // Internal Order Product Map
            if(interOrderLst.size()>0){                
                for(ECM_Internal_Order__c inOrdObj : interOrderLst){
                    if(inOrdObj.ECM_Spent_Amount__c == null)
                    {
                        spentAmount = 0.00;
                    }else if(inOrdObj.ECM_Spent_Amount__c != null){
                        spentAmount = inOrdObj.ECM_Spent_Amount__c;
                    }
                    if(paySumItemMap.get(inOrdObj.ECM_Product__c) != null){
                        inOrdObj.ECM_Spent_Amount__c = spentAmount + paySumItemMap.get(inOrdObj.ECM_Product__c);
                    }
                    interOrderSpentAmtLst.add(inOrdObj);
                }
            }
            if(interOrderSpentAmtLst.size()>0)
            {
                update interOrderSpentAmtLst;
            }
        }catch(Exception e){
            System.debug('Exception Caught in territoryBudgetAmt method of ECM_PaymentSummaryHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }
    /* 
	* Name: territoryBudgetSpentAmt
	* Developer: Saurav Prasad
	* Description: Method to update spend amount in Territory budget with Total confirmed amount in Payment Summary
	*/
    @future
    public static void territoryBudgetSpentAmt(Set<Id> newPaySum){
        
        try{
            Map<Id,ECM_Payment_Summary__c> PaymentMap =new Map<Id,ECM_Payment_Summary__c>();
            Map<Id,set<Id>> Payment_PrimarySalesTerritory=new Map<Id,set<Id>>();
            Map<Id,set<Id>> Payment_PrimarySalesArea=new Map<Id,set<Id>>();
            Map<Id,set<Id>> Payment_PrimarySalesTerritoryRegion=new Map<Id,set<Id>>();
            Map<Id,set<Id>> Payment_PrimarySalesTerritoryBusinessUnit=new Map<Id,set<Id>>();
            Set<Id> ExcludeId =new set<Id>();
            
            for(ECM_Payment_Summary__c PaySum:[select Id,Name,ECM_Contract__c,ECM_Contract__r.AccountId,
                                               ECM_Contract__r.Account.Primary_Sales_Territory__c,
                                               ECM_Contract__r.Account.Primary_Sales_Area__c,
                                               ECM_Contract__r.Account.Primary_Sales_Territory_Region__c,
                                               ECM_Contract__r.Account.Primary_Sales_Territory_Business_Unit__c,
                                               ECM_Total_Amount_Confirmed__c,ECM_Payment_Summary_Status__c
                                               from ECM_Payment_Summary__c 
                                               where ID IN:newPaySum]){
                                                   //Map for Payment record
                                                   PaymentMap.put(PaySum.Id,PaySum);
                                                   
                                                   //Map for Sales Territory Area
                                                   if(PaySum.ECM_Contract__r.Account.Primary_Sales_Area__c!=Null){
                                                       if(Payment_PrimarySalesArea.containsKey(PaySum.ECM_Contract__r.Account.Primary_Sales_Area__c)){
                                                           set<Id> TempPaySum = new set<id>();
                                                           TempPaySum.addAll(Payment_PrimarySalesArea.get(PaySum.ECM_Contract__r.Account.Primary_Sales_Area__c));
                                                           TempPaySum.add(PaySum.id);
                                                           Payment_PrimarySalesArea.put(PaySum.ECM_Contract__r.Account.Primary_Sales_Area__c, TempPaySum);
                                                       }
                                                       else{
                                                           set<Id> TempPaySum= new set<Id>();
                                                           TempPaySum.add(PaySum.Id);
                                                           Payment_PrimarySalesArea.put(PaySum.ECM_Contract__r.Account.Primary_Sales_Area__c, TempPaySum);
                                                       }
                                                       
                                                   }
                                                   
                                                   //Map for Sales Territory Region 
                                                   if(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Region__c!=Null){
                                                       if(Payment_PrimarySalesTerritoryRegion.containsKey(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Region__c)){
                                                           set<Id> TempPaySum = new set<id>();
                                                           TempPaySum.addAll(Payment_PrimarySalesTerritoryRegion.get(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Region__c));
                                                           TempPaySum.add(PaySum.id);
                                                           Payment_PrimarySalesTerritoryRegion.put(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Region__c, TempPaySum);
                                                       }
                                                       else{
                                                           set<Id> TempPaySum= new set<Id>();
                                                           TempPaySum.add(PaySum.Id);
                                                           Payment_PrimarySalesTerritoryRegion.put(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Region__c, TempPaySum);
                                                       }
                                                       
                                                   }
                                                   
                                                   //Map for Sales Territory Business Unit
                                                   if(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Business_Unit__c!=Null){
                                                       if(Payment_PrimarySalesTerritoryBusinessUnit.containsKey(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Business_Unit__c)){
                                                           set<Id> TempPaySum = new set<id>();
                                                           TempPaySum.addAll(Payment_PrimarySalesTerritoryBusinessUnit.get(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Business_Unit__c));
                                                           TempPaySum.add(PaySum.id);
                                                           Payment_PrimarySalesTerritoryBusinessUnit.put(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Business_Unit__c, TempPaySum);
                                                       }
                                                       else{
                                                           set<Id> TempPaySum= new set<Id>();
                                                           TempPaySum.add(PaySum.Id);
                                                           Payment_PrimarySalesTerritoryBusinessUnit.put(PaySum.ECM_Contract__r.Account.Primary_Sales_Territory_Business_Unit__c, TempPaySum);
                                                       }
                                                       
                                                   }
                                               }
            
            List<Territory_Budget__c> TerritoryBudgetList =new List<Territory_Budget__c>();
            
            //Check from Sales Territory Area
            if(Payment_PrimarySalesArea.size()>0){
                for(Territory_Budget__c TR:[select id,ECM_Territory_Hierarchy__c,Spent_Amount__c from Territory_Budget__c where ECM_Territory_Hierarchy__c IN:Payment_PrimarySalesArea.keySet()]){
                    Decimal Temp=0;
                    List<Id> TempList=new List<Id>();
                    
                    //Remove Ids from Exclusion set
                    Set<Id> TempSet=new Set<ID>();
                    TempSet.addAll(Payment_PrimarySalesArea.get(TR.ECM_Territory_Hierarchy__c));
                    //TempSet.removeAll(ExcludeId);
                    
                    TempList.addAll(TempSet);
                    
                    if(TempList.size()>0){
                        for(Integer i=0;i<TempList.size();i++){
                            Temp+=PaymentMap.get(TempList[i]).ECM_Total_Amount_Confirmed__c;
                            ExcludeId.add(TempList[i]);
                        }
                        
                        TR.Spent_Amount__c+=Temp;
                        TerritoryBudgetList.add(TR);
                        
                    }
                }
            }
            
            //Check from Sales Territory Region
            if(Payment_PrimarySalesTerritoryRegion.size()>0){
                for(Territory_Budget__c TR:[select id,ECM_Territory_Hierarchy__c,Spent_Amount__c from Territory_Budget__c where ECM_Territory_Hierarchy__c IN:Payment_PrimarySalesTerritoryRegion.keySet()]){
                    Decimal Temp=0;
                    List<Id> TempList=new List<Id>();
                    
                    //Remove Ids from Exclusion set
                    Set<Id> TempSet=new Set<ID>();
                    TempSet.addAll(Payment_PrimarySalesTerritoryRegion.get(TR.ECM_Territory_Hierarchy__c));
                    TempSet.removeAll(ExcludeId);
                    
                    TempList.addAll(TempSet);
                    
                    if(TempList.size()>0){
                        for(Integer i=0;i<TempList.size();i++){
                            Temp+=PaymentMap.get(TempList[i]).ECM_Total_Amount_Confirmed__c;
                            ExcludeId.add(TempList[i]);
                        }
                        
                        TR.Spent_Amount__c+=Temp;
                        TerritoryBudgetList.add(TR);
                        
                    }
                }
            }
            //Check from Sales Territory Business Unit
            if(Payment_PrimarySalesTerritoryBusinessUnit.size()>0){
                for(Territory_Budget__c TR:[select id,ECM_Territory_Hierarchy__c,Spent_Amount__c from Territory_Budget__c where ECM_Territory_Hierarchy__c IN:Payment_PrimarySalesTerritoryBusinessUnit.keySet()]){
                    Decimal Temp=0;
                    List<Id> TempList=new List<Id>();
                    
                    //Remove Ids from Exclusion set
                    Set<Id> TempSet=new Set<ID>();
                    TempSet.addAll(Payment_PrimarySalesTerritoryBusinessUnit.get(TR.ECM_Territory_Hierarchy__c));
                    TempSet.removeAll(ExcludeId);
                    
                    TempList.addAll(TempSet);
                    
                    if(TempList.size()>0){
                        for(Integer i=0;i<TempList.size();i++){
                            Temp+=PaymentMap.get(TempList[i]).ECM_Total_Amount_Confirmed__c;
                            ExcludeId.add(TempList[i]);
                        }
                        
                        TR.Spent_Amount__c+=Temp;
                        TerritoryBudgetList.add(TR);
                    }
                }
            }
            if(TerritoryBudgetList.size()>0){
                update TerritoryBudgetList;
            }
        }
        catch(Exception e){
            System.debug('Exception Caught in territoryBudgetSpentAmt method of ECM_PaymentSummaryHandler at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }
    /* Update Ps status to rejected */
    //ECM-4515
    //Update PS status to rejected if rejected from approval process
    public static void updateRejectedForPre_Payment(List<ECM_Payment_Summary__c> oldList,List<ECM_Payment_Summary__c> newList){
        
        for(Integer i=0; i<oldList.size(); i++){
            if(newList[i].ECM_SM_Final_Rejection__c &&
               (newList[i].ECM_Payment_Summary_Status__c == 'Open' &&
                oldList[i].ECM_Payment_Summary_Status__c !='Rejected') &&
               newList[i].ECM_Type__c == 'Promo-PrePayment' &&
               UserInfo.getUserId() == newList[i].ECM_Manager_Approver__c){
                   newList[i].ECM_Payment_Summary_Status__c = 'Rejected';
               } 
        }
    }
    //ECM-4516 update the PS Approver values on Fields 
    public static List<ECM_Payment_Summary__c> updateApprover(List<ECM_Payment_Summary__c> pslist, Set<Id> psContractId){
        try{                      
            Map<Id,Contract> contractList = new Map<Id, Contract>([Select Id, Name, Account.Country__r.Code__c,AccountId from Contract where Id IN:psContractId]); 
            Set<string> countryCodeQueue = new Set<string>();
            Set<Id> setUserId = new Set<Id>();
            Map<String,List<String>> mapSalesmembers = new Map<String,List<String>>();
            Map<string, List<string>> activeQueueMemberMap = new Map<string, List<string>>();
            List<String> listActiveUserId = new List<String>();
            
            for(Contract cont :contractList.values()){
                countryCodeQueue.add(cont.Account.Country__r.Code__c+'_CIO');
            }    
            if(countryCodeQueue.size() > 0){        
                for(GroupMember sgm : [SELECT Group.Name, UserOrGroupId, GroupId FROM GroupMember WHERE group.name LIKE :countryCodeQueue and group.type='Queue']){
                    setUserId.add(sgm.UserOrGroupId);
                    if(mapSalesmembers.containsKey(sgm.Group.Name)){
                        List<String> grpMemList = mapSalesmembers.get(sgm.Group.Name);
                        grpMemList.add(sgm.UserOrGroupId);
                        mapSalesmembers.put(sgm.Group.Name, grpMemList);
                    } else {
                        mapSalesmembers.put(sgm.Group.Name, new List<String> {sgm.UserOrGroupId});
                    }
                }  
            }        
            for(User usr :[SELECT Id, isActive FROM User WHERE Id IN :setUserId AND isActive = True]){
                listActiveUserId.add(usr.Id);   
            }            
            //Iterate over mapSalesmembers to get only active member list
            if(mapSalesmembers.size()>0){
                for(string queueName : mapSalesmembers.keySet()){
                    List<String> approverList =  mapSalesmembers.get(queueName);
                    List<String> activeApproverist = new List<String>();
                    if(listActiveUserId != null && listActiveUserId.size()>0){
                        for(Integer i = 0; i < approverList.size(); i++){
                            if(listActiveUserId.contains(approverList.get(i))){
                                activeApproverist.add(approverList.get(i));
                            } 
                        }
                        activeQueueMemberMap.put(queueName, activeApproverist);
                    }
                }
            }          
            for(ECM_Payment_Summary__c ps :pslist){
                string countryQueueName = (contractList!=null && contractList.containskey(ps.ECM_Contract__c))?contractList.get(ps.ECM_Contract__c).Account.Country__r.Code__c+'_CIO':'';
                if(activeQueueMemberMap != Null && contractList.containskey(ps.ECM_Contract__c) && activeQueueMemberMap.containskey(countryQueueName)){
                    List<String> activeApproverist =  activeQueueMemberMap.get(countryQueueName);
                    if(activeApproverist != null && activeApproverist.size()>0){
                        ps.ECM_CIO_Approver_1__c = activeApproverist[0];
                        ps.ECM_CIO_Approver_2__c = activeApproverist[0]; 
                        ps.ECM_CIO_Approver_3__c = activeApproverist[0]; 
                        ps.ECM_CIO_Approver_4__c = activeApproverist[0]; 
                        ps.ECM_CIO_Approver_5__c = activeApproverist[0];
                        ps.ECM_CIO_Approver_6__c = activeApproverist[0];
                        if(activeApproverist.size()>1){
                            ps.ECM_CIO_Approver_2__c = activeApproverist[1];                             
                        }
                        if(activeApproverist.size()>2){
                            ps.ECM_CIO_Approver_3__c = activeApproverist[2];                             
                        }
                        if(activeApproverist.size()>3){
                            ps.ECM_CIO_Approver_4__c = activeApproverist[3]; 
                        }
                        if(activeApproverist.size()>4){                                                   
                            ps.ECM_CIO_Approver_5__c = activeApproverist[4]; 
                        }
                        if(activeApproverist.size()>5){                        
                            ps.ECM_CIO_Approver_6__c = activeApproverist[5];
                        }
                    }
                }
            }                    
            return pslist;
        }catch(Exception ex){
            throw new TriggerException('line 752 in ECM_paymentsummaryHandler'+ex);
           // return null;
        }  
    }
        
    public class TriggerException extends Exception {}


}