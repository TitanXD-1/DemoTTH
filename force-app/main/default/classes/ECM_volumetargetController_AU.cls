/*
*@Name: ECM_volumetargetController_AU
*@Description: This Class is used to fetch the Products and display it in Lightning component - ECM_VolumeTraget
*@History                                                            
*VERSION			AUTHOR							DATE				DETAIL
*1.0			Dasaratha Rami Reddy			03/03/2020			Initial Development
*2.0			Anivesh Muppa					05/03/2021			Modified as per INC19820878
*3.0			Anshu Prakash					13/01/2022			Modified as per ECM-5094;Product Section for the new category on Screen 3 of contract creation_AUS
*3.1			Saurav Prasad					23/02/2022			ECM-5220 - Logic_New Field In Agreement Type for the new screen-"Activation Spend"
*3.2			Nikhilesh Chandak				08/06/2022			ECM-5660 - Added ECM_Exclusive field in conItemList query for E&S contracts
*
*/
public class ECM_volumetargetController_AU {
    
    @AuraEnabled
    public static List<strategywrapper> fetchvolumetargets(contract conObj){
        List<strategywrapper> strategywrapperList=New List<strategywrapper>();
        set<Id> productIds=New set<Id>();
        List<String> strategyList= new list<string>{'RTD[AU]','Spirits[AU]','Spirits Pouring[AU]','Spirits Premium[AU]','Spirits Reserve[AU]','Spirits Draught[AU]','Distilled Non-alcoholic Adult Beverage[AU]'};
            Map<id,Decimal> matoriginalmap=New Map<id,Decimal>();
        Map<String,ECM_Price_List_Item__c> totalsalesdrivermap=New Map<string,ECM_Price_List_Item__c>();
        Map<String,List<ECM_Contract_Item__c>> contractmap=New Map<String,List<ECM_Contract_Item__c>>();  
        contract contra=[select id,accountid,ECM_Agreement_Type__c,ECM_Agreement_Type__r.Geography__r.Name,StartDate,RecordType.Name,ECM_Select_UoM__c,ECM_Payment_Frequency_type__c,ECM_Overall_Investment_Amount__c,Contract_End_Date__c,ECM_Banner__c,ECM_Channel__c,
                         Account.Hybrid__c, Account.Parent_Outlet__c,Account.Parent_Outlet__r.Parent_Outlet__c,Account.Parent_Outlet__r.Hybrid__c from contract where id =: conObj.id];
        
        List<ECM_Contract_Item__c> conItemList=[Select Id,ECM_Contract__r.ECM_Banner__c,ECM_Contract__r.AccountId,ECM_Contract__r.ECM_Agreement_Type__c,ECM_Product__r.Product__c,ECM_Product__r.Product__r.Name,ECM_Product__r.ECM_Pickup_Option__r.Name, 
                                                ECM_First_Pour__c,ECM_Mandatory_Back_Bar__c,ECM_Exclusive__c,ECM_Volume_hybrid_original__c,ECM_volume_hybrid_override__c,ECM_Hybrid_ON__c,
                                                ECM_MAT_original__c,ECM_MAT_override__c,ECM_TSDD_Original__c,ECM_TSDD_Override__c,ECM_TotalAdditional_Discount__c,ECM_Product_Name__c,
                                                ECM_TotalSKU_SpecificRebate__c,ECM_FinalLUC_Current__c,ECM_FinalLUC_Target__c,ECM_LUC_Discount__c,ECM_Contract__r.ECM_RTD_Sales_driver__c,
                                                ECM_Contract__r.ECM_Spirits_Sales_driver__c,ECM_Contract__r.ECM_Spirits_Pouring_Sales_driver__c,ECM_Contract__r.ECM_Spirits_Premium_Sales_driver__c, 
                                                ECM_Contract__r.ECM_Spirits_Reserve_Sales_driver__c,ECM_Contract__r.ECM_Draught_Spirits_Sales_driver__c,ECM_Contract__r.ECM_Channel__c,ECM_MAT_Original_Entered__c,
                                                ECM_Contract__r.ECM_RTD_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name,ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name,
                                                ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name,ECM_Contract__r.ECM_Distilled_NonAlchlic_Sales_driver__c,ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name,ECM_Volume_Target_Investment_Description__c from ECM_Contract_Item__c where ECM_Contract__c =:conObj.Id];
        for(ECM_Contract_Item__c conItem:conItemList){
            productIds.add(conItem.ECM_Product__r.Product__c);
            if(!contractmap.containskey(conItem.ECM_Product__r.ECM_Pickup_Option__r.Name)){
                contractmap.put(conItem.ECM_Product__r.ECM_Pickup_Option__r.Name,new List<ECM_Contract_Item__c>());
                contractmap.get(conItem.ECM_Product__r.ECM_Pickup_Option__r.Name).add(conItem);    
            }else{
                contractmap.get(conItem.ECM_Product__r.ECM_Pickup_Option__r.Name).add(conItem);                
            }
        }
        
        matoriginalmap=ECM_Get_Product_Depletions_Basevolume.ECM_Get_Product_Depletions_Basevolume(conItemList,contra,system.today(),true);
        List<ECM_Price_List_Item__c> priceListItems=[Select Id,ECM_UOS__c,ECM_Base_Price__c,ECM_Gross_Profit__c,ECM_Range__c,ECM_PL1__c,ECM_SD1__c,ECM_Cost_of_Goods_Sold__c,ECM_Global_Minimum__c,ECM_LUC_Conversion_Factor__c,ECM_Banner_Discount__c,ECM_Landed_Unit_Cost__c,ECM_Sales_Driver_Discount__c,ECM_Product__c from ECM_Price_List_Item__c where ECM_Product__c In:productIds
                                                     AND ECM_Price_List__r.ECM_Geography__r.Name=:'Australia' and  ECM_Pickup_Option__c =:contra.ECM_Banner__c];
        for(ECM_Price_List_Item__c price:priceListItems){            
            totalsalesdrivermap.put(price.ECM_Product__c,price);            
        }
        for( String str:strategyList){
            if(contractmap.containskey(str)){
                strategywrapper strwrapper=New strategywrapper();
                List<volumetargetwrapper> volumewrapperList=New List<volumetargetwrapper>();
                for(ECM_Contract_Item__c conitem:contractmap.get(str)){ 
                    if(totalsalesdrivermap.containskey(conitem.ECM_Product__r.Product__c)){
                        volumetargetwrapper volumewrapper =New volumetargetwrapper();
                        volumewrapper.contractItem =  conitem;
                        if(conitem.ECM_Contract__r.ECM_Channel__c =='Hybrid'){
                            
                            if(conitem.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]'){
                                
                                volumewrapper.hybridVolumeSplit =  conitem.ECM_Contract__r.ECM_RTD_Sales_driver__c !=Null ? conitem.ECM_Contract__r.ECM_RTD_Sales_driver__c :0;
                            }
                            else if(conitem.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]'){
                                volumewrapper.hybridVolumeSplit =  conitem.ECM_Contract__r.ECM_Spirits_Sales_driver__c !=Null ? conitem.ECM_Contract__r.ECM_Spirits_Sales_driver__c :0;
                            }
                            else if(conitem.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]'){
                                volumewrapper.hybridVolumeSplit =  conitem.ECM_Contract__r.ECM_Spirits_Pouring_Sales_driver__c !=Null ? conitem.ECM_Contract__r.ECM_Spirits_Pouring_Sales_driver__c :0;
                            }
                            else if(conitem.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]'){
                                volumewrapper.hybridVolumeSplit =  conitem.ECM_Contract__r.ECM_Spirits_Premium_Sales_driver__c !=Null ? conitem.ECM_Contract__r.ECM_Spirits_Premium_Sales_driver__c :0;
                            }
                            else if(conitem.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]'){
                                volumewrapper.hybridVolumeSplit =  conitem.ECM_Contract__r.ECM_Spirits_Reserve_Sales_driver__c !=Null ? conitem.ECM_Contract__r.ECM_Spirits_Reserve_Sales_driver__c :0;
                            }
                            else if(conitem.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]'){
                                volumewrapper.hybridVolumeSplit =  conitem.ECM_Contract__r.ECM_Draught_Spirits_Sales_driver__c !=Null ? conitem.ECM_Contract__r.ECM_Draught_Spirits_Sales_driver__c :0;
                                
                            }
                            //ECM-5094
                            else if(conitem.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]'){
                                volumewrapper.hybridVolumeSplit =  conitem.ECM_Contract__r.ECM_Distilled_NonAlchlic_Sales_driver__c !=Null ? conitem.ECM_Contract__r.ECM_Distilled_NonAlchlic_Sales_driver__c :0;
                                
                            }
                        }
                        else{
                            volumewrapper.hybridVolumeSplit =100;  
                        }
                        decimal Salesdrivediscount = get_sales_driver_discount(conitem,totalsalesdrivermap).get(conitem.ECM_Product__c);
                        volumewrapper.Salesdrivediscount =  Salesdrivediscount!= null ? Salesdrivediscount.setScale(2) :0;
                        volumewrapper.mattargetoriginal =matoriginalmap.get(conitem.ECM_Product__r.Product__c)!=null?matoriginalmap.get(conitem.ECM_Product__r.Product__c):0;
                        volumewrapper.priceListItem =totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c);  
                        //Getting the Mat Target original/Override 
                        //
                        decimal mattargetvalue =(conitem.ECM_MAT_Original_Entered__c && conitem.ECM_MAT_override__c >= 0) ? conitem.ECM_MAT_override__c :volumewrapper.mattargetoriginal ;
                        //Getting the volume  original/Override 
                        decimal matonvalue =mattargetvalue *  ((conitem.ECM_volume_hybrid_override__c >0 ?conitem.ECM_volume_hybrid_override__c:volumewrapper.hybridVolumeSplit)/100);
                        decimal TotalAdditional_Discount=0;
                        /* Calculating Total Additional banner discout starts*/
                        if(conitem.ECM_TSDD_Override__c!=Null && conitem.ECM_TSDD_Override__c >=volumewrapper.Salesdrivediscount){
                            TotalAdditional_Discount= (totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_Banner_Discount__c 
                                                       -(volumewrapper.Salesdrivediscount+(conitem.ECM_TSDD_Override__c-volumewrapper.Salesdrivediscount)))*matonvalue;
                        }
                        else{
                            TotalAdditional_Discount= (totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_Banner_Discount__c 
                                                       -volumewrapper.Salesdrivediscount)*matonvalue;
                        }                        
                        volumewrapper.contractItem.ECM_TotalAdditional_Discount__c = TotalAdditional_Discount >0 ? TotalAdditional_Discount : 0.00;
                        /* Calculating Total Additional banner discout ends*/
                        /* Calculating Current LUC starts*/
                        if(totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_LUC_Conversion_Factor__c !=Null && totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_LUC_Conversion_Factor__c >0){ 
                            if(conitem.ECM_TSDD_Override__c!=Null && conitem.ECM_TSDD_Override__c >=volumewrapper.Salesdrivediscount){
                                volumewrapper.contractItem.ECM_FinalLUC_Current__c =(((totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_Base_Price__c!=Null?totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_Base_Price__c:0)
                                                                                      -(conitem.ECM_TotalSKU_SpecificRebate__c!=Null?conitem.ECM_TotalSKU_SpecificRebate__c:0)
                                                                                      -conitem.ECM_TSDD_Override__c)/(totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_LUC_Conversion_Factor__c)).setScale(2);
                            }
                            else{
                                volumewrapper.contractItem.ECM_FinalLUC_Current__c = (((totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_Base_Price__c!=Null?totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_Base_Price__c:0)
                                                                                       -volumewrapper.Salesdrivediscount
                                                                                       -(conitem.ECM_TotalSKU_SpecificRebate__c!=Null?conitem.ECM_TotalSKU_SpecificRebate__c:0)
                                                                                      )/(totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_LUC_Conversion_Factor__c)).setScale(2);                              
                            }                           
                        }
                        else{
                            volumewrapper.contractItem.ECM_FinalLUC_Current__c =0;   
                        }
                        /* Calculating Current LUC ends*/
                        volumewrapper.contractItem.ECM_TSDD_Override__c = conitem.ECM_TSDD_Override__c!=Null?(conitem.ECM_TSDD_Override__c).setScale(2):0;
                        volumewrapper.contractItem.ECM_TotalSKU_SpecificRebate__c = conitem.ECM_TotalSKU_SpecificRebate__c!=Null?conitem.ECM_TotalSKU_SpecificRebate__c:0;
                        volumewrapper.minsalesdriverval=Integer.valueOf( totalsalesdrivermap.get(conitem.ECM_Product__r.Product__c).ECM_Sales_Driver_Discount__c);
                        system.debug(conitem.ECM_MAT_Original_Entered__c+'@Mat values@'+conitem.ECM_Product_Name__c);
                        //start of change regarding ECM-4065 & INC19820878
                        volumewrapper.mattargetoverRide = (conitem.ECM_MAT_Original_Entered__c && volumewrapper.contractItem.ECM_MAT_override__c>=0)?true:false;
                        system.debug(conitem.ECM_MAT_override__c+'@Mat values@'+volumewrapper.mattargetoverRide);
                        
                        //end of change regarding ECM-4065 & INC19820878
                        volumewrapperList.add(volumewrapper);
                        strwrapper.strategy= conitem.ECM_Product__r.ECM_Pickup_Option__r.Name;
                        strwrapper.volumetargetwrap =volumewrapperList;
                        strwrapper.volumeInvestmentdesc =conitem.ECM_Volume_Target_Investment_Description__c;
                    }  
                    
                } 
                strategywrapperList.add(strwrapper);
            }
        }
        //strategywrapperList.add(strwrapper);
        system.debug('strategywrapperList'+strategywrapperList);
        return strategywrapperList;  
    }
    @AuraEnabled
    public static void updateContractItems(string wrapperJson){
        List<ECM_Contract_Item__c> listconItems = new List<ECM_Contract_Item__c>();
        System.debug('Inside this method'+wrapperJson);
        List<strategywrapper> listwrap =(List<strategywrapper>)JSON.deserialize(wrapperJson, List<strategywrapper>.class);
        Decimal hybridvalue;
        Decimal matvalue;
        for(strategywrapper strwrap : listwrap){
            if(strwrap.volumetargetwrap!=Null){
                for(volumetargetwrapper voltrgetwrap : strwrap.volumetargetwrap){                
                    ECM_Contract_Item__c updateConItems = voltrgetwrap.contractItem;
                    updateConItems.ECM_TSDD_Original__c = (voltrgetwrap.Salesdrivediscount).setScale(2);
                    updateConItems.ECM_Volume_hybrid_original__c =voltrgetwrap.hybridVolumeSplit;
                    system.debug( voltrgetwrap.mattargetoriginal);
                    updateConItems.ECM_MAT_original__c = (voltrgetwrap.mattargetoriginal).setScale(2);
                    updateConItems.ECM_Volume_Target_Investment_Description__c=strwrap.volumeInvestmentdesc;
                    system.debug('Channel val='+updateConItems.ECM_Contract__r.ECM_Channel__c);
                    Decimal matfinal= (updateConItems.ECM_MAT_override__c <=0 && !updateConItems.ECM_MAT_Original_Entered__c) ?updateConItems.ECM_MAT_original__c :updateConItems.ECM_MAT_override__c;
                    if(updateConItems.ECM_volume_hybrid_override__c != null && updateConItems.ECM_volume_hybrid_override__c !=0 && updateConItems.ECM_volume_hybrid_override__c != null){
                        hybridvalue=updateConItems.ECM_volume_hybrid_override__c;
                    } else{
                        hybridvalue =updateConItems.ECM_Volume_hybrid_original__c;
                    }
                    updateConItems.ECM_MAT_UOS__c = (matfinal * voltrgetwrap.priceListItem.ECM_UOS__c).setScale(2);
                    updateConItems.ECM_Total_GP__c = matfinal * voltrgetwrap.priceListItem.ECM_Gross_Profit__c;
                    updateConItems.ECM_Total_COGS__c = matfinal * voltrgetwrap.priceListItem.ECM_Cost_of_Goods_Sold__c;
                    system.debug('reserve'+updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name);
                    
                    if((updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]' && updateConItems.ECM_Contract__r.ECM_RTD_Discount_Level__r.Name =='PL1[AU]')
                       || (updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name =='PL1[AU]')
                       ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name =='PL1[AU]')
                       ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name =='PL1[AU]')
                       ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name =='PL1[AU]')
                       ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]' && updateConItems.ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name =='PL1[AU]')
                       ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]' && updateConItems.ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name =='PL1[AU]') //ECM-5094
                      ){
                          Decimal salesDriver  = matfinal * voltrgetwrap.priceListItem.ECM_PL1__c;
                          Decimal skuSpecificInvoice= updateConItems.ECM_TSDD_Override__c >0 ? (updateConItems.ECM_TSDD_Override__c-updateConItems.ECM_TSDD_Original__c).setScale(2) :0; 
                          updateConItems.ECM_Total_Sales_Driver_Discount__c = salesDriver.setScale(2) ;                         
                          updateConItems.ECMTotal_Additional_Discounts_for_Banner__c = (updateConItems.ECM_Contract__r.ECM_Channel__c == 'Hybrid' && updateConItems.ECM_TotalAdditional_Discount__c!=Null && matfinal>0)?(updateConItems.ECM_TotalAdditional_Discount__c/(matfinal * (hybridvalue/100)))*matfinal:updateConItems.ECM_TotalAdditional_Discount__c;
                          updateConItems.ECM_Total_SKU_Specific_Off_Invoice__c = matfinal *skuSpecificInvoice;
                          updateConItems.ECM_Total_SKU_Specific_Rebate__c = matfinal * updateConItems.ECM_TotalSKU_SpecificRebate__c; 
                      }
                    else if((updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]' && updateConItems.ECM_Contract__r.ECM_RTD_Discount_Level__r.Name =='Range[AU]')
                            || (updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name =='Range[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name =='Range[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name =='Range[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name =='Range[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]' && updateConItems.ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name =='Range[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]' && updateConItems.ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name =='Range[AU]')
                           ){
                               Decimal salesDriver  = matfinal * voltrgetwrap.priceListItem.ECM_Range__c;
                               Decimal skuSpecificInvoice= updateConItems.ECM_TSDD_Override__c >0 ? (updateConItems.ECM_TSDD_Override__c-updateConItems.ECM_TSDD_Original__c).setScale(2) :0; 
                               updateConItems.ECM_Total_Sales_Driver_Discount__c = salesDriver.setScale(2) ;                          
                               updateConItems.ECMTotal_Additional_Discounts_for_Banner__c = (updateConItems.ECM_Contract__r.ECM_Channel__c == 'Hybrid' && updateConItems.ECM_TotalAdditional_Discount__c!=Null && matfinal>0)?(updateConItems.ECM_TotalAdditional_Discount__c/(matfinal * (hybridvalue/100)))*matfinal:updateConItems.ECM_TotalAdditional_Discount__c;
                               updateConItems.ECM_Total_SKU_Specific_Off_Invoice__c = matfinal *skuSpecificInvoice;
                               updateConItems.ECM_Total_SKU_Specific_Rebate__c = matfinal * updateConItems.ECM_TotalSKU_SpecificRebate__c; 
                           }
                    else if((updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]' && updateConItems.ECM_Contract__r.ECM_RTD_Discount_Level__r.Name =='SD1[AU]')
                            || (updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name =='SD1[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name =='SD1[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name =='SD1[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name =='SD1[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]' && updateConItems.ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name =='SD1[AU]')
                            ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]' && updateConItems.ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name =='SD1[AU]')
                           ){
                               Decimal salesDriver  = matfinal * voltrgetwrap.priceListItem.ECM_SD1__c;
                               Decimal skuSpecificInvoice= updateConItems.ECM_TSDD_Override__c >0 ? (updateConItems.ECM_TSDD_Override__c-updateConItems.ECM_TSDD_Original__c).setScale(2) :0; 
                               updateConItems.ECM_Total_Sales_Driver_Discount__c = salesDriver.setScale(2) ;                          
                               updateConItems.ECMTotal_Additional_Discounts_for_Banner__c = (updateConItems.ECM_Contract__r.ECM_Channel__c == 'Hybrid' && updateConItems.ECM_TotalAdditional_Discount__c!=Null && matfinal>0)?(updateConItems.ECM_TotalAdditional_Discount__c/(matfinal * (hybridvalue/100)))*matfinal:updateConItems.ECM_TotalAdditional_Discount__c;
                               updateConItems.ECM_Total_SKU_Specific_Off_Invoice__c = matfinal *skuSpecificInvoice;
                               updateConItems.ECM_Total_SKU_Specific_Rebate__c = matfinal * updateConItems.ECM_TotalSKU_SpecificRebate__c; 
                           }
                    
                    
                    /*if(updateConItems.ECM_volume_hybrid_override__c>0 && updateConItems.ECM_volume_hybrid_override__c<=100){
updateConItems.ECM_Hybrid_ON__c = updateConItems.ECM_volume_hybrid_override__c;
}*/
                    if(updateConItems.ECM_Contract__r.ECM_Channel__c == 'On-Premise' || updateConItems.ECM_Contract__r.ECM_Channel__c == 'Hybrid' ){
                        if( updateConItems.ECM_Contract__r.ECM_Channel__c == 'On-Premise' && (updateConItems.ECM_volume_hybrid_override__c==Null || updateConItems.ECM_volume_hybrid_override__c==0)){
                            updateConItems.ECM_Hybrid_ON__c = updateConItems.ECM_Volume_hybrid_original__c;
                        }
                        if(updateConItems.ECM_volume_hybrid_override__c != null && updateConItems.ECM_volume_hybrid_override__c !=0 && updateConItems.ECM_volume_hybrid_override__c != null){
                            hybridvalue=updateConItems.ECM_volume_hybrid_override__c;
                        }
                        else{
                            hybridvalue =updateConItems.ECM_Volume_hybrid_original__c;
                        }
                        if(updateConItems.ECM_MAT_override__c != null && updateConItems.ECM_MAT_override__c >=0 && updateConItems.ECM_MAT_Original_Entered__c){
                            matvalue=updateConItems.ECM_MAT_override__c;
                        }
                        else{
                            matvalue =updateConItems.ECM_MAT_original__c;
                        }
                        system.debug(updateConItems.ECM_MAT_ON__c);
                        // updateConItems.ECM_Hybrid_ON__c = updateConItems.ECM_Volume_hybrid_original__c;
                        updateConItems.ECM_MAT_ON__c =  matvalue * (hybridvalue/100);
                        system.debug(matvalue);
                        System.debug(hybridvalue);
                        system.debug(updateConItems.ECM_MAT_ON__c);
                        
                        updateConItems.ECM_MAT_UOS_ON__c=updateConItems.ECM_MAT_ON__c* voltrgetwrap.priceListItem.ECM_UOS__c;
                        updateConItems.ECM_Total_GP_ON__c= updateConItems.ECM_MAT_ON__c * voltrgetwrap.priceListItem.ECM_Gross_Profit__c;
                        updateConItems.ECM_Total_COGS_ON__c= updateConItems.ECM_MAT_ON__c * voltrgetwrap.priceListItem.ECM_Cost_of_Goods_Sold__c;
                        if((updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]' && updateConItems.ECM_Contract__r.ECM_RTD_Discount_Level__r.Name =='PL1[AU]')
                           || (updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name =='PL1[AU]')
                           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name =='PL1[AU]')
                           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name =='PL1[AU]')
                           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name =='PL1[AU]')
                           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]' && updateConItems.ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name =='PL1[AU]')
                           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]' && updateConItems.ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name =='PL1[AU]')
                          ){
                              Decimal salesDriver  = updateConItems.ECM_MAT_ON__c * voltrgetwrap.priceListItem.ECM_PL1__c;
                              Decimal skuSpecificInvoice= updateConItems.ECM_TSDD_Override__c >0 ? (updateConItems.ECM_TSDD_Override__c-updateConItems.ECM_TSDD_Original__c).setScale(2) :0; 
                              updateConItems.ECM_Total_Sales_Driver_Discount_ON__c = salesDriver ;
                              decimal Total_Additional_Dis_for_Ban_ON= updateConItems.ECM_TotalAdditional_Discount__c;
                              updateConItems.ECM_Total_Additional_Dis_for_Ban_ON__c = Total_Additional_Dis_for_Ban_ON > 0 ? Total_Additional_Dis_for_Ban_ON : 0.00; 
                              updateConItems.ECM_Total_SKU_Specific_Off_Invoice_ON__c = updateConItems.ECM_MAT_ON__c *skuSpecificInvoice;
                              updateConItems.ECM_Total_SKU_Specific_Rebate_ON__c = updateConItems.ECM_MAT_ON__c * updateConItems.ECM_TotalSKU_SpecificRebate__c; 
                          }
                        else if((updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]' && updateConItems.ECM_Contract__r.ECM_RTD_Discount_Level__r.Name =='Range[AU]')
                                || (updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name =='Range[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name =='Range[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name =='Range[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name =='Range[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]' && updateConItems.ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name =='Range[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]' && updateConItems.ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name =='Range[AU]')
                               ){
                                   Decimal salesDriver  = updateConItems.ECM_MAT_ON__c * voltrgetwrap.priceListItem.ECM_Range__c;
                                   Decimal skuSpecificInvoice= updateConItems.ECM_TSDD_Override__c >0 ? (updateConItems.ECM_TSDD_Override__c-updateConItems.ECM_TSDD_Original__c).setScale(2) :0; 
                                   updateConItems.ECM_Total_Sales_Driver_Discount_ON__c = salesDriver ;
                                   decimal Total_Additional_Dis_for_Ban_ON= updateConItems.ECM_TotalAdditional_Discount__c;
                                   updateConItems.ECM_Total_Additional_Dis_for_Ban_ON__c =Total_Additional_Dis_for_Ban_ON > 0 ? Total_Additional_Dis_for_Ban_ON : 0.00;
                                   updateConItems.ECM_Total_SKU_Specific_Off_Invoice_ON__c = updateConItems.ECM_MAT_ON__c *skuSpecificInvoice;
                                   updateConItems.ECM_Total_SKU_Specific_Rebate_ON__c = updateConItems.ECM_MAT_ON__c * updateConItems.ECM_TotalSKU_SpecificRebate__c; 
                               }
                        else if((updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]' && updateConItems.ECM_Contract__r.ECM_RTD_Discount_Level__r.Name =='SD1[AU]')
                                || (updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name =='SD1[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name =='SD1[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name =='SD1[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name =='SD1[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]' && updateConItems.ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name =='SD1[AU]')
                                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]' && updateConItems.ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name =='SD1[AU]')
                               ){
                                   Decimal salesDriver  = updateConItems.ECM_MAT_ON__c * voltrgetwrap.priceListItem.ECM_SD1__c;
                                   Decimal skuSpecificInvoice= updateConItems.ECM_TSDD_Override__c >0 ? (updateConItems.ECM_TSDD_Override__c-updateConItems.ECM_TSDD_Original__c).setScale(2) :0; 
                                   updateConItems.ECM_Total_Sales_Driver_Discount_ON__c = salesDriver ;
                                   decimal Total_Additional_Dis_for_Ban_ON= updateConItems.ECM_TotalAdditional_Discount__c;
                                   updateConItems.ECM_Total_Additional_Dis_for_Ban_ON__c =Total_Additional_Dis_for_Ban_ON > 0 ? Total_Additional_Dis_for_Ban_ON : 0.00;
                                   updateConItems.ECM_Total_SKU_Specific_Off_Invoice_ON__c = updateConItems.ECM_MAT_ON__c *skuSpecificInvoice;
                                   updateConItems.ECM_Total_SKU_Specific_Rebate_ON__c = updateConItems.ECM_MAT_ON__c * updateConItems.ECM_TotalSKU_SpecificRebate__c; 
                               }
                        
                    }
                    listconItems.add(updateConItems);                
                } 
            }
        }
        try{
            Update listconItems;
        }catch(Exception ex){
            system.debug('Exception on contract items Update '+ex.getMessage());
        }
    }
    
    public static Map<id,decimal> get_sales_driver_discount(ECM_Contract_Item__c updateConItems, Map< string,ECM_Price_List_Item__c> totalsalesdrivermap){
        Map<id,decimal> MAp_Productid_sales_driver_discount = new  Map<id,decimal>();
        if((updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]' && updateConItems.ECM_Contract__r.ECM_RTD_Discount_Level__r.Name =='SD1[AU]')
           || (updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name =='SD1[AU]')
           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name =='SD1[AU]')
           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name =='SD1[AU]')
           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name =='SD1[AU]')
           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]' && updateConItems.ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name =='SD1[AU]')
           ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]' && updateConItems.ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name =='SD1[AU]')
          ){
              MAp_Productid_sales_driver_discount.put(updateConItems.ECM_Product__c,totalsalesdrivermap.get(updateConItems.ECM_Product__r.Product__c).ECM_SD1__c);
              
          }
        else if((updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]' && updateConItems.ECM_Contract__r.ECM_RTD_Discount_Level__r.Name =='Range[AU]')
                || (updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name =='Range[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name =='Range[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name =='Range[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name =='Range[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]' && updateConItems.ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name =='Range[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]' && updateConItems.ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name =='Range[AU]')       
               ){
                   MAp_Productid_sales_driver_discount.put(updateConItems.ECM_Product__c,totalsalesdrivermap.get(updateConItems.ECM_Product__r.Product__c).ECM_Range__c);
                   
               }
        else if((updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'RTD[AU]' && updateConItems.ECM_Contract__r.ECM_RTD_Discount_Level__r.Name =='PL1[AU]')
                || (updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Discount_Level__r.Name =='PL1[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Pouring[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Pouring_Discount_Level__r.Name =='PL1[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Premium[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Premium_Discount_Level__r.Name =='PL1[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Reserve[AU]' && updateConItems.ECM_Contract__r.ECM_Spirits_Reserve_Discount_Level__r.Name =='PL1[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Spirits Draught[AU]' && updateConItems.ECM_Contract__r.ECM_Draught_Spirits_Discount_Level__r.Name =='PL1[AU]')
                ||(updateConItems.ECM_Product__r.ECM_Pickup_Option__r.Name == 'Distilled Non-alcoholic Adult Beverage[AU]' && updateConItems.ECM_Contract__r.ECM_Distilled_NonAlchlic_Discount_Level__r.Name =='PL1[AU]')        
               ){
                   MAp_Productid_sales_driver_discount.put(updateConItems.ECM_Product__c,totalsalesdrivermap.get(updateConItems.ECM_Product__r.Product__c).ECM_PL1__c);
                   
               }
        
        
        return MAp_Productid_sales_driver_discount;
    }
    /*
	* @description	:	This method is used to save Contract changes(ECM-5220)
    * @return		:	returns void
    * @param		:	contract 
	*/
    @AuraEnabled
    public static void savecontract(contract con){
        upsert con;
    }
    
    public class strategywrapper{
        @AuraEnabled public String strategy{get;set;}
        @AuraEnabled public List<volumetargetwrapper> volumetargetwrap{get;set;}
        @AuraEnabled public String volumeInvestmentdesc{get;set;}
    }
    public class volumetargetwrapper{
        @AuraEnabled public ECM_Contract_Item__c contractItem {get;set;}
        @AuraEnabled public Decimal mattargetoriginal{get;set;}
        @AuraEnabled public boolean mattargetoverRide{get;set;}
        
        @AuraEnabled public Decimal hybridVolumeSplit{get;set;}
        @AuraEnabled public ECM_Price_List_Item__c priceListItem{get;set;}       
        @AuraEnabled public Integer minsalesdriverval{get;set;}
        @AuraEnabled public  Decimal Salesdrivediscount{get;set;}
        
    }
    
}