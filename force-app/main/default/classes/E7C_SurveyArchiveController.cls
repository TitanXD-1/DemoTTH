public class E7C_SurveyArchiveController {
    @AuraEnabled
    public static E7C_SurveyArchiveController.E7C_ArchiveWrapper getAllSurveyResponse(String storeName, String surDate, String result)
    {
        Date dt;
        if(surDate != null)
        	dt = Date.valueOf(surDate);
        
        system.debug('sur-->>'+surDate);
        system.debug('dt-->>'+dt);
        
        E7C_SurveyArchiveController.E7C_ArchiveWrapper res = new E7C_SurveyArchiveController.E7C_ArchiveWrapper();
        List<E7C_Survey_Response__c> srList = new List<E7C_Survey_Response__c>();
        String whereClause = ' CreatedById= \''+UserInfo.getUserId()+'\' AND (E7C_Status__c = \'Completed\' OR E7C_Status__c = \'Submitted\') ';
        if(storeName != '')
        {
            whereClause = whereClause +''+' AND E7C_Outlet_Name__c LIKE \'%'+storeName+'%\' ';
        }
        if(surDate != null)
        {
           // whereClause = whereClause +' AND E7C_Survey_Response_Date__c > '+dt+' AND E7C_Survey_Response_Date__c < '+dt.addDays(1) ;
        }
        if(result != '' && result != 'All')
        {
            whereClause = whereClause +' AND E7C_Survey_Result__c =\''+result+'\' ';
        }
        String query = 'SELECT Id, E7C_Outlet_Name__c, E7C_Survey_Result__c, E7C_Survey_Response_Date__c FROM E7C_Survey_Response__c WHERE '+whereClause+' ORDER BY E7C_Survey_Response_Date__c DESC';
        System.debug('whereClause:: '+whereClause);
        System.debug('Query:: '+query);
        
        List<E7C_Survey_Response__c> fileteredSrList = new List<E7C_Survey_Response__c>();
        
        fileteredSrList = Database.query(query);
        
        system.debug('fileteredSrList-->>'+fileteredSrList.size());
        
        if(surDate != null){
            for(E7C_Survey_Response__c srRec : fileteredSrList){
                if(srRec.E7C_Survey_Response_Date__c > dt && srRec.E7C_Survey_Response_Date__c < dt.addDays(1)){
                    srList.add(srRec);
                }
            }
        }else{
            srList.addAll(fileteredSrList);
        }
        system.debug('srList-->>'+srList.size());
        
        Map<String, List<E7C_Survey_Response__c>> monthResponseMap = new Map<String, List<E7C_Survey_Response__c>>();
        List<E7C_Survey_Response__c> appendList = new List<E7C_Survey_Response__c>();
        Set<String> monthSet = new Set<String>();
        for(E7C_Survey_Response__c sr: srList)
        {
            monthSet.add(sr.E7C_Survey_Response_Date__c.format('MMMM')+' '+sr.E7C_Survey_Response_Date__c.year());
            if(monthResponseMap.containsKey(sr.E7C_Survey_Response_Date__c.format('MMMM')+' '+sr.E7C_Survey_Response_Date__c.year()))
            {
                appendList = new List<E7C_Survey_Response__c>();
                appendList.addAll(monthResponseMap.get(sr.E7C_Survey_Response_Date__c.format('MMMM')+' '+sr.E7C_Survey_Response_Date__c.year()));
                appendList.add(sr);
                monthResponseMap.put(sr.E7C_Survey_Response_Date__c.format('MMMM')+' '+sr.E7C_Survey_Response_Date__c.year(), appendList);                
            }else{
                monthResponseMap.put(sr.E7C_Survey_Response_Date__c.format('MMMM')+' '+sr.E7C_Survey_Response_Date__c.year(), new List<E7C_Survey_Response__c>());
                monthResponseMap.get(sr.E7C_Survey_Response_Date__c.format('MMMM')+' '+sr.E7C_Survey_Response_Date__c.year()).add(sr);
            }
        }
        res.monthResponseMap = new Map<String, List<E7C_Survey_Response__c>>(monthResponseMap);
        System.debug('monthList:: '+monthSet);
        res.monthList = new List<String>(monthSet);
        System.debug('res.monthResponseMap:: '+res.monthResponseMap);
        if(res.monthResponseMap.size() > 0)
            return res;
        else
            return null;
    }
    
    
    
    public class E7C_ArchiveWrapper {
        @AuraEnabled
        public Map<String, List<E7C_Survey_Response__c>> monthResponseMap {get; set;}
        @AuraEnabled
        public List<String> monthList {get; set;}
    }
    
}