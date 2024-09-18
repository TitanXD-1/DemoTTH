/*

*   @Class Name: ECM_AnPScreenNavigationController 

*   @Author                  Version       Date           Detail
    Rajarshi Lahiri		     1.0		   25/07/2023	  142189
*/
public with sharing class ECM_AnPScreenNavigationController {
    public static Map<String, String> labelToTranslatedStrMap = new Map<String, String>();
    @AuraEnabled
    public static String validateContract(Id conId){

        String message;
        String language=UserInfo.getLanguage();
        labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'ECM_AnP_Screen_Error','ECM_AnP_Screen_Error_Active_Expired','ECM_AnP_Screen_Records_Not_Created_Error'},language);
        
        Contract con=[Select ECM_Agreement_Type__r.ECM_Enable_A_P_screen__c, Status,ECM_A_P_Records_Created__c from Contract WHERE Id=:conId WITH SECURITY_ENFORCED LIMIT 1 ];
        if(con.ECM_Agreement_Type__c != null){
            if(!con.ECM_Agreement_Type__r.ECM_Enable_A_P_screen__c){
                message=labelToTranslatedStrMap.get('ECM_AnP_Screen_Error');
            }
            else if(con.ECM_Agreement_Type__r.ECM_Enable_A_P_screen__c && !(con.Status=='Expired' || con.Status=='Active')){
                message=labelToTranslatedStrMap.get('ECM_AnP_Screen_Error_Active_Expired');
            }
            else{
                if(!con.ECM_A_P_Records_Created__c){
                    message=labelToTranslatedStrMap.get('ECM_AnP_Screen_Records_Not_Created_Error');
                }
                else{
                    message='Override';
                }
            }
        }

        System.debug(LoggingLevel.DEBUG,'Message'+message);

        return message;
    }
    
}