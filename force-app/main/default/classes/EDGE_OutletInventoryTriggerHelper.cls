/**********************************************************************
Name: EDGE_OutletInventoryTriggerHelper
=======================================================================
Purpose: Helper class for OutletInventoryTriggerHandler
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR                 DATE              DETAIL
1.0      Shahbaz Khan         12-10-2020     Initial Development
2.0      Monalisa Halder      16-10-2020     ES20-8625 (Method : createAveragePriceOutletInventory)
3.0       Monalisa Halder     13/05/2021     [ES20-10354]
***********************************************************************/
public class EDGE_OutletInventoryTriggerHelper {
    //populate Unique Id field
    public static void populateUniqueId(List<Outlet_Inventory__c> newItems){
        if(newItems !=null){
            for(Outlet_Inventory__c outInv : newItems){
                String unique = '';
                if(outInv.Type__c == 'Average'){
                    unique += outInv.Account__c + '_'+outInv.Product__c+ '_'+outInv.Type__c;
                   
                }
                else if(outInv.Type__c == 'Inventory'){
                    unique += outInv.Account__c + '_'+outInv.Product__c+'_'+outInv.Type__c + (outInv.Date__c != null ? '_'+outInv.Date__c.format() : '');
                    
                }
                outInv.Unique_Id__c = unique;
                
            }
        }
        
    }
    /******************
    ES20-8625 : Used to calculate Average Price
    ****************/
    
    public static void createAveragePriceOutletInventory(Map<String, Set<Outlet_Inventory__c>> outletInvSetPerOutletProdMap){
        List<Outlet_Inventory__c> outletInventoryToUpsert = new List<Outlet_Inventory__c>();
        Map<String,Decimal> avgPriceOutletInventoryMap = new  Map<String,Decimal>();
        Map<String, Double> averagePriceRecord = new Map<String, Double>();
        Decimal avgPrice ;
        
        for(String str :outletInvSetPerOutletProdMap.keySet()){
            Decimal totalPrice = 0;
            set<Outlet_Inventory__c> outInvenSet = outletInvSetPerOutletProdMap.get(str);
            for(Outlet_Inventory__c outInvenRec :outInvenSet){
                //ES20-10354
                if(outInvenRec.Price__c != null){
                	totalPrice += outInvenRec.Price__c;    
                }
                
            }
            Integer count = outInvenSet.size();
            //ES20-10354
            if(totalPrice != 0 ){
                if( count !=0){
                    avgPrice = totalPrice/count;    
                }else{
                    avgPrice = 0.0; 
                }
            }else{
                avgPrice = 0.0; 
            }
            
            avgPriceOutletInventoryMap.put(str,avgPrice);
        }
        for(String avgPriceOutletInventoryRec :avgPriceOutletInventoryMap.keySet()){
            Outlet_Inventory__c avgOutInve = new Outlet_Inventory__c();
            avgOutInve.Account__c = avgPriceOutletInventoryRec.split('_')[0];//outletInvSetPerOutletProdMap.get(s).get(0).Account__c;
            avgOutInve.Product__c = avgPriceOutletInventoryRec.split('_')[1];//outletInvSetPerOutletProdMap.get(s).get(0).Product__c;    
            avgOutInve.Price__c = avgPriceOutletInventoryMap.get(avgPriceOutletInventoryRec);
            avgOutInve.Type__c = 'Average';
            avgOutInve.Unique_Id__c = avgOutInve.Account__c + '_'+avgOutInve.Product__c+ '_'+avgOutInve.Type__c;
            outletInventoryToUpsert.add(avgOutInve);  
            
        }
        
        Schema.SObjectField uniqueId = Outlet_Inventory__c.Fields.Unique_Id__c;
        if(outletInventoryToUpsert != null && outletInventoryToUpsert.size()>0){
            Database.UpsertResult [] srList = Database.upsert(outletInventoryToUpsert , uniqueId, false);   
            
            for (Database.UpsertResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully upserted. Outlet Inventory ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('error has occurred.' + err.getStatusCode() + ': ' + err.getMessage());                    
                        System.debug('fields that affected this error: ' + err.getFields());
                        
                    }
                }
            } 
        }
        
    }
    /******************
    ES20-8625 : Used to check rowlimit 12
    ****************/
    public static void limitOutletInventoryinMap( String ouProd, Map<String, Set<Outlet_Inventory__c>> outletInventoryMap, Map<String, Set<Outlet_Inventory__c>> outletInvSetPerOutletProdMap){
       	Integer rowlimit = Integer.valueOf(system.label.EDGE_OutletInventoryLimit);
        if(outletInventoryMap.get(ouProd).size() < rowlimit){
            outletInvSetPerOutletProdMap.put(ouProd, outletInventoryMap.get(ouProd));
        } else{
            Integer counter = 0;
            Set<Outlet_Inventory__c> oiWrapRec = outletInventoryMap.get(ouProd);
            List<EDGE_OutletInventoryCompareDateWrapper> oiWrapperList =  new List<EDGE_OutletInventoryCompareDateWrapper>();
            for(Outlet_Inventory__c outletInvenWrap:oiWrapRec){
            	EDGE_OutletInventoryCompareDateWrapper oiWrapper = new EDGE_OutletInventoryCompareDateWrapper(outletInvenWrap);  
                oiWrapperList.add(oiWrapper);
            }
            oiWrapperList.sort();
            for(EDGE_OutletInventoryCompareDateWrapper outletInvenWrapper:oiWrapperList){
                if(counter < rowlimit){
                    if(outletInvSetPerOutletProdMap.containsKey(ouProd)){
                        outletInvSetPerOutletProdMap.get(ouProd).add(outletInvenWrapper.outletInventory); 
                    }else{
                        outletInvSetPerOutletProdMap.put(ouProd,new Set<Outlet_Inventory__c>{outletInvenWrapper.outletInventory});
                    }
                    counter++;
                }  
            }
        }     
    }
    
    
}