/**********************************************************************
Name: EDGE_StrategyCategoryTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for StrategyCategoriesTriggerHandler
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Manikant Prasad   01/07/2019         ES20-2869 

***********************************************************************/
public  with sharing class EDGE_StrategyCategoryTriggerHelper {
    
    public static void updateAccountCategory(List<Strategy_Categories__c> newItems){
       List<Account> accRecList= new List<Account>();
        Map<Id ,List<Strategy_Categories__c> > accStratCategoryMap = new  Map<Id ,List<Strategy_Categories__c>>();
        
        for(Strategy_Categories__c strCaterec : newItems){
              
            if(accStratCategoryMap.containsKey(strCaterec.Outlet__c)){
                accStratCategoryMap.get(strCaterec.Outlet__c).add(strCaterec);                        
            }
            else{
                accStratCategoryMap.put(strCaterec.Outlet__c, new List<Strategy_Categories__c>{strCaterec});
            }
        }
           
        for ( Id accId : accStratCategoryMap.keyset()){
            Account accRec= new Account(id=accId);
            for (Strategy_Categories__c strCaterec : accStratCategoryMap.get(accId)){                
                if(strCaterec.FRP_Points__c != null && strCaterec.Category__c == 'Deluxe'){
                    accRec.Volume_Category_Deluxe_Actuals__c = strCaterec.FRP_Points__c;
                }
                if(strCaterec.FRP_Points__c != null && strCaterec.Category__c == 'RTD'){
                    accRec.Volume_Category_RTD_Actuals__c = strCaterec.FRP_Points__c;
                }
                if(strCaterec.FRP_Points__c != null && strCaterec.Category__c == 'Premium Core'){
                    accRec.Volume_Category_Premium_Core_Actuals__c = strCaterec.FRP_Points__c;
                }
                if(strCaterec.FRP_Points__c != null && strCaterec.Category__c == 'Super Deluxe'){
                    accRec.Volume_Category_Super_Deluxe_Actuals__c = strCaterec.FRP_Points__c;
                }
                if(strCaterec.FRP_Points__c != null && strCaterec.Category__c == 'Reserve'){
                    accRec.Volume_Category_Reserve_Actuals__c = strCaterec.FRP_Points__c;
                }                
            }
            accRecList.add(accRec);
        }
        if(Schema.sObjectType.Account.isUpdateable() && accRecList.size()>0){
            update accRecList;
        }
    }
}