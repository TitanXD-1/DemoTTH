/*
* @Name: ECM_ES_ParityAndTicketingController
* @description: This Class is for handling E&S contract Parity and Ticket Screen server calls 
* @History 

VERSION    AUTHOR                DATE					DETAIL
2.0       Priya Soni           15/09/2022         Development for ECM-5753: modified methods getParityTicketData,getPickUpOptionType

*/
public class ECM_ES_ParityAndTicketingController {
    public static Id getRecordTypeIdForObject(String objName, String recTypeName) {
        return ((SObject)Type.forName(objName).newInstance())
            .getSObjectType()
            .getDescribe()
            .getRecordTypeInfosByName()
            .get(recTypeName)
            .getRecordTypeId();
    }
    
    
    /*
    * Name : getPickUpOptionType
    * @description : Method to fetch PickUp Option Record of given RecordType
    * @return : list<Pick_Up_Options__c>
    * @param : String Agreement Id, String - API Name of Object, String - RecordType Name  
    */  
    @AuraEnabled
    public static List<List<Pick_Up_Options__c>> getPickUpOptionType(String agreementId, String objectName, List<String> recordType){
        List<List<Pick_Up_Options__c>>  returnVal = new List<List<Pick_Up_Options__c>>();        
        Id parityRecordTypeId = getRecordTypeIdForObject(objectName, recordType[0]);
        Id ticketRecordTypeId = getRecordTypeIdForObject(objectName, recordType[1]);
        
        List<ECM_Event_Additional_Info_Agreement__c> ecmEventAdditionalInfoAgreement = new List<ECM_Event_Additional_Info_Agreement__c>();
        List<Pick_Up_Options__c> ecmParityPickUpOptionTypeReturn  = new List<Pick_Up_Options__c>();
        List<Pick_Up_Options__c> ecmTicketPickUpOptionTypeReturn  = new List<Pick_Up_Options__c>();
        
        for(ECM_Event_Additional_Info_Agreement__c option : [SELECT Id,ECM_Event_Additional_Pickup_Option__c,ECM_Event_Additional_Pickup_Option__r.Name,
                                                             ECM_Event_Additional_Pickup_Option__r.Description__c,ECM_Record_Type__c  
                                                             FROM ECM_Event_Additional_Info_Agreement__c 
                                                             WHERE ECM_Agreement_Type__c =:agreementId AND ECM_Record_Type__c IN :recordType 
                                                             AND ECM_Event_Additional_Pickup_Option__r.Status__c='Active'
                                                             ORDER BY CreatedDate DESC]) {
            option.ECM_Event_Additional_Pickup_Option__r.Name = option.ECM_Event_Additional_Pickup_Option__r.Name.substringBefore('[').trim();
            Pick_Up_Options__c pkOption = new Pick_Up_Options__c(Id=option.ECM_Event_Additional_Pickup_Option__c);
            pkOption.name = option.ECM_Event_Additional_Pickup_Option__r.Name;
            pkOption.Description__c = option.ECM_Event_Additional_Pickup_Option__r.Description__c ;
            if (option.ECM_Record_Type__c == recordType[0]){
                pkOption.RecordTypeId = parityRecordTypeId;
                ecmParityPickUpOptionTypeReturn .add(pkOption);
            }else{
                pkOption.RecordTypeId = ticketRecordTypeId;
                ecmTicketPickUpOptionTypeReturn .add(pkOption);
            }
        }
        
        returnVal.add(ecmParityPickUpOptionTypeReturn );
        returnVal.add(ecmTicketPickUpOptionTypeReturn );
        return returnVal;      
    }
    
    
    
    @AuraEnabled
    public static void savecontract(contract conRecord){
        upsert conRecord;
    }
    
    public class activationWrapper{
        @AuraEnabled public Contract conRec {get;set;}
        @AuraEnabled public List<Pick_Up_Options__c> sec1_pckUpOptions {get;set;}
        @AuraEnabled public List<Pick_Up_Options__c> sec2_pckUpOptions {get;set;}
        @AuraEnabled public List<ECM_Event_Additional_Information__c> sec1_evntInfo {get;set;}
        @AuraEnabled public List<ECM_Event_Additional_Information__c> sec2_evntInfo {get;set;}
        @AuraEnabled public String sec1RecordTypeId;
        @AuraEnabled public String sec2RecordTypeId;
    }
    
    /*
    * @description : This method fetches pickup option records and Event Additional information records along with their recordTypeIds available for a contract
    * @return : activationWrapper 
    * @param : String conId - contract Id, String recTypeNames - String of record Type Names appended by comma
    */
    @AuraEnabled
    public static activationWrapper getParityTicketData(String conId, String recTypeNames){
        List<String> recordType = Label.ECM_ParityScreenRecordTypes.split(',');
        List<Pick_Up_Options__c> pickUpOptionList = new List<Pick_Up_Options__c>();
        List<ECM_Event_Additional_Information__c> activationType1_evntInfo = new List<ECM_Event_Additional_Information__c>();
        List<ECM_Event_Additional_Information__c> activationType2_evntInfo = new List<ECM_Event_Additional_Information__c>();
        Map<String,Id> recordTypeIds = new Map<String,Id>();
        Map<String,Id> recordTypeIds_evntInfo = new Map<String,Id>();
        
        //Fetch Record Type Ids for Objects PickUp Option & Event Additional Information
        List<String> recTypes = recTypeNames.split(',');
        for(String recType : recTypes){
            recordTypeIds.put(recType,
                              ECM_TaxCodeDropdownComponentController.getRecordTypeIdForObject('Pick_Up_Options__c',recType));
            recordTypeIds_evntInfo.put(recType,
                                       ECM_TaxCodeDropdownComponentController.getRecordTypeIdForObject('ECM_Event_Additional_Information__c',recType));
        }
        System.debug('PickUp Option Record Types '+recordTypeIds);
        System.debug('Event Additional Info Record Types '+recordTypeIds_evntInfo);
        
        //Query Contract Fields for Activation Screen and related Event Additional Info Records & Split them in Lists by recordTypes
        Contract conRec = [SELECT Id,ContractNumber,ECM_Agreement_Type__c,Status,
                           (SELECT Id,ECM_Information_Type__c,ECM_Information_Type__r.Name,
                            ECM_Information_Type__r.ECM_Activation_Category__r.Name,
                            ECM_Description__c,RecordTypeId,ECM_Quantity__c,Name
                            FROM Event_Additional_Informations__r 
                            WHERE ECM_Information_Type__c!= NULL
                            AND RecordTypeId IN: recordTypeIds_evntInfo.values())
                           FROM Contract WHERE Id =: conId];
        for(ECM_Event_Additional_Information__c evntInfo : conRec.Event_Additional_Informations__r){
            evntInfo.ECM_Information_Type__r.Name = evntInfo.ECM_Information_Type__r.Name.substringBefore('[');
            if(recordTypeIds_evntInfo.containsKey(recTypes[0]) && evntInfo.RecordTypeId == recordTypeIds_evntInfo.get(recTypes[0])){//Parity
                activationType1_evntInfo.add(evntInfo);
            }
            else if(recordTypeIds_evntInfo.containsKey(recTypes[1]) && evntInfo.RecordTypeId == recordTypeIds_evntInfo.get(recTypes[1])){//Ticketing
                activationType2_evntInfo.add(evntInfo);
            }
        }
        
        //Wrap up all queried items and return
        activationWrapper returnVal = new activationWrapper();
        returnVal.conRec = conRec;
        List<List<Pick_Up_Options__c>> returnPickUpVal = getPickUpOptionType(conRec.ECM_Agreement_Type__c, 'Pick_Up_Options__c', recordType);
        returnVal.sec1_pckUpOptions = returnPickUpVal[0];
        returnVal.sec2_pckUpOptions = returnPickUpVal[1];
        returnVal.sec1_evntInfo = activationType1_evntInfo;
        returnVal.sec2_evntInfo = activationType2_evntInfo;
        returnVal.sec1RecordTypeId = recordTypeIds_evntInfo.containsKey(recTypes[0])?recordTypeIds_evntInfo.get(recTypes[0]): '';
        returnVal.sec2RecordTypeId = recordTypeIds_evntInfo.containsKey(recTypes[0])?recordTypeIds_evntInfo.get(recTypes[1]): '';
        return returnVal;
        
    }
    
    
    @AuraEnabled
    public static Map<String,List<ECM_Event_Additional_Information__c>> savePTData(String conId, String dataToUpsert, String recordTypeIds){
        Map<String,List<ECM_Event_Additional_Information__c>> returnVal = new Map<String,List<ECM_Event_Additional_Information__c>>(); 
        
        if(!String.isBlank(dataToUpsert)){
            List<ECM_Event_Additional_Information__c> responseData = (List<ECM_Event_Additional_Information__c>)JSON.deserialize(dataToUpsert, List<ECM_Event_Additional_Information__c>.class);
            List<ECM_Event_Additional_Information__c> finalList = new List<ECM_Event_Additional_Information__c>(); //List to upsert
            List<ECM_Event_Additional_Information__c> removeList = new List<ECM_Event_Additional_Information__c>(); //List to delete
            Map<String,ECM_Event_Additional_Information__c> currEvntInfoRecs = new Map<String,ECM_Event_Additional_Information__c>();
            List<String> recordTypes = recordTypeIds.split(',');
            List<ECM_Event_Additional_Information__c> type1 = new List<ECM_Event_Additional_Information__c>();
            List<ECM_Event_Additional_Information__c> type2 = new List<ECM_Event_Additional_Information__c>();
            for(ECM_Event_Additional_Information__c currEvntInfoRec : [SELECT Id,ECM_Information_Type__c,ECM_Quantity__c,
                                                                       ECM_Description__c,RecordTypeId
                                                                       FROM ECM_Event_Additional_Information__c 
                                                                       WHERE ECM_Contract__c =: conId 
                                                                       AND RecordTypeId IN: recordTypes])
            {
                currEvntInfoRecs.put(currEvntInfoRec.ECM_Information_Type__c+'_'+currEvntInfoRec.RecordTypeId,currEvntInfoRec);                                                   
            }
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
                System.debug('Class:Exception:::' 
                             + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());
            }
            //Return upserted Data
            
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
    
}