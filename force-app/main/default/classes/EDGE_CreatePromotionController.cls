public with sharing class EDGE_CreatePromotionController {
    
    @AuraEnabled
    public static List<Account> getAccounts(){
        List<Account> accList = new List<Account>();
        
        accList = [SELECT Id, Name, RecordType.Name FROM Account WHERE 
                   (RecordType.Name = 'Distributor/Wholesaler' OR RecordType.Name = 'Owner/Operator') 
                   ORDER By RecordType.Name, Name];
        return accList;
    }
    
    @AuraEnabled
    public static List<string> insertAccPromotion(List<Account_Promotion__c> accPromotionList){
        Map<Id, string> errorMap = new Map<Id, string>();
        List<string> errList = new List<string>();
        try{
            if(accPromotionList.size()>0){
                Database.SaveResult[] saveResultList = Database.insert(accPromotionList, true);
                Integer count = 0;
                for (Database.SaveResult saveResult : saveResultList) {
                    system.debug('@@saveResult' + saveResult);
                    if (!saveResult.isSuccess()) {
                        errorMap.put(accPromotionList[count].Distributor_Owner__c, saveResult.getErrors()[0].getMessage());
                    }
                    count++;
                }
                
                //Create Error List
                if(errorMap.size()>0){
                    for(Account acc : [SELECT Id, Name from Account WHERE Id IN :errorMap.keyset()]){
                        string errMsg = acc.Name + ' : ' + errorMap.get(acc.Id);
                        errList.add(errMsg);
                    }
                }
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        
        return errList;
    }
}