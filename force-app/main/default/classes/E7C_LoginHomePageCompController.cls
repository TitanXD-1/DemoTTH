public without sharing class E7C_LoginHomePageCompController {
    
    @AuraEnabled
    public static wrapDetails getLastCompletedSurvey(){
        
        wrapDetails wrapDetailsVar = new wrapDetails();
        
        User loggedInUserRec = [SELECT Id, LastPasswordChangeDate FROM User WHERE Id=: UserInfo.getUserId()];
        wrapDetailsVar.daysToReset = 90-(Date.valueOf(loggedInUserRec.LastPasswordChangeDate).daysBetween(Date.today()));
                
        List<E7C_Survey_Response__c> srList = [SELECT Id, E7C_Survey_Response_Date__c FROM E7C_Survey_Response__c
                                               WHERE OwnerId =: UserInfo.getUserId()
                                               AND E7C_Status__c = 'Submitted'
                                               ORDER BY E7C_Survey_Response_Date__c DESC];
        if(srList.size() > 0){
            wrapDetailsVar.day = String.valueOf(srList[0].E7C_Survey_Response_Date__c.day());
            wrapDetailsVar.month = String.valueOf(srList[0].E7C_Survey_Response_Date__c.format('MMMMM'));
            wrapDetailsVar.year = String.valueOf(srList[0].E7C_Survey_Response_Date__c.year());
            wrapDetailsVar.formattedTime = String.valueOf(srList[0].E7C_Survey_Response_Date__c.format('h:mm a'));
        }
        
        
        return wrapDetailsVar;
    }
    
    public class wrapDetails {
        @AuraEnabled public Integer daysToReset {get; set;}
        @AuraEnabled public String day {get; set;}
        @AuraEnabled public String month {get; set;}
        @AuraEnabled public String year {get; set;}
        @AuraEnabled public String formattedTime {get; set;}
        
    }
    
    
}