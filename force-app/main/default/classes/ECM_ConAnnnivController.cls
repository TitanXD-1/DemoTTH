/*
*@Name: ECM_ConAnnnivController
*@description: This class fetches required data for VF components "ECM_Con_AnniversaryPouringDrought"
*@History:  
*@AUTHOR              DATE               DETAIL
*@Abhishek shivam     16/09/2022         Email templates for multi-year contracts_SFDC_GLO ECM-5648
*@Wribhu Bose         08/12/2022         ECM-6457: Updation in criteria for Anniversary email (inclusion of product growth driver)
*@Wribhu Bose         12/12/2022         ECM-6555 (BUG): Added PGD map check
*/

public without sharing class  ECM_ConAnnnivController {
    final static string pouringStatus = System.Label.ECM_Anniv_Pouring_Status;
    final static string draughtCockStatus = System.Label.ECM_Anniv_Draught_Cocktail_Status;
    public Id targetObjectId { get; set; }
    public Set<String> pouringProducts { get; set; }
    public Set<String> draughtProducts { get; set; }
    
  /*
* @description : this methods gives the Contract details and its corresponding products based on draught and pouring category
* @return : Contract object
*/  
    
    public Contract getContractDetails() {
        Set<String> pourProdTemp = new Set<String>();
        Set<String> draughtProdTemp = new Set<String>();
        List<Contract> conListofContract = new List<Contract>();
        Map<String,Pick_Up_Options__c> productGrowthDriverMap = new Map<String,Pick_Up_Options__c>();
        String pgdCategory = '';

        conListofContract = [SELECT Id, Account.Email_for_contracts_payments__c,Contract_End_Date__c,Account.ECM_Legal_Name__c,
                             StartDate,Account.Country_Code__c, Owner.Email, Account.Person_Responsible__c,
                             RecordType.Name, ContractNumber, Owner.Name, Account.Name,
                             Owner.IsActive, Owner.Manager.Email, Owner.Manager.IsActive
                             FROM Contract
                             WHERE Id = :targetObjectId];
        
        for(Pick_Up_Options__c pickupOption: [SELECT Id, Name, Geography__r.Code__c, ECM_Product_Growth_Driver_Category__c FROM Pick_Up_Options__c WHERE Geography__r.Code__c =: conListofContract[0].Account.Country_Code__c])
        {
            productGrowthDriverMap.put(pickupOption.Name.subStringBefore('['),pickupOption);
        }

        for( ECM_Sales_Driver_Item_Detail__c Products : [SELECT ECM_Sales_Driver_Item__c,ECM_Product__r.ECM_Lead_Brand__c,ECM_Product__r.ECM_Product_Name__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c,ECM_Sales_Driver_Item__r.Contract__r.Id
                                                         FROM ECM_Sales_Driver_Item_Detail__c WHERE
                                                         ((ECM_Product__r.ECM_Lead_Brand__c = true AND ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c =: pouringStatus) OR (ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c =:draughtCockStatus) )
                                                         AND ECM_Sales_Driver_Item__r.Contract__r.Id = : targetObjectId] )
            
        {
            if(Products.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c == pouringStatus && Products.ECM_Product__r.ECM_Lead_Brand__c ){
                pourProdTemp.add(Products.ECM_Product__r.ECM_Product_Name__c);
            } else if (Products.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c == draughtCockStatus){
                draughtProdTemp.add(Products.ECM_Product__r.ECM_Product_Name__c);
            }
        }
        
        for( ECM_Contract_Item__c Products : [SELECT ECM_Product_growth_driver__c, ECM_Lead_Brand__c, ECM_Contract__c, ECM_Product__r.Product__r.Name
                                              FROM ECM_Contract_Item__c
                                              WHERE ECM_Contract__c =: targetObjectId] )
            
        {
            if (productGrowthDriverMap.containsKey(Products.ECM_Product_growth_driver__c)) {
                pgdCategory = productGrowthDriverMap.get(Products.ECM_Product_growth_driver__c).ECM_Product_Growth_Driver_Category__c;
                
                if(pgdCategory == pouringStatus && Products.ECM_Lead_Brand__c ){
                    pourProdTemp.add(Products.ECM_Product__r.Product__r.Name);
                } else if (pgdCategory == draughtCockStatus){
                    draughtProdTemp.add(Products.ECM_Product__r.Product__r.Name);
                }
            }
        }
        
        if(!pourProdTemp.isEmpty() || !draughtProdTemp.isEmpty()) {
            pouringProducts = pourProdTemp;
            draughtProducts = draughtProdTemp;
        }
        if(conListofContract!=null){
            return conListofContract[0];
        }return null;
    }
    
}