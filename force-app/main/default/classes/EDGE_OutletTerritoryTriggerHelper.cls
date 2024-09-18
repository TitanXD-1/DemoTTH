/**
* @Name: EDGE_OutletTerritoryTriggerHelper

* @Req: The requirement is to provide validations while assigning outlets to 
territory. Outlets can only belong to 1 Sales/DBA/Service/Merchendise Territory.
Outlets assigned to a Sales Territory can be assigned to a Service Territory  
User Story : ES20-257

* @History                                                            

* @VERSION   AUTHOR            DATE              DETAIL
*  1.0      Sagar Barman      13/02/2019       Initial Development
*  1.1	    Saurav Paul	      8th-Mar-2019	   Country Validation
*  1.2      Anand Uppalapati  14-02-2022       Country Validation
*  1.3		Shivam Chauhan	  23-12-2022	   ES20-13670
**/
public with sharing class EDGE_OutletTerritoryTriggerHelper {   
    
    /**
Purpose: The below method provides validation when outlet territory 
are getting inserted. 
**/
    public static void validateOutletAssignmentsOnInsert(List<SObject> newItems){
        try{
            Map<Id,List<Outlet_Territory__c>> mapOutletTerritory = new Map<Id,List<Outlet_Territory__c>>();
            Map<Id,Set<String>> outletTerritoryTypeMap = new Map<Id,Set<String>>();
            Map<Id,Set<String>> outletNewTerritoryTypeMap = new Map<Id,Set<String>>();
            //calling getOutletTerritoryMap to populate mapOutletTerritory
            List<Outlet_Territory__c> newOutletTerritoryItems =  new List<Outlet_Territory__c>();
            mapOutletTerritory = getOutletTerritoryMap(newItems);
            //outletTerritoryTypeMap = getOutletTerritoryTypeMap(newOutletTerritoryItems);
            Set<Id> territoryIdSet = new Set<Id>();
            Map<Id,Territory__c> territoryTypeMap = new Map<Id,Territory__c>();
            for(SObject sob : newItems){ 
                Outlet_Territory__c oultetTerritory = (Outlet_Territory__c)sob; 
                territoryIdSet.add(oultetTerritory.Territory__c);
                newOutletTerritoryItems.add(oultetTerritory);
            }
            //getting Map of Outlet with Territory Type
            outletTerritoryTypeMap = getOutletTerritoryTypeMap(newOutletTerritoryItems);
            //getting Map of Id with Territory
            territoryTypeMap = getTerritoryTypeMap(territoryIdSet);        
            //throwing error in case ONE Oullet is already assigned in Sales OR Service OR DBA OR Mercendise  Territory
            for(SObject sob : newItems){
                Outlet_Territory__c oultetTerritory = (Outlet_Territory__c)sob;
                Set<String> existingTerritoryTypeSet = outletTerritoryTypeMap.get(oultetTerritory.Outlet__c);
                if(existingTerritoryTypeSet != null && existingTerritoryTypeSet.size()>0 && existingTerritoryTypeSet.contains(territoryTypeMap.get(oultetTerritory.Territory__c).Territory_Type__c)){
                    oultetTerritory.addError(System.Label.Error_Message_Outlet_Assignment_on_Territory+' '+territoryTypeMap.get(oultetTerritory.Territory__c).Territory_Type__c);
                }
                else if(existingTerritoryTypeSet == null || !existingTerritoryTypeSet.contains(territoryTypeMap.get(oultetTerritory.Territory__c).Territory_Type__c)){
                    if(outletNewTerritoryTypeMap.containsKey(oultetTerritory.Outlet__c)){
                        if(!outletNewTerritoryTypeMap.get(oultetTerritory.Outlet__c).contains(territoryTypeMap.get(oultetTerritory.Territory__c).Territory_Type__c)){
                            outletNewTerritoryTypeMap.get(oultetTerritory.Outlet__c).add(territoryTypeMap.get(oultetTerritory.Territory__c).Territory_Type__c);
                        }else{
                            oultetTerritory.addError(System.Label.Error_Message_Outlet_Assignment_on_Territory+' '+territoryTypeMap.get(oultetTerritory.Territory__c).Territory_Type__c);
                        }
                    }else{
                        outletNewTerritoryTypeMap.put(oultetTerritory.Outlet__c,new Set<String>{territoryTypeMap.get(oultetTerritory.Territory__c).Territory_Type__c});
                        
                    }
                }  
            }
        }catch(Exception ex){
            System.debug('Exception:'+ex.getLineNumber()+'::'+ex.getMessage()+ex.getCause());            
            
        }
    }    
    
    /**
Purpose: The below method populates the Map of Outlet Id with OutletTerritories. 
**/    
    public static Map<Id,List<Outlet_Territory__c>> getOutletTerritoryMap(List<Outlet_Territory__c> lstOutletTerritory){
        Map<Id,Set<String>> OutletTerritoryTypeMap = new Map<Id,Set<String>>();
        Map<Id,List<Outlet_Territory__c>> mapOutletTerritory = new Map<Id,List<Outlet_Territory__c>>();
        Set<Id> setOutletId = new Set<Id>();
        List<Outlet_Territory__c> lstExistOutletTerritory;  
        try{             
            if(lstOutletTerritory != null && !lstOutletTerritory.isEmpty()){            
                for(Outlet_Territory__c outlet : lstOutletTerritory){
                    if(String.isNotBlank(outlet.Outlet__c)){
                        setOutletId.add(outlet.Outlet__c);
                    }                
                }
            }   
            if(!setOutletId.isEmpty()){
                //getting the Outlet Territories  where Outlet is already assigned to a Sales OR Service Territory
                String territoryType = System.Label.Territory_Type_Auxiliary;
                if(Schema.sObjectType.Outlet_Territory__c.isAccessible()) { // needed to remove APEX crud violations
                    lstExistOutletTerritory = [SELECT ID, Territory__c, Outlet__c, Outlet__r.Name, Territory__r.Name,
                                               Territory__r.Territory_Type__c
                                               FROM Outlet_Territory__c 
                                               WHERE Outlet__c IN : setOutletId and 
                                               Territory__r.Territory_Type__c != :territoryType                                           
                                              ]; 
                }    
            }            
            if(lstExistOutletTerritory != null && !lstExistOutletTerritory.isEmpty()){
                for(Outlet_Territory__c outletTerritory : lstExistOutletTerritory){
                    if(mapOutletTerritory.containsKey(outletTerritory.Outlet__c)){
                        mapOutletTerritory.get(outletTerritory.Outlet__c).add(outletTerritory);                        
                    }
                    else{
                        mapOutletTerritory.put(outletTerritory.Outlet__c, new List<Outlet_Territory__c>{outletTerritory});
                    }
                }
            }           
        }
        catch(Exception ex){
            System.debug('Exception:'+ex.getLineNumber()+'::'+ex.getMessage()+ex.getCause());            
            
        }
        return mapOutletTerritory;
    }
    
    /**
    Purpose: The below method populates the Map of Outlet Id with OutletTerritories type. 
    **/    
    public static Map<Id,Set<String>> getOutletTerritoryTypeMap(List<Outlet_Territory__c> lstOutletTerritory){
        Map<Id,Set<String>> outletTerritoryTypeMap = new Map<Id,Set<String>>();
        Set<Id> setOutletId = new Set<Id>();
        try{             
            if(lstOutletTerritory != null && !lstOutletTerritory.isEmpty()){            
                for(Outlet_Territory__c outlet : lstOutletTerritory){
                    if(String.isNotBlank(outlet.Outlet__c)){
                        setOutletId.add(outlet.Outlet__c);
                    }                
                }
            }   
            if(!setOutletId.isEmpty()){
                //getting the Outlet Territories  where Outlet is already assigned to a Sales OR Service Territory
                String territoryType = System.Label.Territory_Type_Auxiliary;
                if(Schema.sObjectType.Outlet_Territory__c.isAccessible()) { // needed to remove APEX crud violations
                    for(Outlet_Territory__c outTerriObj : [SELECT ID, Territory__c, Outlet__c, Outlet__r.Name, Territory__r.Name,
                                                           Territory__r.Territory_Type__c
                                                           FROM Outlet_Territory__c 
                                                           WHERE Outlet__c IN : setOutletId and 
                                                           Territory__r.Territory_Type__c != :territoryType                                           
                                                          ]){
                                                              if(outletTerritoryTypeMap.containsKey(outTerriObj.Outlet__c)){
                                                                  outletTerritoryTypeMap.get(outTerriObj.Outlet__c).add(outTerriObj.Territory__r.Territory_Type__c);                        
                                                              }else{
                                                                  outletTerritoryTypeMap.put(outTerriObj.Outlet__c,new Set<String>{outTerriObj.Territory__r.Territory_Type__c});
                                                                  
                                                              }
                                                              
                                                              
                                                          }    
                }                     
            }
        }
        catch(Exception ex){
            System.debug('Exception:'+ex.getLineNumber()+'::'+ex.getMessage()+ex.getCause());            
        }
        return OutletTerritoryTypeMap;
    }
    
    /**  
    Name : getTerritoryTypeMap
    Description: The below method populates the Map of Territory. 
    **/ 
    public static Map<Id,Territory__c> getTerritoryTypeMap(Set<Id> territoryIdSet){
        Map<Id,Territory__c> territoryTypeMap = new Map<Id,Territory__c>([SELECT Id,Territory_Type__c FROM Territory__c WHERE Id IN : territoryIdSet]);
        return territoryTypeMap;
    }  
    
    /**    
    Name  : validateCountry
    Description : The method will validate Country. 
    **/   
    public static void validateCountry(Boolean isUpdate, List<SObject> newList, Map<Id,SObject> oldMap){
        //Variables
        Set<Id> outletIdSet = new Set<Id>();
        Set<Id> terriIdSet = new Set<Id>();
        Map<Id,Territory__c> territoryMap ;
        Map<Id,Account> accountMap;
        //Variables
        for(SObject sObj : newList){
            Outlet_Territory__c outltTerrObj = (Outlet_Territory__c)sObj;
            if(isUpdate && oldMap!= null && oldMap.containsKey(outltTerrObj.Id)){
                Outlet_Territory__c oldOutTerObj = (Outlet_Territory__c)oldMap.get(outltTerrObj.Id);
                if(oldOutTerObj.Outlet__c != outltTerrObj.Outlet__c || oldOutTerObj.Territory__c != outltTerrObj.Territory__c){
                    outletIdSet.add(outltTerrObj.Outlet__c);
                    terriIdSet.add(outltTerrObj.Territory__c);
                }
                
            }else if(!isUpdate && String.isNotBlank(outltTerrObj.Outlet__c) && String.isNotBlank(outltTerrObj.Territory__c)){
                outletIdSet.add(outltTerrObj.Outlet__c);
                terriIdSet.add(outltTerrObj.Territory__c);	
            }
        }
        
        //Get Territory & Outlet Country
        if(!outletIdSet.isEmpty() && !terriIdSet.isEmpty()){
            if(Schema.sObjectType.Territory__c.isAccessible()){
                territoryMap = new Map<Id,Territory__c>([SELECT Id,Country__c FROM Territory__c WHERE Id IN : terriIdSet]);
            }
            if(Schema.sObjectType.Account.isAccessible()){
                accountMap =  new Map<Id,Account>([SELECT Id,Country__c FROM Account WHERE Id IN : outletIdSet]);
            }
        }
        
        for(SObject sObj : newList){
            Outlet_Territory__c outltTerrObj = (Outlet_Territory__c)sObj;
            if(territoryMap!= null && territoryMap.containsKey(outltTerrObj.Territory__c) && 
               accountMap != null && accountMap.containsKey(outltTerrObj.Outlet__c)){
                   if(territoryMap.get(outltTerrObj.Territory__c).Country__c != accountMap.get(outltTerrObj.Outlet__c).Country__c){
                       outltTerrObj.addError(Label.Country_Mismatch_Issue_Territory);
                   }
               }
        }
    }
}