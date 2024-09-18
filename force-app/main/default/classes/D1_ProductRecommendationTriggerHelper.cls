/**
 * @description: Trigger Helper for Product Recommendation
 * @name: D1_ProductRecommendationTriggerHelper
 * @history
 * @version     Developer           Date            		Detail
 * 1.0          Pratap Sen     	  22-02-2023       NCP-7904 - Initial Development
*/
public class D1_ProductRecommendationTriggerHelper {
    /**
    * @description: populateUniqueKey - generates the unique key field value
    * @return: void
    * @param: List<D1_Product_Recommendation__c>, Map<Id, SObject>
    */
    public static void populateUniqueKey(List<D1_Product_Recommendation__c> newItems, Map<Id, SObject> oldItems){
        Map<Id, D1_Product_Recommendation__c> mapOldItems;
        if(oldItems != null){
            mapOldItems = (Map<Id, D1_Product_Recommendation__c>)oldItems;
        }
        for(D1_Product_Recommendation__c prodRecomm : newItems){
            if(mapOldItems == null || 
              	(mapOldItems.containsKey(prodRecomm.Id) && 
                   (mapOldItems.get(prodRecomm.Id).Master_Product__c != prodRecomm.Master_Product__c ||
                 	mapOldItems.get(prodRecomm.Id).Recommended_Product__c != prodRecomm.Recommended_Product__c ||
                 	mapOldItems.get(prodRecomm.Id).Country__c != prodRecomm.Country__c ||
                 	mapOldItems.get(prodRecomm.Id).Is_Active__c != prodRecomm.Is_Active__c)
               	)
              )
            {
                prodRecomm.Unique_Key__c = prodRecomm.Master_Product__c + '_' + prodRecomm.Recommended_Product__c + '_' + prodRecomm.Country__c;
                prodRecomm.Unique_Key__c = prodRecomm.Unique_Key__c + '_' + ((prodRecomm.Is_Active__c) ? '1' : '0');
            }
        }
    }
    
    /**
    * @description: checkAndGenerateSharing - To create sharing record on Insert
    * @return: void
    * @param: List<D1_Product_Recommendation__c>
    */
    public static void checkAndGenerateSharing(List<D1_Product_Recommendation__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');
        D1_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Read');
    }
    
    /**
     * @description: validateAndReGenerateSharing - Modify sharing record on update
     * @return: void
     * @param: List<D1_Product_Recommendation__c>, Map<Id, SObject>
    */
    public static void validateAndReGenerateSharing(List<D1_Product_Recommendation__c> newItems, Map<Id, SObject> oldItems){
        List<D1_Product_Recommendation__c> lstNewChangeGeography = new List<D1_Product_Recommendation__c>();
        List<D1_Product_Recommendation__c> lstOldChangeGeography = new List<D1_Product_Recommendation__c>();
        Map<Id, D1_Product_Recommendation__c> mapOldItems;
		
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, D1_Product_Recommendation__c>)oldItems;
        }
        
        for(D1_Product_Recommendation__c prodRecomm : newItems){
            if(mapOldItems.containsKey(prodRecomm.Id) && prodRecomm.Country__c != mapOldItems.get(prodRecomm.Id).Country__c){
                lstNewChangeGeography.add(prodRecomm);
                lstOldChangeGeography.add(mapOldItems.get(prodRecomm.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
            
            D1_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            D1_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Read');
        }
    } 
}