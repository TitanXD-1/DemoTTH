/**
 * @name D1_SFToSAPConnectionUtility
 * @purpose Utility Class for SAP Connection
 * @history                                                                                                                       
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Dipanjan Das     16/12/2020         NCP-1359
**/

public with sharing class D1_SFToSAPConnectionUtility {
    
    /**
     * @description getInterfaceEndPoint
     * @param interfaceName 
     * @return  `string`
     */    
    public static string getInterfaceEndPoint(string interfaceName){
        List<D1_Commerce_SAP_Setting__mdt> sapSettings = [SELECT Id, DeveloperName, Value__c 
                                                          FROM D1_Commerce_SAP_Setting__mdt
                                                          WHERE DeveloperName =:interfaceName LIMIT 1];
        if(sapSettings != null && sapSettings.size() > 0){
            return sapSettings[0].Value__c;
        }else {
            return null;
        }
        
    }
}