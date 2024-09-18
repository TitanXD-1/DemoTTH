/*
@Name: ECM_ContractKpiHelper

@Purpose: This class is the helper for ECM_CTDReInvestmentRateCalcBatch

@History                                                                                                                    
@VERSION    AUTHOR        		DATE              DETAIL
1.0        Subhodeep Sarkar     30/05/2022        Initial Development (ECM-5354)
2.0		   Anand U/Saranya L	22/07/2022		  ECM-5907

*/
public class ECM_ContractKpiHelper {
    
    
    /*
    * Name : calculateCTDInvestmentRate (ECM-5354)
	* @description : Method to calculate CTD Reinvestment Rate for Contract KPI'S
	* @return : void
	* @param : List of Contracts
	*/
    public static void calculateCTDInvestmentRate(List<Contract> contractList){
        
        List<ECM_Contract_KPI__c> conKpiList = new List<ECM_Contract_KPI__c>(); 
        Set<ID> contractId = new Set<ID>();
        Map<Id,List<ECM_Contract_Item__c> > contractVsContractItem = new Map<Id,List<ECM_Contract_Item__c>>();
        
        //creating set of contract id to be processed
        for (Contract conRec:contractList){
            contractId.add(conRec.Id);
        }
        //creating a map of contract vs contract Item values
        for (ECM_Contract_Item__c conItem : [Select ID,ECM_Contract__c, ECM_Price_List_ConItem__c, ECM_Price_List_ConItem__r.ECM_Gross_Profit__c, ECM_Actual_Volume_YTD__c  from ECM_Contract_Item__c where ECM_Contract__c IN:contractId]){
            if(contractVsContractItem.containsKey(conItem.ECM_Contract__c)){
                contractVsContractItem.get(conItem.ECM_Contract__c).add(conItem);
                }
                else{
                contractVsContractItem.put(conItem.ECM_Contract__c,new List<ECM_Contract_Item__c>{conItem});
                    
                }
            }
        
        for (Contract conRec : contractList){
            Decimal customerInvestmentTotal=0;
            Decimal checkSum = 0;
            ECM_Contract_KPI__c conKPIRec =  new ECM_Contract_KPI__c();
            checkSum = nullCheck(conRec.AP_Spent__c) + nullCheck(conRec.Rebate_Paid__c) + nullCheck(conRec.ECM_Contract_SKU_Specific_Rebate_Paid__c) + nullCheck(conRec.ECM_Contract_Other_Spent__c) + nullCheck(conRec.ECM_Contract_Payment_Spent__c) + nullCheck(conRec.ECM_Upfront_Payment_Spent__c);
            if(contractVsContractItem.containsKey(conRec.Id)){
                if(contractVsContractItem.get(conRec.Id)!= null && contractVsContractItem.get(conRec.Id).size()>0) {
                    for (ECM_Contract_Item__c contractItem : contractVsContractItem.get(conRec.Id)){
                    customerInvestmentTotal += (nullCheck(contractItem.ECM_Price_List_ConItem__r.ECM_Gross_Profit__c) * nullCheck(contractItem.ECM_Actual_Volume_YTD__c));
                }
            }
            }
                Decimal checkResult;
                checkResult= (customerInvestmentTotal!=0)?(checkSum/customerInvestmentTotal):0;//add ternary check and round off
                conKPIRec = createContractKpi(conRec.Id, checkResult, 'Total');
                conKpiList.add(conKPIRec);
        }
        
        If(!conKpiList.isEmpty())
        {
            //upsert conKpiList ECM_External_Id__c;
            List<Database.upsertResult> uResults = Database.upsert(conKpiList,ECM_Contract_KPI__c.ECM_External_Id__c,false);
            for (Database.UpsertResult results : uResults){
                if (!results.isSuccess()){
                    System.debug('Failure : Result ID' + results.getId());
                    System.debug('Failure : Result' + results);
                }
            }
        }
    }
    
  //Method to Check Null value
    public static decimal nullCheck(Decimal val){
        return (val == null)?0:val;
       
    }
    
    /*
    * Name : createContractKpi (ECM-5354)
* @description : Method to create contract KPi Records
	* @return : ECM_Contract_KPI__c
	* @param : Id, decimal, String
	*/
    public static ECM_Contract_KPI__c createContractKpi(Id conRec, Decimal val, String type){
        ECM_Contract_KPI__c contractKpiRec= new ECM_Contract_KPI__c();
        contractKpiRec.ECM_Contract__c=conRec;
        contractKpiRec.ECM_Type__c = type;
        contractKpiRec.ECM_External_Id__c = conRec+contractKpiRec.ECM_Type__c ;//ext id formula
        contractKpiRec.ECM_CTD_Re_Investment_Rate__c= val.setScale(2);
        return contractKpiRec;
        
        
        
    }
    /*
* Name : calculateFieldValues (ECM-5907)
* @description : Method to calculate Kpi values depending on contract item values
* @return : void
* @param : Contract Record
*/
    @AuraEnabled
    public static void calculateFieldValues(Contract contractRec){
        Map<Id,List<ECM_Contract_Item__c> > contractVsContractItem = new Map<Id,List<ECM_Contract_Item__c>>();
        Map<Id,List<Decimal> > fieldSums = new Map<Id,List<Decimal>>();
        Id contractId = contractRec.Id;
        if(contractId!=null){
            List<ECM_Contract_Item__c> conItemsList = [Select ID,ECM_Contract__c, ECM_EU_Volume__c, ECM_NSV_After_TI__c, ECM_Total_trade_investment__c,
                                                       ECM_CAAP_Total__c,ECM_Total_GP_EU__c,ECM_AnP_investment__c  
                                                       from ECM_Contract_Item__c 
                                                       where ECM_Contract__c =:contractId];
            Decimal eUVolumeSum =0;
            Decimal totalNSVSum =0;
            Decimal totalTradeInvestmentSum =0;
            Decimal cAAPTotalSum =0;
            Decimal totalGnP =0;
            Decimal AnPInvestment =0;
            if(conItemsList!=null && !conItemsList.isEmpty()){
                for(ECM_Contract_Item__c conItem : conItemsList){
                    eUVolumeSum += nullChecks(conItem.ECM_EU_Volume__c);
                    totalNSVSum += nullChecks(conItem.ECM_NSV_After_TI__c);
                    totalTradeInvestmentSum += nullChecks(conItem.ECM_Total_trade_investment__c);
                    cAAPTotalSum += nullChecks(conItem.ECM_CAAP_Total__c);
                    totalGnP += nullChecks(conItem.ECM_Total_GP_EU__c);
                    AnPInvestment += nullChecks(conItem.ECM_AnP_investment__c);
                }
                List<Decimal> fieldValueSums = new List<Decimal>{eUVolumeSum,totalNSVSum,totalTradeInvestmentSum,cAAPTotalSum,totalGnP,AnPInvestment};
                createConKpiRecs(fieldValueSums,'Total',contractRec);
                updateConRec(contractRec);
            }
        }
    }
    /*
* Name : createConKpiRecs (ECM-5907)
* @description : Method to create contract KPi Records
* @return : void
* @param : List<decimal>, String, Contract Record
*/
    @AuraEnabled
    public static void createConKpiRecs(List<Decimal> fieldValueSums,String type,Contract contractRec){
        List<ECM_Contract_KPI__c> conKpiRecToInsert = new List<ECM_Contract_KPI__c>();
        Id contId = contractRec.Id;
        if(fieldValueSums!=null && !fieldValueSums.isEmpty()){
            ECM_Contract_KPI__c contractKpiRec = new ECM_Contract_KPI__c();
            contractKpiRec.ECM_Contract__c = contId;
            contractKpiRec.ECM_Type__c = type;
            contractKpiRec.ECM_External_Id__c = contId+contractKpiRec.ECM_Type__c ;//ext id formula
            contractKpiRec.ECM_EU_Volume__c = fieldValueSums[0].setScale(2);
            contractKpiRec.ECM_Total_NSV__c = fieldValueSums[1].setScale(2);
            if(contractKpiRec.ECM_EU_Volume__c != null && contractKpiRec.ECM_EU_Volume__c != 0.00){
                contractKpiRec.ECM_NSV_EU__c = (contractKpiRec.ECM_Total_NSV__c/contractKpiRec.ECM_EU_Volume__c).setScale(2);
                contractKpiRec.ECM_Trade_Investment_EU__c = (fieldValueSums[2]/contractKpiRec.ECM_EU_Volume__c).setScale(2);
            }
            contractKpiRec.ECM_CAAP__c = fieldValueSums[3].setScale(2);
            if(contractKpiRec.ECM_Total_NSV__c != null && contractKpiRec.ECM_Total_NSV__c != 0.00){
                contractKpiRec.ECM_CAAP_Percentage__c = ((contractKpiRec.ECM_CAAP__c*100)/contractKpiRec.ECM_Total_NSV__c).setScale(2);
            }
    
            Decimal overallInvstAmt =contractRec.ECM_Overall_Investment_Figure__c;
            if(overallInvstAmt !=0.00 && overallInvstAmt != null){
                contractKpiRec.ECM_CAAP_ROI_Percentage__c =(((fieldValueSums[4] - fieldValueSums[5])*100)/overallInvstAmt).setScale(2);
            }
            conKpiRecToInsert.add(contractKpiRec);
        }
        if(!conKpiRecToInsert.isEmpty()){
            List<Database.upsertResult> uResults = Database.upsert(conKpiRecToInsert,ECM_Contract_KPI__c.ECM_External_Id__c,false);
            for (Database.UpsertResult results : uResults){
                if (!results.isSuccess()){
                    System.debug('Failure : Result ID' + results.getId());
                    System.debug('Failure : Result' + results);
                }
            }
        }
    }
    /*
* Name : nullChecks (ECM-5907)
* @description : Method to check for null value
* @return : decimal
* @param : Decimal
*/
    @AuraEnabled
    public static decimal nullChecks(Decimal val){
        return (val == null)?0:val;
    
}
  /*
* Name : updateConRec (ECM-5907)
* @description : Method to update contract record
* @return : void
* @param : contract record
*/
    @AuraEnabled
    public static void updateConRec(Contract contractRecord){
       try{
           System.debug('contract record' +contractRecord);
            contractRecord.ECM_Forecast_KPI_Calculated__c = true;
            upsert contractRecord;
            
        }catch(Exception ex){
            system.debug('Error='+ex);  
        }        
    }
}