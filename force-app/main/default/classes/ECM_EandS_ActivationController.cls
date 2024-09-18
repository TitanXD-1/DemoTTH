/*
* @Name: ECM_EandS_ActivationController
* @description: This Class is for handling E&S contract Activation Screen server calls 
* @History 

VERSION    AUTHOR                DATE					DETAIL
1.0       Pratap Sen           09/06/2022        Initial Development for ECM-5661: created methods getActivationData,getPickUpOptionsByCategory & saveActivationData
1.1       Priya Soni           15/09/2022        ECM-5753: modified methods getActivationData,getPickUpOptionsByCategory

*/
public with sharing class ECM_EandS_ActivationController {
    /*
    * @description : This method fetches pickup option records and Event Additional information records along with their recordTypeIds available for a contract
    * @return : activationWrapper 
    * @param : String conId - contract Id, String recTypeNames - String of record Type Names appended by comma
    */
    @AuraEnabled
    public static activationWrapper getActivationData(String agreementId, String conId, String recTypeNames){
        List<Pick_Up_Options__c> pickUpOptionList = new List<Pick_Up_Options__c>();
        List<ECM_Event_Additional_Information__c> activationType1_evntInfo = new List<ECM_Event_Additional_Information__c>();
        List<ECM_Event_Additional_Information__c> activationType2_evntInfo = new List<ECM_Event_Additional_Information__c>();
        Map<String,Id> recordTypeIds = new Map<String,Id>();
        Map<String,Id> recordTypeIds_evntInfo = new Map<String,Id>();
		
        //Fetch Record Type Ids for Objects PickUp Option & Event Additional Information
        List<String> recTypes = recTypeNames.split(',');//Activation by Organiser,Activation by Diageo
        for(String recType : recTypes){
            recordTypeIds.put(recType,
                              ECM_TaxCodeDropdownComponentController.getRecordTypeIdForObject('Pick_Up_Options__c',recType.trim()));
            recordTypeIds_evntInfo.put(recType,
                                       ECM_TaxCodeDropdownComponentController.getRecordTypeIdForObject('ECM_Event_Additional_Information__c',recType.trim()));
        }
		System.debug('PickUp Option Record Types '+recordTypeIds);
        System.debug('Event Additional Info Record Types '+recordTypeIds_evntInfo);
        
        //Query Contract Fields for Activation Screen and related Event Additional Info Records & Split them in Lists by recordTypes
        Contract conRec = [SELECT Id,ContractNumber,ECM_Size__c,ECM_Brands__c,ECM_Opening_Hours__c,ECM_Activation_Plans_presented_to_Event__c,
                           ECM_Quantity_of_Activation_Spaces__c,ECM_Locations__c,ECM_Site_Maps__c,Status,
                          	(SELECT Id,ECM_Information_Type__c,ECM_Information_Type__r.Name,
                          	 ECM_Information_Type__r.ECM_Activation_Category__r.Name,
                             ECM_Description__c,RecordTypeId 
                          	 FROM Event_Additional_Informations__r 
                          	 WHERE ECM_Information_Type__c!= NULL 
                          	 AND ECM_Information_Type__r.ECM_Activation_Category__c != NULL
                          	 AND RecordTypeId IN: recordTypeIds_evntInfo.values())
                          FROM Contract WHERE Id =: conId];
        
        for(ECM_Event_Additional_Information__c evntInfo : conRec.Event_Additional_Informations__r){
            evntInfo.ECM_Information_Type__r.Name = evntInfo.ECM_Information_Type__r.Name.substringBefore('[');
            evntInfo.ECM_Information_Type__r.ECM_Activation_Category__r.Name = evntInfo.ECM_Information_Type__r.ECM_Activation_Category__r.Name.substringBefore('[');
            
            if(recordTypeIds_evntInfo.containsKey(recTypes[0]) && evntInfo.RecordTypeId == recordTypeIds_evntInfo.get(recTypes[0])){//Activation by Organiser
                activationType1_evntInfo.add(evntInfo);
            }
            else if(recordTypeIds_evntInfo.containsKey(recTypes[1]) && evntInfo.RecordTypeId == recordTypeIds_evntInfo.get(recTypes[1])){//Activation by Diageo
                activationType2_evntInfo.add(evntInfo);
            }
        }
      
        //Wrap up all queried items and return
        activationWrapper returnVal = new activationWrapper();
        returnVal.conRec = conRec;
        List<Map<String,List<Pick_Up_Options__c>>> returnMapVal = getPickUpOptionsByCategory(agreementId, 'Pick_Up_Options__c', recTypes);
        returnVal.sec1_pckUpOptions = recordTypeIds.containsKey(recTypes[0])?returnMapVal[0] : new Map<String,List<Pick_Up_Options__c>>();
        returnVal.sec2_pckUpOptions = recordTypeIds.containsKey(recTypes[1])?returnMapVal[1] : new Map<String,List<Pick_Up_Options__c>>();
        returnVal.sec1_evntInfo = activationType1_evntInfo;
        returnVal.sec2_evntInfo = activationType2_evntInfo;
        returnVal.sec1RecordTypeId = recordTypeIds_evntInfo.containsKey(recTypes[0])?recordTypeIds_evntInfo.get(recTypes[0]): '';
        returnVal.sec2RecordTypeId = recordTypeIds_evntInfo.containsKey(recTypes[0])?recordTypeIds_evntInfo.get(recTypes[1]): '';
        return returnVal;
        
    }
    /*
* @description : This method processes list of ECM_Event_Additional_Info_Agreement__c  record and group them by 'Activation Category' for a particular recordType
* @return : Map<String,List<Pick_Up_Options__c>> 
* @param : List<Pick_Up_Options__c> pckupOptList - PickUp Options List to process, String recTypeId - recordType Id to filter
*/
    
    @AuraEnabled
    public static List<Map<String,List<Pick_Up_Options__c>>> getPickUpOptionsByCategory(String agreementId, String objectName, List<String> recordType){
        List<Map<String,List<Pick_Up_Options__c>>>  returnVal = new List<Map<String,List<Pick_Up_Options__c>>>();
        Id activationByOrganiserRecordTypeId = ECM_TaxCodeDropdownComponentController.getRecordTypeIdForObject(objectName, recordType[0]);
        Id activationByDiageoRecordTypeId = ECM_TaxCodeDropdownComponentController.getRecordTypeIdForObject(objectName, recordType[1]);
        
        Map<String,List<Pick_Up_Options__c>> ecmActOraganiserMapByCategoryReturn = new Map<String,List<Pick_Up_Options__c>>();
        Map<String,List<Pick_Up_Options__c>> ecmActDiageoMapByCategoryReturn = new Map<String,List<Pick_Up_Options__c>>();
        
        
        for(ECM_Event_Additional_Info_Agreement__c option : [SELECT Id,ECM_Event_Additional_Pickup_Option__c,ECM_Event_Additional_Pickup_Option__r.Name,
                                                             ECM_Agreement_Type__c, ECM_Event_Additional_Pickup_Option__r.ECM_Activation_Category__c,
                                                             ECM_Event_Additional_Pickup_Option__r.ECM_Activation_Category__r.Name,ECM_Record_Type__c  
                                                             FROM ECM_Event_Additional_Info_Agreement__c 
                                                             WHERE ECM_Agreement_Type__c =:agreementId  
                                                             AND ECM_Event_Additional_Pickup_Option__r.ECM_Activation_Category__c != NULL 
                                                             AND ECM_Event_Additional_Pickup_Option__r.Status__c = 'Active' 
                                                             AND ECM_Record_Type__c IN :recordType
                                                             ORDER BY CreatedDate DESC])
        {
            String categoryName = option.ECM_Event_Additional_Pickup_Option__r.ECM_Activation_Category__r.Name.substringBefore('[').trim();
            option.ECM_Event_Additional_Pickup_Option__r.ECM_Activation_Category__r.Name = categoryName;
            option.ECM_Event_Additional_Pickup_Option__r.Name = option.ECM_Event_Additional_Pickup_Option__r.Name.substringBefore('[').trim();
            
            Pick_Up_Options__c pkOption = new Pick_Up_Options__c(Id=option.ECM_Event_Additional_Pickup_Option__c);
            pkOption.name = option.ECM_Event_Additional_Pickup_Option__r.Name;
            pkOption.ECM_Activation_Category__r = option.ECM_Event_Additional_Pickup_Option__r.ECM_Activation_Category__r;
            pkOption.ECM_Activation_Category__c = option.ECM_Event_Additional_Pickup_Option__r.ECM_Activation_Category__c;

            if (option.ECM_Record_Type__c == recordType[0]){
                pkOption.RecordTypeId = activationByOrganiserRecordTypeId;
                if(ecmActOraganiserMapByCategoryReturn.containsKey(categoryName)){
                    List<Pick_Up_Options__c> mapVal = ecmActOraganiserMapByCategoryReturn.get(categoryName);
                    mapVal.add(pkOption);
                    ecmActOraganiserMapByCategoryReturn.put(categoryName,mapVal);
                }
                else{
                    ecmActOraganiserMapByCategoryReturn.put(categoryName,new List<Pick_Up_Options__c>{pkOption});
                }
                
            }else{
                pkOption.RecordTypeId = activationByDiageoRecordTypeId;
                if(ecmActDiageoMapByCategoryReturn.containsKey(categoryName)){
                    List<Pick_Up_Options__c> mapVal = ecmActDiageoMapByCategoryReturn.get(categoryName);
                    mapVal.add(pkOption);
                    ecmActDiageoMapByCategoryReturn.put(categoryName,mapVal);
                }
                else{
                    ecmActDiageoMapByCategoryReturn.put(categoryName,new List<Pick_Up_Options__c>{pkOption});
                }
            }
        }        
        returnVal.add(ecmActOraganiserMapByCategoryReturn);
        returnVal.add(ecmActDiageoMapByCategoryReturn );

        return returnVal;
        
    }
    /*
    * @description : This method upserts and removes Event Additional Information records as per user activity in client-end
    * @return : Map<String,List<ECM_Event_Additional_Information__c>>
    * @param : String conId - contract Id, String dataToUpsert - JSON data covertable into List of activationEvntInfoWrapper,String recordTypeIds - concat recordTypeIds
    */
    @AuraEnabled
    public static Map<String,List<ECM_Event_Additional_Information__c>> saveActivationData(String conId, String dataToUpsert, String recordTypeIds){
        Map<String,List<ECM_Event_Additional_Information__c>> returnVal = new Map<String,List<ECM_Event_Additional_Information__c>>(); 
        
        if(!String.isBlank(dataToUpsert)){
            List<ECM_Event_Additional_Information__c> responseData = (List<ECM_Event_Additional_Information__c>)JSON.deserialize(dataToUpsert, List<ECM_Event_Additional_Information__c>.class);
            List<ECM_Event_Additional_Information__c> finalList = new List<ECM_Event_Additional_Information__c>(); //List to upsert
            List<ECM_Event_Additional_Information__c> removeList = new List<ECM_Event_Additional_Information__c>(); //List to delete
            Map<String,ECM_Event_Additional_Information__c> currEvntInfoRecs = new Map<String,ECM_Event_Additional_Information__c>();
            List<String> recordTypes = recordTypeIds.split(',');
            for(ECM_Event_Additional_Information__c currEvntInfoRec : [SELECT Id,ECM_Information_Type__c,ECM_Information_Type__r.ECM_Activation_Category__c,
                                                                       ECM_Description__c,RecordTypeId
                                                                       FROM ECM_Event_Additional_Information__c 
                                                                       WHERE ECM_Contract__c =: conId 
                                                                       AND RecordTypeId IN: recordTypes])
            {
                currEvntInfoRecs.put(currEvntInfoRec.ECM_Information_Type__c+'_'+currEvntInfoRec.RecordTypeId,currEvntInfoRec);                                                   
            }
            system.debug('current Data'+ currEvntInfoRecs.values());
            //if same Key present in existing records then by User the item is modified : update, else new record is selected : insert
            for(ECM_Event_Additional_Information__c it : responseData){
                String key = it.ECM_Information_Type__c + '_' +it.RecordTypeId;
                ECM_Event_Additional_Information__c finalItem = new ECM_Event_Additional_Information__c();
                
                if(currEvntInfoRecs.containsKey(key)){
                    finalItem = currEvntInfoRecs.get(key);
                    finalItem.ECM_Description__c = it.ECM_Description__c;
                    currEvntInfoRecs.remove(key);
                }
                else{
                    finalItem = it;
                    finalItem.ECM_Contract__c = conId;
                }
                finalItem.ECM_Unique_Id__c = conId+'_'+ key;
                finalList.add(finalItem);
            }
            Try{
                //if there exists current record doesnot match with keys from user responses then it has been removed : delete
                if(!currEvntInfoRecs.isEmpty()){
                    removeList = currEvntInfoRecs.values();
                    delete removeList;
                }
                if(!finalList.isEmpty()){
                    upsert finalList ECM_Event_Additional_Information__c.ECM_Unique_Id__c;
                }
            }
            Catch(Exception ex){
                 System.debug('Class:ECM_EandS_ActivationController\nmethod:saveActivationData\nException:::' 
                              + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());
            }
            //Return upserted Data
        	List<ECM_Event_Additional_Information__c> type1 = new List<ECM_Event_Additional_Information__c>();
            List<ECM_Event_Additional_Information__c> type2 = new List<ECM_Event_Additional_Information__c>();
            for(ECM_Event_Additional_Information__c it : finalList){
                if(it.RecordTypeId == recordTypes[0]){
                    type1.add(it);
                }
                else if(it.RecordTypeId == recordTypes[1]){
                    type2.add(it);
                }
            }
            returnVal.put(recordTypes[0],type1);
            returnVal.put(recordTypes[1],type2);
        }
        return returnVal;
    }
    
    /*
    * @description : This method updates the last saved page field of contract record
    * @return : void 
    * @param : contract conRecord - instance of contract record with updated field value
    */
    @AuraEnabled
    public static void savecontract(contract conRecord){
        upsert conRecord;
    }
    
    public class activationWrapper{
        @AuraEnabled public Contract conRec {get;set;}
        @AuraEnabled public Map<String,List<Pick_Up_Options__c>> sec1_pckUpOptions {get;set;}
        @AuraEnabled public Map<String,List<Pick_Up_Options__c>> sec2_pckUpOptions {get;set;}
        @AuraEnabled public List<ECM_Event_Additional_Information__c> sec1_evntInfo {get;set;}
        @AuraEnabled public List<ECM_Event_Additional_Information__c> sec2_evntInfo {get;set;}
        @AuraEnabled public String sec1RecordTypeId {get;set;}
        @AuraEnabled public String sec2RecordTypeId {get;set;}
    }
}