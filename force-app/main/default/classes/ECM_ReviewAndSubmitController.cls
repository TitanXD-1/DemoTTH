/*
@Name: ECM_ReviewAndSubmitController
@Description: This Class is used to caluculate the hybrid and On premise caluculations in 5th Page
@History:                                                                                                                    
VERSION    AUTHOR                DATE              DETAIL
*1.0      Dasaratha Rami Reddy   31/03/2020        Initial DevelsubmitForApprovalopment
*1.1      Manikandan T    		 03/03/2021        Modified save contract method for the User Story ECM-4066
*1.2	  Chandrakanth			 03/06/2021		   ECM-4194: Delegations Contract Approvals_SFDC_GLO_Contract Creation 
*1.3	  Anivesh Muppa			 26/07/2021		   ECM-4573:Inculde market setting field to validate on user submission
*1.4 	  Anivesh Muppa 		 10/08/2021		   ECM-4452: Add mandatory fields validation 
*1.5	  Subhrojit Majumdar	 02/09/2021		   ECM-4770: A&P unspent should be available from previous active contract
*1.6      Keshav				 13/01/2022		   ECM-4644: Attach Contract PDF to Approvals mail_GLO
*1.7	  Saurav Prasad			 24/01/2022		   ECM-5090: FastTrack_Logic for Approval Mail Attachment_Glo
*1.8      Tanishq & Anshu        10/02/2022        ECM-5160: Screen 5 Contract Recalling_Validations_SFDC_AU
*1.9	  Anivesh Muppa			 25/03/2022		   ECM-5366: added validation for on submit of contract as per the story 
*2.0      Vinay Tummala          06/04/2022        ECM-5397: added getContract method to retrive agreement type fields related to Contract
*2.1	  Saurav Prasad			 12/05/2022		   ECM-5585: Notification for Contract Approval_SFDC_Approval request for sales manager
*2.2      Pratap Sen             26/08/2022        ECM-5816: added logic of E&S contract approval in submitForApproval method
*2.3	  Saurav Prasad       	 18/07/2023        143259	: QA: Sales Manager is not able to approve contract.
*/
public class ECM_ReviewAndSubmitController {
    @AuraEnabled
    public static Wrapper_Review_cal ReviewHybridCaluculatons(contract conObj) {
        Wrapper_Review_cal hybridwrap = New Wrapper_Review_cal();
        totaldisplay TotalOthers = new totaldisplay();
        totaldisplay TotalUpfront_Payment_Loan = new totaldisplay();
        totaldisplay TotalSKUSpecificRebateON = new totaldisplay();
        totaldisplay TotalTraining = new totaldisplay();
        totaldisplay AdditionalInvestmentTotal = new totaldisplay();
        
        totaldisplay TotalSalesDriverDiscount = new totaldisplay();
        totaldisplay TotalAdditionalBannerDiscount = new totaldisplay();
        totaldisplay TotalSKUSpecificOffInvoice = new totaldisplay();
        totaldisplay SalesDriverInvestmentTotal = new totaldisplay();
        
        
        List < ECM_Contract_Item__c > conItemList = [Select Id, ECM_MAT_override__c, ECM_MAT_UOS__c, ECM_Total_GP__c, ECM_Total_SKU_Specific_Rebate_ON__c, ECM_TotalSKU_SpecificRebate__c,ECM_MAT_Original_Entered__c,
                                                     ECM_Total_Sales_Driver_Discount__c, ECMTotal_Additional_Discounts_for_Banner__c, ECM_Total_SKU_Specific_Off_Invoice__c,ECM_MAT_original__c,ECM_Total_SKU_Specific_Rebate__c,
                                                     ECM_Total_COGS__c, ECM_Contract__r.ECM_Duration__c from ECM_Contract_Item__c where ECM_Contract__c =: conObj.Id
                                                    ];
        
        for (ECM_Contract_Item__c conItem: conItemList) {
            hybridwrap.actualCasesPerYear += ((conItem.ECM_MAT_override__c<=0 && !conItem.ECM_MAT_Original_Entered__c)?conItem.ECM_MAT_original__c:conItem.ECM_MAT_override__c).setScale(2);
            hybridwrap.actualCasesOverTerm += (((conItem.ECM_MAT_override__c<=0 && !conItem.ECM_MAT_Original_Entered__c)?conItem.ECM_MAT_original__c:conItem.ECM_MAT_override__c) *(conItem.ECM_Contract__r.ECM_Duration__c/12)).setScale(2);
            hybridwrap.UOSPerYear += conItem.ECM_MAT_UOS__c.setScale(2);
            hybridwrap.UOSOverTerm += (conItem.ECM_MAT_UOS__c * (conItem.ECM_Contract__r.ECM_Duration__c / 12)).setScale(2);
            hybridwrap.GPBeforeTIPerYear += conItem.ECM_Total_GP__c;
            hybridwrap.GPBeforeTIPerTerm += conItem.ECM_Total_GP__c * (conItem.ECM_Contract__r.ECM_Duration__c / 12);
            hybridwrap.COGSPerYear += conItem.ECM_Total_COGS__c;
            hybridwrap.COGSPerTerm += conItem.ECM_Total_COGS__c * (conItem.ECM_Contract__r.ECM_Duration__c / 12);
            
            TotalSKUSpecificRebateON.PerYear += conItem.ECM_Total_SKU_Specific_Rebate__c;
            TotalSalesDriverDiscount.PerYear += conItem.ECM_Total_Sales_Driver_Discount__c.setScale(2);
            TotalAdditionalBannerDiscount.PerYear += conItem.ECMTotal_Additional_Discounts_for_Banner__c.setScale(2);
            TotalSKUSpecificOffInvoice.PerYear += conItem.ECM_Total_SKU_Specific_Off_Invoice__c.setScale(2);
            
        }
        TotalSKUSpecificRebateON.OverTerm = TotalSKUSpecificRebateON.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        TotalSalesDriverDiscount.OverTerm = TotalSalesDriverDiscount.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        TotalAdditionalBannerDiscount.OverTerm = TotalAdditionalBannerDiscount.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        TotalSKUSpecificOffInvoice.OverTerm = TotalSKUSpecificOffInvoice.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        
        SalesDriverInvestmentTotal.PerYear = TotalSalesDriverDiscount.PerYear + TotalAdditionalBannerDiscount.PerYear + TotalSKUSpecificOffInvoice.PerYear;
        
        SalesDriverInvestmentTotal.OverTerm = SalesDriverInvestmentTotal.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        if (conObj.ECM_Total_Training_Over_Term__c != null) {
            TotalTraining.OverTerm = conObj.ECM_Total_Training_Over_Term__c;
            TotalTraining.PerYear = TotalTraining.OverTerm / (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
            
        }
        if (conObj.ECM_Total_Upfront_Payment_Loan_Over_Term__c != null) {
            TotalUpfront_Payment_Loan.OverTerm = conObj.ECM_Total_Upfront_Payment_Loan_Over_Term__c;
            TotalUpfront_Payment_Loan.PerYear = TotalUpfront_Payment_Loan.OverTerm / (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
            
        }
        if (conObj.ECM_Total_Others_Over_Term__c != null) {
            TotalOthers.OverTerm = conObj.ECM_Total_Others_Over_Term__c;
            TotalOthers.PerYear = TotalOthers.OverTerm / (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
            
        }
        if (hybridwrap.GPBeforeTIPerYear != 0) {
            TotalSKUSpecificRebateON.PerGP = (TotalSKUSpecificRebateON.PerYear / hybridwrap.GPBeforeTIPerYear)*100;
            TotalSalesDriverDiscount.PerGP = (TotalSalesDriverDiscount.PerYear / hybridwrap.GPBeforeTIPerYear)*100;
            TotalAdditionalBannerDiscount.PerGP = (TotalAdditionalBannerDiscount.PerYear / hybridwrap.GPBeforeTIPerYear)*100;
            TotalSKUSpecificOffInvoice.PerGP = (TotalSKUSpecificOffInvoice.PerYear / hybridwrap.GPBeforeTIPerYear)*100;
            SalesDriverInvestmentTotal.PerGP = (SalesDriverInvestmentTotal.PerYear / hybridwrap.GPBeforeTIPerYear)*100;
            TotalUpfront_Payment_Loan.PerGP = (TotalUpfront_Payment_Loan.PerYear / hybridwrap.GPBeforeTIPerYear)*100;
            TotalTraining.PerGP = (TotalTraining.PerYear / hybridwrap.GPBeforeTIPerYear)*100;
            TotalOthers.PerGP = (TotalOthers.PerYear / hybridwrap.GPBeforeTIPerYear)*100;
        }
        hybridwrap.TotalOthers = TotalOthers;
        hybridwrap.TotalUpfront_Payment_Loan = TotalUpfront_Payment_Loan;
        hybridwrap.TotalSKUSpecificRebateON = TotalSKUSpecificRebateON;
        hybridwrap.TotalTraining = TotalTraining;
        hybridwrap.AdditionalInvestmentTotal = AdditionalInvestmentTotal(conItemList[0].ECM_Contract__r.ECM_Duration__c, hybridwrap);
        hybridwrap.TotalSalesDriverDiscount = TotalSalesDriverDiscount;
        hybridwrap.TotalAdditionalBannerDiscount = TotalAdditionalBannerDiscount;
        hybridwrap.TotalSKUSpecificOffInvoice = TotalSKUSpecificOffInvoice;
        hybridwrap.SalesDriverInvestmentTotal = SalesDriverInvestmentTotal;
        System.debug('$$$'+conItemList.size()+' '+conItemList[0].ECM_Contract__r.ECM_Duration__c);
        hybridwrap = TotalCustInvst_Calculation(conItemList[0].ECM_Contract__r.ECM_Duration__c, JSON.serialize(hybridwrap), conObj.ECM_OnPremise_Total_A_P_PerYear__c);
        
        return hybridwrap;
    }
    @AuraEnabled
    public static Wrapper_Review_cal Review_On_Premise_Caluculatons(contract conObj) {
        Wrapper_Review_cal On_Premise_wrap = New Wrapper_Review_cal();
        totaldisplay TotalOthers = new totaldisplay();
        totaldisplay TotalUpfront_Payment_Loan = new totaldisplay();
        totaldisplay TotalSKUSpecificRebateON = new totaldisplay();
        totaldisplay TotalTraining = new totaldisplay();
        totaldisplay AdditionalInvestmentTotal = new totaldisplay();
        totaldisplay TotalSalesDriverDiscount = new totaldisplay();
        totaldisplay TotalAdditionalBannerDiscount = new totaldisplay();
        totaldisplay TotalSKUSpecificOffInvoice = new totaldisplay();
        totaldisplay SalesDriverInvestmentTotal = new totaldisplay();
        List < ECM_Contract_Item__c > conItemList = [Select Id, ECM_MAT_ON__c, ECM_MAT_UOS_ON__c, ECM_Total_GP_ON__c, ECM_Total_COGS_ON__c, ECM_Total_SKU_Specific_Rebate_ON__c,
                                                     ECM_Total_COGS__c, ECM_Contract__r.ECM_Duration__c, ECM_Total_Sales_Driver_Discount_ON__c, ECM_Contract__r.ECM_OnPremise_Total_A_P_PerYear__c,
                                                     ECM_Total_Additional_Dis_for_Ban_ON__c, ECM_Total_SKU_Specific_Off_Invoice_ON__c from ECM_Contract_Item__c where ECM_Contract__c =: conObj.Id
                                                    ];
        
        
        
        for (ECM_Contract_Item__c conItem: conItemList) {
            On_Premise_wrap.actualCasesPerYear += conItem.ECM_MAT_ON__c.setScale(2);
            On_Premise_wrap.actualCasesOverTerm += (conItem.ECM_MAT_ON__c * (conItem.ECM_Contract__r.ECM_Duration__c / 12)).setScale(2);
            On_Premise_wrap.UOSPerYear += conItem.ECM_MAT_UOS_ON__c.setScale(2);
            On_Premise_wrap.UOSOverTerm += (conItem.ECM_MAT_UOS_ON__c * (conItem.ECM_Contract__r.ECM_Duration__c / 12)).setScale(2);
            On_Premise_wrap.GPBeforeTIPerYear += conItem.ECM_Total_GP_ON__c;
            On_Premise_wrap.GPBeforeTIPerTerm += conItem.ECM_Total_GP_ON__c * (conItem.ECM_Contract__r.ECM_Duration__c / 12);
            On_Premise_wrap.COGSPerYear += conItem.ECM_Total_COGS_ON__c;
            On_Premise_wrap.COGSPerTerm += conItem.ECM_Total_COGS_ON__c * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
            TotalSKUSpecificRebateON.PerYear += conItem.ECM_Total_SKU_Specific_Rebate_ON__c.setScale(2);
            TotalSalesDriverDiscount.PerYear += conItem.ECM_Total_Sales_Driver_Discount_ON__c.setScale(2);
            TotalAdditionalBannerDiscount.PerYear += conItem.ECM_Total_Additional_Dis_for_Ban_ON__c.setScale(2);
            TotalSKUSpecificOffInvoice.PerYear += conItem.ECM_Total_SKU_Specific_Off_Invoice_ON__c.setScale(2);
        }
        
        
        TotalSKUSpecificRebateON.OverTerm = TotalSKUSpecificRebateON.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        TotalSalesDriverDiscount.OverTerm = TotalSalesDriverDiscount.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        TotalAdditionalBannerDiscount.OverTerm = TotalAdditionalBannerDiscount.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        TotalSKUSpecificOffInvoice.OverTerm = TotalSKUSpecificOffInvoice.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        
        SalesDriverInvestmentTotal.PerYear = TotalSalesDriverDiscount.PerYear + TotalAdditionalBannerDiscount.PerYear + TotalSKUSpecificOffInvoice.PerYear;
        
        SalesDriverInvestmentTotal.OverTerm = SalesDriverInvestmentTotal.PerYear * (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
        
        
        if (conObj.ECM_Total_Training_Over_Term__c != null) {
            TotalTraining.OverTerm = conObj.ECM_Total_Training_Over_Term__c;
            TotalTraining.PerYear = TotalTraining.OverTerm / (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
            
        }
        if (conObj.ECM_Total_Upfront_Payment_Loan_Over_Term__c != null) {
            TotalUpfront_Payment_Loan.OverTerm = conObj.ECM_Total_Upfront_Payment_Loan_Over_Term__c;
            TotalUpfront_Payment_Loan.PerYear = TotalUpfront_Payment_Loan.OverTerm / (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
            
        }
        if (conObj.ECM_Total_Others_Over_Term__c != null) {
            TotalOthers.OverTerm = conObj.ECM_Total_Others_Over_Term__c;
            TotalOthers.PerYear = TotalOthers.OverTerm / (conItemList[0].ECM_Contract__r.ECM_Duration__c / 12);
            
        }
        
        if (On_Premise_wrap.GPBeforeTIPerYear != 0) {
            TotalSKUSpecificRebateON.PerGP = (TotalSKUSpecificRebateON.PerYear / On_Premise_wrap.GPBeforeTIPerYear)*100;
            TotalSalesDriverDiscount.PerGP = (TotalSalesDriverDiscount.PerYear / On_Premise_wrap.GPBeforeTIPerYear)*100;
            TotalAdditionalBannerDiscount.PerGP = (TotalAdditionalBannerDiscount.PerYear / On_Premise_wrap.GPBeforeTIPerYear)*100;
            TotalSKUSpecificOffInvoice.PerGP = (TotalSKUSpecificOffInvoice.PerYear / On_Premise_wrap.GPBeforeTIPerYear)*100;
            SalesDriverInvestmentTotal.PerGP = (SalesDriverInvestmentTotal.PerYear / On_Premise_wrap.GPBeforeTIPerYear)*100;
            TotalUpfront_Payment_Loan.PerGP = (TotalUpfront_Payment_Loan.PerYear / On_Premise_wrap.GPBeforeTIPerYear)*100;
            TotalTraining.PerGP = (TotalTraining.PerYear / On_Premise_wrap.GPBeforeTIPerYear)*100;
            TotalOthers.PerGP = (TotalOthers.PerYear / On_Premise_wrap.GPBeforeTIPerYear)*100;
        }
        
        On_Premise_wrap.TotalSKUSpecificRebateON = TotalSKUSpecificRebateON;
        On_Premise_wrap.TotalTraining = TotalTraining;
        On_Premise_wrap.TotalSalesDriverDiscount = TotalSalesDriverDiscount;
        On_Premise_wrap.TotalAdditionalBannerDiscount = TotalAdditionalBannerDiscount;
        On_Premise_wrap.TotalSKUSpecificOffInvoice = TotalSKUSpecificOffInvoice;
        On_Premise_wrap.SalesDriverInvestmentTotal = SalesDriverInvestmentTotal;
        On_Premise_wrap.TotalOthers = TotalOthers;
        On_Premise_wrap.TotalUpfront_Payment_Loan = TotalUpfront_Payment_Loan;
        system.debug('conObj=>' + conItemList[0].ECM_Contract__r.ECM_OnPremise_Total_A_P_PerYear__c);
        
        On_Premise_wrap.AdditionalInvestmentTotal=AdditionalInvestmentTotal(conItemList[0].ECM_Contract__r.ECM_Duration__c,On_Premise_wrap);
        
        On_Premise_wrap = TotalCustInvst_Calculation(conItemList[0].ECM_Contract__r.ECM_Duration__c, JSON.serialize(On_Premise_wrap), conObj.ECM_OnPremise_Total_A_P_PerYear__c);
        
        return On_Premise_wrap;
    }
    @AuraEnabled
    public static totaldisplay AdditionalInvestmentTotal(decimal ECM_Duration, Wrapper_Review_cal wrappervalues) {
        totaldisplay AdditionalInvestmentTotal = new totaldisplay();
        AdditionalInvestmentTotal.PerYear = wrappervalues.TotalSKUSpecificRebateON.PerYear + wrappervalues.TotalTraining.PerYear +
            wrappervalues.TotalUpfront_Payment_Loan.PerYear +
            wrappervalues.TotalOthers.PerYear;
        AdditionalInvestmentTotal.OverTerm = AdditionalInvestmentTotal.PerYear * (ECM_Duration / 12);
        if (wrappervalues.GPBeforeTIPerYear > 0) {
            AdditionalInvestmentTotal.PerGP = (AdditionalInvestmentTotal.PerYear / wrappervalues.GPBeforeTIPerYear)*100;
        }
        return AdditionalInvestmentTotal;
        
    }
    @AuraEnabled
    public static Wrapper_Review_cal TotalCustInvst_Calculation(decimal ECM_Duration, String wrappervalues, decimal totalAPerYear) {
        system.debug('wrappervalues start'+wrappervalues);
        Wrapper_Review_cal wrappervalue =(Wrapper_Review_cal) System.JSON.deserialize(wrappervalues, Wrapper_Review_cal.class);
        System.debug('$$$'+wrappervalue);
        if(totalAPerYear <=0 || totalAPerYear ==null){
            totalAPerYear=0;
        }
        System.debug('$$$'+wrappervalue.SalesDriverInvestmentTotal.PerYear+'#'+wrappervalue.AdditionalInvestmentTotal.PerYear+'#'+totalAPerYear);
        wrappervalue.TotalCustInvstPerYear = wrappervalue.SalesDriverInvestmentTotal.PerYear + wrappervalue.AdditionalInvestmentTotal.PerYear + totalAPerYear;
        System.debug('$$$'+wrappervalue.TotalCustInvstPerYear+' Duration '+ECM_Duration);
        wrappervalue.TotalCustInvstPerTerm = wrappervalue.TotalCustInvstPerYear * (ECM_Duration / 12);
        System.debug('$$$'+wrappervalue.TotalCustInvstPerTerm);
        if (wrappervalue.GPBeforeTIPerYear != 0) {
            wrappervalue.TotalCustInvstPercentGM = (wrappervalue.TotalCustInvstPerYear / wrappervalue.GPBeforeTIPerYear)*100;
        }
        wrappervalue.GPAfterTIPerYear = wrappervalue.GPBeforeTIPerYear - wrappervalue.TotalCustInvstPerYear;
        wrappervalue.GPAfterTIPerTerm = (wrappervalue.GPBeforeTIPerYear * (ECM_Duration / 12)) - wrappervalue.TotalCustInvstPerTerm;
        wrappervalue.NSVAfterTIPerYear = wrappervalue.GPAfterTIPerYear - wrappervalue.COGSPerYear;
        wrappervalue.NSVAfterTIPerTerm = wrappervalue.NSVAfterTIPerYear * (ECM_Duration / 12);
        if (wrappervalue.NSVAfterTIPerTerm != 0) {
            wrappervalue.GMPercentPerTerm = (wrappervalue.GPAfterTIPerTerm / wrappervalue.NSVAfterTIPerTerm)*100;            
        } 
        If(wrappervalue.NSVAfterTIPerYear!=0){
            wrappervalue.GMPercentPerYear = (wrappervalue.GPAfterTIPerYear/wrappervalue.NSVAfterTIPerYear) *100;
        }
        wrappervalue.TotalUpfront_Payment_Loan.OverTerm=wrappervalue.TotalUpfront_Payment_Loan.OverTerm;
        return wrappervalue;
    }
    /*
     * @Description: Populating A&P unspent value from previous active contract(ECM-4770)
     * @return: Wrapper
     * @param: contract
     */
    //Modification as a part of ECM-5160
    @AuraEnabled
    public static WrapperInst get_active_A_Precord(contract conObj) {
        Decimal value = 0;
        WrapperInst wrapObj = new WrapperInst();
        if(conObj != null){
            List<Contract> conList = [SELECT Id,ECM_A_P_RollOver__c FROM Contract WHERE Id = :conObj.Id];
            if(String.isNotBlank(String.valueOf(conList[0].ECM_A_P_RollOver__c))){
                wrapObj.rollOver = conList[0].ECM_A_P_RollOver__c;
            }
            List<Contract> contr = [SELECT Id, Available_AP_Spend__c, createddate FROM contract WHERE Status =: 'Active'
                                       AND accountId =: conObj.accountId ORDER BY createddate DESC LIMIT 1
                                      ];
            if (contr!= null && contr.size() > 0 && contr[0].Available_AP_Spend__c != null) {
                value = contr[0].Available_AP_Spend__c;
                wrapObj.apUnspent = value;
            }
        }
        return wrapObj;
        //End of ECM-5160
    }
    @AuraEnabled
    Public static ECM_CreateContractController.objectWrapper validationErrorCheck(Contract ContractRecord) {
          if (ContractRecord.CreatedBy == Null) {
            ContractRecord = [select id, accountId,Account.Country_Code__c, Name, ContractNumber,ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c, Contract_End_Date__c, ECM_Duration__c, Status, EndDate, ECM_Additional_info_to_support_decision__c,
                              StartDate, recordTypeId, ECM_Territory__c, ECM_Agreement_Type__c, CreatedBy.Name, Account.Name, ECM_Overall_Investment_Amount__c,
                              ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c, ECM_Hybrid_CustInvest_Total_PercentGP__c, Recordtype.Name
                              from contract where Id =: ContractRecord.Id
                             ];
        }
        ECM_CreateContractController.objectWrapper wrap = new ECM_CreateContractController.objectWrapper();
        ECM_CreateContractController.accountWrapper accwrap = ECM_CreateContractController.getAccountById(ContractRecord.AccountId);
        //changes related to ECM-4573
        Market_Setting__c marketObjs= [SELECT Id, Name__c,Geography__r.Code__c,ECM_Mandatory_field_for_Contract__c,ECM_Contract_Creation_Page__c FROM Market_Setting__c where Geography__r.Code__c =:ContractRecord.Account.Country_Code__c and ECM_Contract_Management_Market__c=true limit 1];
        //Changes related to ECM-4452
        ECM_Contract_Type__c agreementType = getAgreementType(ContractRecord.ECM_Agreement_Type__c);
        
        string errormessage = '';
        //Changes related to ECM-4452
        if(!String.isBlank(agreementType.ECM_Mandatory_Fields_Check__c) && agreementType.ECM_Mandatory_Fields_Check__c.equals('Prior To Submitting Contract For Approval')){            
            //start to ECM-4573
            if(!String.isBlank(marketObjs.ECM_Mandatory_field_for_Contract__c)){
                if (marketObjs.ECM_Mandatory_field_for_Contract__c.contains('SAP Sold to')){ 
                    if(string.isBlank(accwrap.acc.SAP_Sold_to__c)) 
                        errormessage = System.Label.ECM_SAP_Number_Validation;//'customer SAP number is missing from customer record, cannot submit for approval';
                }
                if (marketObjs.ECM_Mandatory_field_for_Contract__c.contains('VAT number')){
                    if(String.isBlank(accwrap.acc.New_VAT__c)) 
                        errormessage += System.Label.ECM_VAT_number;//':Tax registration number is missing from customer record, cannot submit for approval';
                }
                if (marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Legal Name')){ 
                    if(String.isBlank(accwrap.acc.ECM_Legal_Name__c)) 
                        errormessage += System.Label.ECM_Legal_Name_Validation;            
                }
                if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('SAP Ship to')){
                    if(String.isBlank(accwrap.acc.SAP_Ship_to__c))
                        errormessage += System.Label.ECM_SAP_Ship_To ;                 
                }
                if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Customer email for Contract')){
                    if(String.isBlank(accwrap.acc.Email_for_contracts_payments__c))
                        errormessage += System.Label.ECM_Email_for_contracts_payments_Validation ;                 
                }
                if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Sales org')){ 
                    if(String.isBlank(accwrap.acc.Sales_Org__c))
                        errormessage += System.Label.ECM_Sales_Org ;                 
                }
                if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Tax Identification number')){ 
                    if(String.isBlank(accwrap.acc.VAT_Number__c))
                        errormessage += System.Label.ECM_Tax_Registration_Number_Validation;                 
                }
            }
            //end of ECM-4573
        }
        wrap.customerCityStreetName = errormessage;
        system.debug('  wrap.customerCityStreetName' +wrap.customerCityStreetName);
        return wrap;
        
    }
    
    Public static ECM_Contract_Type__c getAgreementType(string agreementTypeId){
        return [SELECT id, Geography__r.Code__c, Name, ECM_Ad_Hoc__c, ECM_Min_Duration__c, ECM_Automatic_approval_amount_threshold__c,
                ECM_Max_Duration__c, ECM_generate_contract_name__c, ECM_Abbreviation__c, ECM_Visible__c, ECM_Allow_Independent__c,
                ECM_Re_Investment_Rate_Approve_Threshold__c,ECM_Mandatory_Fields_Check__c,ECM_Contract_Approval_mail_to_Customer__c
                FROM ECM_Contract_Type__c where Id =:agreementTypeId];        
    }
    
    @AuraEnabled
    Public static ECM_CreateContractController.objectWrapper submitForApproval(Contract ContractRecord) {
        system.debug('ContractRecord '+ContractRecord.AccountId+ ' '+ContractRecord.Id+' '+ContractRecord.RecordTypeId+' '+ContractRecord.ECM_Territory__c+' '+ContractRecord.ECM_Agreement_Type__c);
        String recordTypeIdEnS = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('E&S').getRecordTypeId();//ECM-5816
        String outletRecordTypeID = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String groupRecordTypeID = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        string errormessage = '';
        string EmailId = '';
        string DelegatedUser = System.Label.ECM_Delegated_Approver;
        User recipentUserEmail = new User();
        integer approvalcount;
        string agreementId;
        ECM_CreateContractController.objectWrapper wrap = new ECM_CreateContractController.objectWrapper();
        Boolean isEnS = (ContractRecord.RecordTypeId == recordTypeIdEnS);
        
        AggregateResult cycleCount = [SELECT MAX(ECM_No_of_Approval_Cycles__c) FROM ECM_Approval_Log__c where ECM_Contract__c=:ContractRecord.Id ];
        approvalcount = integer.valueOf(cycleCount.get('expr0')==Null?0:cycleCount.get('expr0'));
        agreementId = ContractRecord.ECM_Agreement_Type__c;
        ECM_CreateContractController.accountWrapper accwrap = ECM_CreateContractController.getAccountById(ContractRecord.AccountId);
        ECM_Contract_Type__c ecmContractType = getAgreementType(agreementId);
        wrap.acc = accwrap.acc;
        wrap.Id = ecmContractType.ECM_Contract_Approval_mail_to_Customer__c?'true':'false';

        Territory__c TerritoryDetails = new Territory__c();
        if (ContractRecord.ECM_Territory__c != Null) {
            TerritoryDetails = getTerritory(ContractRecord.ECM_Territory__c);
        }
        try {
             //added as per ECM-5366
            if(ecmContractType.ECM_Contract_Approval_mail_to_Customer__c){                
                if(String.isBlank(accwrap.acc.Email_for_contracts_payments__c)){
                    ContractRecord.status ='Draft';
                    errormessage = System.Label.ECM_Email_for_contracts_payments;
                }
            }
            if(String.isBlank(errormessage)){
                if ((!isEnS && ContractRecord.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c < ecmContractType.ECM_Automatic_approval_amount_threshold__c 
                    && ContractRecord.ECM_Hybrid_CustInvest_Total_PercentGP__c < ecmContractType.ECM_Re_Investment_Rate_Approve_Threshold__c) ||
                    (isEnS && ContractRecord.ECM_Indicative_Total_Funding__c < ecmContractType.ECM_Automatic_approval_amount_threshold__c)){
                        ContractRecord.status = 'Approved';
                        errormessage = 'Approved'; 
                }
                else if ((!isEnS && (ContractRecord.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c == Null || ContractRecord.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c >= ecmContractType.ECM_Automatic_approval_amount_threshold__c))
                         || (!isEnS && (ContractRecord.ECM_Hybrid_CustInvest_Total_PercentGP__c == Null || ContractRecord.ECM_Hybrid_CustInvest_Total_PercentGP__c >= ecmContractType.ECM_Re_Investment_Rate_Approve_Threshold__c))
                         || (isEnS && ContractRecord.ECM_Indicative_Total_Funding__c >= ecmContractType.ECM_Automatic_approval_amount_threshold__c)){
                             ContractRecord.status = 'In Approval Process';
                             //create Approval Log                               
                             ECM_Approval_Log__c approvLog = new ECM_Approval_Log__c();
                             approvLog.ECM_Time_Date_Log__c = system.now();
                             approvLog.Name = ContractRecord.ContractNumber;
                             approvLog.RecordTypeId = Schema.getGlobalDescribe().get('ECM_Approval_Log__c').getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
                             //Start of ECM-4194
                             if((isEnS || outletRecordTypeID == ContractRecord.RecordTypeId) && TerritoryDetails!=Null && TerritoryDetails.Primary_Sales_Rep__r.ManagerId!=Null){
                                 if(TerritoryDetails.Primary_Sales_Rep__r.Manager.DelegatedApproverId == Null){
                                     recipentUserEmail = getUser(TerritoryDetails.Primary_Sales_Rep__r.ManagerId);//[Select id, Name, Email from User Where Id=:TerritoryDetails.Primary_Sales_Rep__r.ManagerId];
                                     EmailId = recipentUserEmail.Email;
                                     approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?recipentUserEmail.Title:'';
                                 }else{
                                     //Delegation Approval Log
                                     recipentUserEmail = getUser(TerritoryDetails.Primary_Sales_Rep__r.Manager.DelegatedApproverId);
                                     EmailId = recipentUserEmail.Email;
                                     approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?DelegatedUser+' '+recipentUserEmail.Title:'';
                                 }
                             }else if(groupRecordTypeID == ContractRecord.RecordTypeId && accwrap.acc.Person_Responsible__c != Null && accwrap.acc.Person_Responsible__r.ManagerId != Null){
                                 if(accwrap.acc.Person_Responsible__r.Manager.DelegatedApproverId == Null){
                                     recipentUserEmail = getUser(accwrap.acc.Person_Responsible__r.ManagerId);//[Select id, Name, Email from User Where Id=:accwrap.acc.Person_Responsible__r.ManagerId];
                                     EmailId = recipentUserEmail.Email;
                                     approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?recipentUserEmail.Title:'';
                                 }else{
                                     //Delegation Approval Log
                                     recipentUserEmail = getUser(accwrap.acc.Person_Responsible__r.Manager.DelegatedApproverId);
                                     EmailId = recipentUserEmail.Email;
                                     approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?DelegatedUser+' '+recipentUserEmail.Title:'';
                                 }
                             }
                             //End of ECM-4194
                             ContractRecord.status = EmailId != '' ? 'In Approval Process' : 'Draft';
                             approvLog.ECM_Status__c = ContractRecord.status == 'In Approval Process' ? 'Requested' : ContractRecord.status == 'Approved' ? 'Approved' : 'Rejected';
                             approvLog.Name = EmailId != '' ? EmailId : approvLog.Name;
                             approvLog.ECM_No_of_Approval_Cycles__c = approvalcount+1;
                             approvLog.ECM_Type__c = 'Contract';
                             approvLog.ECM_Contract__c = ContractRecord.Id;
                             insert approvLog;
                             
                             if (EmailId != '') {
                                 if(!isEnS){
                                     ECM_CreateContractController.sendPushNotificationForApprovalLog(approvLog.Id,recipentUserEmail.Id); //ECM-5585
                                 } 
                                 sendEmailToUser(recipentUserEmail, ContractRecord,approvLog.Id); //send email to user email id
                             } 
                             else {
                                 errormessage += System.label.ECM_AccountAreLoaded;
                             }
                         }
            }           
            
            system.debug(ContractRecord.ECM_Additional_info_to_support_decision__c);
            update ContractRecord;
            system.debug(errormessage + 'contract record' + ContractRecord.Status);
            wrap.customerCityStreetName = errormessage;
            wrap.customerName = ContractRecord.Status;
            wrap.Upfront = ContractRecord.ECM_Agreement_Type__r.ECM_Upfront_Deed_Minimum__c;
            return wrap;
            
        } 
        catch (Exception ex) {
            throw new AuraHandledException(System.label.ECM_SomeWentWorng + ex.getMessage());            
        }
    }
    Public static void sendEmailToUser(User recipentUserEmail, Contract ContractRecord, Id approvalLogId) {
		
		Market_Setting__c marSetRec = new Market_Setting__c();
        //143259
        Contract conRecord = [SELECT Id,Account.Country_Code__c FROM Contract WHERE Id=:ContractRecord.Id];
        if(ConRecord.Account.Country_Code__c != null){
            marSetRec = [SELECT Id, Name, Geography__r.Code__c, ECM_Contract_pdf_to_Approval_Mails__c FROM Market_Setting__c WHERE Geography__r.Code__c =:ConRecord.Account.Country_Code__c];//ECM-4644
        }
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {recipentUserEmail.Email};
        EmailTemplate emailTemplate = [Select Id, Subject, Description, HtmlValue, DeveloperName, Body from EmailTemplate where DeveloperName = 'ECM_Contract_Approval_Request_Temp_AU'];
        email.setTargetObjectId(recipentUserEmail.Id);
        email.setWhatId(ConRecord.Id);
        email.setOrgWideEmailAddressId([select Id, Address from OrgWideEmailAddress where Address =: Label.ECM_ContractApproverOrgWideEmail].Id);
        email.setTemplateID(emailTemplate.Id);
        email.setSaveAsActivity(false);
        email.setReplyTo(Label.ECM_ContractApproverManagerEmailId);
        email.setToAddresses(toAddresses);
        
        //Start of ECM-5090
        List<Messaging.EmailFileAttachment> allAttachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment approvalMailAttachment = ECM_ApprovalLogUtility.getApprovalMailAttachment(contractRecord.Id,null);
        if(approvalMailAttachment != null){
            allAttachments.add(approvalMailAttachment);
        }
        //end of ECM-5090
        Messaging.EmailFileAttachment attPdf;
		//Modified from ECM-5090
		if(marSetRec.ECM_Contract_pdf_to_Approval_Mails__c){
			String Status = 'Draft';
            Messaging.EmailFileAttachment attach = ECM_ApprovalLogUtility.contractPdf(ContractRecord,Status,null);
            if(attach !=null){
               allAttachments.add(attach); 
               attPdf =  attach;
            }
			
		}
        //Part of ECM-5090
        if(!allAttachments.isEmpty()){
            email.setFileAttachments(allAttachments);
        }
        
        Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        if(attPdf != null){
        Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId();
        ContentVersion cVersionPdf = new ContentVersion();
		if(String.isNotEmpty(recordIdContentVersion)){
			cVersionPdf.RecordTypeId = recordIdContentVersion;
		}
		cVersionPdf.Content_Type__c = 'Contracts';
		cVersionPdf.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
		cVersionPdf.PathOnClient = system.label.ECM_Contract_Approval_Email_PDF_Name;//File name with extention
		cVersionPdf.Title = system.label.ECM_Contract_Approval_Email_PDF_Name;//Name of the file
		cVersionPdf.VersionData = attPdf.body;//File content
		Insert cVersionPdf;
		
		//After saved the Content Verison, get the ContentDocumentId
		Id conDocumentPdf = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersionPdf.Id].ContentDocumentId;
		ContentDocumentLink cDocLinkPdf = new ContentDocumentLink();
		cDocLinkPdf.ContentDocumentId = conDocumentPdf;//Add ContentDocumentId
		cDocLinkPdf.LinkedEntityId = approvalLogId;//Add attachment parentId
		cDocLinkPdf.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
		cDocLinkPdf.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
        Insert cDocLinkPdf;}
    }
    @AuraEnabled
    public static User getUser(String userId) {
        return [Select id, Name, FirstName, Email, Title from User Where Id =: userId];
    }
    @AuraEnabled
    public static Territory__c getTerritory(String territoryId) {
        return [select Id, Name, Primary_Sales_Rep__c, Primary_Sales_Rep__r.Name, Primary_Sales_Rep__r.ManagerId, Primary_Sales_Rep__r.Manager.Email,Primary_Sales_Rep__r.DelegatedApproverId,Primary_Sales_Rep__r.Manager.DelegatedApproverId from Territory__c where id =: territoryId];
    }
    
    //ECM-5397
    @AuraEnabled
    public static Contract getContract(String contractId) {
        return [select Id, ECM_Agreement_Type__r.ECM_Display_Additional_Clause__c,ECM_Additional_Clause__c, ECM_Agreement_Type__r.ECM_Beer_Tap_Term_Confirmation__c, ECM_Beer_Tap_Term_Confirmed__c from contract where id=:contractid];
    }
    
    
    @AuraEnabled
    public static guidelineswrapper getguidelines(contract conObj, Decimal AandpValue, Decimal portfoliovalue,Decimal reinvst) {
        if (AandpValue == null) {
            Contract con = getcontractdetails(conObj);
            AandpValue = con.ECM_A_P_Fund__c != null ? con.ECM_A_P_Fund__c : 0;
        }
        if (portfoliovalue == null) {
            Contract con = getcontractdetails(conObj);
            portfoliovalue = con.ECM_Portfolio_Rebate__c != null ? con.ECM_Portfolio_Rebate__c : 0;
        }
        Wrapper_Review_cal hybridreview = ECM_ReviewAndSubmitController.ReviewHybridCaluculatons(conObj);
        Wrapper_Review_cal onpremisereview = ECM_ReviewAndSubmitController.Review_On_Premise_Caluculatons(conObj);
        guidelineswrapper guidelinewrap = New guidelineswrapper();
        map < String, Pick_Up_Options__c > pickupoptionmap = New map < String, Pick_Up_Options__c > ();
        List < Pick_Up_Options__c > pickupObjList = [Select Id, Name, ECM_Hybrid_UOS__c, Type__c, ECM_On_Premise_UOS__c, ECM_Hybrid_Re_Investment__c,
                                                     ECM_On_Premise_Re_Investment__c from Pick_Up_Options__c where Type__c = 'Local-Segment1'
                                                     AND Geography__r.Name =: 'Australia'
                                                    ];
        for (Pick_Up_Options__c pickup: pickupObjList) {
            pickupoptionmap.put(pickup.Name, pickup);
        }
        if (conObj.ECM_Channel__c == 'hybrid') {
            guidelinewrap.guidelineUOS = pickupObjList[0].ECM_Hybrid_UOS__c;
            guidelinewrap.GuidelineReInvestment = pickupObjList[0].ECM_Hybrid_Re_Investment__c;
            decimal AandpUOS;
            decimal portfolio;
            if (hybridreview.UOSPerYear != null) {
                AandpUOS = hybridreview.UOSPerYear != 0 ? (AandpValue != null ? AandpValue : 0) / hybridreview.UOSPerYear : 0;
                portfolio = hybridreview.UOSPerYear != 0 ? (portfoliovalue != null ? portfoliovalue : 0) / hybridreview.UOSPerYear : 0;
            } else {
                AandpUOS = 0;
                portfolio = 0;
            }
            guidelinewrap.contractUOS = (AandpUOS + portfolio).setScale(2);
            if(reinvst !=null){
                guidelinewrap.contractReInvestment=reinvst.setScale(2);  
            }else{
                guidelinewrap.contractReInvestment = hybridreview.TotalCustInvstPercentGM.setScale(2);
            }
        } else if (conObj.ECM_Channel__c == 'On-Premise' && (conObj.Venue_Type__c == 'Premium [AU]' || conObj.Venue_Type__c == 'Mainstream [AU]' || conObj.Venue_Type__c == 'Iconic [AU]' || conObj.Venue_Type__c == 'Reserve [AU]' || conObj.Venue_Type__c == 'TLA [AU]')) {
            guidelinewrap.guidelineUOS = pickupoptionmap.get(conObj.Venue_Type__c).ECM_On_Premise_UOS__c;
            guidelinewrap.GuidelineReInvestment = pickupoptionmap.get(conObj.Venue_Type__c).ECM_On_Premise_Re_Investment__c;
            decimal AandpUOS;
            decimal portfolio;
            if (onpremisereview.UOSPerYear != null) {
                AandpUOS = onpremisereview.UOSPerYear != 0 ? (AandpValue != null ? AandpValue : 0) / onpremisereview.UOSPerYear : 0;
                portfolio = onpremisereview.UOSPerYear != 0 ? (portfoliovalue != null ? portfoliovalue : 0) / onpremisereview.UOSPerYear : 0;
            } else {
                AandpUOS = 0;
                portfolio = 0;
            }
            guidelinewrap.contractUOS = (AandpUOS + portfolio).setScale(2);
            if(reinvst !=null){
                guidelinewrap.contractReInvestment=reinvst.setScale(2);  
            }else{
                guidelinewrap.contractReInvestment = onpremisereview.TotalCustInvstPercentGM.setScale(2);
            }
            //guidelinewrap.contractReInvestment = onpremisereview.TotalCustInvstPercentGM.setScale(2);
        }
        return guidelinewrap;
    }
    
    @AuraEnabled
    public static List < ECM_Payment_Agreement__c > paymentSchedulevalues(string agreementId) {
        List < ECM_Payment_Agreement__c > paymentScheduleList = [SELECT Id, ECM_Agreement_Type__c, ECM_Payment_Frequency__r.ECM_Other_Investment__c, ECM_Payment_Frequency__c, ECM_Payment_Frequency__r.ECM_Type__c, ECM_Payment_Frequency__r.ECM_Limit_for_prepayment_in_LC__c FROM ECM_Payment_Agreement__c where ECM_Agreement_Type__c =: agreementId AND ECM_Payment_Frequency__r.ECM_Other_Investment__c = true];
        return paymentScheduleList;
    }
    @AuraEnabled
    public static List<volumeoverViewwrap> getvolumeOverview(String contractId){
        List<volumeoverViewwrap> volumeOverviewList=New List<volumeoverViewwrap>();
        map<Id,Decimal> confirmedvolMap=New Map<Id,Decimal>();
        set<Id> paymtSummaryIds=New set<Id>();
        List<ECM_Payment_Summary__c> paymentSummaryList=[Select Id,Name,ECM_Type__c,ECM_Contract__c from ECM_Payment_Summary__c where ECM_Contract__c=:contractId AND ECM_Type__c=:'Volume-Based' AND ECM_Payment_Summary_Status__c=:'Approved'];
        if(paymentSummaryList.size()>0){
            for(ECM_Payment_Summary__c ps:paymentSummaryList){
                paymtSummaryIds.add(ps.Id); 
            }
        }
        List<ECM_Payment_Summary_Item__c> psItemList=[Select Id,ECM_Contract_Item__c,ECM_Confirmed_Volume__c from ECM_Payment_Summary_Item__c where ECM_Payment_Summary__c In:paymtSummaryIds];
        system.debug('psItemList'+psItemList);
        if(psItemList.size()>0){
            for(ECM_Payment_Summary_Item__c psitem:psItemList){
                if(psitem.ECM_Confirmed_Volume__c !=null){
                    if(confirmedvolMap.containskey(psitem.ECM_Contract_Item__c)){
                        decimal sum=confirmedvolMap.get(psitem.ECM_Contract_Item__c)+psitem.ECM_Confirmed_Volume__c;
                        confirmedvolMap.put(psitem.ECM_Contract_Item__c,sum);                            
                    }
                    else{
                        confirmedvolMap.put(psitem.ECM_Contract_Item__c,psitem.ECM_Confirmed_Volume__c);
                    }
                }
                else{
                    confirmedvolMap.put(psitem.ECM_Contract_Item__c,0);
                }
            }  
        }
        system.debug('confirmedvolMap'+confirmedvolMap);
        List<ECM_Contract_Item__c> conItemList=[Select Id,Name,ECM_Product_Name__c,ECM_Volume__c,ECM_Volume_Target_per_PF__c,ECM_Actual_Volume_YTD__c,ECM_Contract__r.ECM_Duration__c,ECM_Contract__r.StartDate,ECM_Contract__r.ECM_Select_UoM__c,ECM_Contract__r.ECM_Payment_Frequency__c,toLabel(ECM_Contract__r.ECM_Payment_Frequency_type__r.ECM_Type__c) from ECM_Contract_Item__c where ECM_Contract__c=:contractId];
        if(conItemList.size()>0){
            for(ECM_Contract_Item__c conItem:conItemList){
                volumeoverViewwrap volwrap=New volumeoverViewwrap();
                volwrap.contractItem =conItem;
                Decimal monthval=conItem.ECM_Contract__r.StartDate.daysBetween(date.today());
                Decimal monthNum=(monthval/365)*12;
                Integer noOfmonths = Integer.valueof(monthNum);
                system.debug('noOfmonths'+noOfmonths+'-'+conItem.ECM_Contract__r.ECM_Duration__c+'-'+conItem.ECM_Contract__r.StartDate);
                if(conItem.ECM_Volume__c !=null){
                    volwrap.targetVolumeYTD = ((conItem.ECM_Volume__c/conItem.ECM_Contract__r.ECM_Duration__c)*noOfmonths).setScale(2);
                }
                else{
                    volwrap.targetVolumeYTD=0; 
                }
                if(confirmedvolMap !=null && confirmedvolMap.containskey(conItem.Id) && conItem.ECM_Actual_Volume_YTD__c!=null){
                    volwrap.ActualVolumeNotPaid =conItem.ECM_Actual_Volume_YTD__c-confirmedvolMap.get(conItem.Id);
                }else{
                    volwrap.ActualVolumeNotPaid =conItem.ECM_Actual_Volume_YTD__c;  
                }
                if(conItem.ECM_Actual_Volume_YTD__c !=null && conItem.ECM_Volume__c!=null){
                    volwrap.vsTargetPercent=((conItem.ECM_Actual_Volume_YTD__c/conItem.ECM_Volume__c)*100).setScale(2);
                }
                else{
                    volwrap.vsTargetPercent=0; 
                }
                volumeOverviewList.add(volwrap);
            }
        }
        return volumeOverviewList;
    }
    
    @AuraEnabled
    public static contract SaveContract(contract conObj, string AandPval, string portfolioval, string hybridreviewstr, String onpremisereviewstr,Decimal AandPUnspent) {
        system.debug('AandPval' + AandPval);
        system.debug('portfolioval' + portfolioval); 
        system.debug('conObj' + conObj);
        Wrapper_Review_cal hybridreview;
        Wrapper_Review_cal onpremisereview;
        if(hybridreviewstr !=null){
            hybridreview =(Wrapper_Review_cal) System.JSON.deserialize(hybridreviewstr, Wrapper_Review_cal.class);
        }
        else{
            hybridreview =new Wrapper_Review_cal();
        }
        if(onpremisereviewstr !=null){
            onpremisereview =(Wrapper_Review_cal) System.JSON.deserialize(onpremisereviewstr, Wrapper_Review_cal.class);
        }
        else{
            onpremisereview =new Wrapper_Review_cal();
        }
        
        if(conObj.ECM_Channel__c=='On-Premise'){
            hybridreview=onpremisereview;
        }
        Map<Id,ECM_Payment_Agreement__c > mapPayments = new Map<Id,ECM_Payment_Agreement__c >();
        
        for(ECM_Payment_Agreement__c payFreq:paymentSchedulevalues(conObj.ECM_Agreement_Type__c)){
            mapPayments.put(payFreq.ECM_Payment_Frequency__c,payFreq);
        }
        
        //Wrapper_Review_cal hybridreview=ECM_ReviewAndSubmitController.ReviewHybridCaluculatons(conObj);
        // Wrapper_Review_cal onpremisereview=ECM_ReviewAndSubmitController.Review_On_Premise_Caluculatons(conObj);
        system.debug('conObj.ECM_Selected_Payment_Schedule_AU__c='+conObj.ECM_Selected_Payment_Schedule_AU__c);
        if(mapPayments.containskey(conObj.ECM_Selected_Payment_Schedule_AU__c)){
            system.debug('=='+mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c);
            //conObj.ECM_Upfront_Pre_payment_amount__c = mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c=='50% Prepayment'?(onpremisereview.TotalUpfront_Payment_Loan.OverTerm)*0.50:mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c=='100% Prepayment'?onpremisereview.TotalUpfront_Payment_Loan.OverTerm*1:conObj.ECM_Upfront_Pre_payment_amount__c;
            conObj.ECM_Upfront_Pre_payment_amount__c = mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c=='50% Prepayment'?(onpremisereview.TotalUpfront_Payment_Loan.OverTerm)*0.50:mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c=='100% Prepayment'?onpremisereview.TotalUpfront_Payment_Loan.OverTerm*1:mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c=='Equal Instalments'?(onpremisereview.TotalUpfront_Payment_Loan.OverTerm)/(conObj.ECM_Duration__c / 12):mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c=='Retrospective'?0:conObj.ECM_Upfront_Pre_payment_amount__c;
            
        }
        if(mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c)!=null && mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__c!=null){
            if((mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c=='Equal Instalments')||(mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c=='Retrospective')){
                
                if (conObj.ECM_Channel__c == 'hybrid') {
                    conObj.ECM_UOS_Upfront_Target__c=hybridreview.UOSPerYear;
                }else if(conObj.ECM_Channel__c == 'On-Premise'){
                    conObj.ECM_UOS_Upfront_Target__c=onpremisereview.UOSPerYear;
                }
                if(mapPayments.get(conObj.ECM_Selected_Payment_Schedule_AU__c).ECM_Payment_Frequency__r.ECM_Type__c=='Equal Instalments'){
                    
                    conObj.ECM_Upfront_Payment_Instalment__c = (onpremisereview.TotalUpfront_Payment_Loan.OverTerm )/(conObj.ECM_Duration__c / 12);
                    
                }else{
                    conObj.ECM_Upfront_Payment_Instalment__c = (onpremisereview.TotalUpfront_Payment_Loan.OverTerm - conObj.ECM_Upfront_Pre_payment_amount__c)/(conObj.ECM_Duration__c / 12);
                }
                
            }
        }
        system.debug('conObj.ECM_Upfront_Pre_payment_amount__c='+conObj.ECM_Upfront_Pre_payment_amount__c);
        //Start - Commenting the below logic as part of the User Story ECM-4066
        /*   Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('A&P').getRecordTypeId();

list < Contract > contr = [select id, UOS_Earnt__c, createddate from contract where Status =: 'Active'
and RecordTypeid =: RecordTypeId and accountid =: conObj.accountid order by createddate limit 1
];
if (contr.size() > 0 && contr[0].UOS_Earnt__c != null) {
conObj.UOS_Earnt__c= contr[0].UOS_Earnt__c;
}*/
        //End - Commenting the below logic as part of the User Story ECM-4066
        conObj.ECM_Current_A_P_Unspent__c =AandPUnspent;
        conObj.ECM_Hybrid_Actual_Cases_PerYear__c = hybridreview.actualCasesPerYear;
        conObj.ECM_Hybrid_Actual_Cases_OverTerm__c = hybridreview.actualCasesOverTerm;
        conObj.ECM_Hybrid_UOS_PerYear__c = hybridreview.UOSPerYear;
        conObj.ECM_Hybrid_UOS_PerTerm__c = hybridreview.UOSOverTerm;
        conObj.ECM_Hybrid_GP_BeforTI_PerYear__c = hybridreview.GPBeforeTIPerYear;
        conObj.ECM_Hybrid_GP_BeforeTI_PerTerm__c = hybridreview.GPBeforeTIPerTerm;
        conObj.ECM_Hybrid_GP_AfterTI_PerYear__c = hybridreview.GPAfterTIPerYear;
        conObj.ECM_Hybrid_GP_AfterTI_PerTerm__c = hybridreview.GPAfterTIPerTerm;
        conObj.ECM_Hybrid_COGS_PerYear__c = hybridreview.COGSPerYear;
        conObj.ECM_Hybrid_COGS_PerTerm__c = hybridreview.COGSPerTerm;
        conObj.ECM_Hybrid_GMPercent_PerYear__c = hybridreview.GMPercentPerYear;
        conObj.ECM_Hybrid_GMPercent_PerTerm__c = hybridreview.GMPercentPerTerm;
        conObj.ECM_Hybrid_CustInvest_Total_PerYear__c = hybridreview.TotalCustInvstPerYear;
        conObj.ECM_Hybrid_CustInvest_Total_PerTerm__c = hybridreview.TotalCustInvstPerTerm;
        conObj.ECM_Hybrid_CustInvest_Total_PercentGP__c = hybridreview.TotalCustInvstPercentGM;
        conObj.ECM_Hybrid_NSV_AfterTI_PerYear__c = hybridreview.NSVAfterTIPerYear;
        conObj.ECM_Hybrid_NSV_AfterTI_PerTerm__c = hybridreview.NSVAfterTIPerTerm;
        
        conObj.ECM_A_P_Fund__c = AandPval !=null ? Decimal.valueOf(AandPval):0;
        conObj.ECM_Portfolio_Rebate__c = portfolioval!=null ? Decimal.valueOf(portfolioval):0;
        conObj.ECM_A_P_Fund_Over_Term__c = (conObj.ECM_A_P_Fund__c * (conObj.ECM_Duration__c / 12)).setScale(2);
        conObj.ECM_Portfolio_Rebate_OverTerm__c = (conObj.ECM_Portfolio_Rebate__c * (conObj.ECM_Duration__c / 12)).setScale(2);
        
        conObj.ECM_Hybrid_A_P_Fund_PerUOS__c = hybridreview.UOSPerYear != 0 ? (conObj.ECM_A_P_Fund__c / hybridreview.UOSPerYear).setScale(2) : 0;
        conObj.ECM_OnPremise_A_P_Fund_PerUOS__c = onpremisereview.UOSPerYear != 0 ? (conObj.ECM_A_P_Fund__c / onpremisereview.UOSPerYear).setScale(2) : 0;
        conObj.ECM_Hybrid_A_P_Fund_PercentGP__c = hybridreview.GPBeforeTIPerYear != 0 ? (conObj.ECM_A_P_Fund__c / hybridreview.GPBeforeTIPerYear).setScale(2) : 0;
        conObj.ECM_OnPremise_A_P_Fund_PercentGP__c = onpremisereview.GPBeforeTIPerYear != 0 ? (conObj.ECM_A_P_Fund__c / onpremisereview.GPBeforeTIPerYear).setScale(2) : 0;
        conObj.ECM_Hybrid_Portfolio_PerUOS__c = hybridreview.UOSPerYear != 0 ? (conObj.ECM_Portfolio_Rebate__c / hybridreview.UOSPerYear).setScale(2) : 0;
        conObj.ECM_Onpremise_Portfolio_Rebate_PerUOS__c = onpremisereview.UOSPerYear != 0 ? (conObj.ECM_Portfolio_Rebate__c / onpremisereview.UOSPerYear).setScale(2) : 0;
        conObj.ECM_Hybrid_Portfolio_PercentGP__c = hybridreview.GPBeforeTIPerYear != 0 ? (conObj.ECM_Portfolio_Rebate__c / hybridreview.GPBeforeTIPerYear).setScale(2) : 0;
        conObj.ECM_OnPremise_Portfolio_Rebate_PercentGP__c = onpremisereview.GPBeforeTIPerYear != 0 ? (conObj.ECM_Portfolio_Rebate__c / onpremisereview.GPBeforeTIPerYear).setScale(2) : 0;
        conObj.ECM_Hybrid_Total_A_P_PerYear__c = (conObj.ECM_A_P_Fund__c + conObj.ECM_Portfolio_Rebate__c).setScale(2);
        conObj.ECM_Hybrid_Total_A_P_PerTerm__c = (conObj.ECM_Hybrid_Total_A_P_PerYear__c * (conObj.ECM_Duration__c / 12)).setScale(2);
        conObj.ECM_Hybrid_Total_A_P_PerUOS__c = (conObj.ECM_Hybrid_A_P_Fund_PerUOS__c + conObj.ECM_Hybrid_Portfolio_PerUOS__c).setScale(2);
        conObj.ECM_Hybrid_Total_A_P_Per_PercentGP__c = (conObj.ECM_Hybrid_A_P_Fund_PercentGP__c + conObj.ECM_Hybrid_Portfolio_PercentGP__c).setScale(2);
        conObj.ECM_OnPremise_Total_A_P_PerYear__c = conObj.ECM_Hybrid_Total_A_P_PerYear__c;
        conObj.ECM_OnPremise_Total_A_P_PerTerm__c = conObj.ECM_Hybrid_Total_A_P_PerTerm__c;
        conObj.ECM_OnPremise_Total_A_P_PerUOS__c = (conObj.ECM_OnPremise_A_P_Fund_PerUOS__c + conObj.ECM_Onpremise_Portfolio_Rebate_PerUOS__c).setScale(2);
        conObj.ECM_OnPremise_Total_A_P_PercentGP__c = (conObj.ECM_OnPremise_A_P_Fund_PercentGP__c + conObj.ECM_OnPremise_Portfolio_Rebate_PercentGP__c).setScale(2);
        
        conObj.ECM_Hybrid_Sales_Driver_Discount_Per_Yea__c = hybridreview.TotalSalesDriverDiscount.PerYear;
        conObj.ECM_Hybrid_Sales_Driver_Discount_Over_te__c = hybridreview.TotalSalesDriverDiscount.OverTerm;
        conObj.ECM_Hybrid_Sales_Driver_Discount_GP__c = hybridreview.TotalSalesDriverDiscount.PerGP;
        conObj.ECM_Hybrid_Additional_Banner_Discoun_Per__c = hybridreview.TotalAdditionalBannerDiscount.PerYear;
        conObj.ECM_Hybrid_Additional_Banner_Disc_Over__c = hybridreview.TotalAdditionalBannerDiscount.OverTerm;
        conObj.ECM_Hybrid_Additional_Banner_Discount_GP__c = hybridreview.TotalAdditionalBannerDiscount.PerGP;
        conObj.ECM_Hybrid_SKU_Specific_Off_Invoice_Per__c = hybridreview.TotalSKUSpecificOffInvoice.PerYear;
        conObj.ECM_Hybrid_SKU_Specific_Off_Invoice_Over__c = hybridreview.TotalSKUSpecificOffInvoice.OverTerm;
        conObj.ECM_Hybrid_SKU_Specific_Off_Invoice_GP__c = hybridreview.TotalSKUSpecificOffInvoice.PerGP;
        conObj.ECM_Hybrid_Total_Sales_Driver_Per_Year__c = hybridreview.SalesDriverInvestmentTotal.PerYear;
        conObj.ECM_Hybrid_Total_Sales_Driver_Over_Term__c = hybridreview.SalesDriverInvestmentTotal.OverTerm;
        conObj.ECM_Hybrid_Total_Sales_Driver_GP__c = hybridreview.SalesDriverInvestmentTotal.PerGP;
        conObj.ECM_Hybrid_SKU_Specific_Rebate_Per_Year__c = hybridreview.TotalSKUSpecificRebateON.PerYear;
        conObj.ECM_Total_SKU_Specific_Rebate_Over_Term__c = hybridreview.TotalSKUSpecificRebateON.OverTerm;
        conObj.ECM_Hybrid_SKU_Specific_Rebate_GP__c = hybridreview.TotalSKUSpecificRebateON.PerGP;
        
        conObj.ECM_Hybrid_Training_Over_Term__c = onpremisereview.TotalTraining.OverTerm;
        conObj.ECM_Hybrid_Training_Per_Year__c = (onpremisereview.TotalTraining.OverTerm / (conObj.ECM_Duration__c / 12)).setScale(2);
        conObj.ECM_Hybrid_Training_GP__c = hybridreview.GPBeforeTIPerYear != 0 ? conObj.ECM_Hybrid_Training_Per_Year__c / hybridreview.GPBeforeTIPerYear.setscale(2) : 0;
        
        conObj.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c = onpremisereview.TotalUpfront_Payment_Loan.OverTerm;
        conObj.ECM_Hybrid_Upfront_Payment_Loan_Per_Year__c = (onpremisereview.TotalUpfront_Payment_Loan.OverTerm / (conObj.ECM_Duration__c / 12)).setScale(2);
        conObj.ECM_Hybrid_Upfront_Payment_Loan_GP__c = hybridreview.GPBeforeTIPerYear != 0 ? conObj.ECM_Hybrid_Upfront_Payment_Loan_Per_Year__c / hybridreview.GPBeforeTIPerYear.setscale(2) : 0;
        
        conObj.ECM_Hybrid_Others_Over_Term__c = onpremisereview.TotalOthers.OverTerm;
        conObj.ECM_Hybrid_Others_Per_Year__c = (onpremisereview.TotalOthers.OverTerm / (conObj.ECM_Duration__c / 12)).setScale(2);
        conObj.ECM_Hybrid_Others_GP__c = hybridreview.GPBeforeTIPerYear != 0 ? conObj.ECM_Hybrid_Others_Per_Year__c / hybridreview.GPBeforeTIPerYear.setscale(2) : 0;
        
        conObj.ECM_Hybrid_Additional_Investment_TotalPe__c = hybridreview.AdditionalInvestmentTotal.PerYear;
        conObj.ECM_Hybrid_Additional_Invest_Total_Over__c = hybridreview.AdditionalInvestmentTotal.OverTerm;
        conObj.ECM_Hybrid_Additional_Investment_TotalGP__c = hybridreview.AdditionalInvestmentTotal.PerGP;
        conObj.ECM_Actual_Cases_Per_Year_OnPremise__c = onpremisereview.actualCasesPerYear;
        conObj.ECM_Actual_Cases_Over_Term_Onpremise__c = onpremisereview.actualCasesOverTerm;
        conObj.ECM_UOS_Per_Year_Onpremise__c = onpremisereview.UOSPerYear;
        conObj.ECM_UOS_Over_Term_Onpremise__c = onpremisereview.UOSOverTerm;
        conObj.ECM_Gross_Profit_Bef_TI_Per_Yer_Onpremis__c = onpremisereview.GPBeforeTIPerYear;
        conObj.ECM_Gross_Profit_Before_TI_Over_Onpremis__c = onpremisereview.GPBeforeTIPerTerm;
        conObj.ECM_Gross_Profit_After_TI_Per_Year_Onpre__c = onpremisereview.GPAfterTIPerYear;
        conObj.ECM_Gross_Profit_After_TI_Over_Term_Onpr__c = onpremisereview.GPAfterTIPerTerm;
        conObj.ECM_COGS_Per_Year_Onpremise__c = onpremisereview.COGSPerYear;
        conObj.ECM_COGS_Over_Term_Onpremise__c = onpremisereview.COGSPerTerm;
        conObj.ECM_GM_Per_Year_Onpremise__c = onpremisereview.GMPercentPerYear;
        conObj.ECM_GM_Over_Term_Onpremise__c = onpremisereview.GMPercentPerTerm;
        conObj.ECM_Net_Sales_Value_After_TI_PerYea_Opre__c = onpremisereview.NSVAfterTIPerYear;
        conObj.ECM_Net_Sales_Value_AfterTI_Over_Onpremi__c = onpremisereview.NSVAfterTIPerTerm;
        conObj.ECM_Customer_Investment_TotalPer_Onpremi__c = onpremisereview.TotalCustInvstPerYear;
        conObj.ECM_Customer_Investment_TotOver_onpremi__c = onpremisereview.TotalCustInvstPerTerm;
        conObj.ECM_Customer_Investment_TotalGP_Onpremis__c = onpremisereview.TotalCustInvstPercentGM;
        conObj.ECM_Sales_Driver_Discount_Per_Onpremise__c = onpremisereview.TotalSalesDriverDiscount.PerYear;
        conObj.ECM_Sales_Driver_Discount_Over_Onpremise__c = onpremisereview.TotalSalesDriverDiscount.OverTerm;
        conObj.ECM_Sales_Driver_Discount_GP_Onpremise__c = onpremisereview.TotalSalesDriverDiscount.PerGP;
        conObj.ECM_Additional_Banner_Discount_Per_Onpre__c = onpremisereview.TotalAdditionalBannerDiscount.PerYear;
        conObj.ECM_Additional_Banner_Discount_Over_Onpr__c = onpremisereview.TotalAdditionalBannerDiscount.OverTerm;
        conObj.ECM_Additional_Banner_Discount_GP_onprem__c = onpremisereview.TotalAdditionalBannerDiscount.PerGP;
        conObj.ECM_SKU_Specific_Off_Invoice_Per_Onpremi__c = onpremisereview.TotalSKUSpecificOffInvoice.PerYear;
        conObj.ECM_SKU_Specific_Off_Invoice_Over_Onprem__c = onpremisereview.TotalSKUSpecificOffInvoice.OverTerm;
        conObj.ECM_SKU_Specific_Off_Invoice_GP_Onpremis__c = onpremisereview.TotalSKUSpecificOffInvoice.PerGP;
        conObj.ECM_Total_Sales_Driver_Per_Year_Onpremis__c = onpremisereview.SalesDriverInvestmentTotal.PerYear;
        conObj.ECM_Total_Sales_Driver_Over_Term_Onpremi__c = onpremisereview.SalesDriverInvestmentTotal.OverTerm;
        conObj.ECM_Total_Sales_Driver_GP_Onpremise__c = onpremisereview.SalesDriverInvestmentTotal.PerGP;
        conObj.ECM_SKU_Specific_Rebate_Per_Year_Onpremi__c = onpremisereview.TotalSKUSpecificRebateON.PerYear;
        conObj.ECM_SKU_Specific_Rebate_Over_Term_Onprem__c = onpremisereview.TotalSKUSpecificRebateON.OverTerm;
        conObj.ECM_SKU_Specific_Rebate_GP_Onpremise__c = onpremisereview.TotalSKUSpecificRebateON.PerGP;
        conObj.ECM_Training_Per_Year_Onpremise__c = onpremisereview.TotalTraining.PerYear;
        conObj.ECM_Total_Training_Over_Term__c = onpremisereview.TotalTraining.OverTerm;
        conObj.ECM_Training_GP_Onpremise__c = onpremisereview.TotalTraining.PerGP;
        conObj.ECM_Upfront_Payment_Loan_Per_Year_Onprem__c = onpremisereview.TotalUpfront_Payment_Loan.PerYear;
        conObj.ECM_Total_Upfront_Payment_Loan_Over_Term__c = onpremisereview.TotalUpfront_Payment_Loan.OverTerm;
        conObj.ECM_Upfront_Payment_Loan_GP_Onpremise__c = onpremisereview.TotalUpfront_Payment_Loan.PerGP;
        conObj.ECM_Others_Per_Year_Onpremise__c = onpremisereview.TotalOthers.PerYear;
        conObj.ECM_Total_Others_Over_Term__c = onpremisereview.TotalOthers.OverTerm;
        conObj.ECM_Others_GP_Onpremise__c = onpremisereview.TotalOthers.PerGP;
        conObj.ECM_Additional_Investment_Total_Per_Onpr__c = onpremisereview.AdditionalInvestmentTotal.PerYear;
        conObj.ECM_Additional_Investment_Total_Over_Onp__c = onpremisereview.AdditionalInvestmentTotal.OverTerm;
        conObj.ECM_Additional_Investment_Total_GP_Onpre__c = onpremisereview.AdditionalInvestmentTotal.PerGP;
        update conObj;
        return conObj;
    }
    
    @AuraEnabled
    public static contract getcontractdetails(contract conObj) {
        return [Select Id, Name, ECM_Portfolio_Rebate__c, ECM_A_P_Fund__c from contract where Id =: conObj.Id];
    }
    public class Wrapper_Review_cal {
        @AuraEnabled public Decimal actualCasesPerYear {
            get;
            set;
        }
        @AuraEnabled public Decimal actualCasesOverTerm {
            get;
            set;
        }
        @AuraEnabled public Decimal UOSPerYear {
            get;
            set;
        }
        @AuraEnabled public Decimal UOSOverTerm {
            get;
            set;
        }
        @AuraEnabled public Decimal GPBeforeTIPerYear {
            get;
            set;
        }
        @AuraEnabled public Decimal GPBeforeTIPerTerm {
            get;
            set;
        }
        @AuraEnabled public Decimal NSVAfterTIPerYear {
            get;
            set;
        }
        @AuraEnabled public Decimal NSVAfterTIPerTerm {
            get;
            set;
        }
        @AuraEnabled public Decimal COGSPerYear {
            get;
            set;
        }
        @AuraEnabled public Decimal COGSPerTerm {
            get;
            set;
        }
        @AuraEnabled public Decimal GPAfterTIPerYear {
            get;
            set;
        }
        @AuraEnabled public Decimal GPAfterTIPerTerm {
            get;
            set;
        }
        @AuraEnabled public Decimal GMPercentPerYear {
            get;
            set;
        }
        @AuraEnabled public Decimal GMPercentPerTerm {
            get;
            set;
        }
        @AuraEnabled public Decimal TotalCustInvstPerYear {
            get;
            set;
        }
        @AuraEnabled public Decimal TotalCustInvstPerTerm {
            get;
            set;
        }
        @AuraEnabled public Decimal TotalCustInvstPercentGM {
            get;
            set;
        }
        /*@AuraEnabled public Decimal TotalSKUSpecificRebateONperYear {get;set;}
@AuraEnabled public Decimal TotalSKUSpecificRebateOverTerm {get;set;}
@AuraEnabled public Decimal TotalSKUSpecificRebatePerofGP {get;set;}
@AuraEnabled public Decimal TotalTrainingperYear {get;set;}
@AuraEnabled public Decimal TotalTrainingOverTerm {get;set;}
@AuraEnabled public Decimal TotalTrainingPerofGP {get;set;}*/
        @AuraEnabled public totaldisplay TotalUpfront_Payment_Loan {
            get;
            set;
        }
        @AuraEnabled public totaldisplay TotalOthers {
            get;
            set;
        }
        @AuraEnabled public totaldisplay TotalSKUSpecificRebateON {
            get;
            set;
        }
        @AuraEnabled public totaldisplay TotalSalesDriverDiscount {
            get;
            set;
        }
        @AuraEnabled public totaldisplay TotalTraining {
            get;
            set;
        }
        @AuraEnabled public totaldisplay AdditionalInvestmentTotal {
            get;
            set;
        }
        @AuraEnabled public totaldisplay TotalAdditionalBannerDiscount {
            get;
            set;
        }
        @AuraEnabled public totaldisplay TotalSKUSpecificOffInvoice {
            get;
            set;
        }
        @AuraEnabled public totaldisplay SalesDriverInvestmentTotal {
            get;
            set;
        }
        public Wrapper_Review_cal() {
            this.actualCasesPerYear = 0;
            this.actualCasesOverTerm = 0;
            this.UOSPerYear = 0;
            this.UOSOverTerm = 0;
            this.GPBeforeTIPerYear = 0;
            this.GPBeforeTIPerTerm = 0;
            this.NSVAfterTIPerYear = 0;
            this.NSVAfterTIPerTerm = 0;
            this.COGSPerYear = 0;
            this.COGSPerTerm = 0;
            this.GPAfterTIPerYear = 0;
            this.GPAfterTIPerTerm = 0;
            this.GMPercentPerYear = 0;
            this.GMPercentPerTerm = 0;
            this.TotalCustInvstPerYear = 0;
            this.TotalCustInvstPerTerm = 0;
            this.TotalCustInvstPercentGM = 0;
            // this.TotalOthers.PerYear=0;
            
        }
    }
    
    public class totaldisplay {
        @AuraEnabled public Decimal PerYear {
            get;
            set;
        }
        @AuraEnabled public Decimal OverTerm {
            get;
            set;
        }
        @AuraEnabled public Decimal PerGP {
            get;
            set;
        }
        public totaldisplay() {
            this.PerYear = 0;
            this.OverTerm = 0;
            this.PerGP = 0;
        }
        
    }
    
    public class guidelineswrapper {
        @AuraEnabled public Decimal guidelineUOS {
            get;
            set;
        }
        @AuraEnabled public Decimal contractUOS {
            get;
            set;
        }
        @AuraEnabled public Decimal contractReInvestment {
            get;
            set;
        }
        @AuraEnabled public Decimal GuidelineReInvestment {
            get;
            set;
        }
        public guidelineswrapper() {
            this.guidelineUOS = 0;
            this.contractUOS = 0;
            this.contractReInvestment = 0;
            this.GuidelineReInvestment = 0;
        }
    }
    
    public class volumeoverViewwrap{
        @AuraEnabled public ECM_Contract_Item__c contractItem {get;set;}
        @AuraEnabled public Decimal targetVolumeYTD{get;set;}
        @AuraEnabled public Decimal ActualVolumeNotPaid{get;set;}
        @AuraEnabled public Decimal vsTargetPercent{get;set;}
    }
    //ECM-5160
    public class WrapperInst{
        
        @AuraEnabled public Decimal apUnspent{get;set;}
        @AuraEnabled public Decimal rollOver{get;set;}
        public WrapperInst(){
            this.apUnspent=0;
            this.rollOver=0;
        }
    }    
}