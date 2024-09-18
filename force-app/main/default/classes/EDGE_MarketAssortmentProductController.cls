/*
Name: EDGE_MarketAssortmentProductController

Req: The requirement is to remove Outlet from territory && Target list member from Target list
ES20-283 - Searching and Removing Market Assortment Product from selected Geography

History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sandeep Sahoo     13/05/2019        Initial Development
2.0       Preyanka Ghosh    28/11/2019        ES20-4503, ES20-4643	
3.0		  Dipanjan D		14/01/2020		  ES20-6388 : createAndMarkMAP, generateProdWrapList, getPicklistValues	
3.0		  Sagar Barman		06/03/2020		  ES20-6838 : createAndMarkMAP, generateProdWrapList
4.0		  Doman Murmu		17/07/2023		  142822
*/

public without sharing class EDGE_MarketAssortmentProductController{
    
    private static string keyFieldLabel = 'label';
    private static string keyFieldApiName = 'value';
    
    @AuraEnabled
    public static List<Market_Assortment_Product__c> searchMarketAssortProductDetails(String queryStr,String recordID){
        try{
            List<Market_Assortment_Product__c> mapList = new List<Market_Assortment_Product__c>();            
            if(Schema.sObjectType.Market_Assortment_Product__c.isAccessible() && String.isNotBlank(recordID)){
                if(queryStr.startsWith(' OR')){
                    queryStr = queryStr.removeStart(' OR');
                    queryStr = ' AND ( ' + queryStr + ' )';
                }
                String strQuery = 'Select Id,Product_Category__c,Product_Description__c,Product_Name__c,Product_Type__c,Product_UPI__c from Market_Assortment_Product__c ';
                strQuery += 'where Market_Assortment__c=:recordID';
                strQuery = String.escapeSingleQuotes(strQuery);		//142822 added String.escapeSingleQuotes
                strQuery = strQuery + queryStr;                    
                strQuery = strQuery +' LIMIT 9999';
                System.debug('strQuery:::'+strQuery);
                mapList = Database.query(strQuery);
            }
            return  mapList;
        }catch(Exception ex){
            System.debug('Exception::'+ex.getMessage());
            //throw new AuraHandledException(ex.getMessage());
            AuraHandledException ae = new AuraHandledException(ex.getMessage());
            ae.setMessage(ex.getMessage());
            throw ae;
        } 
    }
    
    @AuraEnabled
    public static List<Product__c> getProductList(String queryString,String marketId){   
        String POS = 'POS'; //NOPMD
        try{
            List<Product__c> productLIst= new List<Product__c>();
            if(Schema.sObjectType.Product__c.isAccessible()){                     
                if(queryString.startsWith(' OR')){
                    queryString = queryString.removeStart(' OR');
                    queryString = ' AND ( ' + queryString + ' )';
                }
                String strQuery = 'SELECT Id,Name,Description__c,UPIID__c,Category__c,Record_Type_Name__c FROM Product__c WHERE RecordType.Name !=:POS AND ID NOT IN (SELECT Product__c FROM Market_Assortment_Product__c WHERE Market_Assortment__c =:marketId)';    
                strQuery = String.escapeSingleQuotes(strQuery);		//142822 added String.escapeSingleQuotes
                strQuery = strQuery + queryString;
                strQuery = strQuery +' LIMIT 50000';
                System.debug('strQuery2:::'+strQuery);
                productLIst =  Database.query(strQuery);
            }
            return productLIst;    
        }
        catch(Exception ex){
            System.debug('Exception::'+ex.getMessage());
            //throw new AuraHandledException(ex.getMessage());
            AuraHandledException ae = new AuraHandledException(ex.getMessage());
            ae.setMessage(ex.getMessage());
            throw ae;
        }
        
    }
    
    @AuraEnabled
    public static void deleteMarketAssortProductDetails(List<Market_Assortment_Product__c> mapListIds){
        if(mapListIds.size()!=0){
            Database.delete(mapListIds);    
        }
    }
    
    @AuraEnabled
    public static void createAndMarkMAP(List<ProductWrapper> productWrapList,String marketId){        
        List<Market_Assortment_Product__c> newMarketAssortmentList =  new List<Market_Assortment_Product__c>();
        for(ProductWrapper pw : productWrapList){
            Market_Assortment_Product__c maProduct = new Market_Assortment_Product__c();
            maProduct.isCompetitor__c = pw.isCompetitor;
            //maProduct.Transfer_Order_Product__c = pw.isTransferOrder;
            maProduct.Base_UoM__c = pw.baseUOM;
            if(pw.selectedTransferOrder != null && pw.selectedTransferOrder.size()>0){
                String selectedTO = '';
                for(String option : pw.selectedTransferOrder){
                    selectedTO += option + ';';
                }  
                maProduct.Transfer_Order_Product_New__c = selectedTO;                
            }
            if(pw.selectedUsedUOM != null && pw.selectedUsedUOM.size()>0){
                String usedUOM = '';
                for(String option : pw.selectedUsedUOM){
                    usedUOM += option + ';';
                }
                maProduct.Used_UoM__c = usedUOM;
            }
            //added for Transfer order
            if(pw.selectedTOUsedUOM != null && pw.selectedTOUsedUOM.size()>0){
                String usedUOMTO = '';
                for(String option : pw.selectedTOUsedUOM){
                    usedUOMTO += option + ';';
                }
                maProduct.TO_Used_UOM__c = usedUOMTO;
            }
            
            if(pw.selectedFreeGood != null && pw.selectedFreeGood.size()>0){
                String usedFG = '';
                for(String option : pw.selectedFreeGood){
                    usedFG += option + ';';
                }  
                maProduct.Free_Good__c = usedFG;                
            }
            maProduct.Product__c = pw.product.Id;
            maProduct.Market_Assortment__c = marketId;
            maProduct.Base_Price__c = pw.priceFG;     
            newMarketAssortmentList.add(maProduct);
        }
        if(!newMarketAssortmentList.isEmpty() && Schema.sObjectType.Market_Assortment_Product__c.isCreateable()){
            try{
                insert newMarketAssortmentList;                
            } catch(Exception mapException){
                throw new AuraHandledException('Error: ' + mapException.getMessage());              
            }
        }
    }

	@AuraEnabled
    public static List<ProductWrapper> generateProdWrapList(List<Product__c> prodList){
	
		Set<Id> prodIds = new Set<Id>();
		List<ProductWrapper> prodWrapList = new List<ProductWrapper>();
		Map<Id, List<Map<String,String>>> prodWithUOSTypeMap = new Map<Id, List<Map<String,String>>>();
		
		for(Product__c prod : prodList){
			prodIds.add(prod.Id);
		}
        
		for(Product_UOM__c prodUOM : [SELECT Id, Product__c, Type__c FROM Product_UOM__c WHERE Product__c IN :prodIds]){
            Map<String, String> picklistEntry = new Map<String, String>();
            picklistEntry.put(keyFieldLabel, prodUOM.Type__c);
            picklistEntry.put(keyFieldApiName, prodUOM.Type__c);
            if(prodWithUOSTypeMap.containsKey(prodUOM.Product__c)){
				prodWithUOSTypeMap.get(prodUOM.Product__c).add(picklistEntry);
			}else{
				prodWithUOSTypeMap.put(prodUOM.Product__c, new List<Map<string, string>>{picklistEntry});
			}
		}
		
		for(Product__c prod : prodList){
			ProductWrapper prodWrap = new ProductWrapper();
            prodWrap.isCompetitor = false;
            prodWrap.isTransferOrder = false;
            prodWrap.selectedTransferOrder = new List<String>();//Added for ES20-6838
            prodWrap.selectedTOUsedUOM = new List<String>();//Added for ES20-6838
			prodWrap.usedUOMOptions = prodWithUOSTypeMap.containsKey(prod.Id) ? prodWithUOSTypeMap.get(prod.Id) : null;			
            prodWrap.selectedFreeGood = new List<String>();
            prodWrap.selectedUsedUOM = new List<String>();
            prodWrap.baseUOM = '';
            prodWrap.priceFG = null;
            prodWrap.product = prod;
			prodWrapList.add(prodWrap);
		}
		
		return prodWrapList;
	}
	
    @AuraEnabled
	public static List<Map<String,String>> getPicklistValues(String objectName, string fieldName){
        List<Map<String,String>> picklistEntries = new List<Map<String,String>>();
        
        Schema.sObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        List<Schema.PicklistEntry> picklistValues = objFieldMap.get(fieldName).getDescribe().getPickListValues();
        
        for( Schema.PicklistEntry pickValues : picklistValues){
            Map<String, String> picklistEntry = new Map<String, String>();
            picklistEntry.put(keyFieldLabel, pickValues.getLabel());
            picklistEntry.put(keyFieldApiName, pickValues.getValue());
            picklistEntries.add(picklistEntry);
        }
        
        return picklistEntries;
    } 
    
    //create wrapper class
    public class ProductWrapper{        
        @AuraEnabled public Boolean isCompetitor {get; set;}
        @AuraEnabled public Boolean isTransferOrder{get; set;}
        @AuraEnabled public List<String> selectedTransferOrder {get; Set;}//Added for ES20-6838
        @AuraEnabled public List<String> selectedTOUsedUOM {get; Set;}//Added for ES20-6838
        @AuraEnabled public List<Map<String,String>> usedUOMOptions {get; Set;}
        @AuraEnabled public List<String> selectedFreeGood {get; Set;}
        @AuraEnabled public List<String> selectedUsedUOM {get; Set;}
        @AuraEnabled public String baseUOM {get; Set;}
        @AuraEnabled public Decimal priceFG{get; set;}
        @AuraEnabled public Product__c product{get; set;}
    }
}