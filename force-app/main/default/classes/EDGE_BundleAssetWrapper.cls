/*Req: The requirement is to build Custom API to get Asset Data For a Bundle
User Story : ES20-ES20-13697
History                                                            
                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0      Monalisa Halder           06/01/2023         ES20-13697 -Custom API for D1 to get Asset Data For a Bundle
*/
public class EDGE_BundleAssetWrapper {
    
    @AuraEnabled
    public EDGE_OutletBundleWrapper bundleWrapper{get;set;}
    @AuraEnabled
    public  List<EDGE_AssetWrapper> assetWrapperList{get;set;}

}