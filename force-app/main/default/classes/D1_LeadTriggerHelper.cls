/**
  * @name D1_LeadTriggerHelper
  * @purpose Trigger Helper Class for LeadTriggerHandler
  * @history                                                                                                                       
  * VERSION  	AUTHOR            DATE              DETAIL
  * 1.0      	Sayan			13/08/2021         NCP-4081
**/
public class D1_LeadTriggerHelper {
    
    /**
     * @userStory NCP-4081
     * @description Validate Phone number depending upon regex set on metadata
     * @param newItems
     * @param oldItems
     **/
    public static void validatePhoneNumber(List<sObject> newItems, Map<Id,SObject> oldItems){
        Map<Id,Lead> mapOldItems;
        List<SObject> lstNewData = new List<SObject>();
        Set<String> setPhonePrefix = new Set<String>();
        List<String> lstFieldName = new List<String>{'MobilePrefix__c','Mobile__c','PhonePrefix__c','Phone__c'};
        List<String> lstFieldToUpdate = new List<String>{'MobilePhone','Phone'};
        
        if(oldItems != null){
            mapOldItems = (Map<Id,Lead>) oldItems;
        }
        
        if(newItems != null && newItems.size()>0){
            for(sObject newObject : newItems){
                Lead newLead = (Lead)newObject;
                                
                if(((newLead.MobilePrefix__c != null && newLead.Mobile__c != null) || (newLead.PhonePrefix__c != null && newLead.Phone__c != null)) && 
                   (oldItems == null || 
                    (oldItems != null && mapOldItems.containsKey(newLead.Id) && 
                     (newLead.MobilePrefix__c != mapOldItems.get(newLead.Id).MobilePrefix__c || newLead.Mobile__c != mapOldItems.get(newLead.Id).Mobile__c || 
                      newLead.PhonePrefix__c != mapOldItems.get(newLead.Id).PhonePrefix__c || newLead.Phone__c != mapOldItems.get(newLead.Id).Phone__c)
                    ))
                  ){
                      lstNewData.add(newObject);
                      if(String.isNotBlank(newLead.MobilePrefix__c)){
                          setPhonePrefix.add(newLead.MobilePrefix__c);
                      }
                      
                      if(String.isNotBlank(newLead.PhonePrefix__c)){
                          setPhonePrefix.add(newLead.PhonePrefix__c);
                      }
                  }
            }
            
            if(lstNewData != null && lstNewData.size()>0){
                EDGE_PhoneFormatting.validatePhoneNumber(lstNewData, setPhonePrefix, lstFieldName, lstFieldToUpdate);
            }            
        }
    }
    /**
     * @userStory NCP-4082
     * @description This method will complete the Geographies Hierarchy of an Account when
					the Country ISO Code is provided.
     * @param recNew
     * @param recOld
     **/  
    public static void setGeographyTree(list<Lead> recNew, list<Lead>  recOld){
        List<String> countryList = new List<String>();
        Map<String, Geography__c> geographyMap = new Map<String, Geography__c>();
        
        for(Integer i=0;i<recNew.size();i++){
            if(Trigger.isInsert || (Trigger.isUpdate && recNew[i].Country_ISO_Code__c != recOld[i].Country_ISO_Code__c)){
                countryList.add(recNew[i].Country_ISO_Code__c);
            }
        }
        
        if(!countryList.isEmpty()){
            for(Geography__c geo: [SELECT Id, Code__c, name, parent_geography__c, parent_geography__r.parent_geography__c, parent_geography__r.parent_geography__r.parent_geography__c
                                   FROM Geography__c WHERE Code__c IN: countryList])
            {
                geographyMap.put(geo.Code__c, geo);
            }
        }
        
        if(!geographyMap.isEmpty()){
            for(Integer i=0;i<recNew.size();i++){
                if((Trigger.isInsert || ((Trigger.isUpdate && recNew[i].Country_ISO_Code__c != recOld[i].Country_ISO_Code__c) &&  
                    (recOld[i].Country__c == null || recOld[i].Cluster__c == null || recOld[i].Market__c == null || recOld[i].Hub__c == null))) && //included hierarchy check as a part of NCP-2869
                   	geographyMap.get(recNew[i].Country_ISO_Code__c) != null){
                       
                    Geography__c geo = geographyMap.get(recNew[i].Country_ISO_Code__c);
                    recNew[i].Hub__c = geo.Parent_Geography__r.Parent_Geography__c;
                    recNew[i].Market__c = geo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c;
                    recNew[i].Cluster__c = geo.Parent_Geography__c;
                    recNew[i].Country__c = geo.id;
                }
            }
        }
    }
    
    
    /**
     * @description This method is used to map the UIN Number field of lead object with Account field based on D1 setting
     * @param newItems 
     * @param oldItems 
     */
    
    public static void mapUINumberField(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id,Lead> mapOldItems;
        
        Map<ID,Lead> leadAccountMap=new Map<ID,Lead>();
        Set<Id> countryIdsSet = new Set<Id>();
        List<Account> accountUpdateList = new List<Account>();
        List<Account> accList = new List<Account>();
        set<Id> setAccountIds = new set<Id>();
        string taxAPI;
        
        if(oldItems != null){
            mapOldItems = (Map<Id,Lead>) oldItems;
        }
        
        if(newItems != null){
            for(SObject obj :newItems.values()){     
                Lead leadObj = (Lead)obj;                
                if(leadObj.ConvertedAccountId != null && mapOldItems.get(leadObj.Id).ConvertedAccountId == null && !mapOldItems.get(leadObj.Id).IsConverted && leadObj.isConverted){
                    countryIdsSet.add(leadObj.Country__c);
                    leadAccountMap.put(leadObj.ConvertedAccountId,leadObj);
                }
            }
        }

        if(countryIdsSet.size()>0 && Schema.sObjectType.D1_Setting__c.isAccessible()){
            for(D1_Setting__c d1setting : [SELECT  UIN_Field__c, UIN_Label__c, UIN_Setting__c FROM D1_Setting__c WHERE Market__c =:countryIdsSet]){
                taxAPI = d1setting.UIN_Field__c;
            }
        }
        
        if(String.isNotBlank(taxAPI) && Schema.sObjectType.Account.isAccessible()){
            setAccountIds.addAll(leadAccountMap.keySet());
            String queryStr = 'SELECT Id';
            if(!queryStr.containsIgnoreCase(taxAPI)){
                queryStr += ', ' + taxAPI;
            }
            queryStr += ' FROM Account WHERE Id IN :setAccountIds';
            accList = Database.query(queryStr);
        }       
        
        
        if(accList != null && leadAccountMap != null){
            for(Account accRecd : accList){
                if(leadAccountMap.containsKey(accRecd.Id) && EDGE_Constant.HAS_ACCOUNT_INSERT_RUN == true){
                    Lead leadRecd = leadAccountMap.get(accRecd.Id);
                    accRecd.put(taxAPI, leadRecd.UIN_Number__c);                   
                    accountUpdateList.add(accRecd);
                }            
            } 
        }
        
        if(accountUpdateList != null && accountUpdateList.size()>0){
            database.update(accountUpdateList);
        }        
    }
    
    
    public static void populatePardotBUCountryCode(List<sObject> newItems, Map<Id,SObject> oldItems){
        
        Map<Id,Lead> mapOldIdToLead = (Map<Id,Lead>) oldItems;
        List<Lead> listNewLead = (List<Lead>) newItems;
        Boolean isOldMap =  mapOldIdToLead != null;
        
        
        Set<Id> setRelatedCountryId = new Set<Id>();
        List<Lead> listLeadToUpdate = new List<Lead>();
        for(Lead newLead: listNewLead){

            if( !isOldMap
                ||(isOldMap && (mapOldIdToLead.get(newLead.Id).Country__c != newLead.Country__c ||
                              mapOldIdToLead.get(newLead.Id).LeadSource != newLead.LeadSource 
                               ) 
                  )
              ){
                setRelatedCountryId.add(newLead.Country__c);
                listLeadToUpdate.add(newLead);
            }
        }
        setRelatedCountryId.remove(null);
        
        
        
        Map<Id,Geography__c> mapIdToCountry = new Map<Id,Geography__c>(); 
        
        if(!setRelatedCountryId.isEmpty()){
            
            for(Geography__c geography: [
                SELECT Id,Code__c
                FROM Geography__c
                WHERE ID IN:setRelatedCountryId                
            ]){
                mapIdToCountry.put(geography.Id, geography);
                
            }
        }
       

        
        for(Lead lead: listLeadToUpdate){
             Geography__c relatedCountry = mapIdToCountry.get(Lead.Country__c);

            if(relatedCountry !=null){
                Lead.Country_ISO_Code__c = relatedCountry.Code__c;//NCP-6401
                if(lead.LeadSource == 'DiageoOne')
                {
                     Lead.Pardot_BU_Sync_Code__c = relatedCountry.Code__c + '_Nonsync';
                }
               else
               {
                   Lead.Pardot_BU_Sync_Code__c = relatedCountry.Code__c + '_sync';
               } 
                
            }
        }

    }
}