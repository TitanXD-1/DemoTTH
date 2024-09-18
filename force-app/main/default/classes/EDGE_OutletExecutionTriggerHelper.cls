/**
* @Name: EDGE_OutletExecutionTriggerHelper
* @Req: Add products to Market(Country) if the product is missing in Market but coming as 
* @Outlet Execution from TRAX.Please visit : https://diageo.quip.com/NEAhAJahe6u4/Market-Assortment-Design 
   for design
* @User Story : ES20-290
   User Story : ES20-128Method createOpportunity,getOppTemplate,createOpp
   History                                                            
* @VERSION   AUTHOR            DATE              DETAIL
*  1.0       Sagar Barman     01/04/2019       Initial Development
*  1.1       Saurav Paul      19/04/2019       US : ES20-128
*  1.2       Saurav Paul      15/05/2019       US : ES20-1140
*  1.3       Anuja Chatterjee 26/08/2019       US : ES20- 3484,4266- geographyCheckInOpptyTemplateFetch method added
                                                    Geography Change On Opportunity Object
*  1.4       Preyanka Ghosh   26/12/2019       US : ES20-6532  
*  1.5       Sagar Barman     04/05/2020       US : ES20-7662(changed the query on Opportunity_Template__c)
*  1.6       Monalisa Halder  23/11/2020       US : ES20-8980   
*  1.7       Dinesh Sharma    15/02/2021       US : ES20-9346(expireOpportunity)
*  1.8       Dinesh Sharma    26/02/2021       US : ES20-9787,9757,9844 (Check Fascia for Opportunity Creation if the Country's
Market Setting allows)
*  1.9       Rajarshi Lahiri  07/09/2022       US : ES20-13288

*  1.10      Priya Soni/Anand 25/10/2022       US : ES20-13397 Update WPA Opportunity Stage to Closed when Distribution field of OE is changed to 'Yes'
*  1.11	     Rajarshi Lahiri  25/10/2022	   US : ES20-13396 Logic to generate WPA opportunities once Outlet Execution record is created when Distribution field of OE is changed to 'No'
*  2.1		 Dipanjan Das	  08/07/2024	   155298-- Amend Source Criteria check for mapping Opportunity Templates while creating a new Opportunity basis TRAX response
*  2.2		 Saurav Prasad	  14/08/2024	   155304 : GB Opportunity Scoring: Auto Closure of Advanced Analytics generated opportunities based on TRAX response (MPA/MAS/WPA)
*/
public with sharing class EDGE_OutletExecutionTriggerHelper {  
    
    final static String productRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product').getRecordTypeId();
    final static String outletExecutionMASRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation').getRecordTypeId();
    final static String sourceTrax = 'TRAX';
    /**    
* @description: the below method creates the MarketAssortmentProduct. 
* @return: void
* @param: Map<Id, SObject>
**/
    public static void createMarketAssortmentProduct(Map<Id, SObject> newItems){
        
        /**variables**/                       
        List<Market_Assortment_Product__c> newMAPList = new List<Market_Assortment_Product__c>();
        Set<Id> productIdSet = new Set<Id>(); 
        Set<Id> countryIdSet = new Set<Id>();
        Set<Id> outletIdSet = new Set<Id>();
        Set<String> maketUniqueIdSet = new Set<String>();  
        
        Map<Id,List<Id>> newCountryProductMap = new Map<Id,List<Id>>();//map of Country with products
        Map<Id,List<Id>> newProductAccountMap = new Map<Id,List<Id>>();// map of products with Account
        List<Account> outletList = new List<Account>(); 
        
        /**variables**/                        
        for(SObject sob : newItems.values()){
            Outlet_Execution__c oultetEx = (Outlet_Execution__c)sob;
            if(oultetEx.RecordTypeId == productRecordTypeId){
                outletIdSet.add(oultetEx.Outlet__c);
                productIdSet.add(oultetEx.Product__c);
            }
            
        } 
        if(productIdSet.size() > 0){
            //getting the outlets and its countries associated with the Outlet execution 
            if(Schema.sObjectType.Account.isAccessible()){
                //populate map of country and Products with new Outlet Excution 
                for(Account acc : [SELECT Id, Country__c FROM Account WHERE Id IN : outletIdSet]){                
                    countryIdSet.add(acc.Country__c);
                }
            }
            
            for(Market_Assortment_Product__c marketAssortment : [SELECT Id, Unique_ID__c FROM Market_Assortment_Product__c WHERE Market_Assortment__c IN :countryIdSet AND Product__c IN :productIdSet]){
                maketUniqueIdSet.add(marketAssortment.Unique_ID__c);
            }
            
            for(Id countryId : countryIdSet){
                for(Id productId : productIdSet){
                    //commented the below line for User story ES20-8980 and added line 68
                    //String key = countryId + '_' + productId;
                    String key = productId + '_' + countryId;
                    if(!maketUniqueIdSet.contains(key)){
                        newMAPList.add(new Market_Assortment_Product__c(Market_Assortment__c = countryId, Product__c = productId));
                    }          
                }
            }
            try{ 
                //insert the new Market Assortment Product list
                if(newMAPList.size() >0){
                    if(Schema.sObjectType.Market_Assortment_Product__c.isCreateable()){
                        Database.insert(newMAPList,false); 
                    }
                } 
            }catch(Exception ex){
                System.debug('Exception from EDGE_OutletExecutionTriggerHelper '+ex+' on line'+ex.getLineNumber());    
            }      
        }
        
    }
    
 /**    
* @description: the below method creates opportunity based on Opportnity Template. 
* @return: void
* @param: Map<Id, SObject>,Boolean
**/
    public static void createOpportunity(Map<Id, SObject> newItems, Map<Id, SObject> oldMap, Boolean isTemplateUpdateOnOpp){
        //Variables
        Set<Id> outletIdSet = new Set<Id>();
        Set<String> productSet = new Set<String>();
        Set<String> activationSet = new Set<String>();
        List<Outlet_Territory__c> outTerriLst = new List<Outlet_Territory__c>(); 
        List<Outlet_Execution__c> outExeList = new List<Outlet_Execution__c> ();
        Set<String> fasciaSet = new Set<String>();
        Set<String> subSegmentSet = new Set<String>(); 
        Set<String> territorySet = new Set<String>(); 
        Set<String> segmentSet = new Set<String>();
        Set<String> channelSet = new Set<String>(); 
        Set<String> marketSet = new Set<String>();
        Set<String> hubSet = new Set<String>();
        Set<String> countrySet = new Set<String>(); 
        Set<String> clusterSet = new Set<String>();
        Set<String> areaSet = new Set<String>();
        Set<String> regionSet = new Set<String>();
        Map<id,Market_Setting__c> countryMarketMap = new Map<id,Market_Setting__c>();
        Map<String,Outlet_Territory__c> primaryTerrMap = new Map<String,Outlet_Territory__c> ();
        Map<String,Outlet_Territory__c> auxTerrMap = new Map<String,Outlet_Territory__c> ();
        List<Opportunity_Template__c> oppTemList = new List<Opportunity_Template__c>();
        Map<String,List<Opportunity_Template__c>> oppTemplateMap = new Map<String,List<Opportunity_Template__c>>();
        Map<String,List<Opportunity_Template__c>> oppTemplateActivationMap = new Map<String,List<Opportunity_Template__c>>();
        List<Opportunity> openOppList = new List<Opportunity>();
        Map<String,Opportunity> openOppMap = new Map<String,Opportunity>();
        Map<String,Opportunity> openOppActMap = new Map<String,Opportunity>();/* For US-2954*/
        Map<Id,Account> outletMap = new Map<Id,Account>();
        List<Opportunity> oppInsertList = new List<Opportunity>();
        Map<Id,Outlet_Execution__c> oldOutletExeMap;
        Map<String,Template_Weighing__c> templtWeiMap = new Map<String,Template_Weighing__c>();
        //Variables
        if(oldMap != null){
            oldOutletExeMap = (Map<Id, Outlet_Execution__c>)oldMap;
        }
        //Adding values to set variable
        //Creating Product, Activation Set for which oppty needs to be created
        for(SObject sobj : newItems.values()){
            Outlet_Execution__c oultetEx = (Outlet_Execution__c)sobj;
            if((((oldOutletExeMap != null)
                 &&((oldOutletExeMap.get(oultetEx.Id).MAS__c != oultetEx.MAS__c && oultetEx.MAS__c == 'No') ||
                    (oldOutletExeMap.get(oultetEx.Id).NPA__c != oultetEx.NPA__c && oultetEx.NPA__c == 'No') ||
                    (oldOutletExeMap.get(oultetEx.Id).MPA__c != oultetEx.MPA__c && oultetEx.MPA__c == 'No')||
                   (oldOutletExeMap.get(oultetEx.Id).Distribution_TRAX__c != oultetEx.Distribution_TRAX__c && oultetEx.Distribution_TRAX__c == 'No'))) ||
                (oldOutletExeMap == null && oultetEx.MAS__c == 'No' ||oultetEx.NPA__c == 'No' ||oultetEx.MPA__c == 'No' || oultetEx.Distribution_TRAX__c == 'No')))//ES20-13396
            {
                outletIdSet.add(oultetEx.Outlet__c);
                productSet.add(oultetEx.Product__c);
                activationSet.add(oultetEx.Activation_Reference__c);
                outExeList.add(oultetEx);
            }
        }
        
        System.debug('--productSet--'+productSet);
        System.debug('--activationSet--'+activationSet);
        
        
        //Fetching related Outlet territory records (include Fascia__c in the Query as per US ES20-9787)
        if(!outletIdSet.isEmpty() && Schema.sObjectType.Outlet_Territory__c.isAccessible()){
            outTerriLst = [SELECT Territory__c,Outlet__c,Outlet__r.Fascia__c,Outlet__r.Global_Segment__c,Outlet__r.Global_Sub_Segment__c,
                           Outlet__r.Global_Channel__c,Outlet__r.Country__c,Outlet__r.Cluster__c,Outlet__r.Primary_Sales_Territory__c, 
                           Outlet__r.Outlet_Visit_Prioritisation_Grade__r.value__c,Outlet__r.Market__c,Outlet__r.Hub__c,Outlet__r.Area__c,Outlet__r.Region__c FROM Outlet_Territory__c 
                           WHERE Outlet__c IN : outletIdSet];
        }
        System.debug('outTerriLst::'+outTerriLst);
        
        if(!outTerriLst.isEmpty()){
            for(Outlet_Territory__c outTerrObj : outTerriLst){
                fasciaSet.add(outTerrObj.Outlet__r.Fascia__c);// included as per US ES20-9787
                subSegmentSet.add(outTerrObj.Outlet__r.Global_Sub_Segment__c);
                territorySet.add(outTerrObj.Territory__c);
                segmentSet.add(outTerrObj.Outlet__r.Global_Segment__c);
                channelSet.add(outTerrObj.Outlet__r.Global_Channel__c);
                marketSet.add(outTerrObj.Outlet__r.Market__c);
                hubSet.add(outTerrObj.Outlet__r.Hub__c);
                countrySet.add(outTerrObj.Outlet__r.Country__c);
                clusterSet.add(outTerrObj.Outlet__r.Cluster__c);
                areaSet.add(outTerrObj.Outlet__r.Area__c);
                regionSet.add(outTerrObj.Outlet__r.Region__c);
                if(String.isNotBlank(outTerrObj.Outlet__r.Primary_Sales_Territory__c)){
                    primaryTerrMap.put(outTerrObj.Outlet__c,outTerrObj);
                }else{
                    auxTerrMap.put(outTerrObj.Outlet__c,outTerrObj);
                }
                outletMap.put(outTerrObj.Outlet__c, new Account(Id = outTerrObj.Outlet__c,
                                                                Fascia__c = outTerrObj.Outlet__r.Fascia__c,
                                                                Global_Segment__c = outTerrObj.Outlet__r.Global_Segment__c,
                                                                Global_Sub_Segment__c = outTerrObj.Outlet__r.Global_Sub_Segment__c,
                                                                Global_Channel__c = outTerrObj.Outlet__r.Global_Channel__c,
                                                                Market__c = outTerrObj.Outlet__r.Market__c,
                                                                Hub__c = outTerrObj.Outlet__r.Hub__c, 
                                                                Cluster__c = outTerrObj.Outlet__r.Cluster__c,
                                                                Country__c = outTerrObj.Outlet__r.Country__c,
                                                                Area__c = outTerrObj.Outlet__r.Area__c,
                                                                Region__c = outTerrObj.Outlet__r.Region__c,
                                                                Primary_Sales_Territory__c = outTerrObj.Outlet__r.Primary_Sales_Territory__c));
            }
        }
        System.debug('outletMap::'+outletMap);
        
        // Fetch Market Setting record for each Country ES20-9787
        List<Market_Setting__c> marketSettingRecords = [SELECT Include_Fascia_in_Opportunity_Generation__c,Geography__c,Geography__r.Code__c,language__c from Market_Setting__c WHERE Geography__c in :countrySet ] ;
        for(Market_Setting__c msr : marketSettingRecords ){
            if(!countryMarketMap.containsKey(msr.Geography__c)){
                countryMarketMap.put(msr.Geography__c, msr);
            }
            system.debug('@@countryMarketMap '+countryMarketMap);
        }
        
        //Fetching open opportunity List
        if(Schema.sObjectType.Opportunity.isAccessible()){
            openOppList = [SELECT Id, Product__c, AccountId, StageName, Type, Activation__c, Activation_Name__c,Source__c 
                           FROM Opportunity 
                           WHERE Source__c = :sourceTrax 
                           AND (Product__c IN : productSet OR Activation_Name__c LIKE : activationSet)
                           AND AccountId IN : outletIdSet
                           AND StageName IN('Open','Pending') 
                           AND Type IN('MAS','MPA','NPA','WPA')]; //ES20-13396 //155298 Adding Source as Trax
        }
        
        System.debug('@@openOppList' +openOppList);
        if(!openOppList.isEmpty()){
            for(Opportunity oppObj : openOppList){
                //Creating composite key
                if(String.isNotBlank(oppObj.Product__c)){
                    String cmpKey = String.valueOf(oppObj.Product__c) + String.valueOf(oppObj.AccountId) + String.valueOf(oppObj.Type);
                    openOppMap.put(cmpKey, oppObj);   
                }
                else if(String.isNotBlank(oppObj.Activation__c)){
                    String cmpActKey = String.valueOf(oppObj.Activation_Name__c) + String.valueOf(oppObj.AccountId) + String.valueOf(oppObj.Type);
                    openOppMap.put(cmpActKey, oppObj);
                }
            }
        }
        System.debug('openOppMap::'+openOppMap);
        
        //Fetching Opportunity Template list
        if(Schema.sObjectType.Opportunity_Template__c.isAccessible()){
            oppTemList = [SELECT Id, Action__c, Channel__c, Activation__c,Fascia__c,Fascia__r.Country__c, Activation_Name__c, Territory__c, Opportunity_Type__c, Cluster__c, Weight_Value__c,
                          End_Date__c, Product__c, Sub_Segment__c, Segment__c,Weight_Type__c, Multiply_By_Prioritisation__c,Area_Region__c,Source__c
                          FROM Opportunity_Template__c 
                          WHERE Source__c = :sourceTrax
                          AND Opportunity_Type__c IN ('MPA','MAS','NPA','WPA')//ES20-13396
                          AND (Product__c IN : productSet OR Activation_Name__c LIKE : activationSet)
                          AND (Start_Date__c <= TODAY AND (End_Date__c = NULL OR End_Date__c >= TODAY))
                          AND (Territory__c IN :territorySet
                               OR Segment__c IN :segmentSet 
                               OR Channel__c IN :channelSet
                               OR Sub_Segment__c IN :subSegmentSet
                               OR Fascia__c IN :fasciaSet
                               OR Territory__c =: NULL
                               OR Segment__c IN :NULL 
                               OR Channel__c IN :NULL
                               OR Sub_Segment__c IN :NULL
                               OR Fascia__c IN :NULL
                              )
                          AND ( Cluster__c IN :marketSet 
                               OR Cluster__c IN :hubSet
                               OR Cluster__c IN :countrySet
                               OR Cluster__c IN :clusterSet 
                               OR Area_Region__c IN :areaSet
                               OR Area_Region__c IN :regionSet
                              ) 
                          
                         ];//155298 Adding Source as Trax
        }
        System.debug('oppTemList::'+oppTemList);
        
        
        //Get Template Weighing - Add Opportunity Template Filter
        if(Schema.sObjectType.Template_Weighing__c.isAccessible()){
            List<Template_Weighing__c> tmpltWelst = new List<Template_Weighing__c> ();
            tmpltWelst = [SELECT Id,Cluster__c,Country__c,Opportunity_Template__c,Sub_Segment__c,Weight__c 
                          FROM Template_Weighing__c 
                          WHERE Opportunity_Template__c IN : oppTemList];
            if(!tmpltWelst.isEmpty()){
                for(Template_Weighing__c weightObj : tmpltWelst){
                    String cmpKey = String.valueOf(weightObj.Sub_Segment__c) + String.valueOf(weightObj.Cluster__c) + String.valueOf(weightObj.Country__c) + String.valueOf(weightObj.Opportunity_Template__c);
                    templtWeiMap.put(cmpKey, weightObj);
                }
            }
        }
        
        //Creating Opportunity Tempalte Map
        if(!oppTemList.isEmpty()){
            for(Opportunity_Template__c oppTempObj : oppTemList){
                
                // Check for Fascia Combination ES20-9787
                if(	 countryMarketMap.get(oppTempObj.Fascia__r.Country__c) != null 
                   && countryMarketMap.get(oppTempObj.Fascia__r.Country__c).Include_Fascia_in_Opportunity_Generation__c){
                       
                       if(String.isNotBlank(oppTempObj.Fascia__c) && String.isNotBlank(oppTempObj.Fascia__r.Country__c))
                       {
                           if(String.isNotBlank(oppTempObj.Product__c)){
                               String faciaKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Fascia__c) + String.valueOf(oppTempObj.Product__c);
                               if(oppTemplateMap.containsKey(faciaKey)) {
                                   List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(faciaKey);
                                   opprTempList.add(oppTempObj);
                                   oppTemplateMap.put(faciaKey, opprTempList);
                               } else {
                                   oppTemplateMap.put(faciaKey, new List<Opportunity_Template__c> { oppTempObj });
                               }
                           }
                           else if(String.isNotBlank(oppTempObj.Activation__c)){
                               String faciaActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Fascia__c) + String.valueOf(oppTempObj.Activation_Name__c);
                               if(oppTemplateActivationMap.containsKey(faciaActKey)) {
                                   List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(faciaActKey);
                                   opprTempList.add(oppTempObj);
                                   oppTemplateActivationMap.put(faciaActKey, opprTempList);
                               } else {
                                   oppTemplateActivationMap.put(faciaActKey, new List<Opportunity_Template__c> { oppTempObj });
                               }
                           } system.debug('@@oppTemplateMap '+oppTemplateMap);
                       }
                   }
                
                
                else if( (String.isBlank(oppTempObj.Fascia__c) || oppTempObj.Fascia__c == null)
                        || (countryMarketMap.get(oppTempObj.Fascia__r.Country__c) != null && countryMarketMap.get(oppTempObj.Fascia__r.Country__c).Include_Fascia_in_Opportunity_Generation__c)){
                            //Check for Sub Segment & Territory Combination
                            if(String.isNotBlank(oppTempObj.Sub_Segment__c) && (String.isNotBlank(oppTempObj.Territory__c))){
                                if(String.isNotBlank(oppTempObj.Product__c)){
                                    String subSegTerrKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Sub_Segment__c) + String.valueOf(oppTempObj.Territory__c) + String.valueOf(oppTempObj.Product__c);
                                    if(oppTemplateMap.containsKey(subSegTerrKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(subSegTerrKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateMap.put(subSegTerrKey, opprTempList);
                                    } else {
                                        oppTemplateMap.put(subSegTerrKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }                        
                                }
                                
                                else if(String.isNotBlank(oppTempObj.Activation__c)){
                                    String subSegTerrActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Sub_Segment__c) + String.valueOf(oppTempObj.Territory__c) + String.valueOf(oppTempObj.Activation_Name__c);
                                    if(oppTemplateActivationMap.containsKey(subSegTerrActKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(subSegTerrActKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateActivationMap.put(subSegTerrActKey, opprTempList);
                                    } else {
                                        oppTemplateActivationMap.put(subSegTerrActKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }
                                }
                            }
                            
                            //Check for Sub Segment Combination
                            else if(String.isNotBlank(oppTempObj.Sub_Segment__c)){
                                if(String.isNotBlank(oppTempObj.Product__c)){
                                    String subSegKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Sub_Segment__c) + String.valueOf(oppTempObj.Product__c);
                                    if(oppTemplateMap.containsKey(subSegKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(subSegKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateMap.put(subSegKey, opprTempList);
                                    } else {
                                        System.debug('In');
                                        oppTemplateMap.put(subSegKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }
                                }
                                else if(String.isNotBlank(oppTempObj.Activation__c)){
                                    String subSegActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Sub_Segment__c) + String.valueOf(oppTempObj.Activation_Name__c);
                                    if(oppTemplateActivationMap.containsKey(subSegActKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(subSegActKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateActivationMap.put(subSegActKey, opprTempList);
                                    } else {
                                        oppTemplateActivationMap.put(subSegActKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }
                                }
                            }
                            
                            //Check for Segment & Territory Combination
                            else if(String.isNotBlank(oppTempObj.Segment__c) && String.isNotBlank(oppTempObj.Territory__c)){
                                
                                if(String.isNotBlank(oppTempObj.Product__c)){
                                    
                                    String segTerrKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Segment__c) + String.valueOf(oppTempObj.Territory__c)+String.valueOf(oppTempObj.Product__c);
                                    if(oppTemplateMap.containsKey(segTerrKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(segTerrKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateMap.put(segTerrKey, opprTempList);
                                    } else {
                                        oppTemplateMap.put(segTerrKey, new List<Opportunity_Template__c> { oppTempObj });
                                    } 
                                }
                                else if(String.isNotBlank(oppTempObj.Activation__c)){
                                    String segTerrActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Segment__c) + String.valueOf(oppTempObj.Territory__c)+String.valueOf(oppTempObj.Activation_Name__c);
                                    if(oppTemplateActivationMap.containsKey(segTerrActKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(segTerrActKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateActivationMap.put(segTerrActKey, opprTempList);
                                    } else {
                                        oppTemplateActivationMap.put(segTerrActKey, new List<Opportunity_Template__c> { oppTempObj });
                                    } 
                                } 
                            }
                            
                            //Check for Segment Combination
                            else if(String.isNotBlank(oppTempObj.Segment__c)){
                                if(String.isNotBlank(oppTempObj.Product__c)){
                                    String segmentKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Segment__c) + String.valueOf(oppTempObj.Product__c);
                                    if(oppTemplateMap.containsKey(segmentKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(segmentKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateMap.put(segmentKey, opprTempList);
                                    } else {
                                        oppTemplateMap.put(segmentKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }
                                }
                                else if(String.isNotBlank(oppTempObj.Activation__c)){
                                    String segmentActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Segment__c) + String.valueOf(oppTempObj.Activation_Name__c);
                                    if(oppTemplateActivationMap.containsKey(segmentActKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(segmentActKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateActivationMap.put(segmentActKey, opprTempList);
                                    } else {
                                        oppTemplateActivationMap.put(segmentActKey, new List<Opportunity_Template__c> { oppTempObj });
                                    } 
                                }
                            }
                            
                            //Check for Channel & Territory Combination
                            else if(String.isNotBlank(oppTempObj.Channel__c) && (String.isNotBlank(oppTempObj.Territory__c))){
                                if(String.isNotBlank(oppTempObj.Product__c)){
                                    String chnlTerrKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Channel__c) + String.valueOf(oppTempObj.Territory__c) + String.valueOf(oppTempObj.Product__c);
                                    if(oppTemplateMap.containsKey(chnlTerrKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(chnlTerrKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateMap.put(chnlTerrKey, opprTempList);
                                    } else {
                                        oppTemplateMap.put(chnlTerrKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }
                                }
                                else if(String.isNotBlank(oppTempObj.Activation__c)){
                                    String chnlTerrActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Channel__c) + String.valueOf(oppTempObj.Territory__c) + String.valueOf(oppTempObj.Activation_Name__c);
                                    if(oppTemplateActivationMap.containsKey(chnlTerrActKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(chnlTerrActKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateActivationMap.put(chnlTerrActKey, opprTempList);
                                    } else {
                                        oppTemplateActivationMap.put(chnlTerrActKey, new List<Opportunity_Template__c> { oppTempObj });
                                    } 
                                }
                            }
                            
                            //Check for Territory Combination
                            else if(String.isNotBlank(oppTempObj.Territory__c)){
                                if(String.isNotBlank(oppTempObj.Product__c)){
                                    String terrKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Territory__c) + String.valueOf(oppTempObj.Product__c);
                                    if(oppTemplateMap.containsKey(terrKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(terrKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateMap.put(terrKey, opprTempList);
                                    } else {
                                        oppTemplateMap.put(terrKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }
                                }
                                else if(String.isNotBlank(oppTempObj.Activation__c)){
                                    String terrActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Territory__c) + String.valueOf(oppTempObj.Activation_Name__c);
                                    if(oppTemplateActivationMap.containsKey(terrActKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(terrActKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateActivationMap.put(terrActKey, opprTempList);
                                    } else {
                                        oppTemplateActivationMap.put(terrActKey, new List<Opportunity_Template__c> { oppTempObj });
                                    } 
                                }
                            }       
                            
                            //Check for Channel Combination
                            else if(String.isNotBlank(oppTempObj.Channel__c)){
                                if(String.isNotBlank(oppTempObj.Product__c)){
                                    String chnnlKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Channel__c) + String.valueOf(oppTempObj.Product__c);
                                    if(oppTemplateMap.containsKey(chnnlKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(chnnlKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateMap.put(chnnlKey, opprTempList);
                                    } else {
                                        oppTemplateMap.put(chnnlKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }  
                                }
                                else if(String.isNotBlank(oppTempObj.Activation__c)){
                                    String chnlActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Channel__c) + String.valueOf(oppTempObj.Activation_Name__c);
                                    if(oppTemplateActivationMap.containsKey(chnlActKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(chnlActKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateActivationMap.put(chnlActKey, opprTempList);
                                    } else {
                                        oppTemplateActivationMap.put(chnlActKey, new List<Opportunity_Template__c> { oppTempObj });
                                    } 
                                }
                            }
                            
                            //Check for Area/Region and Country Combination
                            else if(String.isNotBlank(oppTempObj.Area_Region__c) && String.isNotBlank(oppTempObj.Cluster__c)){
                                system.debug('--In loop---'+oppTempObj.Area_Region__c);
                                if(String.isNotBlank(oppTempObj.Product__c)){
                                    String areaRegionCountryKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Area_Region__c) + String.valueOf(oppTempObj.Cluster__c) + String.valueOf(oppTempObj.Product__c);
                                    if(oppTemplateMap.containsKey(areaRegionCountryKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(areaRegionCountryKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateMap.put(areaRegionCountryKey, opprTempList);
                                    } else {
                                        oppTemplateMap.put(areaRegionCountryKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }  
                                    
                                    System.debug('@@oppTemplateMap' +oppTemplateMap);                        
                                }
                                else if(String.isNotBlank(oppTempObj.Activation__c)){
                                    String areaRegionCountryActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Area_Region__c) + String.valueOf(oppTempObj.Cluster__c) + String.valueOf(oppTempObj.Activation_Name__c);
                                    if(oppTemplateActivationMap.containsKey(areaRegionCountryActKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(areaRegionCountryActKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateActivationMap.put(areaRegionCountryActKey, opprTempList);
                                    } else {
                                        oppTemplateActivationMap.put(areaRegionCountryActKey, new List<Opportunity_Template__c> { oppTempObj });
                                    } 
                                }
                            }
                            
                            //Check for Country/Cluster/Hub/Market Combination
                            else if(String.isNotBlank(oppTempObj.Cluster__c)){
                                system.debug('Inside Cluster');
                                if(String.isNotBlank(oppTempObj.Product__c)){
                                    String clstrKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Cluster__c) + String.valueOf(oppTempObj.Product__c);
                                    if(oppTemplateMap.containsKey(clstrKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateMap.get(clstrKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateMap.put(clstrKey, opprTempList);
                                    } else {
                                        oppTemplateMap.put(clstrKey, new List<Opportunity_Template__c> { oppTempObj });
                                    }  
                                }
                                else if(String.isNotBlank(oppTempObj.Activation__c)){
                                    String clstrKeyActKey = String.valueOf(oppTempObj.Opportunity_Type__c) + String.valueOf(oppTempObj.Cluster__c) + String.valueOf(oppTempObj.Activation_Name__c);
                                    if(oppTemplateActivationMap.containsKey(clstrKeyActKey)) {
                                        List<Opportunity_Template__c> opprTempList = oppTemplateActivationMap.get(clstrKeyActKey);
                                        opprTempList.add(oppTempObj);
                                        oppTemplateActivationMap.put(clstrKeyActKey, opprTempList);
                                    } else {
                                        oppTemplateActivationMap.put(clstrKeyActKey, new List<Opportunity_Template__c> { oppTempObj });
                                    } 
                                }
                            }  
                        }
                
            }
        }
        
        System.debug('oppTemplateActivationMap::'+oppTemplateActivationMap);
        System.debug('oppTemplateMap::'+oppTemplateMap);
        
        //Create Pickup Option Name Map
        Map<String,String> pickUpOptionActivationMap =  new Map<String,String>();
        for(Pick_Up_Options__c pcoptnObj : [Select Id,Type__c,Name from Pick_Up_Options__c where Type__c ='MAS' and Status__c='Active'] ){
            String tempString = pcoptnObj.Name;
            String subString = tempString.substringBefore('[').trim();
            pickUpOptionActivationMap.put(subString, pcoptnObj.Id);
        }
        
        System.debug('pickUpOptionActivationMap::'+pickUpOptionActivationMap);
        
        //Loop through Outlet Execution
        for(Outlet_Execution__c execuObj : outExeList){
                Map<String,String> oppKPIMap=new Map<String,String>{'MAS'=>'MAS__c','MPA'=>'MPA__c','NPA'=>'NPA__c','WPA'=>'Distribution_TRAX__c'};//ES20-13396
                for(String oppKPIType:oppKPIMap.keySet()){
                    Decimal multiplier, tempWeight;
                    String oppType, terriId, oppMASCmpKey;
                    Opportunity_Template__c oppTemplateObj;
                    Opportunity_Template__c oppTemplateActObj;
                    if((oldOutletExeMap != null && oldOutletExeMap.get(execuObj.Id).get(oppKPIMap.get(oppKPIType)) != 'No' && execuObj.get(oppKPIMap.get(oppKPIType)) == 'No')
                       || (oldOutletExeMap == null && execuObj.get(oppKPIMap.get(oppKPIType)) == 'No')){
                           
                           oppType = oppKPIType;
                           //Creating key to check whether any open opp exist or not
                           if(String.isNotBlank(execuObj.Product__c)){
                               oppMASCmpKey = String.valueOf(execuObj.Product__c) + String.valueOf(execuObj.Outlet__c) + String.valueOf(oppType);
                           }
                           else if(String.isNotBlank(execuObj.Activation_Reference__c)){
                               oppMASCmpKey = String.valueOf(execuObj.Activation_Reference__c) + String.valueOf(execuObj.Outlet__c) + String.valueOf(oppType);
                           }
                           System.debug('--oppMASCmpKey--'+oppMASCmpKey);
                           //Added OR condition for ES20-6532. It will now consider the existing opportunity also 
                           //so that we can update the Opportunity Template of an Opportunity
                           if(openOppMap!= null && (!openOppMap.containsKey(oppMASCmpKey) || (isTemplateUpdateOnOpp && openOppMap.containsKey(oppMASCmpKey)))){
                               System.debug('--inside openOppMap check--');
                               System.debug('--primaryTerrMap--'+primaryTerrMap);
                               //Get Opportunity Template for Primary Territory
                               if(primaryTerrMap!= null && primaryTerrMap.containsKey(execuObj.Outlet__c)){
                                   Decimal multiplierTemp = primaryTerrMap.get(execuObj.Outlet__c).Outlet__r.Outlet_Visit_Prioritisation_Grade__r.value__c;
                                   multiplier = multiplierTemp!= null ? multiplierTemp : 0;
                                   //Get Opportunity Template
                                   if(String.isNotBlank(execuObj.Product__c)){
                                       oppTemplateObj = getOppTemplate(oppTemplateMap, null, outletMap.get(execuObj.Outlet__c), null, execuObj, oppType, null);   
                                   }
                                   else if(String.isNotBlank(execuObj.Activation_Reference__c)){
                                       System.debug('--Activation_Reference__c--'+execuObj.Activation_Reference__c);
                                       
                                       String pickupId = pickUpOptionActivationMap.get(execuObj.Activation_Reference__c);
                                       System.debug('--pickupId--'+pickupId);
                                       
                                       oppTemplateActObj = getOppTemplate(null, oppTemplateActivationMap, outletMap.get(execuObj.Outlet__c), null, execuObj, oppType, pickupId);
                                   }
                                   
                                   //Get Opportunity Template Weighing if Opp Template found
                                   if(oppTemplateObj!= null){
                                       tempWeight = getTempWeight(primaryTerrMap, templtWeiMap, execuObj.Outlet__c, oppTemplateObj.Id);
                                   }
                                   if(oppTemplateActObj!= null){
                                       tempWeight = getTempWeight(primaryTerrMap, templtWeiMap, execuObj.Outlet__c, oppTemplateActObj.Id);
                                   }
                               }
                               ////Get Opportunity Template for Secondary Territory
                               else if (auxTerrMap!= null && auxTerrMap.containsKey(execuObj.Outlet__c)){
                                   Decimal multiplierTemp = auxTerrMap.get(execuObj.Outlet__c).Outlet__r.Outlet_Visit_Prioritisation_Grade__r.value__c;
                                   multiplier = multiplierTemp!= null ? multiplierTemp : 0;
                                   terriId = auxTerrMap.get(execuObj.Outlet__c).Territory__c;
                                   if(String.isNotBlank(execuObj.Product__c)){
                                       oppTemplateObj = getOppTemplate(oppTemplateMap, null, outletMap.get(execuObj.Outlet__c), terriId, execuObj, oppType, null);
                                   }
                                   else if(String.isNotBlank(execuObj.Activation_Reference__c)){
                                       String pickupId = pickUpOptionActivationMap.get(execuObj.Activation_Reference__c);
                                       oppTemplateActObj = getOppTemplate(null, oppTemplateActivationMap, outletMap.get(execuObj.Outlet__c), terriId, execuObj, oppType, pickupId);  
                                   }
                                   
                                   //Get Opportunity Template Weighing if Opp Template found
                                   if(oppTemplateObj!= null){
                                       tempWeight = getTempWeight(auxTerrMap, templtWeiMap, execuObj.Outlet__c, oppTemplateObj.Id);
                                   }
                                   if(oppTemplateActObj!= null){
                                       tempWeight = getTempWeight(auxTerrMap, templtWeiMap, execuObj.Outlet__c, oppTemplateActObj.Id);
                                   }
                               }
                               
                               //Create Product Opportunity
                               System.debug('--oppTemplateObj--'+oppTemplateObj);
                               if(oppTemplateObj != null){
                                   Opportunity opp;
     
                                   //Added IF/ELSE condition for ES20-6532, so that we can pass opportunity id if open opportunity exists 
                                   if(openOppMap.containsKey(oppMASCmpKey)){
                                       opp = createOppRecord(execuObj, oppTemplateObj, oppType, multiplier, tempWeight, null, openOppMap.get(oppMASCmpKey).Id);                                       
                                   } else {
                                       opp = createOppRecord(execuObj, oppTemplateObj, oppType, multiplier, tempWeight, null, null);                                       
                                   }                                   
                                   oppInsertList.add(opp);
                               }
                               System.debug('--oppTemplateActObj--'+oppTemplateActObj);
                               //Create Activation Opportunity
                               if(oppTemplateActObj !=null){
                                   String pickupId = pickUpOptionActivationMap.get(execuObj.Activation_Reference__c);
                                   Opportunity opp;
                                   //Added IF/ELSE condition for ES20-6532, so that we can pass opportunity id if open opportunity exists
                                   if(openOppMap.containsKey(oppMASCmpKey)){
                                       opp = createOppRecord(execuObj, oppTemplateActObj, oppType, multiplier, tempWeight, pickupId, openOppMap.get(oppMASCmpKey).Id);                                       
                                   } else {
                                       opp = createOppRecord(execuObj, oppTemplateActObj, oppType, multiplier, tempWeight, pickupId, null);                                       
                                   }
                                   oppInsertList.add(opp);
                               }
                           }
                       }
                }
        }
        System.debug('@@oppInsertList' +oppInsertList);
        if(!oppInsertList.isEmpty() && Schema.sObjectType.Opportunity.isCreateable() && Schema.sObjectType.Opportunity.isUpdateable()){
            try{
                system.debug('--opportunityList---'+oppInsertList);
                upsert oppInsertList;
                //insert oppInsertList;
            }catch(Exception ex){ 
                system.debug('@@ex' +ex);
                system.debug('@@ex Messsage ' +ex.getMessage());
                if(!System.isBatch())
                {
                    List<Outlet_Execution__c> oeList = newItems.values();
                    new EDGE_GenericException(ex, oeList[0]);  
                }
                else{
                    /*List<Database.UpsertResult> upResults =*/ Database.upsert(oppInsertList,false);
                   /* for(Database.UpsertResult upsertResult : upResults){
                        if(!upsertResult.isSuccess()){
                            System.debug('Opportunity Upsert Id : ' + upsertResult.getId());
                            System.debug('Opportunity Upsert Error : ' + upsertResult.getErrors());
                        }
                    }*/
                    
                }
                
            }
        }
    }
/**    
* @description: the below method finds Opportunity Template. . 
* @return: void
**/
    public static Opportunity_Template__c getOppTemplate(Map<String,List<Opportunity_Template__c>> oppTemplateMap, Map<String,List<Opportunity_Template__c>> oppTemplateActivationMap, Account accObjVal, String terriId, Outlet_Execution__c execuObj, String oppType, String pickUpId ){
        String terriVal;
        String cmpKey;
        string cmpKey1;
        Id productId = execuObj.Product__c;
        List<Opportunity_Template__c> opptyTempList;
        Opportunity_Template__c opptyTemplateFetch;
        
        if(terriId == null){
            terriVal = accObjVal.Primary_Sales_Territory__c;
        }else{
            terriVal = terriId;
        }
        System.debug('@@oppTemplateMap' +oppTemplateMap);
        System.debug('@@oppTemplateActivationMap' +oppTemplateActivationMap);
        
        // Fetching Fascia Template ES20-9787
        if(String.isNotBlank(accObjVal.Fascia__c) ){
            if(execuObj.Product__c != null){
                cmpKey1 = oppType + String.valueOf(accObjVal.Fascia__c) + productId;
                System.debug('Key@@'+cmpKey1);
                if (!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }     
            else if(execuObj.Activation_Reference__c != null){
                cmpKey1 = oppType + String.valueOf(accObjVal.Fascia__c) + execuObj.Activation_Reference__c;
                System.debug('@@cmpKey1' +cmpKey1);
                if (!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }
        } 
        
        //Fetching Sub-Segment Template
        if(String.isNotBlank(accObjVal.Global_Sub_Segment__c)){
            if(execuObj.Product__c != null){
                cmpKey = oppType + String.valueOf(accObjVal.Global_Sub_Segment__c) + terriVal + productId;
                cmpKey1 = oppType + String.valueOf(accObjVal.Global_Sub_Segment__c) + productId;
                
                if(!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }     
            else if(execuObj.Activation_Reference__c != null){
                cmpKey = oppType + String.valueOf(accObjVal.Global_Sub_Segment__c) + terriVal + execuObj.Activation_Reference__c;
                cmpKey1 = oppType + String.valueOf(accObjVal.Global_Sub_Segment__c) + execuObj.Activation_Reference__c;
                System.debug('@@cmpKey' +cmpKey);
                System.debug('@@cmpKey1' +cmpKey1);
                if(!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }
        } 
        
        //Fetching Segment Template
        if(String.isNotBlank(accObjVal.Global_Segment__c)){
            if(execuObj.Product__c!=null){
                cmpKey = oppType + String.valueOf(accObjVal.Global_Segment__c) + terriVal + productId;
                cmpKey1 = oppType + String.valueOf(accObjVal.Global_Segment__c) + productId; 
                if(!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }
            else if(execuObj.Activation_Reference__c!=null){
                cmpKey = oppType + String.valueOf(accObjVal.Global_Segment__c) + terriVal + execuObj.Activation_Reference__c;
                cmpKey1 = oppType + String.valueOf(accObjVal.Global_Segment__c) + execuObj.Activation_Reference__c;
                System.debug('@@cmpKey' +cmpKey);
                System.debug('@@cmpKey1' +cmpKey1);
                if(!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }
        }
        
        //Fetching Channel Template
        if(String.isNotBlank(accObjVal.Global_Channel__c)){
            if(execuObj.Product__c!=null){
                cmpKey = oppType + String.valueOf(accObjVal.Global_Channel__c) + terriVal + productId;
                cmpKey1 = oppType + terriVal + productId;
                string cmpKey2 = oppType + String.valueOf(accObjVal.Global_Channel__c) + productId;
                if(!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey2)){
                    opptyTempList = oppTemplateMap.get(cmpKey2);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }
            else if(execuObj.Activation_Reference__c!=null){
                cmpKey = oppType + String.valueOf(accObjVal.Global_Channel__c) + terriVal + execuObj.Activation_Reference__c;
                cmpKey1 = oppType + terriVal + execuObj.Activation_Reference__c;
                string cmpKey2 = oppType + String.valueOf(accObjVal.Global_Channel__c) + execuObj.Activation_Reference__c; 
                System.debug('@@cmpKey' +cmpKey);
                System.debug('@@cmpKey1' +cmpKey1);
                System.debug('@@cmpKey2' +cmpKey2);
                if(!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey1)){
                    system.debug('@@cmpKey1' + cmpKey1 + '::'+ '@@oppTemplateActivationMap' + oppTemplateActivationMap.get(cmpKey1));
                    opptyTempList = oppTemplateActivationMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey2)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey2);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }
        } 
        
        //Fetching Area/Region Template
        if(String.isNotBlank(accObjVal.Region__c) && String.isNotBlank(accObjVal.Area__c) && String.isNotBlank(accObjVal.Country__c)){
            if(execuObj.Product__c != null){
                cmpKey = oppType + String.valueOf(accObjVal.Region__c) + String.valueOf(accObjVal.Country__c) + productId;
                cmpKey1 = oppType + String.valueOf(accObjVal.Area__c) + String.valueOf(accObjVal.Country__c) + productId;
                System.debug('@@cmpKey' +cmpKey);
                System.debug('@@cmpKey1' +cmpKey1);
                if(!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }     
            else if(execuObj.Activation_Reference__c != null){
                System.debug('@@cmpKey' +cmpKey);
                System.debug('@@cmpKey1' +cmpKey1);
                cmpKey = oppType + String.valueOf(accObjVal.Region__c) + String.valueOf(accObjVal.Country__c) + execuObj.Activation_Reference__c;
                cmpKey1 = oppType + String.valueOf(accObjVal.Area__c) + String.valueOf(accObjVal.Country__c) + execuObj.Activation_Reference__c;
                if(!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }
        }
        
        //Fetching Market/Hub/Cluster/Country Template
        if(String.isNotBlank(accObjVal.Market__c) && String.isNotBlank(accObjVal.Hub__c) &&
           String.isNotBlank(accObjVal.Cluster__c) && String.isNotBlank(accObjVal.Country__c))
        {
            if(execuObj.Product__c != null){
                cmpKey = oppType + String.valueOf(accObjVal.Country__c) + productId;
                cmpKey1 = oppType + String.valueOf(accObjVal.Cluster__c) + productId;
                String cmpKey2 = oppType + String.valueOf(accObjVal.Hub__c) + productId;
                String cmpKey3 = oppType + String.valueOf(accObjVal.Market__c) + productId;
                
                
                if(!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey2)){
                    opptyTempList = oppTemplateMap.get(cmpKey2);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateMap.isEmpty() && oppTemplateMap.containsKey(cmpKey3)){
                    opptyTempList = oppTemplateMap.get(cmpKey3);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }
            else if(execuObj.Activation_Reference__c != null){
                cmpKey = oppType + String.valueOf(accObjVal.Country__c) + execuObj.Activation_Reference__c;
                cmpKey1 = oppType + String.valueOf(accObjVal.Cluster__c) + execuObj.Activation_Reference__c;
                String cmpKey2 = oppType + String.valueOf(accObjVal.Hub__c) + execuObj.Activation_Reference__c;
                String cmpKey3 = oppType + String.valueOf(accObjVal.Market__c) + execuObj.Activation_Reference__c;
                System.debug('@@cmpKey' +cmpKey);
                System.debug('@@cmpKey1' +cmpKey1);
                System.debug('@@cmpKey2' +cmpKey2);
                System.debug('@@cmpKey3' +cmpKey3);
                if(!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey1)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey1);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey2)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey2);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }else if (!oppTemplateActivationMap.isEmpty() && oppTemplateActivationMap.containsKey(cmpKey3)){
                    opptyTempList = oppTemplateActivationMap.get(cmpKey3);
                    opptyTemplateFetch = geographyCheckInOpptyTemplateFetch(opptyTempList,accObjVal);
                    return opptyTemplateFetch;
                }
            }
        } 
        
        return null;
    }
/**    
* @description: the below method finds exact Opportunity Template matching further with Area/Region and Cluster field in Opportunity Template. 
* @return: void
* @Param : List<Opportunity_Template__c> , Account
**/
    public static Opportunity_Template__c geographyCheckInOpptyTemplateFetch(List<Opportunity_Template__c> opptyTempList,Account accObjVal){
        System.Debug('@@opptyTempList' +opptyTempList);
        String regionRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        String areaRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Area').getRecordTypeId();
        String countryRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Country').getRecordTypeId();
        String clusterRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Cluster').getRecordTypeId();
        String hubRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Hub').getRecordTypeId();
        String marketRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Market').getRecordTypeId();
        Set<String> optyTemplateClusterSet = new Set<String>();
        Set<String> optyTemplateAreaRegSet = new Set<String>();
        Map<String,String> geographyRecordMap = new Map<String,String>();
        Geography__c geoAreaRegObj;
        Geography__c geoClusterRegObj;
        
        if(opptyTempList!=null){
            for(Opportunity_Template__c opptyTempObj : opptyTempList){
                optyTemplateClusterSet.add(opptyTempObj.Cluster__c);
                optyTemplateAreaRegSet.add(opptyTempObj.Area_Region__c);
            }
        }
        
        if(optyTemplateClusterSet!=null && optyTemplateClusterSet.size()>0){
            for(Geography__c geoObj : [SELECT Id, RecordTypeId FROM Geography__c WHERE Id IN : optyTemplateClusterSet OR
                                       Id IN : optyTemplateAreaRegSet ]){
                                           geographyRecordMap.put(geoObj.Id,geoObj.RecordTypeId);
                                       }
        }
        
        if(opptyTempList!=null){
            for(Opportunity_Template__c opptyTempObj : opptyTempList){        
                if(!String.isBlank(opptyTempObj.Area_Region__c)){
                    geoAreaRegObj = new Geography__c(Id=opptyTempObj.Area_Region__c);   
                }
                if(!String.isBlank(opptyTempObj.Cluster__c)){
                    geoClusterRegObj = new Geography__c(Id=opptyTempObj.Cluster__c); 
                }
                
                if(!String.isBlank(opptyTempObj.Area_Region__c) && !String.isBlank(opptyTempObj.Cluster__c)){
                    if(geographyRecordMap!=null && geographyRecordMap.containsKey(geoAreaRegObj.Id) && geographyRecordMap.containsKey(geoClusterRegObj.Id)){        
                        if(geographyRecordMap.get(geoAreaRegObj.Id)== regionRecordTypeId && geographyRecordMap.get(geoClusterRegObj.Id) == countryRecordTypeId 
                           && accObjVal.Region__c==opptyTempObj.Area_Region__c && accObjVal.Country__c==opptyTempObj.Cluster__c)
                        {
                            return opptyTempObj;
                        }
                        else if(geographyRecordMap.get(geoAreaRegObj.Id) == areaRecordTypeId && geographyRecordMap.get(geoClusterRegObj.Id) == countryRecordTypeId
                                && accObjVal.Area__c==opptyTempObj.Area_Region__c && accObjVal.Country__c==opptyTempObj.Cluster__c)
                        {
                            return opptyTempObj;
                        }
                    }
                }
                
                else if(String.isBlank(opptyTempObj.Area_Region__c) && !String.isBlank(opptyTempObj.Cluster__c)){
                    if(geographyRecordMap!=null && geographyRecordMap.containsKey(geoClusterRegObj.Id)){   
                        if(geographyRecordMap.get(geoClusterRegObj.Id) == countryRecordTypeId && accObjVal.Country__c==opptyTempObj.Cluster__c){
                            return opptyTempObj;
                        }
                        else if(geographyRecordMap.get(geoClusterRegObj.Id) == clusterRecordTypeId && accObjVal.Cluster__c==opptyTempObj.Cluster__c){ 
                            return opptyTempObj; 
                        }
                        else if(geographyRecordMap.get(geoClusterRegObj.Id) == hubRecordTypeId && accObjVal.Hub__c==opptyTempObj.Cluster__c){ 
                            return opptyTempObj; 
                        }
                        else if(geographyRecordMap.get(geoClusterRegObj.Id) == marketRecordTypeId && accObjVal.Market__c==opptyTempObj.Cluster__c){
                            return opptyTempObj; 
                        }
                    }
                }
            }
        }
        return null;
    } 
/**    
* @description: the below method creates Opportunity Instances.
* @return: void
* @Param : Opportunity_Template__c , Outlet_Execution__c,String , Decimal , String
**/
    public static Opportunity createOppRecord(Outlet_Execution__c execObj, Opportunity_Template__c optyTempObj, String oppType, Decimal multiplier, Decimal tempWeight, String activationId, Id opportunityId){
        system.debug('@@activationId' + activationId);
        Opportunity oppObj;
        
        //Added IF/ELSE condition for ES20-6532, so that we can update opportunity details of open opportunity
        if(String.isNotBlank(opportunityId)){
            oppObj = new Opportunity(Id = opportunityId);            
        } else {
            oppObj = new Opportunity();
        }
        
        oppObj.AccountId = execObj.Outlet__c;
        oppObj.Opportunity_Template__c = optyTempObj.Id;
        oppObj.Name = String.valueOf(optyTempObj.Opportunity_Type__c) + '-' + String.valueOf(optyTempObj.Action__c);
        oppObj.Source__c = sourceTrax; //155298 Adding Source as Trax
        if(optyTempObj.End_Date__c != null && optyTempObj.End_Date__c > Date.today()){
            oppObj.CloseDate =  optyTempObj.End_Date__c;
        }else{
            oppObj.CloseDate = Date.today().addYears(1);
        }
        oppObj.Product__c = execObj.Product__c; 
        oppObj.Activation__c = activationId; 
        oppObj.Type = oppType;
        oppObj.StageName = 'Open';
        oppObj.Outlet_Execution__c = execObj.Id;
        oppObj.Weight_Method__c = optyTempObj.Weight_Type__c;
        
        if(optyTempObj.Weight_Type__c == 'Manual Value'){
            oppObj.Commentary__c = (String.isNotBlank(execObj.Commentary__c)) ? execObj.Commentary__c :'';
            if(!optyTempObj.Multiply_By_Prioritisation__c){
                oppObj.Weight_Value__c = optyTempObj.Weight_Value__c != null ? optyTempObj.Weight_Value__c : 0;    
            }
            else if(optyTempObj.Multiply_By_Prioritisation__c){
                oppObj.Weight_Value__c = optyTempObj.Weight_Value__c != null ? optyTempObj.Weight_Value__c* multiplier : 0;  
            }
        }else if (optyTempObj.Weight_Type__c == 'MAS or MPA Weight' ){
            oppObj.Commentary__c = (String.isNotBlank(execObj.Commentary__c)) ? execObj.Commentary__c :'';
            if(!optyTempObj.Multiply_By_Prioritisation__c){
                oppObj.Weight_Value__c = tempWeight;   
            }
            else if(optyTempObj.Multiply_By_Prioritisation__c){
                oppObj.Weight_Value__c = tempWeight * multiplier;   
            }
        }
        else if(optyTempObj.Weight_Type__c == 'Advanced Analytics based weight'){
            oppObj.Weight_Value__c = execObj.Predicted_RSV__c !=null? execObj.Predicted_RSV__c :0;
            oppObj.Commentary__c = (String.isNotBlank(execObj.Commentary__c)) ? execObj.Commentary__c :'';
        }
        else if(optyTempObj.Weight_Type__c == 'Always on Top'){
            oppObj.Commentary__c = (String.isNotBlank(execObj.Commentary__c)) ? execObj.Commentary__c :''; 
        }
        return  oppObj;
    }
/**    
* @description: to close opportunity as per TRAX response 
* @return: void
* @Param : Map<Id, SObject>
**/
    public static void closeOpportunity(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set<Id> outletIdSet = new Set<Id>();
        Set<String> productIdSet = new Set<String>();
        Set<String> activationSet = new Set<String>();
        Set<String> outletExKpiString = new Set<String>(); 
        //List<Opportunity> opportunityList = new List<Opportunity>();
        //List<Opportunity> opportunityActivationList = new List<Opportunity>();
        List<Opportunity> opportunityUpdateList = new List<Opportunity>();
        //155304
        Map<String,List<Opportunity>> existingOpportunityMap = new Map<String,List<Opportunity>>();
        
        
        
        for(SObject sob : newItems.values()){
            Outlet_Execution__c outletEx = (Outlet_Execution__c)sob;
            outletIdSet.add(outletEx.Outlet__c); 
            productIdSet.add(outletEx.Product__c);
            activationSet.add(outletEx.Activation_Reference__c);
            //155304 - created for PMD resolution
            outletExKpiString.addAll(updateKpiString(outletEx));
        }
        
        //Get Opportunity
        //if(activationSet.size() > 0 || productIdSet.size() > 0){
        // opportunityList = ; 
        
        // if(opportunityList.size()>0){
        
        //155298 Adding Source as Trax
        //155304 - update the query
        existingOpportunityMap = getOpenOpportunity(outletIdSet,productIdSet,activationSet);
        
        for(String str : outletExKpiString){
            //155304 - condition update
            if(existingOpportunityMap.containsKey(str)){
                //existingOpportunityMap.get(str).StageName = 'Closed';
                opportunityUpdateList.addAll(closeOpportunityMethod(existingOpportunityMap.get(str)));
            }
        }
        //}
        
        //update the opportunity List
        if(!opportunityUpdateList.isEmpty() && Schema.sObjectType.Opportunity.isUpdateable()){
            update opportunityUpdateList ;
        }           
        //}
        
    }
    //155304 - created for PMD resolution
    public static Map<String,List<Opportunity>> getOpenOpportunity(Set<Id> outletIdSet, Set<String> productIdSet, Set<String> activationSet){
        Map<String,List<Opportunity>> existingOpportunityMap = new Map<String,List<Opportunity>>();
        List<String> oppTemplateSource = System.Label.EDGE_CloseOpp_OppTemp_Source.split(',');
        
        for(Opportunity opp : [SELECT Id, Product__c, AccountId, StageName, Type, Activation__c, Activation_Name__c, Source__c 
                               FROM Opportunity 
                               WHERE Source__c IN : oppTemplateSource 
                               AND (Product__c IN : productIdSet OR Activation_Name__c LIKE : activationSet)
                               AND AccountId IN : outletIdSet
                               AND StageName NOT IN ('Closed','Expired')]){
                                   if(opp.Activation__c != null){
                                       String keyActivationString = String.valueOf(opp.AccountId) + '_' + String.valueOf(opp.Activation_Name__c) + '_' + opp.Type;
                                       //existingOpportunityMap.put(keyActivationString, opp);
                                       if(!existingOpportunityMap.containsKey(keyActivationString)){
                                           existingOpportunityMap.put(keyActivationString,new List<Opportunity>{opp});
                                       }else{
                                           existingOpportunityMap.get(keyActivationString).add(opp);
                                       }
                                   }
                                   else if(opp.Product__c !=null){
                                       String keyString = String.valueOf(opp.AccountId) + '_' + String.valueOf(opp.Product__c) + '_' + opp.Type;
                                       //existingOpportunityMap.put(keyString, opp);
                                       if(!existingOpportunityMap.containsKey(keyString)){
                                           existingOpportunityMap.put(keyString,new List<Opportunity>{opp});
                                       }else{
                                           existingOpportunityMap.get(keyString).add(opp);
                                       }
                                   }
                               }
        return existingOpportunityMap;
    }
    //155304 - created for PMD resolution
    public static Set<String> updateKpiString(Outlet_Execution__c outletEx){
        Set<String> outletExKpiString = new Set<String>();
        
        if(isStringNotBlankMPA(outletEx)){
            outletExKpiString.add(String.valueOf(outletEx.Outlet__c) +'_' + String.valueOf(outletEx.Product__c) + '_' + 'MPA');
        }
        
        if(isStringNotBlankNPA(outletEx)){
            outletExKpiString.add(String.valueOf(outletEx.Outlet__c) + '_' + String.valueOf(outletEx.Product__c) + '_' + 'NPA');
        }
        if(isStringNotBlankMAS(outletEx)){
            outletExKpiString.add(String.valueOf(outletEx.Outlet__c) + '_' + String.valueOf(outletEx.Activation_Reference__c) + '_' + 'MAS');
        }
        //ES20-13397
        if(isStringNotBlankTrax(outletEx)){
            outletExKpiString.add(String.valueOf(outletEx.Outlet__c) + '_' + String.valueOf(outletEx.Product__c) + '_' + 'WPA');
        }
        return outletExKpiString;
    }
    
    //155304 - created for PMD resolution
    public static Boolean isStringNotBlankMPA(Outlet_Execution__c outletEx){
        return (String.isNotBlank(outletEx.Product__c) && String.isNotBlank(outletEx.Outlet__c) && String.isNotBlank(outletEx.MPA__c) && outletEx.MPA__c == 'Yes');
    }
    
    //155304 - created for PMD resolution
    public static Boolean isStringNotBlankNPA(Outlet_Execution__c outletEx){
        return (String.isNotBlank(outletEx.Product__c) && String.isNotBlank(outletEx.Outlet__c) && String.isNotBlank(outletEx.NPA__c) && outletEx.NPA__c == 'Yes');
    }
    
    //155304 - created for PMD resolution
     public static Boolean isStringNotBlankMAS(Outlet_Execution__c outletEx){
        return (String.isNotBlank(outletEx.Activation_Reference__c) && String.isNotBlank(outletEx.Outlet__c) && String.isNotBlank(outletEx.MAS__c) && outletEx.MAS__c == 'Yes');
    }
    //155304 - created for PMD resolution
    public static Boolean isStringNotBlankTrax(Outlet_Execution__c outletEx){
        return (String.isNotBlank(outletEx.Product__c) && String.isNotBlank(outletEx.Outlet__c) && String.isNotBlank(outletEx.Distribution_TRAX__c) && outletEx.Distribution_TRAX__c == 'Yes');
    }
    
    /*
     * CloseListOpportunity - //155304 - create for PMD resolution
     * */
    public static List<Opportunity> closeOpportunityMethod(List<Opportunity> values){
        for(Opportunity opp : values){
            opp.StageName = 'Closed';
        }
        
        return values;
        
    }
/**    
* @description: to get Template Weighing Weight ,Added this method for ES20-1140 
* @return: void
* @Param : Map<Id, SObject>
**/
    public static Decimal getTempWeight(Map<String,Outlet_Territory__c> terrMap, Map<String,Template_Weighing__c> templtWeiMap,Id outletId ,Id oppTempId ){
        String clusterVal = terrMap.get(outletId).Outlet__r.Cluster__c;
        String countryVal = terrMap.get(outletId).Outlet__r.Country__c;
        String subSegVal = terrMap.get(outletId).Outlet__r.Global_Sub_Segment__c;
        String tempWetCmpKey = subSegVal+clusterVal+countryVal+oppTempId;
        Decimal tempWeight = 0;
        if(templtWeiMap!= null && templtWeiMap.containsKey(tempWetCmpKey)){
            tempWeight = templtWeiMap.get(tempWetCmpKey).Weight__c != null ? templtWeiMap.get(tempWetCmpKey).Weight__c : 0;
        }
        return tempWeight;
    } 
/**    
* @description: to expire Opportunity ,Added this method for ES20-9346
* @return: void
* @Param : list<Outlet_Execution__c>,set<id>
**/
    public static void expireOpportunity(list<Outlet_Execution__c> newOutletExecutionValuesList , set<id> outletId){
        
        system.debug('@@outletId'+outletId);
        system.debug('@@@newOutletExecutionValuesList1055' +newOutletExecutionValuesList);
        map<string,list<Outlet_Execution__c>> newOutletExecutionUniqueKey = new  map<string,list<Outlet_Execution__c>>();
        list<Opportunity> OpptoExpire = new list<Opportunity>();
        for(Outlet_Execution__c oeRec :newOutletExecutionValuesList ){
            if(oeRec.Activation_Reference__c != null && oeRec.RecordTypeId == outletExecutionMASRecordTypeId  ){
                string Key = oeRec.Outlet__c+'_'+oeRec.Activation_Reference__c;
                if(!newOutletExecutionUniqueKey.containsKey(key)){
                    newOutletExecutionUniqueKey.put(key, new List<Outlet_Execution__c>{oeRec});
                }else{
                    newOutletExecutionUniqueKey.get(key).add(oeRec);
                }
            } else if(oeRec.Product__c != null && oeRec.RecordTypeId == productRecordTypeId  ){
                string Key = oeRec.Outlet__c+'_'+oeRec.Product__c;
                if(!newOutletExecutionUniqueKey.containsKey(key)){
                    newOutletExecutionUniqueKey.put(key, new List<Outlet_Execution__c>{oeRec});
                }else{
                    newOutletExecutionUniqueKey.get(key).add(oeRec);
                }
            }
        }
        system.debug('newOutletExecutionUniqueKey '+newOutletExecutionUniqueKey);
        
        List<Opportunity> oppList = [select id , StageName ,AccountId,Type, Opportunity_Template__c,Outlet_Execution__c,Product__c,Activation__c,Activation__r.Name,
                                     Outlet_Execution__r.Outlet__c   from Opportunity  where StageName NOT IN  ('Closed', 'Expired') AND (Outlet_Execution__r.Latest_Entry__c = false) 
                                     AND (AccountId IN : outletId ) AND (Type = 'MPA' OR Type = 'MAS')];
        system.debug('oppList '+oppList);
        if(!oppList.isEmpty()){
            for(Opportunity opp : oppList){
                if(Opp.Type == 'MPA' ){
                    String Key = opp.AccountId+'_'+opp.Product__c;
                    if(!newOutletExecutionUniqueKey.containsKey(Key)){
                        opp.stageName = 'Expired';
                        OpptoExpire.add(opp);
                    }
                }else if(Opp.Type == 'MAS'){
                    String Key = opp.AccountId+'_'+opp.Activation__r.Name.substringBefore('[');
                    if(!newOutletExecutionUniqueKey.containsKey(Key)){
                        opp.stageName = 'Expired';
                        OpptoExpire.add(opp);
                    }
                }
                system.debug('OpptoExpire'+OpptoExpire);
            }
            if(!OpptoExpire.isEmpty() && Schema.sObjectType.Opportunity.isUpdateable()){
                update OpptoExpire;
            }
        }
        
    }
    
}