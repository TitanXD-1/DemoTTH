public without sharing class E7C_Utility {
    
    public static Id getSurveyId(String userMarket){
        User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String persona = 'Mystery Shopper';
        if(u.ContactId != null)
        {
            Contact c = [Select E7C_Persona__c from Contact where Id=:u.ContactId];
        }
        
        return [SELECT Id FROM Survey__c 
                WHERE IsActive__c = true AND Country__r.Name = :userMarket AND E7Cs_Persona__c = :persona].Id;
    }
    
    public static Id getSurveyResponseId(String surveyId){
        List<E7C_Survey_Response__c> surResList = [SELECT Id, E7C_Status__c, OwnerId FROM E7C_Survey_Response__c 
                                         WHERE E7C_Status__c = 'Draft' AND Survey__c =: surveyId AND OwnerId =: UserInfo.getUserId() LIMIT 1];
        System.debug('surResList>>>'+surResList);
        if(surResList.size() > 0){
            return surResList[0].Id;   
        }else{
            return null;
        } 
    }
    
    public static Id getCompletedSurveyResponseId(String surveyId){
        List<E7C_Survey_Response__c> surResList = [SELECT Id, E7C_Status__c, OwnerId FROM E7C_Survey_Response__c 
                                         WHERE E7C_Status__c = 'Completed' AND Survey__c =: surveyId AND OwnerId =: UserInfo.getUserId() ORDER BY LastModifiedDate DESC ];
        System.debug('surResList>>>'+surResList);
        if(surResList.size() > 0){
            return surResList[0].Id;   
        }else{
            return null;
        } 
    }
    
    public static String createSurveyResponseRecord(String surveyId, String outlet, String status, String notes, String outletName, String outletAddress, String outletLat, String outletLong){
        E7C_Survey_Response__c srRec = new E7C_Survey_Response__c();
        
        
        srRec.Survey__c = surveyId;
        srRec.E7C_Survey_Outlet__c = outlet;
        srRec.E7C_Outlet_Name__c = outletName;
        srRec.E7C_Outlet_Address__c = outletAddress;
        srRec.E7C_Outlet_Geometry__Latitude__s = Decimal.valueOf(outletLat);
        srRec.E7C_Outlet_Geometry__Longitude__s = Decimal.valueOf(outletLong);
        srRec.E7C_Status__c = status;
        srRec.E7C_Survey_Response_Date__c = Datetime.now();
        srRec.E7C_Notes__c = notes;
        srRec.OwnerId = UserInfo.getUserId();
        insert srRec;
        return srRec.Id;
    }
    
    
    public static String updateSurveyResponseRecord(String surveyResponseId, String surveyId, String outlet, String status, String notes, String outletName, String outletAddress, String outletLat, String outletLong){
        E7C_Survey_Response__c srRec = [SELECT Id, E7C_Survey_Outlet__c, E7C_Status__c,
                                        E7C_Survey_Response_Date__c, E7C_Notes__c, OwnerId 
                                        FROM E7C_Survey_Response__c 
                                        WHERE Id =: surveyResponseId];
        
        srRec.Survey__c = surveyId;
        srRec.E7C_Survey_Outlet__c = outlet;
        srRec.E7C_Outlet_Name__c = outletName;
        srRec.E7C_Outlet_Address__c = outletAddress;
        srRec.E7C_Outlet_Geometry__Latitude__s = Decimal.valueOf(outletLat);
        srRec.E7C_Outlet_Geometry__Longitude__s = Decimal.valueOf(outletLong);
        srRec.E7C_Status__c = status;
        srRec.E7C_Survey_Response_Date__c = Datetime.now();
        srRec.E7C_Notes__c = notes;
        srRec.OwnerId = UserInfo.getUserId();
        update srRec;
        return srRec.Id;
    }
}