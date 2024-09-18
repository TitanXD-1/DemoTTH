/**
*@Class Name: EDGE_KPITargetOperations

*@		Author          Version         Date           Detail
*@   Dipanjan Das        V1.0        13/05/2019     ES20-1268 : Update Outlet KPI Target from KPI Target Object
*@   Preyanka Ghosh		 v2.0		 19/02/2020		ES20-6944 : SFDC SOS Target update
*@	 Saranya L			 v3.0		 03/09/2021		ES20-10941: Target Override Not Allowed check
*@	 Shivam/Rajarshi	 v4.0		 04/05/2023	    ES20-14005,ES20-13960 
*@	 Shivam/Doman		 v5.0		 20/09/2023		145439 	  : getMSCountryChannel,setKPITarget
*@	 Raghavendra		 v6.0		 20/09/2023		145738
*@   Sandip/Joshraj      v7.0        03/05/2024     153343 UAT_Sanity_Target of Outlet KPI Achievement is getting updated with Target of KPI Target,
**/
public with sharing class EDGE_KPITargetOperations {
    
    public static List<Outlet_KPI_Achievement__c> lstOutletKPI = new List<Outlet_KPI_Achievement__c>();
    
    /**
*@ Method  : populateOutletKPIs
*@ Purpose : This methods used to create/update SOS KPI Target fields in Outlet KPIsTarget Object.
**/
    public static List<Outlet_KPI_Achievement__c> populateOutletKPIs(List<KPIs_Target__c> kpiTargetList, List<Account> outletList, List<Outlet_KPI_Achievement__c> lstOutletKPIUpdate){
        List<String> categories = new List<String>();
        Map<String, Outlet_KPI_Achievement__c> mapOutletKPI = new Map<String, Outlet_KPI_Achievement__c>();
        Map<String, Decimal> territoryCategoryKPIs = new Map<String, Decimal>();
        Map<id,String> mapCountryChannel = new Map<id,String>();
        
        Schema.DescribeFieldResult f = KPIs_Target__c.Category__c.getDescribe();
        Schema.sObjectField t = f.getSObjectField();
        List<PicklistEntry> entries = t.getDescribe().getPicklistValues();
        for(PicklistEntry entry : entries){
            categories.add(entry.getValue());
        }
        
        territoryCategoryKPIs=getKey(kpiTargetList);
        populatemapOutletKPI(lstOutletKPIUpdate,mapOutletKPI);
        getMSCountryChannel(mapCountryChannel);//145439
        
        String mapKeySubsegment;
        String mapKeySegment;       
        EDGE_OutletKPIWrapper outletKPIWrapper = new EDGE_OutletKPIWrapper();
        outletKPIWrapper.mapOutletKPI = mapOutletKPI;
        outletKPIWrapper.territoryCategoryKPIs = territoryCategoryKPIs;
        outletKPIWrapper.mapCountryChannel = mapCountryChannel;
        for(Account outlet : outletList){
            for(String categoryName : categories){
                mapKeySubsegment = outlet.Primary_Sales_Territory__c + '_' +outlet.Global_Segment__c+'_'+outlet.Global_Sub_Segment__c+'_'+ categoryName;
                mapKeySegment = outlet.Primary_Sales_Territory__c + '_' +outlet.Global_Segment__c+'_'+ categoryName;                             
                Map<String,String> mapKeywithCat=new Map<String,String>();  
                if(territoryCategoryKPIs.containsKey(mapKeySubsegment))
                {
                    mapKeywithCat.put('Key',mapKeySubsegment);
                    mapKeywithCat.put('Category',categoryName);
                    getOutletKPI(mapKeywithCat,OutletKPIWrapper,outlet);                                 
                }
                else if(territoryCategoryKPIs.containsKey(mapKeySegment))
                {
                    mapKeywithCat.put('Key',mapKeySegment);
                    mapKeywithCat.put('Category',categoryName);
                    getOutletKPI(mapKeywithCat,OutletKPIWrapper,outlet);                    
                }
                else if(!(territoryCategoryKPIs.containsKey(mapKeySubsegment)||territoryCategoryKPIs.containsKey(mapKeySegment)) && mapOutletKPI.containsKey(outlet.Id +'_SoS_' + categoryName))
                {                  
                    Outlet_KPI_Achievement__c outletKPI = mapOutletKPI.get(outlet.Id +'_SoS_' + categoryName);
                    outletKPI.Target__c=null;
                    lstOutletKPI.add(outletKPI);  
                }
            }
            
        }
        return lstOutletKPI;
        
    }
    
    /**
*@ Method	:getOutletKPI
*@ purpose:This method is used to create/update Outlet KPI record.
**/
    public static void getOutletKPI(Map<String,String> mapKeywithCat,EDGE_OutletKPIWrapper outletKPIWrapper,Account outlet){
        if(outletKPIWrapper.mapOutletKPI != null && outletKPIWrapper.mapOutletKPI.containsKey(outlet.Id +'_SoS_' + mapKeywithCat.get('Category'))){
            Outlet_KPI_Achievement__c outletKPI = outletKPIWrapper.mapOutletKPI.get(outlet.Id +'_SoS_' + mapKeywithCat.get('Category'));
            
            if(outletKPI != null && outletKPI.Target_Override_Not_Allowed__c!= true)     // added this Target_Override_Not_Allowed__c check by saranya for ES20-10941
                
            {
                outletKPI.Target__c = setKPITarget(mapKeywithCat,outletKPIWrapper,outlet)??outletKPI.Target__c;//145439
                lstOutletKPI.add(outletKPI);
            }
            
        } else {
            Outlet_KPI_Achievement__c outletKPI = new Outlet_KPI_Achievement__c();
            outletKPI.Category__c = mapKeywithCat.get('Category');
            outletKPI.KPI_Type__c = 'SoS';
            outletKPI.Target__c = setKPITarget(mapKeywithCat,outletKPIWrapper,outlet)??outletKPI.Target__c;//145439
            outletKPI.Outlet__c = outlet.Id;
            outletKPI.Unique_Id__c = outlet.Id +'_SoS_' + outletKPI.Category__c;
            lstOutletKPI.add(outletKPI);
        }
    }
    
    
    /**
*@ Method	:	getKey
*@ purpose	:	This method is used to create key from KPI Target object based on Segment, Subsegment and Category fields.
**/
    public static Map<String, Decimal> getKey(List<KPIs_Target__c> kpiTargetList){
        Map<String, Decimal> territoryCategoryKPIs = new Map<String, Decimal>();
        //Create a mapping for Territory, Segment, Sub Segment Category 
        for(KPIs_Target__c kpiTarget : kpiTargetList){
            String key;
            if(kpiTarget.Sub_Segment__c!=null){
                key = kpiTarget.Territory__c + '_' + kpiTarget.Segment__c + '_' + kpiTarget.Sub_Segment__c + '_' + kpiTarget.Category__c;
            }
            else{
                key = kpiTarget.Territory__c + '_' + kpiTarget.Segment__c + '_' + kpiTarget.Category__c;
            }
            territoryCategoryKPIs.put(key, kpiTarget.Target__c);
        }
        return territoryCategoryKPIs;
        
    }
    
    /**
*@ Method	:	populatemapOutletKPI
*@ purpose	:	This method is used to populate map of unique id with Outlet KPI Achiv record 
**/
    public static void populatemapOutletKPI(List<Outlet_KPI_Achievement__c> lstOutletKPIUpdate,Map<String, Outlet_KPI_Achievement__c> mapOutletKPI){
        //If we are updating Outlet KPI Achievement Target only in that case we will update the record only
        if(lstOutletKPIUpdate != null && lstOutletKPIUpdate.size()>0){
            for(Outlet_KPI_Achievement__c outletKPI : lstOutletKPIUpdate){
                mapOutletKPI.put(outletKPI.Unique_Id__c, outletKPI);
            }
            lstOutletKPIUpdate.clear();
        }
    }
    
    /**
*@ ADO		:	145439
*@ Method	:	getMSCountryChannel
*@ purpose	:	This method is used to get map of Country and it's selected SOS Target Value(Channel) from Market Setting.
**/
    public static void getMSCountryChannel(Map<id,String> mapCountryChannel){
        List<market_setting__c> marketSettingRecord = [Select Geography__c,SOS_target_from_DDH__c from market_setting__c WITH SECURITY_ENFORCED];//sc
        for(market_setting__c marketSetting:marketSettingRecord){
            mapCountryChannel.put(marketSetting.Geography__c,marketSetting.SOS_target_from_DDH__c);
        }
        System.debug(LoggingLevel.Debug,'mapCountryChannel'+mapCountryChannel);
    }
    
    /**
*@ ADO		:	145439
*@ Method	:	setKPITarget
*@ purpose	:	This method is used to get target value from Outlet KPI Target record on the basis of Market Setting's SOS Target field.
**/

    public static Decimal setKPITarget(Map<String,String> mapKeywithCat,EDGE_OutletKPIWrapper outletKPIWrapper,Account outlet){
        Decimal target;
        if(outletKPIWrapper.mapCountryChannel != null && outletKPIWrapper.mapCountryChannel.get(outlet.Country__c) != null){
            if(outletKPIWrapper.mapCountryChannel.get(outlet.Country__c).contains(outlet.Global_Channel__c)){
                // The parent outlet's channel matches with any of the values selected in SOS_target_from_DDH__c field from market setting
                target = null; //SoS Issue number
            }
            else{
                if(outletKPIWrapper.territoryCategoryKPIs != null && mapKeywithCat.get('Key') != null){
                    // The parent outlet's channel doesn't matche with any of the values selected in SOS_target_from_DDH__c field hence keeping the existing logic
                    target = outletKPIWrapper.territoryCategoryKPIs.get(mapKeywithCat.get('Key')); 
                } 
            }
        }
        else{//Market Setting SOS_target_from_DDH__c field value is blank
            if(outletKPIWrapper.territoryCategoryKPIs != null && mapKeywithCat.get('Key') != null){
                target = outletKPIWrapper.territoryCategoryKPIs.get(mapKeywithCat.get('Key'));
            }
        }
        return target;
    }
}