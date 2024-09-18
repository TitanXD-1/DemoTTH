/**********************************************************************
Name: EDGE_MapsLocationTriggerHelper
=======================================================================
Req:ES20-8491-(Updating start lat and long on User)
=======================================================================
History                                                            
-------  
VERSION   AUTHOR             DATE              DETAIL
1.0       Sandip Ghosh       18/08/2020      Initial Development
***********************************************************************/
public with sharing class EDGE_MapsLocationTriggerHelper {
    
    public static void updateUserLocation(List<maps__Location__c> newItems){
        Map<Id,maps__Location__c> userLocationMap=new Map<Id,maps__Location__c>();
        List<User> userListToUpdate = new List<User>();
        
        if(newItems!=null){
            for(maps__Location__c mapLocation :newItems){
                if(mapLocation.maps__Longitude__c !=null || mapLocation.maps__Latitude__c !=null ){  
                    userLocationMap.put(mapLocation.maps__User__c,mapLocation);  
                }
                system.debug('@@userLocationMap' +userLocationMap);
            }
        }
        
        
        if(userLocationMap!=null && userLocationMap.size()>0){
            for(User usr :[Select Id,Start_Latitude__c,Start_Longitude__c from User where Id IN :userLocationMap.keyset()] ){
                if((userLocationMap.get(usr.Id))!=null){
                    usr.Start_Longitude__c = (userLocationMap.get(usr.Id)).maps__Longitude__c;                       
                    usr.Start_Latitude__c = (userLocationMap.get(usr.Id)).maps__Latitude__c;   
                }
                userListToUpdate.add(usr);
            }   
            
        }
    
    system.debug('@@userListToUpdate' +userListToUpdate);
    if(userListToUpdate!=null && userListToUpdate.size()>0){
        update userListToUpdate;
    }
    
  }
}