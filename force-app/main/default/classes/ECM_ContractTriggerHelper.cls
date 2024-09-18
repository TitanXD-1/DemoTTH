/**
* @Description: ECM_ContractTriggerHelper
* @Purpose: This is the Helper class of Contract Trigger for CM team
* @History:                                                            
* @VERSION		AUTHOR							DATE           		DETAIL
*	1.0		Anuja Chattopadhyay				07/03/2022			ECM-5269 Contract & Contract with PS Reports Creation With Primary Sales Area & Territory of Contract Owner
*	1.1		Nikhilesh Chandak				14/06/2022			ECM-5678 Updation of Approval Log Status to Cancel for Cancelled Contracts
*   1.2		Suvendu Roy						01/08/2022			ECM-5958 Updation of Approval Date to the day when Contracts moved to Approved Status
*	1.3		Saranya L						26/09/2022			ECM-6175 Updation of open/provisional Payment Summaries of Parent Contract to Cancelled 
*	1.3		Suvendu Roy						26/09/2022			ECM-6174 Updation the Parent Contract status to 'Amended'
*   1.4		Tanishq Banerjee				08/03/2023			ECM-6803 QA_Defect: Salesrep unable to cancel the contract
*	1.5		Saurav Prasad					02/05/2023			CUS-324 Distribution from Trax on Contract Item_SFDC_Europe
*	1.6		Suvendu Roy		     			05/05/2023			CUS-292 Distribution% on Contract_SFDC_Europe
*   1.7     Joshraj Sen                     12/05/2023          CUS-369 Distribution from Trax on Contract Item_SFDC_Europe
*/
public class ECM_ContractTriggerHelper {
    
    public static Boolean isExecutedOnce = false;//CUS-324
    public static Boolean isAddendumTriggered = false;
    /**
     * @description : to update Sales Area and Territory of Contract Owner
     * @param : List,Map 
     */
	public static void updateSalesAreaAndTerritory(List<SObject> newItems,Map<Id, SObject> oldItems){
        Map<Id,Contract> oldContractMap;
        List<Contract> newContracts = (List<Contract>)newItems;
        Set<Id> perRespIdSet = new Set<Id>();
        List<Contract> conList = new List<Contract>();
        Map<Id,Territory__c> terrMap = new Map<Id,Territory__c>();
        if(oldItems != null){
            oldContractMap = (Map<Id,Contract>)oldItems;
        }
        for(Contract contractRec: newContracts){
            if((oldItems == null && contractRec.OwnerId != null)
               ||(oldItems != null && oldContractMap.containsKey(contractRec.Id) 
                  && oldContractMap.get(contractRec.Id).OwnerId!= contractRec.OwnerId)){
                perRespIdSet.add(contractRec.OwnerId);
                conList.add(contractRec);
            }
        }
        if(!perRespIdSet.isEmpty()){
            for(Territory__c terrObj : [SELECT Id,Primary_Sales_Rep__c, Name,Sales_Area__c  
                                        FROM Territory__c 

                                        WHERE RecordType.Name = 'Sales Territory'
                                        AND Primary_Sales_Rep__c IN : perRespIdSet]){

                
                terrMap.put(terrObj.Primary_Sales_Rep__c,terrObj);
            }
        }
        if(!conList.isEmpty()){
            for(Contract contractObj : conList){
                if(String.isNotBlank(contractObj.OwnerId) && terrMap.containsKey(contractObj.OwnerId)){
                    Territory__c terrObj = terrMap.get(contractObj.OwnerId);
                    contractObj.ECM_Primary_Sales_Territory__c = terrObj.Id;
                    contractObj.ECM_Primary_Sales_Area__c = terrObj.Sales_Area__c;
                }
            }
        }
    }

/**
* @description : updateApprovalLogStatusToCancel(ECM-5678)
* @return : void
* @param : List<contract>
*/  
    
    public static void updateApprovalLogStatusToCancel(Map<Id, sObject>newItems,Map<Id, sObject> oldItems){
        
        List<Id> cancelledCons = new List<Id>();
        Map<Id, Contract> mapOldItems = new Map<Id, COntract>();
        Map<Id, Contract> mapNewItems = new Map<Id, COntract>();
        if (oldItems != null) {
            mapOldItems = (Map<Id, Contract>) oldItems;
        }
        if (newItems != null) {
            mapNewItems = (Map<Id, Contract>) newItems;
        }
        for(Id conId: newItems.keyset()){
            System.debug(LoggingLevel.Info,'Status New----->'+ mapNewItems.get(conId).Status);
            System.debug(LoggingLevel.Info,'Status Old----->'+ mapOldItems.get(conId).Status);
            if((mapNewItems.get(conId).Status != mapOldItems.get(conId).Status) && mapNewItems.get(conId).Status == 'Cancelled'){
                cancelledCons.add(conId);
            }
        }
        updateApprvlLogs(cancelledCons);
    }
    //ECM-6803
    private static void updateApprvlLogs(List<Id> cancelledCons){
        List<ECM_Approval_Log__c> approvalLogs = new List<ECM_Approval_Log__c>();
        if(!cancelledCons.isEmpty()){
            approvalLogs = [select Id,ECM_Status__c,ECM_Contract__c, ECM_Contract__r.Status 
                       from ECM_Approval_Log__c
                       WHERE ECM_Contract__c in: cancelledCons AND ECM_Status__c = 'Requested' WITH SECURITY_ENFORCED];
        }
        
        System.debug(LoggingLevel.Info,'Cancelled Contracts Approval log Ids --->'+approvalLogs);
        if(!approvalLogs.isEmpty() && Schema.sObjectType.ECM_Approval_Log__c.isUpdateable()){
            for(ECM_Approval_Log__c currentApprovalLog : approvalLogs){
                	currentApprovalLog.ECM_Status__c = 'Cancelled';
            }
        update approvalLogs; 
    	}
    }
	
/**
* @description : updateApprovalDate (ECM-5958)
* @return : void
* @param : List<contract>
*/   
    public static void updateApprovalDate(Map<Id, sObject>newItems,Map<Id, sObject> oldItems){
        Map<Id, Contract> mapOldItems = new Map<Id, COntract>();
        Map<Id, Contract> mapNewItems = new Map<Id, COntract>();
        if (oldItems != null) {
            mapOldItems = (Map<Id, Contract>) oldItems;
        }
        if (newItems != null) {
            mapNewItems = (Map<Id, Contract>) newItems;
        }
        String recordTypesNames = Label.ECM_Contract_Record_Types;
        List<String> recordTypesNameList = recordTypesNames.split(',');
        List<Id> recordTypesIdList = new List<Id>();
        for(String recordTypesName: recordTypesNameList){
            Id recordTypesId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get(recordTypesName).getRecordTypeId();
            recordTypesIdList.add(recordTypesId);
        }
        for(Id conId: newItems.keyset()){
            if(recordTypesIdList.contains(mapNewItems.get(conId).RecordTypeId) && 
               mapNewItems.get(conId).Status != mapOldItems.get(conId).Status && 
               mapNewItems.get(conId).Status == 'Approved'){
                mapNewItems.get(conId).ECM_Approval_Date__c = System.today();
            }
        }
    }
    /*
     *@description : updateParentContract - updating parent contracts opem/provisional Payment summaries to cancelled status
	 *@return : void
	 *@param : List<contract>
     */
	public static void updateParentContract(Map<Id, sObject>newItems,Map<Id, sObject> oldItems){
        Map<Id, Contract> mapOldItems = new Map<Id, COntract>();
        Map<Id, Contract> mapNewItems = new Map<Id, COntract>();
        List<ECM_Payment_Summary__c> paySummToUpdate = new List<ECM_Payment_Summary__c>();
        List<Contract> conRecsToUpdate = new List<Contract>();
        Set<Id> parentContIds = new Set<Id>();
		List<String> statusValues = Label.ECM_PaymentSummary_Status.split(',');
        if (oldItems != null) {
            mapOldItems = (Map<Id, Contract>) oldItems;
        }
        if (newItems != null) {
            mapNewItems = (Map<Id, Contract>) newItems;
        }
        for(Contract conRec : mapNewItems.values()){
            if(conRec.ECM_Amended__c && conRec.ECM_Parent_Contract__c !=null && mapOldItems.get(conRec.Id).Status != conRec.Status && conRec.Status == 'Active'){
                parentContIds.add(conRec.ECM_Parent_Contract__c);
            }
        }
        // Quering the payment Summaries and changing open/provisional Status records to cancelled status
        List<ECM_Payment_Summary__c> paySumList = [SELECT Id,ECM_Payment_Summary_Status__c FROM ECM_Payment_Summary__c WHERE ECM_Contract__c IN : parentContIds AND (ECM_Payment_Summary_Status__c IN : statusValues)];
        if(paySumList != null && !paySumList.isEmpty()){
            for(ECM_Payment_Summary__c paySummRec : paySumList){
                paySummRec.ECM_Payment_Summary_Status__c = 'Cancelled';
                paySummToUpdate.Add(paySummRec);
            }
        }
        // Updating the Payment Summaries
        if(!paySummToUpdate.isEmpty()){
            Database.update(paySummToUpdate, false);
        }
        //Updating the Parent Contract status to 'Amended' ECM-6174
        for(Id conRecId : parentContIds){
            Contract conRec = new Contract(Id = conRecId);
            conRec.Status = 'Amended';
            conRecsToUpdate.add(conRec);
        }
        if(!conRecsToUpdate.isEmpty()){
            Database.update(conRecsToUpdate, false);
        }
        
    }
    
    
     /*
*@description : updateDistributionAchievedInCI - update Distribution Achieved in Contract Items based on Outlet Execution
*@return : void
*@param : Map<Id, sObject> ,Map<Id, sObject>
*/
    public static void updateDistributionAchievedInCI(Map<Id, sObject>newItems,Map<Id, sObject> oldItems){
        Map<Id, Contract> mapOldItems = (Map<Id, Contract>) oldItems;
        Map<Id, Contract> mapNewItems = (Map<Id, Contract>) newItems;
        
        map<Id,List<ECM_Contract_Item__c>> mapOfContractWithCI = new Map<Id,List<ECM_Contract_Item__c>>();
        map<String, Date> mapOfOutletWithOutletEx = new map<String, Date>();
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        
        String groupContractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get(System.Label.ECM_Group_Contract_RecordType).getRecordTypeId();
        String outletContractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get(System.Label.ECM_Outlet_Contract_RecordType).getRecordTypeId();
        String outletExProductRecordTypeId = Schema.SObjectType.Outlet_Execution__c.getRecordTypeInfosByName().get(System.Label.ECM_OutletExecution_ProductRecordType).getRecordTypeId();
        String yesString=System.label.D1_Yes;//CUS-369
        //set<Id> groupContractIds = new set<Id>();
        Map<Id,String> accountMap = new Map<Id,String>();
        set<Id> outletIds = new set<Id>();
        set<Id> contractIds = new set<Id>();
        set<Id> productIds = new set<Id>();
        map<Id,set<Id>> contractWithOutletContracts = new map<Id,set<Id>>();
        map<Id,Contract> contractMap = new map<Id,Contract>();
        set<Id> setOfConItemsWithDistribution = new set<Id>();
        List<Contract> conRecsToUpdate = new List<Contract>();
        Map<Id, Decimal> distCountMap = new Map<Id, Decimal>();
        
        
        for(Contract conRec: mapNewItems.values()){
            if(groupContractRecordTypeId == conRec.RecordTypeId || 
               outletContractRecordTypeId == conRec.RecordTypeId) {
                   accountMap.put(conRec.accountId,'');
               }
        }
        if(!accountMap.isEmpty()){
            for(Account acc:
                [SELECT Id,Country__r.Code__c
                 FROM Account WHERE Id IN:accountMap.keySet()]){
                     accountMap.put(acc.Id, acc.Country__r.Code__c);
                 }
        }
        
        for(Contract conRec: mapNewItems.values()){
            if(mapOldItems.get(conRec.Id).Status!=conRec.Status &&
               conRec.Status == System.Label.ECM_DistributionAchieved_ContractStatus &&
               accountMap.containsKey(conRec.AccountId) && 
               System.Label.ECM_DistributionAchieved_ContractCountryCodes.split(';').contains(accountMap.get(conRec.AccountId)) ){
                   
                   if(groupContractRecordTypeId == conRec.RecordTypeId || 
                      outletContractRecordTypeId == conRec.RecordTypeId) {
                          contractMap.put(conRec.Id,conRec);
                      }  
               }
        }
        
        isExecutedOnce = (!contractMap.isEmpty());
        System.debug('isExecutedOnce @'+isExecutedOnce);
        
        if(isExecutedOnce){
            //Get all outlet records
            for(Outlet_Contract__c outletContract : 
                [SELECT Id,Outlet__c,Contract__c FROM Outlet_Contract__c 
                 WHERE Contract__c IN:contractMap.keySet()]){
                     outletIds.add(outletContract.Outlet__c);
                     if(!contractWithOutletContracts.containsKey(outletContract.Contract__c)){
                         contractWithOutletContracts.put(outletContract.Contract__c,new set<Id>{outletContract.Outlet__c});
                     }else{
                         contractWithOutletContracts.get(outletContract.Contract__c).add(outletContract.Outlet__c);
                     }
                 }
            
            //Get all contract items and products
            for(ECM_Contract_Item__c conItem :
                [SELECT Id,ECM_Contract__c,ECM_Contract__r.RecordTypeId,ECM_Product__c,
                 ECM_Contract__r.AccountId,ECM_Distribution_Achieved__c,ECM_Contract__r.startDate,
                 ECM_Contract__r.Contract_End_Date__c,Name,
                 ECM_Product__r.Product__c,ECM_Product__r.Product__r.RecordTypeId,
                 ECM_Product__r.Product__r.RecordType.DeveloperName,
                 ECM_Product__r.Product__r.CRI__c,ECM_Product__r.Product__r.Brand_Varient__c,
                 ECM_Product__r.Product__r.Item__r.Brand_Varient__c FROM ECM_Contract_Item__c 
                 WHERE ECM_Contract__c IN:contractMap.keySet()
                 Order by ECM_Contract__c]){
                     conItemList.add(conItem);
                     if(mapOfContractWithCI.containsKey(conItem.ECM_Contract__c)){
                         mapOfContractWithCI.get(conItem.ECM_Contract__c).add(conItem);
                     }
                     else{
                         mapOfContractWithCI.put(conItem.ECM_Contract__c,new List<ECM_Contract_Item__c>{conItem});
                     }
                     switch on conItem.ECM_Product__r.Product__r.RecordType.DeveloperName {
                         when 'SKU' {
                             System.debug('SKU');
                             productIds.add(conItem.ECM_Product__r.Product__r.CRI__c);
                             productIds.add(conItem.ECM_Product__r.Product__r.Brand_Varient__c);
                         }
                         when 'CRI' {
                             System.debug('CRI');
                             productIds.add(conItem.ECM_Product__r.Product__c);
                             productIds.add(conItem.ECM_Product__r.Product__r.Item__r.Brand_Varient__c);
                         }
                         when 'Item' {
                             System.debug('Item');
                             productIds.add(conItem.ECM_Product__r.Product__r.Brand_Varient__c);
                         }
                         when 'Brand_Variant' {
                             System.debug('Brand Variant');
                             productIds.add(conItem.ECM_Product__r.Product__c);
                         }
                         when else {
                             System.debug('none of the above');
                         }
                     }
                     
                 }
            
            //Get Outlet Executions
            for(Outlet_Execution__c outletEx:
                [SELECT Id,Product__c,Product__r.RecordTypeId,Outlet__c,
                 Product__r.RecordType.DeveloperName,Date_of_Execution__c
                 FROM Outlet_Execution__c 
                 WHERE Outlet__c IN:outletIds AND
                 Distribution_TRAX__c=:yesString AND //CUS-369
                 Product__c IN:productIds AND
                 RecordTypeId=:outletExProductRecordTypeId
                 Order by Product__r.RecordType.DeveloperName]){
                     mapOfOutletWithOutletEx.put(outletEx.Outlet__c + '_' + outletEx.Product__c,outletEx.Date_of_Execution__c);
                     
                 }
            
            if(!contractMap.isEmpty()){
                for(ECM_Contract_Item__c conItem :conItemList){
                    Date startDate = conItem.ECM_Contract__r.startDate;
                    Date endDate = conItem.ECM_Contract__r.Contract_End_Date__c;
                    
                    if(contractWithOutletContracts.containsKey(conItem.ECM_Contract__c)){
                           
                           for(Id outletId:contractWithOutletContracts.get(conItem.ECM_Contract__c)){
                               
                               switch on conItem.ECM_Product__r.Product__r.RecordType.DeveloperName {
                                   
                                   when 'SKU' {
                                       String key1,key2;
                                        key1 = outletId + '_' + conItem.ECM_Product__r.Product__r.CRI__c;
                                        key2 = outletId + '_' + conItem.ECM_Product__r.Product__r.Brand_Varient__c;
                                       
                                       if((mapOfOutletWithOutletEx.containsKey(key1) && 
                                           (mapOfOutletWithOutletEx.get(key1)>=startDate && mapOfOutletWithOutletEx.get(key1)<=endDate)) ||
                                         (mapOfOutletWithOutletEx.containsKey(key2) && 
                                           (mapOfOutletWithOutletEx.get(key2)>=startDate && mapOfOutletWithOutletEx.get(key2)<=endDate))){
                                           setOfConItemsWithDistribution.add(conItem.Id);
                                               break;
                                       }
                                       
                                   }
                                   
                                   when 'CRI' {
                                       String key1,key2;
                                       key1 = outletId + '_' + conItem.ECM_Product__r.Product__c;
                                       key2 = outletId + '_' + conItem.ECM_Product__r.Product__r.Item__r.Brand_Varient__c;
                                       
                                       if((mapOfOutletWithOutletEx.containsKey(key1) && 
                                           (mapOfOutletWithOutletEx.get(key1)>=startDate && mapOfOutletWithOutletEx.get(key1)<=endDate)) ||
                                         (mapOfOutletWithOutletEx.containsKey(key2) && 
                                           (mapOfOutletWithOutletEx.get(key2)>=startDate && mapOfOutletWithOutletEx.get(key2)<=endDate))){
                                           setOfConItemsWithDistribution.add(conItem.Id);
                                               break;
                                       }
                                       
                                   }
                                   
                                   when 'Item' {
                                       String key1;
                                       key1 = outletId + '_' + conItem.ECM_Product__r.Product__r.Brand_Varient__c;
                                       
                                       if((mapOfOutletWithOutletEx.containsKey(key1) && 
                                           (mapOfOutletWithOutletEx.get(key1)>=startDate && mapOfOutletWithOutletEx.get(key1)<=endDate))){
                                               setOfConItemsWithDistribution.add(conItem.Id);
                                               break;
                                           }
                                   }
                                   
                                   when 'Brand_Variant' {
                                       String key1;
                                       key1 = outletId + '_' + conItem.ECM_Product__r.Product__c;
                                       
                                       if((mapOfOutletWithOutletEx.containsKey(key1) && 
                                           (mapOfOutletWithOutletEx.get(key1)>=startDate && mapOfOutletWithOutletEx.get(key1)<=endDate))){
                                               setOfConItemsWithDistribution.add(conItem.Id);
                                               break;
                                           }
                                   }
                                   
                                   when else {
                                       System.debug('none of the above');
                                   }
                               }
                               //end of switch case
                           }
                        //end of inner loop
                    }
                }
            }
            //CUS-292
            for(ECM_Contract_Item__c conItem : conItemList){
                conItem.ECM_Distribution_Achieved__c  = setOfConItemsWithDistribution.contains(conItem.Id)?'Yes':'No';
                if(conItem.ECM_Distribution_Achieved__c == 'Yes'){
                    if(distCountMap.containsKey(conItem.ECM_Contract__c)){
                        Decimal count  = distCountMap.get(conItem.ECM_Contract__c) + 1;
                        distCountMap.put(conItem.ECM_Contract__c,count);
                    }
                    else{
                        distCountMap.put(conItem.ECM_Contract__c, 1);
                    }
                }
            }
            if(!conItemList.isEmpty()){
                update conItemList;
            }
            
            for(Id conId : mapOfContractWithCI.keySet()){
                
                Decimal totalSize = mapOfContractWithCI.get(conId).size();
                Decimal countSize = distCountMap.containsKey(conId)?distCountMap.get(conId):0;
                if(totalSize!=0){
                    Decimal percentageVal = countSize != 0? ((countSize/totalSize)*100):0;
                    Contract conRecord = new Contract(Id=conId);
                    conRecord.ECM_Distribution_Percentage__c = percentageVal.setScale(2);
                    conRecsToUpdate.add(conRecord);
                }
            }
            if(!conRecsToUpdate.isEmpty()){
                update conRecsToUpdate;
            }
            //CUS-292
        }
        
    }
}