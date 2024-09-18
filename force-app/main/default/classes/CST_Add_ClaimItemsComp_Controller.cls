public class CST_Add_ClaimItemsComp_Controller {
    
    @AuraEnabled
    public static WrapperData getClaimItems(String claimId){
        
        WrapperData wrapperDataVar = new WrapperData();
        
        wrapperDataVar.claimRec = [SELECT Id, CST_Status__c, CurrencyIsoCode, CST_Sales_Organisation__r.Tax_Code_Mandatory__c, CST_Sales_Organisation__r.Display_Additional_Tax__c, CST_Sales_Organisation__c,
                                   CST_Sales_Organisation__r.Additional_Tax_Display_Name__c, CST_Sales_Organisation__r.Display_The_Commitment_Form_Number__c, CreatedById FROM CST_Claim__c WHERE Id =: claimId];

        wrapperDataVar.claimItems = [SELECT Id, CST_Claim__c, Type__c, 
                                     CST_General_Ledger__c, CST_General_Ledger__r.Name,
                                     CST_Internal_Order__c, CST_Internal_Order__r.Name,
                                     CST_Net_Value__c, CST_Tax_Code__c, CST_Tax_Code__r.Name,
                                     Total_Item_value__c, User_Input_On_Additional_Tax__c, Commitment_Number__c,Additional_Tax_Pricing_Condition__c,Additional_Tax_Value__c
                                     FROM CST_Claim_Item__c 
                                     WHERE CST_Claim__c =: claimId];
        
        wrapperDataVar.plVals = getPicklistValueMap(new List<String> {'Type__c'}, 'CST_Claim_Item__c');
        
        //wrapperDataVar.isLoggedInUserClaimCreator = (UserInfo.getUserId() == wrapperDataVar.claimRec.Id ? true : false);
        
        if(wrapperDataVar.claimRec.CST_Sales_Organisation__r.Display_Additional_Tax__c==true){
            List<String> ap = new List<String>();
            List<String> ti = new List<String>();
            Map<String, List<String>> fieldMap = new Map<String, List<String>>();
            for(Pick_Up_Options__c pickUpOptn:[Select id, recordtype.name,CST_Add_Tax_Pricing_Condition__c,CST_Tax_Rate__c,Type__c, CST_Type__c, Sales_Organisation__c,CST_Default_record__c from Pick_Up_Options__c 
                                               where Sales_Organisation__c =: wrapperDataVar.claimRec.CST_Sales_Organisation__c and CST_Type__c != null and Type__c ='CST Additional Tax']){
                                                   if(pickUpOptn.CST_Type__c == 'A&P'){
                                                       ap.add(pickUpOptn.CST_Add_Tax_Pricing_Condition__c+':'+pickUpOptn.CST_Tax_Rate__c);
                                                   }else if(pickUpOptn.CST_Type__c == 'Trade Investment'){
                                                       ti.add(pickUpOptn.CST_Add_Tax_Pricing_Condition__c+':'+pickUpOptn.CST_Tax_Rate__c);
                                                   }
                                               }
            if(ap.size()>0){
                fieldMap.put('A&P', new List<String>(ap));
            }
            if(ti.size()>0){
                fieldMap.put('TI', new List<String>(ti));
            }
            wrapperDataVar.pricingCondPLs = fieldMap;
        }
        
        return wrapperDataVar;
    }
    
    @AuraEnabled
    public static string getProfileInfo()
    {
        Boolean hasPermission = FeatureManagement.checkPermission('CST_Creator');
        
        Id profileId=userinfo.getProfileId();
		String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileName.equals('CST Creator') || hasPermission)
            return 'Invalid';
        else
            return 'Valid';        
    }
    

    public class WrapperData{
        
        @AuraEnabled
        public CST_Claim__c claimRec{get; set;}
        
        @AuraEnabled
        public List<CST_Claim_Item__c> claimItems{get; set;}
        
        @AuraEnabled
        public Map<String, List<String>> plVals{get; set;}
        
        @AuraEnabled
        public Map<String, List<String>> pricingCondPLs{get; set;}
        
        //@AuraEnabled
        //public boolean isLoggedInUserClaimCreator{get; set;}
        
        public WrapperData(){
            claimRec = new CST_Claim__c();
            claimItems = new List<CST_Claim_Item__c>();
            plVals = new Map<String, List<String>>();
            pricingCondPLs = new Map<String, List<String>>();
            //isLoggedInUserClaimCreator = false;
        }
    }
    
    @AuraEnabled
    public static Map<String, List<String>> getPicklistValueMap(List<String> fieldName, String objectName){
        SObjectType type = Schema.getGlobalDescribe().get(objectName);
        
        Map<String, List<String>> fieldMap = new Map<String, List<String>>();
        List<String> l;
        
        for(String str : fieldName){
            l = new List<String>();
            for(Schema.PickListEntry s :type.getDescribe().fields.getMap().get(str).getDescribe().getPicklistValues()){
                l.add(s.getLabel());
            }
            fieldMap.put(str, new List<String>(l));
            System.debug('fieldMap '+fieldMap);
        }
        return fieldMap;
    }
    
    @AuraEnabled
    public static void saveClaimItems(String claimId, List<CST_Claim_Item__c> claimItemList){
        system.debug(claimId + 'claimId');
        system.debug(claimItemList + 'claimItemList');
        List<CST_Claim_Item__c> claimItemsToInsert = new List<CST_Claim_Item__c>();
        List<CST_Claim_Item__c> claimItemsToUpdate = new List<CST_Claim_Item__c>();
        
        
        try{
            
            for(CST_Claim_Item__c claimItemRec : claimItemList){

                if(claimItemRec.Id != null){
                    claimItemsToUpdate.add(claimItemRec);
                }
                else{
                    claimItemRec.CST_Claim__c = claimId;
                    claimItemsToInsert.add(claimItemRec);
                }
                
            }
            
            system.debug('claimItemsToInsert-->>'+claimItemsToInsert);
            system.debug('claimItemsToUpdate-->>'+claimItemsToUpdate);
            
            insert claimItemsToInsert;
            update claimItemsToUpdate;
            
        }catch(Exception e){
            throw new AuraException(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static void deleteRecord(String recIdToDelete){
        try{
            delete [SELECT Id FROM CST_Claim_Item__c WHERE Id =: recIdToDelete ];
        }catch(Exception e){
            throw new AuraException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static boolean vaidationMethod(id recordId){
        Set<id> setIds = new Set<id>();
        setIds.add(recordId);
        CST_ClaimToSAPCallout.getClaimBillingData(setIds);
        return true;
    }
    /**

* @description getUser
* @return Boolean 
* @param Id


*/
    @AuraEnabled
    public static Boolean getUser( Id claimId)
    {        
        
        List<CST_Claim__c> claimList = [SELECT Id,CST_Status__c,CST_Approver__c
                                        FROM CST_Claim__c
                                        WHERE Id =: claimId];
        
        
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if((profileName =='CST Approver') && (claimList[0].CST_Status__c=='New')) 
        {
            return True;
        }    
        else
        {
            return False; 
        }
        
    }    
}