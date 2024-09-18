/**********************************************************************
Name: EDGE_AccountKPIAchievementTriggerHelper
=======================================================================
Req: 
ES20-8587 : Unique ID in Object creation Activation_KPI_Achievement_US1c_SFDC_Operator View
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Juned Khan	 15/09/2020		  Initial Development
**********************************************************************/
public class EDGE_AccountKPIAchievementTriggerHelper {
    
     /*******************************************************************
Method  : populateUniqueIdField
Purpose : This method is used to populate Unique Id field in Account KPI Achievement
********************************************************************/ 
    
    public static void populateUniqueIdField(List<Account_KPI_Achievement__c> newItems){
        string unique = null;
        for(Account_KPI_Achievement__c accKpiAch : newItems){
            If(accKpiAch.KPI_Type__c != null){
                unique = accKpiAch.Account__c+ '_' + accKpiAch.KPI_Type__c;
                If(accKpiAch.Activation_Survey_KPI__c != null){
                    unique += '_'+ accKpiAch.Activation_Survey_KPI__c;
                }
                accKpiAch.Unique_Id__c= unique;
            }
            }
        }
}