/**********************************************************************
Name: EDGE_ProductInactiveBatch
=======================================================================
Req: This batch class updates the Active checkbox on Expiration of the Product
User Story : ES20-4312
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR            DATE              DETAIL
1.0			Sagar Barman	  11/10/2019      Initial Development
2.0			Kapil Baliyan	  30/12/2019	  Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
***********************************************************************/

public class EDGE_ProductInactiveBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{ 
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    final String BY_UNIT_STR = 'By Unit';
    final String BY_SIZE_STR = 'By Size';
    final String BY_QUANTITY_STR = 'By Quantity';
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    /** Start Method **/   
    public Database.QueryLocator start(Database.BatchableContext bc){        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        string countryCode = batchSetting.Country_Code__c;
        String strQuery = 'SELECT Id, Name, Country__c, Start_Date__c, Expiry_Date__c, A_P_Cost__c, IsActive__c, RecordType.Name, Pricing_Type__c FROM Product__c WHERE Country__r.code__c=:countryCode AND RecordType.Name =\'POS\' AND (Start_Date__c = TODAY OR Expiry_Date__c = TODAY)';
        return Database.getQueryLocator(strQuery);
    }
    
    /** Execute Method **/ 
    public void execute(Database.BatchableContext bc, List<Product__c> scope){
        List<Product__c> updateActiveProductList = new List<Product__c>();
        Map<Id,Product__c> mapProductbyUnit = new Map<Id,Product__c>();
        Map<Id,Product__c> mapProductbySize = new Map<Id,Product__c>();
        Map<Id,Product__c> mapProductbyQuantity = new Map<Id,Product__c>();        
        Map<Id,List<Product_Variant__c>> mapProductWithVariant = new Map<Id,List<Product_Variant__c>>();
        Map<Id,List<Product_Pricing__c>> mapProductWithPricing = new Map<Id,List<Product_Pricing__c>>();
        
        try{
            for(Product__c product : scope){
                //Mark Expired Product as inactive
                if(product.IsActive__c == true && (product.Start_Date__c > System.today() || product.Expiry_Date__c <= System.today())){
                    product.IsActive__c = false;
                    updateActiveProductList.add(product);
                }
                
                if(product.Start_Date__c <= System.today() && (product.Expiry_Date__c > System.today() || product.Expiry_Date__c == null)){
                    if(product.Pricing_Type__c == BY_UNIT_STR){
                        mapProductbyUnit.put(product.Id,product);
                    }else if(product.Pricing_Type__c == BY_SIZE_STR){
                        mapProductbySize.put(product.Id, product);
                    }else if(product.Pricing_Type__c == BY_QUANTITY_STR){
                        mapProductbyQuantity.put(product.Id, product);
                    }
                }
            }
            
            //By Unit
            if(mapProductbyUnit.size()>0){
                updateActiveProductList = EDGE_UtilityClass.activateProductByUnit(mapProductbyUnit, updateActiveProductList);
            }
            
            //By Size
            if(mapProductbySize.size()>0){
                //Get Product Variant
                for(Product_Variant__c prodV : [SELECT Id, Product__c, Product__r.Pricing_Type__c, Unit_Price__c 
                                                FROM Product_variant__c 
                                                WHERE Product__c IN :mapProductbySize.keySet() AND Product__r.Pricing_Type__c =:BY_SIZE_STR])
                {
                    String productId = prodV.Product__c;
                    if(mapProductWithVariant.containsKey(productId)){
                        mapProductWithVariant.get(productId).add(prodV);
                    }else{
                        mapProductWithVariant.put(productId, new List<Product_Variant__c>{prodV});
                    }    
                }
                
                //Call Utility Class Method
                updateActiveProductList = EDGE_UtilityClass.activateProductBySize(mapProductWithVariant, mapProductbySize, updateActiveProductList);
            }
            
            //By Quantity
            if(mapProductbyQuantity.size()>0){
                //Get Product Pricing
                for(Product_Pricing__c prodC : [SELECT Id, Product__c, Product__r.Pricing_Type__c, Range_Price__c 
                                                FROM Product_Pricing__c 
                                                WHERE Product__c IN :mapProductbyQuantity.keySet() AND Product__r.Pricing_Type__c =:BY_QUANTITY_STR])
                {    
                    String productId = prodC.Product__c;
                    if(mapProductWithPricing.containsKey(productId)){
                        mapProductWithPricing.get(productId).add(prodC);
                    }else{
                        mapProductWithPricing.put(productId, new List<Product_Pricing__c>{prodC});
                    }
                }
                
                //Call Utility Class Method
                updateActiveProductList = EDGE_UtilityClass.activateProductByQuantity(mapProductWithPricing, mapProductbyQuantity, updateActiveProductList);
            }
            
            if(updateActiveProductList.size() > 0){
                Database.update(updateActiveProductList,false);
            }
            
            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
            }
        }catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_ProductInactiveBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }

        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
    }
}