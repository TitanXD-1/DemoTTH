/*
Name: D1_AssetWrapper

History                                                                                                                        
VERSION   AUTHOR              DATE            DETAIL
1.0    Swaraj Samanta       05/12/2022      ES20-13611 - Service Build for D1 to fetch Assets associated to Bundle_SFDC_Quality Equipments

*/
public class EDGE_AssetWrapper {
        @AuraEnabled
		public string recordId{get;set;}
        @AuraEnabled
        public String assetName{get;set;}
        @AuraEnabled
        public Double quantity{get;set;}
        @AuraEnabled
    	public Date installDate{get;set;}
}