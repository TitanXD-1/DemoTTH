/*
@Name: ECM_volumeInputController
@Description: This Class is used for handle server calls from ECM_VolumeInput & ECM_VolumeInput_Header.
@History:                                                          

VERSION			AUTHOR							DATE			DETAIL
1.0			Srutadeba chanda				21/04/2021		Initial Development
1.2			Chandrakanth Suram				23/04/2021		ECM-4188
1.3			Saurav Prasad					28/12/2021		ECM-4973 - POC_Group Contract Accessibility_SFDC_GLO
1.4			Anshu & Tanishq					21/06/2022		ECM-5538: Display of UoMs for RTD & Draught Cocktails on different screens/pages
1.5         Prashanth                       08/07/2022      ECM-5722: Edit/Confirm the Volume Input and Payment Summary in the Expired Status of the Contract
1.6			Saurav Prasad					28/11/2022      ECM-6373: Tool Translation_Volume Input Screen_SFDC
*/
public class ECM_volumeInputController {
    
    @AuraEnabled
    public static AccessWrapper getVolumeInputAccess(String contractId) {
        User oUser = [select id,Name,Profile.name FROM User Where id =: userInfo.getUserId()]; 
        Contract con = [SELECT Id,Status,Account.Country__c,OwnerId,Account.Person_Responsible__c,RecordTypeId FROM Contract WHERE Id =: contractId];
        String groupRecordTypeID = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
        Market_Setting__c marketSettingRec=new Market_Setting__c();
        marketSettingRec= [select id , Depletion_market__c from Market_Setting__c where Geography__c=:con.Account.Country__c];
        AccessWrapper accessWrapperObj= new AccessWrapper();                                 
        if(marketSettingRec!=null){
            accessWrapperObj.profileName=oUser.Profile.Name;
            accessWrapperObj.isActiveContract=false;
            accessWrapperObj.isNonDepletionMarket=false;
            accessWrapperObj.isCurrentUserContractOwner = true;
            //ECM-5722
            if(Label.ECM_VolumeInput_ContractStatus.contains(con.Status) ){
                accessWrapperObj.isActiveContract=true;
            }
            if(marketSettingRec.Depletion_market__c==false){
                accessWrapperObj.isNonDepletionMarket=true;
            }
            //ECM-4973
            if(con.RecordTypeId == groupRecordTypeID){
                accessWrapperObj.isCurrentUserContractOwner = (oUser.Id == con.OwnerId || 
                                                               oUser.Id == con.Account.Person_Responsible__c || 
                                                               oUser.Profile.Name == System.Label.ECM_Profile_System_Administrator);
            }
        }
        return accessWrapperObj;
        
    }  
    
    public class AccessWrapper{
        @AuraEnabled
        public boolean isActiveContract{get;set;}
        @AuraEnabled
        public boolean isNonDepletionMarket{get;set;}
        @AuraEnabled
        public string profileName{get;set;}
        @AuraEnabled
        public boolean isCurrentUserContractOwner{get;set;}
        
    }
    @AuraEnabled
    Public static Contract contractValues(String contractId){
        //ECM-6373 - added to Label in the query
        Contract con=[Select id,Name,AccountId,Account.Name,RecordType.Name,ECM_Agreement_Type__r.Volume_UoM_for_Spirits__c,
                      ECM_Agreement_Type__r.ECM_Volume_UoM_for_Beer__c,ECM_Agreement_Type__r.ECM_Volume_UoM_for_RTD__c,
                      ECM_Agreement_Type__r.ECM_Volume_UoM_for_Draught_Cocktails__c,ECM_Duration__c,ECM_Payment_Frequency__c,
                      toLabel(ECM_Payment_Frequency_type__r.ECM_Type__c)
                      from Contract where id=:contractId];////ECM-5538: Added ECM_Volume_UoM_for_RTD__c & ECM_Volume_UoM_for_Draught_Cocktails__c in the query

        return con;   
        
    }
}