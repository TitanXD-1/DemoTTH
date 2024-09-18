/*******************************************************************************************
Name: EDGE_OutletCallCountHelper

Author          Version     Date           Detail
Sandip Ghosh    V1.0       15/09/2020     [ES20-8500]
Monalisa Halder V2.0       13/01/2021     [ES20-9419]
Juned Khan	v3.0	       15/01/2021     [ES20-8700]
Monalisa Halder V4.0       25/03/2021     [ES20-10004]
*********************************************************************************************/
public with sharing class EDGE_OutletCallCountHelper {
 	public static Map<Id,Integer> virtualCallsCountMap; 
    public static Map<Id,Integer> telephoneCallsCountMap;
    public static Map<Id,Integer> physicalCallsCountMap; 
    
    public static void createOutletWrapListOperator(List<Account> listOFOperators, List<EDGE_BatchSObjectWrapper> noOfCallsRecords){

        Map<Id, Account> outletIdToOutletMap = new Map<Id,Account>();
        
        String completedStatus = 'Completed';
        Set<Id> opIdsSet = new Set<Id>();
        List<Account> operatorToUpdate = new List<Account>();
		Map<Id,Account> operatorToUpdateMap=new Map<Id,Account>();
        Integer maxOutletPerOperator= Integer.valueOf(System.Label.EDGE_Max_Outlet_Per_Operator);
       
        for(Account opRec : listOFOperators){
            opIdsSet.add(opRec.Id);
        }
       
        //EDGE_UtilityClass.printGovLimits(26);
        if(opIdsSet != null && opIdsSet.size()>0 && Schema.sObjectType.Call__c.isAccessible()){
            EDGE_BatchSObjectWrapper callCountWrapper = noOfCallsRecords.get(0);
            if(callCountWrapper.virtualCallsCountMap != null){
                virtualCallsCountMap = callCountWrapper.virtualCallsCountMap;
            }
            if(callCountWrapper.physicalCallsCountMap != null){
                physicalCallsCountMap = callCountWrapper.physicalCallsCountMap;
            }
            if(callCountWrapper.telephoneCallsCountMap != null){
                telephoneCallsCountMap = callCountWrapper.telephoneCallsCountMap;
            }
		
            for(Account outlet : [Select Id,Name,Primary_Sales_Rep__r.Name,Operator__c from Account where Operator__c in :opIdsSet AND RecordType.Name = 'Outlet' order by createdDate DESC]){ //Id in :outletIds
                outletIdToOutletMap.put(outlet.Id,outlet);
            }
            
            Map<Id, EDGE_OutletCallsServiceWrapper> opToOutletsMap = new Map<Id, EDGE_OutletCallsServiceWrapper>();
            if(outletIdToOutletMap != null){
                for(Account accRecd : outletIdToOutletMap.values()){
                    EDGE_OutletCallsServiceWrapper.EDGE_OutletWrapper outletWrap = new EDGE_OutletCallsServiceWrapper.EDGE_OutletWrapper();
                    Integer physicalCalls = physicalCallsCountMap.containsKey(accRecd.Id) ? physicalCallsCountMap.get(accRecd.Id) : 0;
                    Integer telephoneCalls = telephoneCallsCountMap.containsKey(accRecd.Id) ? telephoneCallsCountMap.get(accRecd.Id) : 0;
                    Integer virtualCalls = virtualCallsCountMap.containsKey(accRecd.Id) ? virtualCallsCountMap.get(accRecd.Id) : 0;
                    outletWrap.Outletid = accRecd.Id;
                    outletWrap.OutletName = accRecd.Name;
					outletWrap.PrimarySalesRepName = (accRecd.Primary_Sales_Rep__r.Name != null) ? accRecd.Primary_Sales_Rep__r.Name : '';                     outletWrap.PhysicalCalls = physicalCalls;
                    outletWrap.TelephoneCalls = telephoneCalls;
                    outletWrap.VirtualCalls = virtualCalls;
                    outletWrap.TotalCall = outletWrap.PhysicalCalls + outletWrap.TelephoneCalls + outletWrap.VirtualCalls;
                    
                    
                    if(!opToOutletsMap.containsKey(accRecd.Operator__c)){
                        EDGE_OutletCallsServiceWrapper kpiServiceWrapper = new EDGE_OutletCallsServiceWrapper();
                        kpiServiceWrapper.Outletlist = new List<EDGE_OutletCallsServiceWrapper.EDGE_OutletWrapper>();
                        kpiServiceWrapper.Outletlist.add(outletWrap);
                        opToOutletsMap.put(accRecd.Operator__c,kpiServiceWrapper);
                    }else{
                        EDGE_OutletCallsServiceWrapper kpiServiceWrapper = opToOutletsMap.get(accRecd.Operator__c);
                        if(kpiServiceWrapper != null && kpiServiceWrapper.Outletlist != null && kpiServiceWrapper.Outletlist.size() <= maxOutletPerOperator){ //Replace with same label
                            kpiServiceWrapper.Outletlist.add(outletWrap);
                        }
                    }
                }
                
            }
            //EDGE_UtilityClass.printGovLimits(89);
            //ES20-8700
            List<String> fieldNames= new List<String>();
            if(label.EDGE_Account_Fields_for_JSON != null){    
                fieldNames = label.EDGE_Account_Fields_for_JSON.split(';'); //replace with the actual label
            } 
            for(Id opId : opToOutletsMap.keySet()){
				
                Integer fieldCount = 0;
                EDGE_OutletCallsServiceWrapper kpiServiceWrapper =  opToOutletsMap.get(opId);
				List<EDGE_OutletCallsServiceWrapper.EDGE_OutletWrapper> tempWrapperList;
               // System.debug('For Operator '+ opId + ' kpiServiceWrapper.Outletlist.size() :: ' + kpiServiceWrapper.Outletlist.size());
				Account operator = new Account(Id = opId);
                Integer noOfOutlets = kpiServiceWrapper.Outletlist.size();
                Integer loopLimit = noOfOutlets <= maxOutletPerOperator ? noOfOutlets : maxOutletPerOperator; // Replace 1000 with a label
                Integer noOfOutletInTextField = Integer.valueOf(System.Label.EDGE_No_Of_Outlet_Limit);
                    
               	for(Integer outletIterator=0; outletIterator<loopLimit; outletIterator++){
                   
                    if((outletIterator == 0) || (math.mod(outletIterator,noOfOutletInTextField) == 0 && outletIterator>0)){
                        tempWrapperList = new List<EDGE_OutletCallsServiceWrapper.EDGE_OutletWrapper>();
                    }
                    if(kpiServiceWrapper != null && tempWrapperList!= null){
                        tempWrapperList.add(kpiServiceWrapper.Outletlist[outletIterator]);
                    }
                    
                    if((outletIterator== noOfOutlets-1) || (math.mod(outletIterator,noOfOutletInTextField) == noOfOutletInTextField-1 && outletIterator>0)){
                        EDGE_OutletCallsServiceWrapper kpiServiceWrapperRec = new EDGE_OutletCallsServiceWrapper();
                        kpiServiceWrapperRec.Outletlist = tempWrapperList;
                        String tempfinalJSONStr = JSON.serialize(kpiServiceWrapperRec);
                        if(fieldNames!=null && tempfinalJSONStr!=null ){
                            operator.put(fieldNames[fieldCount],tempfinalJSONStr);//finalJSON);
                            fieldCount++;
                        }
                        operatorToUpdate.add(operator);
                        operatorToUpdateMap.putall(operatorToUpdate);
                    }
                    
                }
            }
            //EDGE_UtilityClass.printGovLimits(130);
            if(operatorToUpdateMap.size()>0){
                update operatorToUpdateMap.values();
            }
            
        }
        
    }
  
}