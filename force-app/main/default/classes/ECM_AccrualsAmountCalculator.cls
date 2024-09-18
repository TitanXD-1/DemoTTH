public class ECM_AccrualsAmountCalculator {
    public Map<string,Decimal> getAmountwithoutTax(Map<Id,ECM_Contract_Item__c> ConItemIds ){
        Map<string, wrapobj > conItemWithAmount = new Map<string, wrapobj >();
        Set<Id> accids = new Set<Id>();
        Set<Id> prodids = new Set<Id>();
        Map<string,ECM_Contract_Item_Analysis__c> ciaBudget = new Map<string,ECM_Contract_Item_Analysis__c>(); 
        List<string> uniqueContractProduct = new List<string>();
        Map<string,Decimal> conitemBudgetWithAmount = new  Map<string,Decimal>(); 
        Date lastDate = system.today().addmonths(-1);
        integer periodval =  system.today().month();
        string fiscal = FiscalYear(system.today().toStartOfMonth(),system.today().toStartOfMonth().addMonths(1).addDays(-1)).removeEndIgnoreCase('/');
        system.debug('fiscal='+fiscal);
        Map<String,Market_Setting__c> markMap = new Map<String,Market_Setting__c>();
        for(Market_Setting__c marketsetting :[Select Id,Name,ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c,ECM_Tiering_Payment_Amount_Calculation__c,Geography__r.Name from Market_Setting__c/*where Geography__r.Name=:accObj.Country__r.Name*/]){
            markMap.put(marketsetting.Geography__r.Name,marketsetting);
        }

        Map<ID,List<ECM_Sales_Driver_Item_Detail__c>> itemsSalesdriverDetails = new Map<ID,List<ECM_Sales_Driver_Item_Detail__c>>();
        List<ECM_Sales_Driver_Item_Detail__c> salesdriverItem = [Select Id,Name,ECM_Product__c,ECM_Investment_Amount__c,ECM_Budget_Type__c from ECM_Sales_Driver_Item_Detail__c where ECM_Product__c=:ConItemIds.keyset()];
        for(ECM_Sales_Driver_Item_Detail__c SDID: salesdriverItem){
            if(itemsSalesdriverDetails.containskey(SDID.ECM_Product__c)){
                List<ECM_Sales_Driver_Item_Detail__c> lstSalesdriver = itemsSalesdriverDetails.get(SDID.ECM_Product__c);
                lstSalesdriver.add(SDID);
                itemsSalesdriverDetails.put(SDID.ECM_Product__c,lstSalesdriver);
            }else{
                itemsSalesdriverDetails.put(SDID.ECM_Product__c,new List<ECM_Sales_Driver_Item_Detail__c>{SDID});
            }
            if(conItemWithAmount.containskey(SDID.ECM_Product__c+SDID.ECM_Budget_Type__c)){
                decimal inv = conItemWithAmount.get(SDID.ECM_Product__c+SDID.ECM_Budget_Type__c).amountVal+SDID.ECM_Investment_Amount__c;
                conItemWithAmount.put(SDID.ECM_Product__c+SDID.ECM_Budget_Type__c,new wrapobj(inv,SDID.ECM_Budget_Type__c));
            }else{
                conItemWithAmount.put(SDID.ECM_Product__c+SDID.ECM_Budget_Type__c,new wrapobj(SDID.ECM_Investment_Amount__c,SDID.ECM_Budget_Type__c));
            }
        }
        List<ECM_Contract_Item_Analysis__c> conItemAnalysis =[Select Id,Name,ECM_Agreement_Type_Name__c,Amount_Without_Tax__c,ECM_Budget_Type_Name__c,
                                                              ECM_Concept__c, ECM_Contract_Status__c,ECM_Fiscal_Year__c,ECM_Period__c, ECM_Product_Name__c,
                                                              ECM_Contract_Item_ID__c from ECM_Contract_Item_Analysis__c where CreatedDate=:lastDate AND ECM_Fiscal_Year__c=:fiscal];
        if(conItemAnalysis.size()>0){
            for(ECM_Contract_Item_Analysis__c ciaRec : conItemAnalysis){
                ciaBudget.put(ciaRec.ECM_Contract_Item_ID__c+(ciaRec.ECM_Budget_Type_Name__c==Null?'New':ciaRec.ECM_Budget_Type_Name__c),ciaRec);
            }            
        }
        system.debug('ciaBudget='+ciaBudget);
        for(ECM_Contract_Item__c prodItems : ConItemIds.values()){            
            if(!accids.contains(prodItems.ECM_Contract__r.AccountID)){
                accids.add(prodItems.ECM_Contract__r.AccountID);
            }
            if(!prodids.contains(prodItems.ECM_Product__r.Product__c)){
                prodids.add(prodItems.ECM_Product__r.Product__c);
            }
        }
        //get depletion 
        Map<string,List<Depletions__c>> depletioninfo = new Map<string,List<Depletions__c>>(getDeplication(accids,prodids));
        //get product conversions values 
        Map<Id,List<Map<string,decimal>>> prodConversionfactor = new Map<Id,List<Map<string,decimal>>>(getconversionfactor(prodids));
        system.debug('==conversion map='+prodConversionfactor);
        //get tiering 
        Map<id,ECM_Tiering__c> Conitem_tiering = new Map<id,ECM_Tiering__c>(getTiering(ConItemIds.keyset()));
        
        for(ECM_Contract_Item__c prodItems : ConItemIds.values()){
            if(itemsSalesdriverDetails.containskey(prodItems.Id)){
                decimal A_PVal=0;
                decimal TIVal=0;
                for(ECM_Sales_Driver_Item_Detail__c SDIDRec: itemsSalesdriverDetails.get(prodItems.Id)){
                    if(!uniqueContractProduct.contains(prodItems.id+SDIDRec.ECM_Budget_Type__c)){
                        uniqueContractProduct.add(prodItems.id+SDIDRec.ECM_Budget_Type__c);
                        Decimal amnt= 0;
                        if(conItemWithAmount.containskey(prodItems.id+SDIDRec.ECM_Budget_Type__c)){                             
                            if(SDIDRec.ECM_Budget_Type__c == 'A&P [ES]'){
                                amnt = conItemWithAmount.get(prodItems.id+SDIDRec.ECM_Budget_Type__c).amountVal/prodItems.ECM_contract__r.ECM_Duration__c;
                            }else if(SDIDRec.ECM_Budget_Type__c == 'TI [ES]'){
                                amnt = conItemWithAmount.get(prodItems.id+SDIDRec.ECM_Budget_Type__c).amountVal/prodItems.ECM_contract__r.ECM_Duration__c;
                                Decimal actVol = 0;
                                if(depletioninfo.containskey(prodItems.ECM_Contract__r.AccountID+'-'+prodItems.ECM_Product__r.Product__c)){
                                    amnt+= getDpltnVolumeAmnt(prodItems,depletioninfo,prodConversionfactor,Conitem_tiering,markMap);
                                   /* Date startDate = prodItems.ECM_Contract__r.StartDate;
                                    Date EndDate = system.today().toStartOfMonth().addMonths(1).addDays(-1);
                                    actVol = getvolumecal(depletioninfo.get(prodItems.ECM_Contract__r.AccountID+'-'+prodItems.ECM_Product__r.Product__c),prodItems.ECM_Product__r.Base_UoM__c,startDate,EndDate,prodConversionfactor);
                                  system.debug('actVol='+actVol);
                                    if(Conitem_tiering.size()>0 && Conitem_tiering.containskey(prodItems.id)){
                                        if(actVol>=0 && Conitem_tiering.get(prodItems.id).ECM_Tier_1_volume_limit__c>=actVol){
                                            actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_1_rate_per_UoM__c;
                                        }else if(Conitem_tiering.get(prodItems.id).ECM_Tier_1_volume_limit__c+1<=actVol && Conitem_tiering.get(prodItems.id).ECM_Tier_2_volume_limit__c>=actVol){
                                            actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier2_rate_per_UoM__c;
                                        }else if(Conitem_tiering.get(prodItems.id).ECM_Tier_2_volume_limit__c+1<=actVol && Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c>=actVol){
                                             actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c; 
                                        }
                                        else if(Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c<actVol){
                                            if(markMap.size()>0){
                                                if(markMap.containskey(prodItems.ECM_Contract__r.Account.Country__r.Name)){
                                                    if(markMap.get(prodItems.ECM_Contract__r.Account.Country__r.Name).ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c!=null){
                                                        actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c;
                                                    }else if(markMap.get(prodItems.ECM_Contract__r.Account.Country__r.Name).ECM_Tiering_Payment_Amount_Calculation__c!=null){
                                                        actVol = Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c;
                                                    }
                                                }
                                            }
                                            
                                        }
                                    }else{
                                        actVol = actVol*(prodItems.ECM_UoM__c!=Null?Decimal.valueOf(prodItems.ECM_UoM__c):0);
                                    }*/
                                    
                                }                                 
                                else if(prodItems.ECM_Retro_investment__c!=Null && prodItems.ECM_Retro_investment__c>0){
                                    amnt = amnt+(prodItems.ECM_Retro_investment__c/prodItems.ECM_contract__r.ECM_Duration__c);
                                }
                            }
                            
                        }
                        if(ciaBudget.containskey(prodItems.id+SDIDRec.ECM_Budget_Type__c)){
                            amnt += ciaBudget.get(prodItems.id+SDIDRec.ECM_Budget_Type__c).Amount_Without_Tax__c;
                        }
                        conitemBudgetWithAmount.put(prodItems.id+'-'+SDIDRec.ECM_Budget_Type__c,amnt);
                    }                       
                }
                if(!uniqueContractProduct.contains(prodItems.id+'TI [ES]')){
                    decimal amnt=0; 
                    Decimal actVol = 0;
                    if(depletioninfo.containskey(prodItems.ECM_Contract__r.AccountID+'-'+prodItems.ECM_Product__r.Product__c)){
                       /* Date startDate = prodItems.ECM_Contract__r.StartDate;
                        Date EndDate = system.today().toStartOfMonth().addMonths(1).addDays(-1);
                        actVol = getvolumecal(depletioninfo.get(prodItems.ECM_Contract__r.AccountID+'-'+prodItems.ECM_Product__r.Product__c),prodItems.ECM_Product__r.Base_UoM__c,startDate,EndDate,prodConversionfactor);
                        if(Conitem_tiering.containskey(prodItems.id)){
                            if(actVol>=0 && Conitem_tiering.get(prodItems.id).ECM_Tier_1_volume_limit__c>=actVol){
                                actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_1_rate_per_UoM__c;
                            }else if(Conitem_tiering.get(prodItems.id).ECM_Tier_1_volume_limit__c+1<=actVol && Conitem_tiering.get(prodItems.id).ECM_Tier_2_volume_limit__c>=actVol){
                                actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier2_rate_per_UoM__c;
                            }else if(Conitem_tiering.get(prodItems.id).ECM_Tier_2_volume_limit__c+1<=actVol && Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c>=actVol){
                                             actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c; 
                                        }
                                        else if(Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c<actVol){
                                            if(markMap.size()>0){
                                                if(markMap.containskey(prodItems.ECM_Contract__r.Account.Country__r.Name)){
                                                    if(markMap.get(prodItems.ECM_Contract__r.Account.Country__r.Name).ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c!=null){
                                                        actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c;
                                                    }else if(markMap.get(prodItems.ECM_Contract__r.Account.Country__r.Name).ECM_Tiering_Payment_Amount_Calculation__c!=null){
                                                        actVol = Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c;
                                                    }
                                                }
                                            }
                                            
                                        }
                        }else{
                            actVol = actVol*(prodItems.ECM_UoM__c!=null?Decimal.valueOf(prodItems.ECM_UoM__c):1);
                        }*/
                        amnt+= getDpltnVolumeAmnt(prodItems,depletioninfo,prodConversionfactor,Conitem_tiering,markMap);
                        //amnt+=actVol;
                    }
                    else if(prodItems.ECM_Retro_investment__c!=Null && prodItems.ECM_Retro_investment__c>0){
                        amnt = (prodItems.ECM_Retro_investment__c/prodItems.ECM_contract__r.ECM_Duration__c);                        
                    }
                    if(ciaBudget.containskey(prodItems.id+'TI [ES]')){
                        amnt += ciaBudget.get(prodItems.id+'TI [ES]').Amount_Without_Tax__c;
                    }
                    conitemBudgetWithAmount.put(prodItems.id+'-'+'TI [ES]',amnt);      
                }
            }else{
                Decimal amnt= 0;
                Decimal actVol = 0;
                if(depletioninfo.containskey(prodItems.ECM_Contract__r.AccountID+'-'+prodItems.ECM_Product__r.Product__c)){
                    /*Date startDate = prodItems.ECM_Contract__r.StartDate;
                    Date EndDate = system.today().toStartOfMonth().addMonths(1).addDays(-1);
                    actVol = getvolumecal(depletioninfo.get(prodItems.ECM_Contract__r.AccountID+'-'+prodItems.ECM_Product__r.Product__c),prodItems.ECM_Product__r.Base_UoM__c,startDate,EndDate,prodConversionfactor);
                    if(Conitem_tiering.containskey(prodItems.id)){
                        if(actVol>=0 && Conitem_tiering.get(prodItems.id).ECM_Tier_1_volume_limit__c>=actVol){
                            actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_1_rate_per_UoM__c;
                        }else if(Conitem_tiering.get(prodItems.id).ECM_Tier_1_volume_limit__c+1<=actVol && Conitem_tiering.get(prodItems.id).ECM_Tier_2_volume_limit__c>=actVol){
                            actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier2_rate_per_UoM__c;
                        }else if(Conitem_tiering.get(prodItems.id).ECM_Tier_2_volume_limit__c+1<=actVol && Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c>=actVol){
                                             actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c; 
                                        }
                                        else if(Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c<actVol){
                                            if(markMap.size()>0){
                                                if(markMap.containskey(prodItems.ECM_Contract__r.Account.Country__r.Name)){
                                                    if(markMap.get(prodItems.ECM_Contract__r.Account.Country__r.Name).ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c!=null){
                                                        actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c;
                                                    }else if(markMap.get(prodItems.ECM_Contract__r.Account.Country__r.Name).ECM_Tiering_Payment_Amount_Calculation__c!=null){
                                                        actVol = Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c;
                                                    }
                                                }
                                            }
                                            
                                        }
                    }else{
                        actVol = actVol*(prodItems.ECM_UoM__c!=null?Decimal.valueOf(prodItems.ECM_UoM__c):1);
                    }*/
                    amnt+= getDpltnVolumeAmnt(prodItems,depletioninfo,prodConversionfactor,Conitem_tiering,markMap);
                   // amnt+=actVol; 
                    /*if(ciaBudget.containskey(prodItems.id+'New')){
amnt += ciaBudget.get(prodItems.id+'New').Amount_Without_Tax__c+amnt;
}*/
                    /*if(prodItems.ECM_Retro_investment__c!=Null && prodItems.ECM_Retro_investment__c>0){
amnt = amnt+(prodItems.ECM_Retro_investment__c/prodItems.ECM_contract__r.ECM_Duration__c);
if(ciaBudget.containskey(prodItems.id+'TI [ES]')){
amnt += ciaBudget.get(prodItems.id+'TI [ES]').Amount_Without_Tax__c;
}                        
}
conitemBudgetWithAmount.put(prodItems.id+'TI [ES]',amnt);*/
                }
                else if(prodItems.ECM_Retro_investment__c!=Null && prodItems.ECM_Retro_investment__c>0){
                    amnt = (prodItems.ECM_Retro_investment__c/prodItems.ECM_contract__r.ECM_Duration__c);                        
                }
                if(ciaBudget.containskey(prodItems.id+'TI [ES]')){
                    amnt += ciaBudget.get(prodItems.id+'TI [ES]').Amount_Without_Tax__c;
                }
                conitemBudgetWithAmount.put(prodItems.id+'-'+'TI [ES]',amnt);                
                
            }
        }
        return conitemBudgetWithAmount;
    }
    
    public Decimal getDpltnVolumeAmnt(ECM_Contract_Item__c prodItems,Map<string,List<Depletions__c>> depletioninfo,Map<Id,List<Map<string,decimal>>> prodConversionfactor,
                                      Map<id,ECM_Tiering__c> Conitem_tiering,Map<String,Market_Setting__c> markMap){
                                          decimal actVol = 0;
                                          Date startDate = prodItems.ECM_Contract__r.StartDate;
                                          Date EndDate = system.today().toStartOfMonth().addMonths(1).addDays(-1);
                                          actVol = getvolumecal(depletioninfo.get(prodItems.ECM_Contract__r.AccountID+'-'+prodItems.ECM_Product__r.Product__c),prodItems.ECM_Product__r.Base_UoM__c,startDate,EndDate,prodConversionfactor);
                                          system.debug('actVol='+actVol);
                                          if(Conitem_tiering.size()>0 && Conitem_tiering.containskey(prodItems.id)){
                                              if(actVol>=0 && Conitem_tiering.get(prodItems.id).ECM_Tier_1_volume_limit__c>=actVol){
                                                  actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_1_rate_per_UoM__c;
                                              }else if(Conitem_tiering.get(prodItems.id).ECM_Tier_1_volume_limit__c+1<=actVol && Conitem_tiering.get(prodItems.id).ECM_Tier_2_volume_limit__c>=actVol){
                                                  actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier2_rate_per_UoM__c;
                                              }else if(Conitem_tiering.get(prodItems.id).ECM_Tier_2_volume_limit__c+1<=actVol && Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c>=actVol){
                                                  actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c; 
                                              }
                                              else if(Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c<actVol){
                                                  if(markMap.size()>0){
                                                      if(markMap.containskey(prodItems.ECM_Contract__r.Account.Country__r.Name) && markMap.get(prodItems.ECM_Contract__r.Account.Country__r.Name).ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c !=Null){
                                                          if(markMap.get(prodItems.ECM_Contract__r.Account.Country__r.Name).ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c=='Pay at tier 3 rate any exceeding volume (opt.1)'){
                                                              actVol = actVol*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c;
                                                          }else if(markMap.get(prodItems.ECM_Contract__r.Account.Country__r.Name).ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c=='Pay only per tier 3 volume limit (opt.2)'){
                                                              actVol = Conitem_tiering.get(prodItems.id).ECM_Tier_3_volume_limit__c*Conitem_tiering.get(prodItems.id).ECM_Tier_3_rate_per_UoM__c;
                                                          }
                                                      }
                                                  }
                                                  
                                              }
                                          }else{
                                              actVol = actVol*(prodItems.ECM_UoM__c!=null?Decimal.valueOf(prodItems.ECM_UoM__c):1);
                                          }
                                          return actVol;        
                                      }
    
    public Map<id,ECM_Tiering__c> getTiering(Set<id> conitemsId){
        Map<id,ECM_Tiering__c> tieritems = new Map<id,ECM_Tiering__c>();
        for(ECM_Tiering__c tier: [SELECT Id,Name,ECM_Contract_Item__c,ECM_Tier2_rate_per_UoM__c,ECM_Tier_1_rate_per_UoM__c,ECM_Tier_1_volume_limit__c,ECM_Tier_2_volume_limit__c,ECM_Tier_3_rate_per_UoM__c,ECM_Tier_3_volume_limit__c FROM ECM_Tiering__c where ECM_Contract_Item__c IN: conitemsId]){
            tieritems.put(tier.ECM_Contract_Item__c,tier);
        }
        return tieritems;
    }
    
    public static Map<Id,List<Map<string,decimal>>> getconversionfactor(Set<Id> prodIds){
        Map<Id,List<Map<string,decimal>>> conversionmap =new Map<Id,List<Map<string,decimal>>>();
        for(Product_UOM__c ProdUom: [SELECT Id,Name,Product__c,Conversion_Factor__c,Denominator__c,Numerator__c,Type__c,Unique_ID__c 
                                     FROM Product_UOM__c WHERE Product__c IN: ProdIds]){
                                         if(conversionmap.containskey(ProdUom.Product__c)){
                                             List<Map<string,decimal>> lsttypeUom = conversionmap.get(ProdUom.Product__c);
                                             lsttypeUom.add(new Map<string,decimal>{ProdUom.Type__c=>ProdUom.Conversion_Factor__c});
                                             conversionmap.put(ProdUom.Product__c,lsttypeUom); 
                                         }else{
                                             conversionmap.put(ProdUom.Product__c,new List<Map<string,decimal>>{new Map<string,decimal>{ProdUom.Type__c=>ProdUom.Conversion_Factor__c}}); 
                                         }
                                         
                                     }
        return conversionmap;
    }
    public decimal getvolumecal(List<Depletions__c> depltnRecords, string baseuom,Date startdata, Date enddate,Map<Id,List<Map<string,decimal>>> UOMFactor){
        decimal actualvolume=0;
        if(baseuom==Null){
            return 0;
        }
        for(Depletions__c dpltn : depltnRecords){
            if(dpltn.ECM_Start_Period__c>=startdata && dpltn.ECM_End_Period__c<=enddate){
                if(baseuom==dpltn.ECM_UoM__c){
                    actualvolume+=dpltn.ECM_Volume__c;
                    //UOMFactor
                }else{
                    if(UOMFactor.size()>0 && UOMFactor.containskey(dpltn.ECM_Product__c)){
                        if(UOMFactor.get(dpltn.ECM_Product__c).size()>0){
                            for(Map<string,decimal> uomtype: UOMFactor.get(dpltn.ECM_Product__c)){
                                system.debug(dpltn.ECM_Volume__c+'depltn='+baseuom);
                                actualvolume+=(dpltn.ECM_Volume__c*uomtype.get(baseuom));
                            }
                        }
                    }
                }
                
            }
        }
        return actualvolume;
    }
    public static string FiscalYear(Date startDate, Date endDate){
        Integer startDateMonth = startDate.month();
        Integer endDateMonth = endDate.month();
        Integer startDateYear = startDate.year();
        Integer endDateYear = endDate.year();
        String fiscalYear = '';
        for(integer i=startDateYear; i<= endDateYear; i++){
            integer dateYear = i;
            if(i==startDateYear){
                if(startDateMonth<7){
                    fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                }
            }
            if(i==endDateYear){
                if(startDateYear == endDateYear){
                    if(startDateMonth<7 && endDateMonth >= 7){
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    if(startDateMonth >= 7 && endDateMonth >= 7){
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                }
                else if(startDateYear+1 == endDateYear){
                    if(startDateMonth < 7 && endDateMonth < 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    if(startDateMonth >= 7 && endDateMonth < 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    if(startDateMonth >= 7 && endDateMonth >= 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    if(startDateMonth < 7 && endDateMonth >= 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                }
                else{
                    if(endDateMonth >= 7){
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                        dateYear = dateYear+1;
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                    else{
                        fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
                    }
                }
            }
            if(i != startDateYear && i != endDateYear){
                fiscalYear += 'FY'+string.valueof(dateYear).right(2)+'/';
            }
        }
        return fiscalYear;
    }
    public static Map<string,List<Depletions__c>> getDeplication(Set<Id> accids, Set<Id> ProdIds){
        string prevfiscal = FiscalYear(system.today().addMonths(-1).toStartOfMonth(),system.today().toStartOfMonth().addDays(-1)).removeEndIgnoreCase('/');
        string fiscal = FiscalYear(system.today().toStartOfMonth(),system.today().toStartOfMonth().addMonths(1).addDays(-1)).removeEndIgnoreCase('/');		
        Map<String,List<Depletions__c>> deplitionmap = new Map<String,List<Depletions__c>>();
        string queryString = 'Select Name,ECM_Volume__c,ECM_UoM__c,ECM_Product__c,ECM_Outlet__c,ECM_End_Period__c,ECM_Start_Period__c from Depletions__c where ECM_Outlet__c IN:accids AND ECM_Product__c IN:ProdIds';
        if(prevfiscal != fiscal){
            Date startdate = system.today().toStartOfMonth();
            Date enddate = system.today().toStartOfMonth().addMonths(1).addDays(-1);
            queryString = queryString+' AND ECM_Start_Period__c>=:startdate AND ECM_End_Period__c<=:enddate';
        }
        List<Depletions__c> lstdepletion = Database.query(queryString); //[Select Name,ECM_Volume__c,ECM_Product__c,ECM_Outlet__c from Depletions__c where ECM_Outlet__c IN:accids AND ECM_Product__c IN:ProdIds];
        
        system.debug('Depletions==='+lstdepletion);
        for(Depletions__c dpt : lstdepletion){
            if(deplitionmap.containskey(dpt.ECM_Outlet__c+'-'+dpt.ECM_Product__c)){
                deplitionmap.get(dpt.ECM_Outlet__c+'-'+dpt.ECM_Product__c).add(dpt);
            }else{
                deplitionmap.put(dpt.ECM_Outlet__c+'-'+dpt.ECM_Product__c,new List<Depletions__c>{dpt});
            }
            
        }
        return deplitionmap;
    }
    public class wrapobj{
        public decimal amountVal{get;set;}
        public string budgetval {get;set;}
        public wrapobj(decimal amt, string bdt){
            amountVal = amt;
            budgetval = bdt;
        }
    }
}