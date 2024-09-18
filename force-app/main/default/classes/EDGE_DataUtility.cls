/**
* @Name: EDGE_DataUtility


* @Purpose: Common methods to fetch Edge Data from batch job


* @History                                                            
                                                           
* @VERSION       AUTHOR               DATE              DETAIL
*  1.0	        Sudipta Nandi	      30/10/2021	 	ES20-10839

   2.0	        Sudipta Nandi	      11/13/2021	 	ES20-10648
	
   2.1			Rajarshi Lahiri		  09/06/2022		ES20-12745
*/
public class EDGE_DataUtility {
	
    /**
    * @method   fetchUserCountry  ES20-10644
    * @description fetch user country
    *          Case 1 - User country = Available_Countries__c if there's only one value in Available_Countries__c
    *          Case 2 - User country = Default_Country__c if there are multiple values in Available_Countries__c and Default_Country__c has value
    * @return map
    * @param set

    */

    public static Map<Id, String> fetchUserCountry(Set<Id> userIdSet){
        
        Map<Id, String> userToCountryMap = new Map<Id, String>();
        
        if(userIdSet != null){
            for(User u : [SELECT Id, Available_Countries__c, Default_Country__c FROM User WHERE Id IN : userIdSet])
            {
                List<String> assignedCountriesList = new List<String>();
                String userCountry = '';
                
                if(u.Available_Countries__c != null){
                    assignedCountriesList.addAll(u.Available_Countries__c.split(';'));
                }
                
                if(assignedCountriesList!=null && assignedCountriesList.size()>0)
                {
                    if(assignedCountriesList.size()==1) //case 1
                        userCountry = assignedCountriesList.get(0);
                    else if(assignedCountriesList.size()>1 && u.Default_Country__c!=null) //case 2
                        userCountry = u.Default_Country__c;
                    /*else if(assignedCountriesList.size()>1 && u.Default_Country__c==null) //case 3
                        userCountry = assignedCountriesList.get(0); */          
                }
                if(!String.isBlank(userCountry)){
                    userToCountryMap.put(u.Id,userCountry);
                }  
            }
        } 
        return userToCountryMap;
    }   

    /*

    public static Map<Id, String> fetchOutletCountry(Set<Id> accIdSet)
    {
        Map<Id, String> outletToCountryMap = new Map<Id, String>();
        if(accIdSet != null){
            for(Account acc : [SELECT Id,Country_Code__c FROM Account WHERE Id IN : accIdSet])
            {
                if(!outletToCountryMap.keySet().contains(acc.Id)){
                    outletToCountryMap.put(acc.Id,acc.Country_Code__c);
                }
            }      
        }
        return outletToCountryMap;
    }

    */

    public static Map<String, KPI_Achivement__c> getkpiAchievementMap(Set<String>userList, String RecordTypeName, String KpiType){
        Map<String, KPI_Achivement__c> kpiAchivementMap = new Map<String, KPI_Achivement__c>();
        //Quering on KPI Achievement object for Upserting Records
        //Added Manager_Count_Reset__c in query for ES20-12745
        for(KPI_Achivement__c kpiAchive : [SELECT Id, User__c, Category__c, Volume_Category__c, KPI_Type__c,Actual_Numerator__c,Total_Denominator__c,Achievement__c,Manager_Count_Reset__c FROM KPI_Achivement__c WHERE User__c IN :userList AND recordType.developerName =:RecordTypeName AND KPI_Type__c =:kpiType]){
            if(kpiAchive.KPI_Type__c == KpiType){
                kpiAchivementMap.put(kpiAchive.User__c + '_' + kpiAchive.KPI_Type__c, kpiAchive);                    
            }
            
        }
        return kpiAchivementMap;
    }


}