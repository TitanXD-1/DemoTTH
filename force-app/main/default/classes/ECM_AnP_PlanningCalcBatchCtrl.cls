/*
*@Name: ECM_AnP_PlanningCalcBatchCtrl
*@Test Class: ECM_AnP_PlanningCalcBatchTest
*@Description: This class is used in ECM_AnP_PlanningCalcBatch (batch class) as a controller class
*@History                                                            
*
*VERSION		AUTHOR					DATE				DETAIL
*1.0			Saurav Prasad		31/07/2023			Initial Development - 143389 : Creation of A&P screen records for Active/Expired contract and equal split of A&P
*1.1			Shivam Chauhan		07/08/2023				143947
*/
public class ECM_AnP_PlanningCalcBatchCtrl {

    public ECM_A_P_Planning__c updateAnPForecast(WrapperClass wrap, ECM_A_P_Planning__c anpRecord,String iterationStep){

        ECM_Contract_Item__c conItem = wrap.contractItem;
        System.debug(loggingLevel.DEBUG,'conItem inside @'+ conItem);
        System.debug(loggingLevel.DEBUG,'conItem - contract inside @'+ conItem.ECM_Contract__r);
        Map<Integer,Schema.FieldSetMember> forecastFieldSetMap = new  Map<Integer,Schema.FieldSetMember>();
        Map<Integer,Schema.FieldSetMember> paidFieldSetMap = new Map<Integer,Schema.FieldSetMember>();
        
        forecastFieldSetMap.putAll(wrap.forecastFieldSetMap);
        paidFieldSetMap.putAll(wrap.paidFieldSetMap);
        System.debug(LoggingLevel.DEBUG,'forecast'+forecastFieldSetMap);
        System.debug(LoggingLevel.DEBUG,'paid'+paidFieldSetMap);

        System.debug(LoggingLevel.INFO,'iterationStep @'+ iterationStep);
        switch on iterationStep {
            when 'First' {
                wrap.startMonth = conItem.ECM_Contract__r.StartDate.month();
                wrap.endMonth = conItem.ECM_Contract__r.Contract_End_Date__c.year() == conItem.ECM_Contract__r.StartDate.year() 
                    && conItem.ECM_Contract__r.Contract_End_Date__c.month()<12?conItem.ECM_Contract__r.Contract_End_Date__c.month():12;
                
            }
            when 'Last' {
                wrap.startMonth = 1;
                wrap.endMonth = conItem.ECM_Contract__r.Contract_End_Date__c.month();
                
            }
            when else {
                wrap.startMonth = 1;
                wrap.endMonth = 12;
                
            }
        }
        System.debug(LoggingLevel.DEBUG,'wrap @'+ wrap);
        for(Integer i=wrap.startMonth; i<=wrap.endMonth;i++){
            //forcast
            anpRecord.put(forecastFieldSetMap.get(i).getFieldPath(),wrap.forecastAmount);
            System.debug(LoggingLevel.DEBUG,forecastFieldSetMap.get(i).getFieldPath()+'-amount:'+wrap.forecastAmount);
            //paid
            anpRecord.put(paidFieldSetMap.get(i).getFieldPath(),wrap.paidAmount);
            System.debug(LoggingLevel.DEBUG,paidFieldSetMap.get(i).getFieldPath()+'-amount:'+wrap.paidAmount);
        }
        System.debug(LoggingLevel.DEBUG,'anpRecord @'+anpRecord);

        return anpRecord;
        
    }
    
    public void getSchemaFieldSet(Schema.FieldSet fieldSetData,Map<Integer,Schema.FieldSetMember> fieldSetMap){
        Integer countRef = 1;
        for(Schema.FieldSetMember fs : fieldSetData.getFields()){
            fieldSetMap.put(countRef,fs);
            countRef++;
        }
    }
    
    public void getContractAndCIMap(List<Contract> scope, Map<Id,contract> contractMap, map<Id,ECM_Contract_Item__c> mapOfCI){
        for(Contract conRec: scope){
            System.debug(LoggingLevel.DEBUG,'ContractId @'+conRec.Id);
            contractMap.put(conRec.Id, conRec);
            for(ECM_Contract_Item__c conItem: conRec.Contract_Items__r){
                mapOfCI.put(conItem.Id, conItem);
            }
        }
    }
    
    public List<ECM_A_P_Planning__c> getListofAnPRecords(map<Id,ECM_Contract_Item__c> mapOfCI, Map<Integer,Schema.FieldSetMember> forecastFieldSetMap, Map<Integer,Schema.FieldSetMember> paidFieldSetMap){
        List<ECM_A_P_Planning__c> listOfAnPRecords = new List<ECM_A_P_Planning__c>();
        
        System.debug(LoggingLevel.DEBUG, 'forecast out @'+forecastFieldSetMap);
        System.debug(LoggingLevel.DEBUG, 'paid out @'+paidFieldSetMap);
        for(ECM_Contract_Item__c conItem : mapOfCI.values()){  
                Integer calenderY = (conItem.ECM_Contract__r.Contract_End_Date__c.year() - conItem.ECM_Contract__r.StartDate.year()) + 1;
            mapOfCI.get(conItem.Id).ECM_Phasing_Forecast_Total__c = conItem.ECM_TotalAnP_incl_Indirect__c>0?((conItem.ECM_TotalAnP_incl_Indirect__c/conItem.ECM_Contract__r.ECM_Duration__c).setScale(2)*conItem.ECM_Contract__r.ECM_Duration__c).setScale(2,RoundingMode.DOWN):0;//143947
            mapOfCI.get(conItem.Id).ECM_Paid_A_P_Total__c = 0;//143947
                System.debug(LoggingLevel.DEBUG,'calenderY @'+calenderY);
                System.debug(LoggingLevel.DEBUG,'conItem @'+conItem);
                for(Integer i=1; i<=calenderY; i++){
                    String iterationStep = i==1?'First':i==calenderY?'Last':'Middle';
                    ECM_A_P_Planning__c anpRecord = new ECM_A_P_Planning__c();
                    anpRecord.ECM_Contract_Item__c = conItem.id;
                    anpRecord.ECM_Calendar_Year__c = conItem.ECM_Contract__r.StartDate.addYears((i-1)).year();
                    //wrapper class construct
                    WrapperClass wrap = new WrapperClass();
                    wrap.forecastAmount = conItem.ECM_TotalAnP_incl_Indirect__c  > 0 ? 
                        (conItem.ECM_TotalAnP_incl_Indirect__c/conItem.ECM_Contract__r.ECM_Duration__c).setScale(2):0;
                    wrap.forecastFieldSetMap.putAll(forecastFieldSetMap);
                    wrap.paidFieldSetMap.putAll(paidFieldSetMap);
                    wrap.contractItem = conItem;
                    
                    listOfAnPRecords.add(updateAnPForecast(wrap,anpRecord,iterationStep));
                    System.debug(LoggingLevel.DEBUG, 'Inner Loop @'+anpRecord);
                }
            }
        return listOfAnPRecords;
    }
    
    public ResultWrapper getResults(Database.SaveResult[] srList, List<ECM_A_P_Planning__c> listOfAnPRecords,map<Id,ECM_Contract_Item__c> mapOfCI){
        String tempString ='';
        Integer countVar = 0;
        set<Id> exclusionConIds = new set<Id>();
        Boolean hasError = false;
        ResultWrapper wrapResult = new ResultWrapper();
        System.debug(LoggingLevel.DEBUG,'Result @'+ srList);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    hasError = true;
                    for(Database.Error err : sr.getErrors()) {
                        tempString = tempString +' Message : ' + 'Records Failed On Insert :'+err.getStatusCode() + ': ' + err.getMessage() + '\n'+' fields that affected this error: ' + err.getFields() +' \n'; 
                    }
                    ECM_A_P_Planning__c anpRecord = listOfAnPRecords[countVar];
                    exclusionConIds.add(mapOfCI.get(anpRecord.ECM_Contract_Item__c).ECM_Contract__c);
                }
                countVar++;
            }
        wrapResult.exceptionMsg = tempString;
        wrapResult.exclusionIds.addAll(exclusionConIds);
        wrapResult.hasError = hasError;
        return wrapResult;
    }
    public class WrapperClass {
        public Integer startMonth;
        public Integer endMonth;
        public Decimal forecastAmount;
        public Decimal paidAmount;
        public Map<Integer,Schema.FieldSetMember> forecastFieldSetMap;
        public Map<Integer,Schema.FieldSetMember> paidFieldSetMap;
        public ECM_Contract_Item__c contractItem;
        
        public wrapperClass(){
            this.startMonth =0;
            this.endMonth=0;
            this.forecastAmount=0;
            this.paidAmount=0;
            this.forecastFieldSetMap = new Map<Integer,Schema.FieldSetMember>();
            this.paidFieldSetMap = new Map<Integer,Schema.FieldSetMember>();
            this.contractItem = new ECM_Contract_Item__c();
        }
        
    }
    
    public class ResultWrapper {
        public string exceptionMsg;
        public set<Id> exclusionIds;
        public Boolean hasError;
        
        public resultWrapper(){
            this.exceptionMsg = '';
            this.exclusionIds = new set<Id>();
            this.hasError = false;
        }
    }
}