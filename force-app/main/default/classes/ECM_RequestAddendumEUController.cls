/*
Name: ECM_RequestAddendumEUController
History                                                                                                                  
VERSION			AUTHOR					DATE				DETAIL
1.0				Pratik				07/07/2022 			Intial Development ECM-5786
2.0			Saurav Prasad			23/09/2022			ECM-6061 : Create New Version for Active Contract_Addendum_SFDC_EU
2.1         Anand Uppalapati        28/09/2022          ECM-6063  Child Contract record creation for Addendum_SFDC_EU
*/ 
public class ECM_RequestAddendumEUController {
    //Below funtion is using to get/update Contract
    @AuraEnabled
    public static contract updateLastSavedPageCon(String contractId){
        system.debug('contractId_test'+contractId);
        Contract conObj=[Select Id,Name,Status,account.Country__c,account.Country_Code__c,ECM_Last_saved_page__c from contract where id=:contractId];
        conObj.ECM_Last_saved_page__c = 2;
        Update conObj;
        return conObj;
    }
    
    //Below funtion is using to get all the data from BE and sent to FE
    @AuraEnabled
    public static AddendumWrapper getContract(String contractId){
        AddendumWrapper wrap = new AddendumWrapper();
        List<String> optionToCreateAddendum = new List<String>();
        Contract conObj=[SELECT Id,Name,Status,OwnerId,ECM_Last_saved_page__c,ContractNumber,account.Country__c,account.Country_Code__c FROM contract WHERE Id=:contractId];
        List<ECM_Technical_Market_Setting__mdt> addendumFieldValue =[SELECT Id, ECM_Contract_Status_for_Addendum__c, ECM_Options_to_Create_Addendum__c FROM ECM_Technical_Market_Setting__mdt WHERE ECM_Country__c =:conObj.Account.Country_Code__c];
        if(!addendumFieldValue.isEmpty()){
            optionToCreateAddendum=addendumFieldValue[0].ECM_Options_to_Create_Addendum__c.split(',');
        }
        system.debug('optionToCreateAddendum'+optionToCreateAddendum);
        /*if(!optionToCreateAddendum.isEmpty()){
for(String labelName: optionToCreateAddendum){
ObjValues objval = new ObjValues();
objval.label = getLabelValue(labelName);
objval.value = getLabelValue(labelName);
objvalList.add(objval);
}
}*/
        User currentuserInfo=[SELECT Id,name,profileid,profile.Name FROM user WHERE Id=:Userinfo.getUserId() Limit 1];
        wrap.userinfo=currentuserInfo;
        wrap.conObj = conObj;
        wrap.addendumField = addendumFieldValue;
        wrap.Options.addAll(optionToCreateAddendum);
        system.debug('wrap'+wrap);
        return wrap;
        
    }
    
    // To get the user country
    @AuraEnabled
    public static String getUserCountry(){
        User us = [SELECT Id,Available_Countries__c,Default_Country__c FROM User WHERE Id=:Userinfo.getUserId() ];
        String userCountry ;
        if(us.Available_Countries__c != null){
            if(us.Available_Countries__c.contains(';')) {				  
                userCountry = us.Default_Country__c;
            }else{
                userCountry = us.Available_Countries__c;
            }
        }
        return userCountry;
        
    }
    // To check Addendum record size
    @AuraEnabled
    public static Boolean checkAddendumRecord(String contractId,String adStatus){
        //ECM-6061
        String contractChangeStatusRestriction = System.Label.ECM_Addendum_Change_Contract_Status_Restriction;
        Boolean containsAmended = false;
        Boolean addendumError = false;
        for(Contract con:[SELECT Id,Status,ECM_Amended__c FROM Contract 
                          where ECM_Parent_Contract__c =: contractId]){
            if(con.ECM_Amended__c && contractChangeStatusRestriction.containsIgnoreCase(con.Status)){
                containsAmended = true;
            }
        }
        //ECM-6299
        for(ECM_Addendum__c addendum:
            [SELECT Id,ECM_Status__c,ECM_Contract__c,ECM_Contract__r.ECM_Parent_Contract__c,
             ECM_Contract__r.ECM_Parent_Contract__r.Status
             FROM ECM_Addendum__c WHERE ECM_Contract__c=:contractId ]){
                 if(adStatus.containsIgnoreCase(addendum.ECM_Status__c) || 
                    (addendum.ECM_Contract__r.ECM_Parent_Contract__c != NULL && 
                     contractChangeStatusRestriction.split(';')[0].containsIgnoreCase(addendum.ECM_Contract__r.ECM_Parent_Contract__r.Status))){
                        addendumError= true;
                        //return true;
                    } 
             }
        if(containsAmended || addendumError){
            return true;
        }else{
            return false;
        }        
    }
    //inserting the Addendum record
    @AuraEnabled
    public static void submitAddendumRequestEU(String contractId,String contractNumber,String addendumType){        
        ECM_Addendum__c addendum=new ECM_Addendum__c();
        addendum.Name = contractNumber+'_'+addendumType+'_'+ System.today().format();
        addendum.ECM_Status__c ='Draft';
        addendum.ECM_Addendum_Type__c= addendumType;
        addendum.ECM_Contract__c=contractId;
        insert addendum;
    }
    
    //Below wrapper is using to get Data from BE
    public class AddendumWrapper{
        @AuraEnabled public  Contract conObj {get;set;}
        @AuraEnabled public List<ECM_Technical_Market_Setting__mdt>  addendumField {get;set;}
        @AuraEnabled public List<String> Options {get; set;}
        @AuraEnabled public User userinfo{get;set;}
        public AddendumWrapper(){
            conObj= new Contract();
            addendumField= new List<ECM_Technical_Market_Setting__mdt>();
            Options= new List<String>();
            userinfo = new User();
        }  
    }
  /**
	* @description : handleChangeContract - This methods used to create child contract and related items when user selects 
                     Change Contract option while requesting for addendum.
	* @return : String
	* @param : Parentcontract Id,Child Contract,String 
	*/ 
    @AuraEnabled
    public static Contract handleChangeContract(Id parentConId, Contract childContract){//ECM-6063
        Contract insertedContractRec = new Contract();
        String reasonForRecall ='';
        if(parentConId != null && childContract !=null){
            insertedContractRec = ECM_ContractRecallCtrl.confirmRecall(parentConId,childContract,reasonForRecall);
            return insertedContractRec;
        }else {
            return null;
        }
    }
    
}