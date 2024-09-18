/*
* Name: ECM_SelectProductsController
* Purpose: This Class is used to fetch the Products and display it in Lightning component - ECM_SelectProducts
* History                                                            
                                                            
    VERSION    AUTHOR                DATE              	DETAIL
    1.0      Pradeep Kumar Reddy    31/01/2020        	Initial Development
             Dasaratha Rami Reddy
	2.0      Anivesh Muppa		    5/03/2021        	Modified as per ECM-4091
	3.0      Sayan Mullick		    6/07/2021        	Modified as per ECM-4400
	3.1      Saurav Paul		    01/09/2021        	Modified as per ECM-4763
	3.2		 Saranya L			    19/07/2022			Modified as per ECM-5847
    3.3      Tanishq Banerjee       30/07/2022          Modified as per ECM-5914
    3.4      Tanishq Banerjee       12/08/2022          Modified as per ECM-5977
*/ 

public without sharing class ECM_SelectProductsController {
    
    // Method Name : fetchProductAgreements
    // Description : This method is used to fetch the all the products based on selected Agreement Type
    @AuraEnabled
    public static selectProductsWrapper fetchProductAgreements(String agreementTypeId ,list<ECM_Product_Agreement__c> preferredProductsList,Contract ContractDetails, boolean isAus){
        system.debug(LoggingLevel.Info,isAus);
        System.debug(LoggingLevel.Debug,'Resource Used S2 fetchProductAgreements starts :'+Limits.getQueries()+'/'+Limits.getLimitQueries()+' '+Limits.getCpuTime()+'/'+Limits.getLimitCpuTime()+' '+Limits.getDmlRows()+'/'+Limits.getLimitDmlRows());
        selectProductsWrapper wrap = new selectProductsWrapper();
        List<preferredProductsListWrapper> preferredWrapList = new List<preferredProductsListWrapper>();
        List<unpreferredProductsListWrapper> unpreferredWrapList = new List<unpreferredProductsListWrapper>();

        List<ECM_Product_Agreement__c> preferredList = new List<ECM_Product_Agreement__c>();
        List<ECM_Product_Agreement__c> unpreferredList = new List<ECM_Product_Agreement__c>();

        Map<Id,Decimal> prdtVolumeMap = new Map<Id,Decimal>();
        Contract contractRec = [Select Id,RecordType.Name, name,StartDate,Contract_End_Date__c, AccountId, CreatedDate, Account.Hybrid__c,Account.Parent_Outlet__c,ECM_Channel__c from Contract where Id =: ContractDetails.Id];
        Date startdt;
        Date enddt;
        if(isAus){
            startdt = system.today();
        	startdt = Date.newInstance(startdt.year()-1, startdt.month(), startdt.day());
            startdt = startdt.toStartOfMonth();
            enddt = system.today().toStartOfMonth();
        }
        else{
            startdt =contractRec.StartDate;
        	startdt = Date.newInstance(startdt.year()-1, startdt.month(), startdt.day());
        }
        
        
       // Date enddt =contractRec.StartDate;//contractRec.Contract_End_Date__c;
        //enddt = Date.newInstance(enddt.year()-1, enddt.month(), enddt.day());
        
        set<id> outletids=new set<id>();
        list<contract> groupcontracts= new list<contract>();
        //Changes according to ECM-4091
        if(isAus){
            if(contractRec.Account.Parent_Outlet__c!=Null && contractRec.Account.Hybrid__c){
                outletids.add(contractRec.Account.Parent_Outlet__c);
            }else{
                outletids.add(contractRec.AccountId);
            }
            
        }else{
            outletids.add(contractRec.AccountId);
        }
        //end of Changes according to ECM-4091
        if(contractRec.RecordType.Name=='Group'){
            
            for(Outlet_Contract__c groupoutlet :[select id,Outlet__c,Outlet__r.Hybrid__c,Outlet__r.Parent_Outlet__c,Contract__c from Outlet_Contract__c where Contract__c=:contractRec.id]){
                outletids.add(groupoutlet.Outlet__c);
            }
        }
        System.debug('outletids'+outletids);

        if(isAus){
            for(Depletions__c depletion : [Select Id, ECM_Product__c, ECM_Volume__c, ECM_Outlet__c, ECM_End_Period__c, ECM_Start_Period__c From Depletions__c where ECM_Outlet__c in: outletids AND  ECM_Start_Period__c >=:startdt and ECM_End_Period__c <=:enddt and ECM_Volume__c >0]){//ECM_End_Period__c <= : enddt and
                prdtVolumeMap.put(depletion.ECM_Product__c,depletion.ECM_Volume__c);
            }
        }
        else{
            for(Depletions__c depletion : [Select Id, ECM_Product__c, ECM_Volume__c, ECM_Outlet__c, ECM_End_Period__c, ECM_Start_Period__c From Depletions__c where ECM_Outlet__c in: outletids AND  ECM_Start_Period__c >=:startdt and ECM_Volume__c >0]){//ECM_End_Period__c <= : enddt and
                prdtVolumeMap.put(depletion.ECM_Product__c,depletion.ECM_Volume__c);
            }
        }
        system.debug(prdtVolumeMap);
        if(preferredProductsList != null && preferredProductsList.size()>0 ){
            preferredList = [select id,Product_Name__c,ECM_Preferred__c, ECM_Market_Assortment_Product__c,ECM_Market_Assortment_Product__r.Product__c,ECM_Contract_Type__r.Geography__r.Name ,ECM_Market_Assortment_Product__r.Product__r.Name, ECM_Contract_Type__c,ECM_Lead_Brand__c, ECM_Max_TI_limit_per_min_UoM_value__c , ECM_Max_TI_limit_per_9LC_EU_value__c,ECM_Market_Assortment_Product__r.ECM_Pickup_Option__c,ECM_Market_Assortment_Product__r.ECM_Pickup_Option__r.ECM_Strategy_group__c from ECM_Product_Agreement__c where ECM_Contract_Type__c =:agreementTypeId and id in:preferredProductsList ];//ECM-5914
            for(ECM_Product_Agreement__c prdtAgrmt : preferredList){
                preferredProductsListWrapper preferredWrap = new preferredProductsListWrapper();
                preferredWrap.Product = prdtAgrmt;
                if(prdtVolumeMap.containsKey(prdtAgrmt.ECM_Market_Assortment_Product__r.Product__c)){
                    preferredWrap.productVolume = prdtVolumeMap.get(prdtAgrmt.ECM_Market_Assortment_Product__r.Product__c);
                }
                preferredWrapList.add(preferredWrap);
            }

            unpreferredList = [select id,Product_Name__c,ECM_Preferred__c, ECM_Market_Assortment_Product__c,ECM_Market_Assortment_Product__r.Product__c,ECM_Contract_Type__r.Geography__r.Name,ECM_Market_Assortment_Product__r.Product__r.Name, ECM_Contract_Type__c,ECM_Lead_Brand__c , ECM_Max_TI_limit_per_min_UoM_value__c , ECM_Max_TI_limit_per_9LC_EU_value__c,ECM_Market_Assortment_Product__r.ECM_Pickup_Option__c,ECM_Market_Assortment_Product__r.ECM_Pickup_Option__r.ECM_Strategy_group__c from ECM_Product_Agreement__c where ECM_Contract_Type__c =:agreementTypeId AND id NOT in:preferredProductsList];//ECM-5914
            for(ECM_Product_Agreement__c prdtAgrmt : unpreferredList){
                unpreferredProductsListWrapper unpreferredWrap = new unpreferredProductsListWrapper();
                unpreferredWrap.Product = prdtAgrmt;
                if(prdtVolumeMap.containsKey(prdtAgrmt.ECM_Market_Assortment_Product__r.Product__c)){
                    unpreferredWrap.productVolume = prdtVolumeMap.get(prdtAgrmt.ECM_Market_Assortment_Product__r.Product__c);
                }
                unpreferredWrapList.add(unpreferredWrap);
            }
        }else{
            preferredList = [select id,Product_Name__c,ECM_Preferred__c, ECM_Market_Assortment_Product__c,ECM_Market_Assortment_Product__r.Product__c,ECM_Market_Assortment_Product__r.Product__r.Name, ECM_Contract_Type__c,ECM_Lead_Brand__c , ECM_Max_TI_limit_per_min_UoM_value__c , ECM_Max_TI_limit_per_9LC_EU_value__c,ECM_Market_Assortment_Product__r.ECM_Pickup_Option__c,ECM_Market_Assortment_Product__r.ECM_Pickup_Option__r.ECM_Strategy_group__c from ECM_Product_Agreement__c where ECM_Contract_Type__c =:agreementTypeId AND ECM_Preferred__c=true ];//ECM-5914
            for(ECM_Product_Agreement__c prdtAgrmt : preferredList){
                preferredProductsListWrapper preferredWrap = new preferredProductsListWrapper();
                preferredWrap.Product = prdtAgrmt;
                if(prdtVolumeMap.containsKey(prdtAgrmt.ECM_Market_Assortment_Product__r.Product__c)){
                    preferredWrap.productVolume = prdtVolumeMap.get(prdtAgrmt.ECM_Market_Assortment_Product__r.Product__c);
                }
                preferredWrapList.add(preferredWrap);
            }

            unpreferredList = [select id,Product_Name__c,ECM_Preferred__c, ECM_Market_Assortment_Product__c,ECM_Market_Assortment_Product__r.Product__c,ECM_Market_Assortment_Product__r.Product__r.Name, ECM_Contract_Type__c,ECM_Lead_Brand__c , ECM_Max_TI_limit_per_min_UoM_value__c , ECM_Max_TI_limit_per_9LC_EU_value__c,ECM_Market_Assortment_Product__r.ECM_Pickup_Option__c,ECM_Market_Assortment_Product__r.ECM_Pickup_Option__r.ECM_Strategy_group__c from ECM_Product_Agreement__c where ECM_Contract_Type__c =:agreementTypeId AND ECM_Preferred__c=false];//ECM-5914
            for(ECM_Product_Agreement__c prdtAgrmt : unpreferredList){
                unpreferredProductsListWrapper unpreferredWrap = new unpreferredProductsListWrapper();
                unpreferredWrap.Product = prdtAgrmt;
                if(prdtVolumeMap.containsKey(prdtAgrmt.ECM_Market_Assortment_Product__r.Product__c)){
                    unpreferredWrap.productVolume = prdtVolumeMap.get(prdtAgrmt.ECM_Market_Assortment_Product__r.Product__c);
                }
                unpreferredWrapList.add(unpreferredWrap);
            }
        }
        wrap.preferredProductsList = preferredWrapList;
        wrap.unpreferredProductsList = unpreferredWrapList;
        if(agreementTypeId != null){
            wrap.selectedAgreementType = [Select id,Name,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Volume_target__c FROM ECM_Contract_Type__c Where Id=:agreementTypeId];
        }
        if(agreementTypeId != null){
            wrap.selectedAgreementType = [Select id,Name,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Volume_target__c FROM ECM_Contract_Type__c Where Id=:agreementTypeId];
        }
        System.debug('Resource Used S2 fetchProductAgreements ends :'+Limits.getQueries()+'/'+Limits.getLimitQueries()+' '+Limits.getCpuTime()+'/'+Limits.getLimitCpuTime()+' '+Limits.getDmlRows()+'/'+Limits.getLimitDmlRows());
        return wrap;
    }
    
   
    // Method Name : cancelContract
    // Description : This method is used to cancel contract
    @AuraEnabled
    public static void cancelContract(String con){
        Contract conStat = [select id, Status FROM Contract where id =: con];
        conStat.Status = 'Cancelled';

        update conStat;
    }
    
    
    // Method Name : insertContractitems
    // Description : This method is used to insert contract Items which are new and removed contracts will be deleted
    @AuraEnabled
      //Start added as part of ECM-5788
    public static List<ECM_Contract_Item__c> insertContractitems(Contract contrObj,List<ECM_Product_Agreement__c> prodagrList,String addendumRecordId){
 	 //End added as part of ECM-5788        
        Set<Id> mrtPrdctsIdSet = new Set<Id>();
        set<Id> productIds=New set<Id>();
        Map<String,ECM_Price_List_Item__c> Pricelistmap=New Map<string,ECM_Price_List_Item__c>();
        List<ECM_Technical_Market_Setting__mdt> mktSetList =  new List<ECM_Technical_Market_Setting__mdt>();
        List<ECM_Contract_Item__c> tobeinsertedcontractList=New List<ECM_Contract_Item__c>();
        List<ECM_Price_List_Item__c> priceListItem = new List <ECM_Price_List_Item__c>();
        Set<Id> agrtypeId= new Set<Id>();
        Map<String,ECM_Price_List_Item__c> prodpriceListmap = New Map<String,ECM_Price_List_Item__c>();
        
        contract con = [SELECT Id,ECM_Agreement_Type__r.Geography__r.Name,ECM_Agreement_Type__r.Geography__r.Code__c,
                        ECM_Agreement_Type__r.ECM_Volume_target__c,Account.Country__r.Code__c 
                        FROM contract 
                        WHERE Id =:contrObj.Id];
        mktSetList = [SELECT masterlabel,ECM_Country__c,P_L_Calculation_on_Agreement_Type_PL__c
                      				FROM ECM_Technical_Market_Setting__mdt 
                      				WHERE ECM_Country__c =:con.Account.Country__r.Code__c];
        List<ECM_Contract_Item__c> perviousContractItemsList = [Select Id, ECM_Product__c, ECM_Contract__c FROM ECM_Contract_Item__c WHERE ECM_Contract__c =: contrObj.Id];
        for(ECM_Contract_Item__c ci : perviousContractItemsList){
            
            mrtPrdctsIdSet.add(ci.ECM_Product__c);
        }
        Set<Id> removedMrtPrdctsIsDet = mrtPrdctsIdSet.Clone();
        //Changes for ECM-4400
        Boolean checkMktStng = mktSetList[0].P_L_Calculation_on_Agreement_Type_PL__c;
        if(checkMktStng){
            priceListItem=[SELECT Id,ECM_Product__c,ECM_Pickup_Option__c,ECM_Price_List__c, ECM_Base_UoM__c,
                           ECM_EU_Conversion_Factor__c,ECM_Base_Price__c,ECM_Cost_of_Goods_Sold__c  
                           FROM ECM_Price_List_Item__c 
                           WHERE ECM_Price_List__c  IN (SELECT ECM_Agreement_Price_List__c 
                                                        FROM ECM_Contract_Type__c 
                                                        WHERE Id = :contrObj.ECM_Agreement_Type__c)];//ECM-4400
        }else{
            priceListItem=[SELECT Id,ECM_Product__c,ECM_Pickup_Option__c,
                           ECM_EU_Conversion_Factor__c,ECM_Base_Price__c,ECM_Cost_of_Goods_Sold__c
                           FROM ECM_Price_List_Item__c 
                           WHERE ECM_Price_List__r.ECM_Geography__r.Name =: con.ECM_Agreement_Type__r.Geography__r.Name];
        }
        //ECM-4400 end
        
        if(!priceListItem.isEmpty()){
        	for(ECM_Price_List_Item__c plItem:priceListItem){
            	if(plItem.ECM_Product__c !=null){
                	prodpriceListmap.put(con.ECM_Agreement_Type__r.Geography__r.Name=='Australia'? plItem.ECM_Product__c+'-'+plItem.ECM_Pickup_Option__c:plItem.ECM_Product__c+'_'+plItem.ECM_Base_UoM__c ,plItem);
            	}
        	}
        }
        //ECM-5847- added to get MAP ids and base uom and cm uom fields
        Set<Id> mrtPrdcts = new Set<Id>();
        for(ECM_Product_Agreement__c epa:prodagrList){
            mrtPrdcts.add(epa.ECM_Market_Assortment_Product__c);
        }
        
        Map<Id,Market_Assortment_Product__c> mrtAssetProdMap = new Map<Id,Market_Assortment_Product__c>([SELECT Id,ECM_CM_UoM__c,Base_UoM__c FROM Market_Assortment_Product__c where Id IN :mrtPrdcts AND Id NOT IN: mrtPrdctsIdSet]);
        for(ECM_Product_Agreement__c epa:prodagrList){            
            removedMrtPrdctsIsDet.remove(epa.ECM_Market_Assortment_Product__c);
            if(!mrtPrdctsIdSet.contains(epa.ECM_Market_Assortment_Product__c)){
                ECM_Contract_Item__c contractItem=New ECM_Contract_Item__c();
                contractItem.ECM_Contract__c = contrObj.Id;
                contractItem.ECM_Lead_Brand__c = epa.ECM_Lead_Brand__c;
                contractItem.ECM_Product__c=epa.ECM_Market_Assortment_Product__c;
                //Insert 'CI Product Strategy' when 'Product' is inserted in Contract Item ECM-5914
                if(epa.ECM_Market_Assortment_Product__r.ECM_Pickup_Option__c != null && epa.ECM_Market_Assortment_Product__r.ECM_Pickup_Option__r.ECM_Strategy_group__c != null){
                    contractItem.ECM_CI_Product_Strategy__c = epa.ECM_Market_Assortment_Product__r.ECM_Pickup_Option__r.ECM_Strategy_group__c;
                }
                
                if(mrtAssetProdMap.containsKey(epa.ECM_Market_Assortment_Product__c) && mrtAssetProdMap.get(epa.ECM_Market_Assortment_Product__c).ECM_CM_UoM__c!=null ){//ECM-5847
                    contractItem.ECM_Contracts_UoM__c = mrtAssetProdMap.get(epa.ECM_Market_Assortment_Product__c).ECM_CM_UoM__c;
                }
                else if(mrtAssetProdMap.containsKey(epa.ECM_Market_Assortment_Product__c) && mrtAssetProdMap.get(epa.ECM_Market_Assortment_Product__c).Base_UoM__c!=null){//ECM-5847
                    contractItem.ECM_Contracts_UoM__c = mrtAssetProdMap.get(epa.ECM_Market_Assortment_Product__c).Base_UoM__c;
                }
                if(con.ECM_Agreement_Type__r.ECM_Volume_target__c == false){
                    contractItem.ECM_UoM__c='0';
                    contractItem.ECM_Volume__c=0;
                    contractItem.ECM_Investment__c=0;    
                }
                //Start added as part of ECM-5788
                if(addendumRecordId!=null){
                    contractItem.ECM_Addendum__c=addendumRecordId;
                }
                  //End added as part of ECM-5788
                tobeinsertedcontractList.add(contractItem);
            }
        }
        if(removedMrtPrdctsIsDet.size() > 0){
            list<ECM_Contract_Item__c> removedContractItemsList = [Select Id, ECM_Product__c, ECM_Contract__c FROM ECM_Contract_Item__c WHERE ECM_Contract__c =: contrObj.Id AND ECM_Product__c IN: removedMrtPrdctsIsDet];
            Delete removedContractItemsList;
        }
        
        List<ECM_Contract_Item__c> tobereturnedList=New List<ECM_Contract_Item__c>();
        if(tobeinsertedcontractList.size()>0){
            insert tobeinsertedcontractList;  
            tobereturnedList =[SELECT Id,ECM_Product__c,ECM_Price_List_ConItem__c,ECM_Price_List_ConItem__r.ECM_Base_UoM__c,ECM_Contracts_UoM__c,
                               ECM_Contract__r.ECM_Agreement_Type__r.Volume_UoM_for_Spirits__c,ECM_Product__r.Product_Name__c,
                               ECM_Product__r.Product__c,ECM_Lead_Brand__c,ECM_Investment__c,ECM_Volume__c,ECM_UoM__c,ECM_Cogs_per_Unit__c,
                               ECM_Contract__c,ECM_Contract__r.ECM_Banner__c,ECM_Product__r.Base_UOM__c,ECM_Price_List_ConItem__r.ECM_EU_Conversion_Factor__c,
                               ECM_Price_List_ConItem__r.ECM_Base_Price__c,ECM_Price_List_ConItem__r.ECM_Cost_of_Goods_Sold__c,ECM_Net_Net_List_Price__c
                               FROM ECM_Contract_Item__c 
                               WHERE ECM_Contract__c =:contrObj.Id];  
            for(ECM_Contract_Item__c conitems : tobereturnedList ){ 
                String tempKey;
                if(checkMktStng){
                    tempKey = conitems.ECM_Product__r.Product__c+'_'+conitems.ECM_Contracts_UoM__c;//ECM-5977
                }else{
                    tempKey = String.valueOf(conitems.ECM_Product__r.Product__c)+'-'+String.valueOf(conitems.ECM_Contract__r.ECM_Banner__c);

                }                 
                //Changes done for ECM-5977
                if(prodpriceListmap.containsKey(tempKey)){ //Changes done for 4400                     
                  conitems.ECM_Price_List_ConItem__c =prodpriceListmap.get(tempKey).id;
                      // Update Net Net List Price and COGS in Contract Item ECM-5914                      
                      Decimal basePrice = prodpriceListmap.get(tempKey).ECM_Base_Price__c;
                      Decimal convFactr = prodpriceListmap.get(tempKey).ECM_EU_Conversion_Factor__c;
                      Decimal costGoodsold = prodpriceListmap.get(tempKey).ECM_Cost_of_Goods_Sold__c;
                      if(convFactr != null){
                          conitems.ECM_Net_Net_List_Price__c = basePrice != null ? convFactr * basePrice : null;
                          conitems.ECM_Cogs_per_Unit__c = costGoodsold != null ? convFactr * costGoodsold : null;
                      }                  
                }
            }
            update tobereturnedList;            
        }        
        
        tobereturnedList =[Select Id,ECM_Product__c,ECM_Price_List_ConItem__c,ECM_Product__r.Product_Name__c,ECM_Lead_Brand__c,ECM_Investment__c,ECM_Volume__c,ECM_UoM__c,ECM_Contract__c from ECM_Contract_Item__c where ECM_Contract__c =:contrObj.Id];  
        upsert contrObj;
        return tobereturnedList;
    }
    
    // Wrapper Class : selectProductsWrapper
    // Description   : This wrapper will hold Products as two seperate Lists
    public class selectProductsWrapper{
        @AuraEnabled public List<preferredProductsListWrapper> preferredProductsList{get;set;}
        @AuraEnabled public List<unpreferredProductsListWrapper> unpreferredProductsList{get;set;}
        @AuraEnabled public ECM_Contract_Type__c selectedAgreementType{get;set;}
    }
    public class preferredProductsListWrapper{
        @AuraEnabled public ECM_Product_Agreement__c Product{get;set;}
        @AuraEnabled public ECM_Price_List_Item__c Pricelist{get;set;}
        @AuraEnabled public Decimal productVolume{get;set;}
    }
    public class unpreferredProductsListWrapper{
        @AuraEnabled public ECM_Product_Agreement__c Product{get;set;}
        @AuraEnabled public Decimal productVolume{get;set;}
    }
    
}