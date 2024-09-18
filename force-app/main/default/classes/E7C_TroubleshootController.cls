public without sharing class E7C_TroubleshootController {
	
    @AuraEnabled
    public static TroubleshootWrapper getTroubleshootData(){
        List<E7C_Troubleshoot_Content__c> tsContentList = [SELECT E7C_Action__c, E7C_Cause__c, toLabel(E7C_Criteria__c), E7C_Troubleshoot__c, toLabel(E7C_Type__c) FROM E7C_Troubleshoot_Content__c];
    	TroubleshootWrapper tWrap = new TroubleshootWrapper();
        Set<String> criteriaSet = new Set<String>();
        Set<String> typeSet = new Set<String>();
        Map<String, String> crTypeMap = new Map<String, String>();
        Map<String, List<E7C_Troubleshoot_Content__c>> typeTcListMap = new Map<String, List<E7C_Troubleshoot_Content__c>>();
        List<E7C_Troubleshoot_Content__c> appendTcList = new List<E7C_Troubleshoot_Content__c>();
        String typeStr;
        
        for(E7C_Troubleshoot_Content__c tc : tsContentList)
        {
            if(tc.E7C_Criteria__c != '')
            {
                criteriaSet.addAll(tc.E7C_Criteria__c.split(';'));
                typeSet.addAll(tc.E7C_Type__c.split(';'));
                for(String typ : tc.E7C_Type__c.split(';'))
                {
                    System.debug('typ:: '+typ);
                    if(!typeTcListMap.containsKey(typ))
                    {
                        typeTcListMap.put(typ, new List<E7C_Troubleshoot_Content__c>());
                        typeTcListMap.get(typ).add(tc);
                    }else{
                        appendTcList = new List<E7C_Troubleshoot_Content__c>();
                        appendTcList.addAll(typeTcListMap.get(typ));
                        appendTcList.add(tc);
                        typeTcListMap.put(typ, appendTcList);
                    }
                    System.debug('typeTcListMap:: '+typeTcListMap.get(typ));
                }
                
                for(String cr: tc.E7C_Criteria__c.split(';'))
                {
                    if(crTypeMap.containsKey(cr))
                    {
                        typeStr = crTypeMap.get(cr)+';'+tc.E7C_Type__c;
                        crTypeMap.put(cr, typeStr);
                    }else{
                        crTypeMap.put(cr, tc.E7C_Type__c);
                    }
                }
            }
        }
        
        Map<String, List<String>> crTypeListMap = new Map<String, List<String>>();
        for(String cr: crTypeMap.keySet())
        {
            crTypeListMap.put(cr, new List<String>(new Set<String>(crTypeMap.get(cr).split(';'))));
        }
        
        System.debug('CriteriaSet:: '+criteriaSet);
        System.debug('typeTcListMap:: '+typeTcListMap);
        tWrap.criteriaList = new List<String>();
        tWrap.criteriaList.addAll(criteriaSet);
        tWrap.typeList = new List<String>();
        tWrap.typeList.addAll(typeSet);
        tWrap.crTypeListMap = new Map<String, List<String>>();
        tWrap.crTypeListMap.putAll(crTypeListMap);
        tWrap.typeTcListMap = new Map<String, List<E7C_Troubleshoot_Content__c>>();
        tWrap.typeTcListMap.putAll(typeTcListMap);
        return tWrap;
    }
    
    public class TroubleshootWrapper{
        @AuraEnabled
        public List<String> criteriaList {get; set;}
        @AuraEnabled
        public List<String> typeList {get; set;}
        @auraEnabled
        public Map<String, List<String>> crTypeListMap {get; set;}
        @AuraEnabled
        public Map<String, List<E7C_Troubleshoot_Content__c>> typeTcListMap {get; set;}
    }
}