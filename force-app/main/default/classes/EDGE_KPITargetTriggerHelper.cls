/**
*@	Name: EDGE_KPITargetTriggerHelper
*@	Req: 
*@	ES20-1268 - Share of Shelf - Target object look up

* @History 
                                                        
* @VERSION   AUTHOR            	DATE              	DETAIL
* 1.0        Dipanjan Das		15/05/2019       	Initial Development 
* 2.0        Preyanka Ghosh		19/02/2020		 	ES20-6944 : SFDC SOS Target update
* 3.0        Shivam/Rajarshi	05/02/2022	     	ES20-14005,ES20-13960
* 4.0		 Raghavendra		20/09/2023		  	145738
* 5.0        Joshraj Sen        04/05/2024          153343 When MS is Off Trade and the target of On Trade KPI Target Record is changed, the Target of the Off-Trade Outlet KPI Achievment is made blank
**/

public with sharing class EDGE_KPITargetTriggerHelper {
    
/**
*@	Method  : populateOutletKPIs
*@	Purpose : This methods used to calcluate outlet level SOS KPI Targets

**/  

    public static void populateOutletSOSKPIs(List<KPIs_Target__c> newItems){
        
        Set<Id> territoryIdSet = new Set<Id>();
        List<String> categories = new List<String>();
        List<Account> outletList = new List<Account>();
        List<Outlet_KPI_Achievement__c> lstOutletKPIUpdate = new List<Outlet_KPI_Achievement__c>();
        Set<String> kpiTargetSegments=new Set<String>();
        Set<String> kpiTargetSubSegments=new Set<String>();
        for(KPIs_Target__c kpiTarget : newItems){
            territoryIdSet.add(kpiTarget.Territory__c);          
            categories.add(kpiTarget.Category__c);
            kpiTargetSegments.add(kpiTarget.Segment__c ?? '');//Joshraj Sen 
            kpiTargetSubSegments.add(kpiTarget.Sub_Segment__c ?? '');  
        }       
        //List<KPIs_Target__c> kpiTargetsFromTerritory =new List<KPIs_Target__c>();
        if(territoryIdSet != null && territoryIdSet.size() > 0 && Schema.sObjectType.Account.isAccessible()){
            //ES20-14005,ES20-13960
            outletList = [SELECT Id, Primary_Sales_Territory__c, Country__c, Global_Channel__c, Global_Segment__c,Global_Sub_Segment__c FROM Account WHERE Primary_Sales_Territory__c IN :territoryIdSet AND Status__c = 'Active'];//145738 - added Country__c and Global_Channel__c           
        	if(kpiTargetSubSegments!=null && kpiTargetSubSegments.size()>0)
            {
                 lstOutletKPIUpdate = [SELECT Id, Unique_Id__c, Category__c, KPI_Type__c, Target__c, Outlet__c, Target_Override_Not_Allowed__c FROM Outlet_KPI_Achievement__c WHERE Outlet__r.Primary_Sales_Territory__c IN :territoryIdSet AND KPI_Type__c = 'SoS' AND Category__c IN :categories AND Outlet__r.Global_Segment__c in :kpiTargetSegments and Outlet__r.Global_Sub_Segment__c in :kpiTargetSubSegments WITH SECURITY_ENFORCED];//Included Segments by Joshraj Sen              
            }
            else
            {
                 lstOutletKPIUpdate = [SELECT Id, Unique_Id__c, Category__c, KPI_Type__c, Target__c, Outlet__c, Target_Override_Not_Allowed__c FROM Outlet_KPI_Achievement__c WHERE Outlet__r.Primary_Sales_Territory__c IN :territoryIdSet AND KPI_Type__c = 'SoS' AND Category__c IN :categories AND Outlet__r.Global_Segment__c in :kpiTargetSegments WITH SECURITY_ENFORCED];//Included Segments by Joshraj Sen
            }
           
        }


        
        if(outletList != null && outletList.size() > 0){
            List<Outlet_KPI_Achievement__c> lstOutletKPI = EDGE_KPITargetOperations.populateOutletKPIs(newItems, outletList,lstOutletKPIUpdate);
            /*for(Outlet_KPI_Achievement__c oka:lstOutletKPI){
            }*/
            if(lstOutletKPI != null && lstOutletKPI.size() >0 ){
                upsert lstOutletKPI Unique_Id__c;            
            }
        }
            
    }    
}