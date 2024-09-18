/**********************************************************************
Name: EDGE_UserBusinessRoleTriggerHelper
=======================================================================
Req: The requirement is to remove Outlet from territory && Target list member from Target list
ES20-277 - Remove Target list member from Target List- Static
ES20-258 - Remove Outlet Territory from Territory
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sandeep Sahoo     27/02/2019        Initial Development

***********************************************************************/

public without sharing class EDGE_RemoveElementController{
    //Searching Target list member from Selected Static Target list
    @AuraEnabled
    public static List<Target_List_Member__c> searchTargetMemberDetails(String queryString,String recordID){
        try{ 
            List<Target_List_Member__c> tarmemlist = new List<Target_List_Member__c>();            
            if(Schema.sObjectType.Target_List_Member__c.isAccessible() && String.isNotBlank(recordID)){
                if(queryString.startsWith(' OR')){
                    queryString = queryString.removeStart(' OR');
                    queryString = ' AND ( ' + queryString + ' )';
                }
                Id outletRecordTypeId = Schema.SObjectType.account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
                String strQuery = 'SELECT Id,Outlet__r.Name,Name,Outlet__r.Is_Active__c,Outlet__r.Ref__c,Assignment_Status__c, ';
                strQuery +='Outlet__r.BillingStreet, Outlet__r.BillingCity, Outlet__r.BillingPostalCode,Outlet__r.Country__r.Name FROM Target_List_Member__c ';
                strQuery +='where Target_List__c=:recordId and Assignment_Status__c In (\'Active\',\'Waiting Activation\') ';
                strQuery = strQuery + queryString;                    
                strQuery = strQuery +' LIMIT 9999';
                tarmemlist = Database.query(strQuery);                                       
            }
            return tarmemlist;                
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }        
    }
    //This method is used to update selected Target List Member to Waiting Removal so that the night batch can pick it up
    @AuraEnabled
    public static void removeMember(List<String> memberID){
        try{        
            List<Target_List_Member__c> tarmemlist = new List<Target_List_Member__c>();
            List<Target_List_Member__c> updatetarmemlist = new List<Target_List_Member__c>();            
            tarmemlist  = [SELECT Id,Assignment_Status__c FROM Target_List_Member__c where ID in :memberID]; 
            for( Target_List_Member__c tlm : tarmemlist ){
                tlm.Assignment_Status__c='Waiting Removal';
                updatetarmemlist.add(tlm);
            }
            if(updatetarmemlist!=null && updatetarmemlist.size()>0) {
                Database.update(updatetarmemlist);     
            }                      
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }         
    }
    //Searching Outlet Territory from Selected Territory
    @AuraEnabled
    public static List<Outlet_Territory__c> searchOutletTerritoryDetails(String queryString,String recordID){
        try{
            List<Outlet_Territory__c> outletterrlist = new List<Outlet_Territory__c>();
            if(Schema.sObjectType.Outlet_Territory__c.isAccessible() && String.isNotBlank(recordID)){ 
                if(queryString.startsWith(' OR')){
                    queryString = queryString.removeStart(' OR');
                    queryString = ' AND ( ' + queryString + ' )';
                }
                String strQuery = 'SELECT Id,Name,Outlet__r.Name,Outlet__r.Ref__c,Active__c,Outlet__r.BillingStreet, Outlet__r.BillingCity, Outlet__r.BillingPostalCode,Outlet__r.Country__r.Name FROM Outlet_Territory__c where Territory__c=:recordID and Active__c in  (\'Active\',\'Waiting Activation\') ';        
                strQuery = strQuery + queryString;                    
                strQuery = strQuery +' LIMIT 9999';                       
                outletterrlist = Database.query(strQuery);              
            }
            return outletterrlist;   
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }         
    }
    //Removal of Outlet by Updating Active field of Outlet territory records to Draft Remove 
    @AuraEnabled
    public static void removeOutlet(List<String> memberID){
        try{
            System.debug('==memberID=='+memberID);
            List<Outlet_Territory__c> outletterrlist = new List<Outlet_Territory__c>();
            List<Outlet_Territory__c> updatetoutletterrlist = new List<Outlet_Territory__c>();
            
            outletterrlist  = [SELECT Id,Active__c FROM Outlet_Territory__c where ID in :memberID ];  
            for( Outlet_Territory__c ot : outletterrlist ){
                ot.Active__c='Waiting Removal';
                updatetoutletterrlist.add(ot);
            } 
            if(updatetoutletterrlist!=null && updatetoutletterrlist.size()>0){
                Database.update(updatetoutletterrlist);
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        } 
    }
}