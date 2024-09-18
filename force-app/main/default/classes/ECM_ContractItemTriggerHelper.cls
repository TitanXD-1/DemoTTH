/*
* Class Name : ECM_ContractItemTriggerHelper
* @description: Helper Class for ECM_ContractItemTriggerHandler
* @history
* VERSION    AUTHOR               DATE             DETAIL
* 1.0        Keshava Murthy M     27/01/2022      	ECM-5127 : Disable Edit for related objects of Contract_SFDC_GLO
* 1.1        Pratap Sen           11/02/2022     	ECM-5218 : Fix for the Bug - Enable Profile Check   
* 1.2		 Saurav Prasad		  06/07/2022		ECM-5790 : Validations for Addendum “Forecast Volume“ Screen_SFDC_EU
* 1.3        Pratap Sen           12/07/2022        ECM-5292 : Fixed the implementation of this story for sept22 release
* 1.4        Pratik Somani        10/11/2022        ECM-6315 : Migrating Actual Volume CTD KPI from Parent to child contract_SFDC_EU
* 1.5        Abhishek Sivam       10/11/2022        ECM-6307 : Migrating Contract CTD KPIs from parent to child contract_SFDC_EU
*/

public without sharing class ECM_ContractItemTriggerHelper {
    
    /*
    * @description : Checking profiles to edit/delete Contract Item when Contract status is not draft.
    * @return : void
    * @param : trigger.newMap,trigger.oldMap
    */
    public static void disableConItem(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        String userProfile = [SELECT Name FROM Profile WHERE id = :UserInfo.getProfileId()].Name;
        List<String> allowedProfiles = System.Label.ECM_Profiles_for_ContractRelatedRecordEdit.split(',');//system admin,EDGE BAU user,Int Dataloader
        if(userProfile != NULL && !allowedProfiles.contains(userProfile)){
            if(newItems != NULL){
                disableConItemEdit(newItems.Values());
            }
            else{
                disableConItemDelete(oldItems.Values());          
            }
        }
    }
    
    /*
    * @description : Not allow any profiles to edit Contract Item when Contract status is In Approval, Approved, Inactive, Active, Legal Review, Cancelled.
    * @return : void
    * @param : trigger.New
    */
    public static void disableConItemEdit(List <ECM_Contract_Item__c> newConItems){


        Map<id,String> conMap = new Map<id,String>();
        try{
            for (ECM_Contract_Item__c conItemrecord: [select Id, ECM_Contract__c,ECM_Contract__r.Status,ECM_Addendum__c,ECM_Addendum__r.ECM_Status__c from ECM_Contract_Item__c where Id in:newConItems]) {         
                
                if (conItemrecord.ECM_Contract__c != null) {
                    conMap.put(conItemrecord.ECM_Contract__c,conItemrecord.ECM_Contract__r.Status);         
                }                 
            }
            List<String> conStatus = Label.ECM_Contract_Status_Check.split(',');//In Approval Process,Approved,InActive,Legal Review,Cancelled
            if(!conMap.isEmpty() && conStatus.size()>0){
                for (ECM_Contract_Item__c conItemObj: newConItems) {         
                    if (conItemObj.ECM_Contract__c != null && conMap.containsKey(conItemObj.ECM_Contract__c)) { 
                        if(conStatus.contains(conMap.get(conItemObj.ECM_Contract__c))){
                            conItemObj.addError(Label.ECM_Disable_Edit_Error);//Edit disabled. You can only edit when associated contract is in draft status.                        
                        }
                    }
                }
            }
        }catch(Exception e){
            System.debug('Exception Caught in disableConItemEdit method of ECM_ContractItemTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
        
    }
    
    /*
	* @description : Not allow any profiles to delete Contract Item when Contract status is In Approval, Approved, Inactive, Active, Legal Review, Cancelled.
	* @return : void
	* @param : trigger.old
	*/
    public static void disableConItemDelete(List <ECM_Contract_Item__c> oldConItems){
        Map<id,String> conStatusMap = new Map<id,String>();
        try{
            for (ECM_Contract_Item__c conItem: [select id, ECM_Contract__c,ECM_Contract__r.Status from ECM_Contract_Item__c where Id in:oldConItems]) {         
                if (conItem.ECM_Contract__c != null) {   
                    conStatusMap.put(conItem.ECM_Contract__c,conItem.ECM_Contract__r.Status);                    
                }                 
            }
            List<String> conStatus = Label.ECM_Contract_Status_Check.split(',');//In Approval Process,Approved,InActive,Legal Review,Cancelled
            if(!conStatusMap.isEmpty() && conStatus.size()>0){
                for (ECM_Contract_Item__c conItemsObj: oldConItems) {         
                    if (conItemsObj.ECM_Contract__c != null && conStatusMap.containsKey(conItemsObj.ECM_Contract__c)) { 
                        if(conStatus.contains(conStatusMap.get(conItemsObj.ECM_Contract__c))){
                            conItemsObj.addError(Label.ECM_Disable_Delete_Error);//Delete disabled. You can only delete when associated contract is in draft status.                       
                        }
                    }
                }
            }
        }catch(Exception e){
            System.debug('Exception Caught in disableConItemDelete method of ECM_ContractItemTriggerHelper at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
        
    }
	
    /*
	* @description : update 'CTD Total NSV' when 'Actual Volume CTD' is updated - ECM-5292
	* @return : void
	* @param : trigger.new, trigger.oldMap
	*/
    public static void updateCiNSV(List<ECM_Contract_Item__c> newConItems, Map<Id,sObject> oldConItems){
        Map<Id,ECM_Contract_Item__c> oldConItemsMap = new Map<Id,ECM_Contract_Item__c>();
        List<ECM_Contract_Item__c> conIds = new List<ECM_Contract_Item__c>();
        if(oldConItems!=null) {
            oldConItemsMap = (Map<Id,ECM_Contract_Item__c>)oldConItems;
            for(ECM_Contract_Item__c conItem : newConItems) {
                if(oldConItemsMap.containsKey(conItem.id) && 
                   ((oldConItemsMap.get(conItem.id).ECM_Actual_Volume_YTD__c != conItem.ECM_Actual_Volume_YTD__c)||(oldConItemsMap.get(conItem.id).ECM_CTD_Trade_Lump_Sum__c != conItem.ECM_CTD_Trade_Lump_Sum__c)) && 
                   conItem.ECM_Actual_Volume_YTD__c != null && conItem.ECM_Actual_Volume_YTD__c !=0 && conItem.ECM_Net_Net_List_Price__c != null && conItem.ECM_CTD_Trade_Lump_Sum__c !=null ){
                       conItem.ECM_CTD_Total_NSV__c = ((conItem.ECM_Net_Net_List_Price__c - Decimal.valueOf(conItem.ECM_UoM__c))*conItem.ECM_Actual_Volume_YTD__c) - conItem.ECM_CTD_Trade_Lump_Sum__c;
                   }               
            }         
        }
        //ECM-6315
        if(oldConItems==null) {
            for(ECM_Contract_Item__c conItem : newConItems) {
                if(conItem.ECM_Actual_Volume_YTD__c != null && conItem.ECM_Actual_Volume_YTD__c !=0 && conItem.ECM_Net_Net_List_Price__c != null && conItem.ECM_CTD_Trade_Lump_Sum__c !=null && conItem.ECM_UoM__c != null &&  conItem.ECM_UoM__c != ''){
                       conItem.ECM_CTD_Total_NSV__c = ((conItem.ECM_Net_Net_List_Price__c - Decimal.valueOf(conItem.ECM_UoM__c))*conItem.ECM_Actual_Volume_YTD__c) - conItem.ECM_CTD_Trade_Lump_Sum__c;
                   }               
            }         
        }
    }
	
    /*
	* @description : update roll up Summary fields in Contract Object
	* @return : void
	* @param : trigger.new, trigger.oldMap
	*/
    public static void rollUpsCalalter(List <ECM_Contract_Item__c> newConItems,Map<Id,sObject>oldConItems)
    {
        Map<Id,List<ECM_Contract_Item__c>> conToConItem = new Map<Id,List<ECM_Contract_Item__c>>();
        Map<Id,List<ECM_Contract_Item__c>> newConToConItem = new Map<Id,List<ECM_Contract_Item__c>>();
        Map<Id,Contract> contoCon=new Map<Id,Contract>();
        Map<Id,ECM_Contract_Item__c> oldConItemsMap;
        List<Contract> updatedContracts = new List<Contract>();
        Set<Id> conIds=new Set<Id>();
        Set<Id> conItemIds=new Set<Id>();
        for(ECM_Contract_Item__c conItem:newConItems){
            conItemIds.add(conItem.Id);
        }
        if(oldConItems!=null){
            oldConItemsMap=(Map<Id,ECM_Contract_Item__c>)oldConItems;
        }
        //ECM-6307 - Added ECM_CTD_Overall_Investment__c logic in this method
        for(ECM_Contract_Item__c conItem:newConItems){
            if((oldConItems==null && (conItem.ECM_NSV_After_TI__c!=null||conItem.ECM_CTD_Total_NSV__c!=null||conItem.ECM_CTD_A_P_Investment__c!=null||conItem.ECM_CTD_GP__c!=null
              ||conItem.ECM_CTD_Baseline_CAAP__c!=null||conItem.ECM_CTD_Overall_Investment__c!=null)) || oldConItemsMap!=null && oldConItemsMap.containsKey(conItem.Id) 
              && ((conItem.ECM_NSV_After_TI__c!=oldConItemsMap.get(conItem.Id).ECM_NSV_After_TI__c)||(conItem.ECM_CTD_Total_NSV__c!=oldConItemsMap.get(conItem.Id).ECM_CTD_Total_NSV__c)
              || (conItem.ECM_CTD_A_P_Investment__c!=oldConItemsMap.get(conItem.Id).ECM_CTD_A_P_Investment__c) || (conItem.ECM_CTD_GP__c!=oldConItemsMap.get(conItem.Id).ECM_CTD_GP__c)
              || (conItem.ECM_CTD_Baseline_CAAP__c!=oldConItemsMap.get(conItem.Id).ECM_CTD_Baseline_CAAP__c)||(conItem.ECM_CTD_Overall_Investment__c!=oldConItemsMap.get(conItem.Id).ECM_CTD_Overall_Investment__c))){
                  
                conIds.add(conItem.ECM_Contract__c); 
                  if(newConToConItem.containsKey(conItem.ECM_Contract__c)){
                      newConToConItem.get(conItem.ECM_Contract__c).add(conItem);
                  }else{
                      newConToConItem.put(conItem.ECM_Contract__c, new List<ECM_Contract_Item__c>{conItem});
                  }
            }            
        }
        if(!conIds.isEmpty()){
            List<Contract> conList= [SELECT Id,ECM_Amended__c,ECM_CTD_Total_Baseline_CAAP__c,ECM_CTD_Total_NSV__c,ECM_Total_NSV__c,ECM_CTD_Total_A_P_Investment__c,ECM_CTD_Total_GP__c,ECM_CTD_Overall_Investment__c,
                                     (SELECT Id,ECM_CTD_Baseline_CAAP__c,ECM_NSV_After_TI__c,ECM_CTD_Total_NSV__c,ECM_CTD_A_P_Investment__c,ECM_CTD_GP__c,ECM_CTD_Overall_Investment__c 
                                      FROM Contract_Items__r) FROM Contract WHERE Id IN:conIds];
            if(conList!=null&&!conList.isEmpty())
            {
                for(Contract tempCon:conList)
                {
                    conToConItem.put(tempCon.Id,tempCon.Contract_Items__r);
                    conToCon.put(tempCon.Id,tempCon);
                }
            }
            if(!newConToConItem.isEmpty()){
                for(Id conId : newConToConItem.keySet()){
                    Contract conObj;
                    Decimal totalgp = 0;
                    Decimal totalap = 0;
                    Decimal totalnsv = 0;
                    Decimal totalctdnsv = 0;
                    Decimal totalBaselineCaap=0;
                    DEcimal totalCtdOvrallInv=0;
                    
                    if(!conToCon.isEmpty() && conToCon.containsKey(conId)){
                        conObj = conToCon.get(conId);
                                                
                        conObj.ECM_CTD_Total_GP__c=null;
                        conObj.ECM_CTD_Total_A_P_Investment__c=null;
                        conObj.ECM_Total_NSV__c=null;
                        conObj.ECM_CTD_Total_NSV__c=null;
                        conObj.ECM_CTD_Total_Baseline_CAAP__c=null;
                        conObj.ECM_CTD_Overall_Investment__c=null;
                        
                    }
                    Boolean gpFlag=false;
                    Boolean apFlag=false;
                    Boolean nsvFlag=false;
                    Boolean ctdNsvFlag=false;
                    Boolean baselineCaap=false;
                    Boolean ctdOvrall = false;
                    if(conToConItem.containsKey(conId)){
                        for(ECM_Contract_Item__c itemObj: conToConItem.get(conId)){
                            if(itemObj.ECM_CTD_Baseline_CAAP__c!=null){
                                baselineCaap=true;
                                totalBaselineCaap += itemObj.ECM_CTD_Baseline_CAAP__c;
                            }
                            if(itemObj.ECM_CTD_GP__c!=null){
                                gpFlag=true;
                                totalgp += itemObj.ECM_CTD_GP__c;
                            }
                            if(itemObj.ECM_CTD_A_P_investment__c!=null){
                                apFlag=true;
                                totalap += itemObj.ECM_CTD_A_P_investment__c;
                            }
                            if(itemObj.ECM_NSV_After_TI__c!=null){
                                nsvFlag=true;
                                totalnsv += itemObj.ECM_NSV_After_TI__c;
                            }
                            if(itemObj.ECM_CTD_Total_NSV__c!=null){
                                ctdNsvFlag=true;
                                totalctdnsv += itemObj.ECM_CTD_Total_NSV__c;
                            }
                            if(itemObj.ECM_CTD_Overall_Investment__c!=null){
                                ctdOvrall=true;
                                totalCtdOvrallInv += itemObj.ECM_CTD_Overall_Investment__c;
                            }
                        }
                    }
                    if(conObj != null){
                        if(gpFlag==false){
                            totalgp=null;
                        }
                        if(apFlag==false){
                            totalap=null;
                        }
                        if(nsvFlag==false){
                            totalNSV=null;
                        }
                        if(ctdNsvFlag==false){
                            totalctdnsv=null;
                        }
                        if(baselineCaap==false){
                            totalBaselineCaap=null;
                        }
                        if(ctdOvrall==false){
                            totalCtdOvrallInv=null;
                        }
                        conObj.ECM_CTD_Total_GP__c=totalgp;
                        conObj.ECM_CTD_Total_A_P_Investment__c=totalap;
                        conObj.ECM_Total_NSV__c=totalNSV;
                        conObj.ECM_CTD_Total_NSV__c=totalctdnsv; 
                        conObj.ECM_CTD_Total_Baseline_CAAP__c=totalBaselineCaap;
                        conObj.ECM_CTD_Overall_Investment__c=totalCtdOvrallInv;
                        
                        updatedContracts.add(conObj);
                    }
                }
            }
        }
        if(!updatedContracts.isEmpty())
        {
            update updatedContracts;
        }
            
    }
    public static void rollUpsCalDel(Map<Id,sObject>oldConItems)
    {
        Map<Id,List<ECM_Contract_Item__c>> contractMap=new Map<Id,List<ECM_Contract_Item__c>>();
        Map<Id,ECM_Contract_Item__c> oldConItemsMap=(Map<Id,ECM_Contract_Item__c>)oldConItems;
        List<Contract> updatedContracts = new List<Contract>();
        if(!oldConItemsMap.isEmpty()&&oldConItemsMap!=null){
         for(ECM_Contract_Item__c conItem: oldConItemsMap.values()) {         
                if(contractMap.containsKey(conItem.ECM_Contract__c))
                {
                    contractMap.get(conItem.ECM_Contract__c).add(conItem);
                }
                else
                {
                    List<ECM_Contract_Item__c> cList=new List<ECM_Contract_Item__c>();
                    cList.add(conItem);
                    contractMap.put(conItem.ECM_Contract__c,cList);
                }
         }}
        //ECM-6307 - Added ECM_CTD_Overall_Investment__c logic in this method
        List<Contract> conList=[SELECT Id,ECM_CTD_Total_Baseline_CAAP__c,(SELECT Id,ECM_CTD_Baseline_CAAP__c,ECM_NSV_After_TI__c,ECM_CTD_Total_NSV__c,ECM_CTD_A_P_Investment__c,ECM_CTD_GP__c,ECM_CTD_Overall_Investment__c 
                                FROM Contract_Items__r),ECM_CTD_Total_GP__c,ECM_CTD_Total_A_P_Investment__c,ECM_Total_NSV__c,ECM_CTD_Total_NSV__c,ECM_CTD_Overall_Investment__c FROM Contract 
                                WHERE Id IN:contractMap.keySet()];
        if(!conList.isEmpty()&&conList!=null){
            for(Contract conObject:conList){
                for(ECM_Contract_Item__c oldConItemObj:contractMap.get(conObject.Id)){
                    if(oldConItemObj != null){
                        if(oldConItemObj.ECM_CTD_GP__c!=null && conObject.ECM_CTD_Total_GP__c!=null){
                            conObject.ECM_CTD_Total_GP__c -= oldConItemObj.ECM_CTD_GP__c;
                        }
                        if(oldConItemObj.ECM_CTD_A_P_Investment__c!=null && conObject.ECM_CTD_Total_A_P_Investment__c!=null){
                            conObject.ECM_CTD_Total_A_P_Investment__c -= oldConItemObj.ECM_CTD_A_P_Investment__c;
                        }
                        if(oldConItemObj.ECM_NSV_After_TI__c!=null && conObject.ECM_Total_NSV__c!=null){
                            conObject.ECM_Total_NSV__c -= oldConItemObj.ECM_NSV_After_TI__c;
                        }
                        if(oldConItemObj.ECM_CTD_Total_NSV__c!=null && conObject.ECM_CTD_Total_NSV__c!=null){
                            conObject.ECM_CTD_Total_NSV__c -= oldConItemObj.ECM_CTD_Total_NSV__c;
                        }
                        if(oldConItemObj.ECM_CTD_Baseline_CAAP__c!=null && conObject.ECM_CTD_Total_Baseline_CAAP__c!=null){
                            conObject.ECM_CTD_Total_Baseline_CAAP__c -= oldConItemObj.ECM_CTD_Baseline_CAAP__c;
                        }
                        if(oldConItemObj.ECM_CTD_Overall_Investment__c!=null && conObject.ECM_CTD_Overall_Investment__c!=null){
                            conObject.ECM_CTD_Overall_Investment__c -= oldConItemObj.ECM_CTD_Overall_Investment__c;
                        }                        
                    }
                }
                if(conObject.ECM_CTD_Total_Baseline_CAAP__c==0 || conObject.ECM_CTD_Total_GP__c==0 || conObject.ECM_CTD_Total_A_P_Investment__c==0 ||conObject.ECM_Total_NSV__c ==0 
                   || conObject.ECM_CTD_Total_NSV__c==0 || conObject.ECM_CTD_Overall_Investment__c==0){
                    Boolean gpFlag=false;
                    Boolean apFlag=false;
                    Boolean nsvFlag=false;
                    Boolean ctdNsvFlag=false;
                    Boolean baselineCaap=false;
                    Boolean ctdOvrall = false;
                    for(ECM_Contract_Item__c newConItemObj:conObject.Contract_Items__r){
                        if(newConItemObj.ECM_CTD_GP__c!=null){
                            gpFlag=true;
                        }
                        if(newConItemObj.ECM_CTD_A_P_Investment__c!=null){
                            apFlag=true;
                        }
                        if(newConItemObj.ECM_NSV_After_TI__c!=null){
                            nsvFlag=true;
                        }
                        if(newConItemObj.ECM_CTD_Total_NSV__c!=null){
                            ctdnsvFlag=true;
                        }
                        if(newConItemObj.ECM_CTD_Baseline_CAAP__c!=null){
                            baselineCaap=true;
                        }
                        if(newConItemObj.ECM_CTD_Overall_Investment__c!=null){
                            ctdOvrall=true;
                        }                        
                    }
                    if(gpflag==false){
                        conObject.ECM_CTD_Total_GP__c=null;
                    }
                    if(apFlag==false){
                        conObject.ECM_CTD_Total_A_P_Investment__c=null;
                    }if(nsvFlag==false){
                        conObject.ECM_Total_NSV__c=null;
                    }
                    if(ctdNsvFlag==false){
                        conObject.ECM_CTD_Total_NSV__c=null;
                    }
                    if(ctdNsvFlag==false){
                        conObject.ECM_CTD_Total_NSV__c=null;
                    }
                    if(baselineCaap==false){
                        conObject.ECM_CTD_Total_Baseline_CAAP__c=null;
                    }
                    if(ctdOvrall==false){
                        conObject.ECM_CTD_Overall_Investment__c=null;
                    }
                }
                    updatedContracts.add(conObject);
            }
        }
        if(!updatedContracts.isEmpty()&&updatedContracts!=null){
            update updatedContracts;
        }
    }
    //Changes related to ECM-6315->start
    /*
	* @description : update Volume CTD for Child Contract Object
	* @return : void
	* @param : trigger.new, trigger.oldMap
	*/
    public static void updateChildVolumeCTD(List <ECM_Contract_Item__c> newConItems,Map<Id,sObject>oldConItems)
    {
        Map<Id,ECM_Contract_Item__c> oldConItemsMap = new Map<Id,ECM_Contract_Item__c>();
        Map<String,ECM_Contract_Item__c> conItemContract = new Map<String,ECM_Contract_Item__c>();
        Map<String,Decimal> conItemTIDiff = new Map<String,Decimal>();
        Map<String,Decimal> conItemAnPDiff = new Map<String,Decimal>();
        Map<String,Decimal> conItemTotalDiff = new Map<String,Decimal>();
        List<ECM_Contract_Item__c> conItemIds = new List<ECM_Contract_Item__c>();
        List<ECM_Contract_Item__c> updateConItem = new List<ECM_Contract_Item__c>();
        set<Id> parentContId = new set<Id>();
        Decimal oldCTDParentValue;
        if(oldConItems!=null) {
            oldConItemsMap = (Map<Id,ECM_Contract_Item__c>)oldConItems;
            for(ECM_Contract_Item__c conItem : newConItems) {
                if(oldConItemsMap.containsKey(conItem.id) && ((oldConItemsMap.get(conItem.id).ECM_Actual_Volume_YTD__c != conItem.ECM_Actual_Volume_YTD__c && 
                   conItem.ECM_Actual_Volume_YTD__c != null) || (oldConItemsMap.get(conItem.id).ECM_CTD_Trade_Lump_Sum__c != conItem.ECM_CTD_Trade_Lump_Sum__c) 
                   || (oldConItemsMap.get(conItem.id).ECM_CTD_A_P_Investment__c != conItem.ECM_CTD_A_P_Investment__c ) 
                   || (oldConItemsMap.get(conItem.id).ECM_CTD_Overall_Investment__c != conItem.ECM_CTD_Overall_Investment__c))){
                       parentContId.add(conItem.ECM_Contract__c);
                       String parentContractProductkey = conItem.ECM_Contract__c + '_' +conItem.ECM_Product__c;
                       conItemContract.put(parentContractProductkey,conItem);
                       conItemTIDiff.put(parentContractProductkey,(conItem.ECM_CTD_Trade_Lump_Sum__c != null?conItem.ECM_CTD_Trade_Lump_Sum__c:0) - (oldConItemsMap.get(conItem.id).ECM_CTD_Trade_Lump_Sum__c != null?oldConItemsMap.get(conItem.id).ECM_CTD_Trade_Lump_Sum__c:0));
                       conItemAnPDiff.put(parentContractProductkey,(conItem.ECM_CTD_A_P_Investment__c != null?conItem.ECM_CTD_A_P_Investment__c:0) - (oldConItemsMap.get(conItem.id).ECM_CTD_A_P_Investment__c != null?oldConItemsMap.get(conItem.id).ECM_CTD_A_P_Investment__c:0));
                       conItemTotalDiff.put(parentContractProductkey,(conItem.ECM_CTD_Overall_Investment__c != null?conItem.ECM_CTD_Overall_Investment__c:0) - (oldConItemsMap.get(conItem.id).ECM_CTD_Overall_Investment__c != null?oldConItemsMap.get(conItem.id).ECM_CTD_Overall_Investment__c:0));
                   }
            }
        }
        if(parentContId!=null && !parentContId.isEmpty()){
            conItemIds = [SELECT Id,ECM_Parent_Actual_Volume_CTD__c,ECM_Product__c,ECM_Product__r.Product__c,ECM_Contract__c,ECM_Contract__r.ECM_Amended__c,ECM_Actual_Volume_YTD__c,
                          ECM_Contract__r.ECM_Parent_Contract__r.status,ECM_Contract__r.ECM_Parent_Contract__c,ECM_Contract__r.status,ECM_CTD_Trade_Lump_Sum__c,ECM_CTD_A_P_Investment__c,ECM_CTD_Overall_Investment__c 
                          FROM ECM_Contract_Item__c WHERE ECM_Contract__r.ECM_Amended__c = true AND ECM_Contract__r.status !=: Label.ECM_ContractStatusCancelled AND ECM_Contract__r.ECM_Parent_Contract__c IN:parentContId];
            if(conItemIds!=null && !conItemIds.isEmpty()){
                for(ECM_Contract_Item__c conitems : conItemIds){                     
                    String childContractProductKey = conitems.ECM_Contract__r.ECM_Parent_Contract__c + '_' + conitems.ECM_Product__c;
                    Boolean isAddCI = false;
                    if(conItemContract.containskey(childContractProductKey)){                        
                        oldCTDParentValue = conitems.ECM_Parent_Actual_Volume_CTD__c != null?conitems.ECM_Parent_Actual_Volume_CTD__c:0;
                        system.debug('oldCTDParentValue'+oldCTDParentValue);
                        conitems.ECM_Parent_Actual_Volume_CTD__c = conItemContract.get(childContractProductKey).ECM_Actual_Volume_YTD__c==null?0:conItemContract.get(childContractProductKey).ECM_Actual_Volume_YTD__c;
                        system.debug('conitems.ECM_Parent_Actual_Volume_CTD__c'+conitems.ECM_Parent_Actual_Volume_CTD__c);
                        //conitems.ECM_Actual_Volume_YTD__c += (conitems.ECM_Parent_Actual_Volume_CTD__c-oldCTDParentValue);
                        conitems.ECM_Actual_Volume_YTD__c=(conitems.ECM_Actual_Volume_YTD__c==null?0:conitems.ECM_Actual_Volume_YTD__c)+(conitems.ECM_Parent_Actual_Volume_CTD__c-oldCTDParentValue);
                        system.debug('conitems.ECM_Actual_Volume_YTD__c'+conitems.ECM_Actual_Volume_YTD__c);
                        //updateConItem.add(conitems);
                        isAddCI = true;
                    }
                    if(conItemTIDiff.containskey(childContractProductKey)){
                        conitems.ECM_CTD_Trade_Lump_Sum__c = conItemTIDiff.get(childContractProductKey) + (conitems.ECM_CTD_Trade_Lump_Sum__c!=null? conitems.ECM_CTD_Trade_Lump_Sum__c:0);
                        isAddCI = true;
                    }
                    if(conItemAnPDiff.containskey(childContractProductKey)){
                        conitems.ECM_CTD_A_P_Investment__c = conItemAnPDiff.get(childContractProductKey) + (conitems.ECM_CTD_A_P_Investment__c!=null? conitems.ECM_CTD_A_P_Investment__c:0);
                        isAddCI = true;
                    }
                    if(conItemTotalDiff.containskey(childContractProductKey)){
                        conitems.ECM_CTD_Overall_Investment__c = conItemTotalDiff.get(childContractProductKey) + (conitems.ECM_CTD_Overall_Investment__c!=null? conitems.ECM_CTD_Overall_Investment__c:0);
                        isAddCI = true;
                    } 
                    if(isAddCI){
                        updateConItem.add(conitems);  
                    }
                }  
            }
        }
        if(updateConItem!=null&&!updateConItem.isEmpty()){
            update updateConItem;
        }
    }
    //Changes related to ECM-6315->End
}