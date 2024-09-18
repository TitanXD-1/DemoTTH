/*
 * Class Name : ECM_updatePaymentSummaryItemsQueuable
 * @description: This Class used to queue the data from "ECM_updateDepletionsQueuable"
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0      Manikandan T         16/07/2021        	Initial Development
 * 2.0		Saurav Prasad		 16/07/2021			Development for ECM-4663
 * 3.0		Sayan Mullick		 03/09/2021			Development for ECM-4748 -> Payment Summary %Achieved table calc.

*/

public class ECM_updatePaymentSummaryItemsQueuable implements Queueable{
    
    String conId;
    String volumejson;
    
    public ECM_updatePaymentSummaryItemsQueuable(String conId,String volumeWrap ) {
        this.conId=conId;
        this.volumejson= volumeWrap;
    }
    public void execute(System.QueueableContext qc) {
        
        List<VolumeInputWrapper> volumeWrap = new List<VolumeInputWrapper>();
        Map<Id, Decimal> psMap= new Map<Id, Decimal>();
        set<String> restrictedPaymentStatus = new set<String>{'Submitted','Approved','Completed','In Approval process'};
            try{
                if(string.isNotBlank(volumejson)){
                    volumeWrap =(List<VolumeInputWrapper>)JSON.deserialize(volumejson, List<VolumeInputWrapper>.class);             
                }
                Set<String> uniqueDepletionId = new Set<String>();
                if(!volumeWrap.isEmpty()){
                    Contract conRec = [SELECT Id, Account.Country__c, ECM_Payment_Frequency_type__c, ECM_Payment_Frequency_type__r.ECM_Type__c, AccountId, ECM_Payment_Frequency__c, Contract_End_Date__c, StartDate FROM Contract where Id=:conId];
                    Market_Setting__c marSet = [SELECT Id,Name,Geography__c,ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c,Depletion_market__c,ECM_Enable_Target__c FROM Market_Setting__c Where Geography__c =: conRec.Account.Country__c];
                    
                    Map<Id, ECM_Payment_Summary_Item__c> updatePayItems = new Map<Id, ECM_Payment_Summary_Item__c>();
                    Map<id,List<ECM_Payment_Summary_Item__c>> mapOfupdatePayItems = new Map<Id,List<ECM_Payment_Summary_Item__c>>();
                    set<Id> contItemIds = new set<Id>();
                    List<ECM_Payment_Summary_Item__c> listOfPayItems = new List<ECM_Payment_Summary_Item__c>();
                    Map<Id,List<ECM_Payment_Summary_Item__c>> mapOfApprovedPaymentSummary= new Map<Id,List<ECM_Payment_Summary_Item__c>>();
                    Map<Id,ECM_Tiering__c> mapOfTier = new Map<Id,ECM_Tiering__c>();
                    List<ECM_Payment_Summary__c> psLst = new List<ECM_Payment_Summary__c>();
                    List<ECM_Payment_Summary__c> updatePaySum = New List<ECM_Payment_Summary__c>();
                    
                    //get all Payment summaries
                    for(ECM_Payment_Summary__c paysum:[SELECT Id, ECM_Contract__c, ECM_End_Period__c, ECM_Invoice_Receival_Date__c, ECM_Invoice_Status__c, ECM_Payment_Summary_Status__c,                                                             
                                                       ECM_Sales_Driver__c, ECM_Start_Period__c, ECM_Tax_Rate__c, ECM_Total_Amount_Confirmed__c,ECM_Total_Amount_Forecasted__c, ECM_Type__c, ECM_Budget_types__c,
                                                       ECM_Fiscal_Years__c, ECM_Total_to_be_Invoiced__c, ECM_UoS_Total__c, ECM_No_Invoice_Required__c, ECM_Approval_Date__c, ECM_Payment_Due_Date__c,ECM_Submitted_Date__c,
                                                       ECM_Contract__r.Account.Country__r.Name,ECM_Contract__r.Status,
                                                       (SELECT Id,ECM_Payment_Summary__c,ECM_Payment_Summary__r.ECM_End_Period__c, ECM_Payment_Summary__r.ECM_Start_Period__c, ECM_Confirmed_Amount_Per_Payment__c, ECM_Contract_Item__c,

                                                        ECM_Contract_Item__r.ECM_Product__r.Product__c,ECM_Contract_Item__r.ECM_Lead_Brand__c,ECM_Confirmed_Volume__c, ECM_Actual_Cases__c,ECM_Contract_Item__r.ECM_UoM__c,ECM_Payment_Summary__r.ECM_Contract__c,ECM_Percentage_Target_Achieved__c,ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c 

                                                        FROM Payment_Summary_Item__r) FROM ECM_Payment_Summary__c 
                                                       Where Ecm_Contract__c=:conId AND ECM_Type__c=:System.label.Ecm_Payment_Summary_Volume_based]){
                                                           //Depletion market check
                                                           if(!marSet.Depletion_market__c){
                                                               psLst.add(paysum);
                                                               if(paysum.ECM_Contract__r.Status == 'Active'
                                                                  && 
                                                                  paysum.Payment_Summary_Item__r.size() > 0){
                                                                      for(ECM_Payment_Summary_Item__c payitem:paysum.Payment_Summary_Item__r){
                                                                          contItemIds.add(payitem.ECM_Contract_Item__c);
                                                                      }
                                                                  }
                                                           }
                                                           //filtering with specific payment summary status
                                                           if(!restrictedPaymentStatus.contains(paysum.ECM_Payment_Summary_Status__c)){
                                                               listOfPayItems.addAll(paysum.Payment_Summary_Item__r);
                                                               mapOfupdatePayItems.put(paysum.Id,paysum.Payment_Summary_Item__r);
                                                           }
                                                           
                                                           //get Approved Payment summary items
                                                           else if((paysum.ECM_Payment_Summary_Status__c == 'Approved' || 
                                                                    paysum.ECM_Payment_Summary_Status__c == 'Completed') &&
                                                                   paysum.ECM_Contract__r.Status == 'Active' && 
                                                                   paysum.Payment_Summary_Item__r.size() > 0){
                                                                       mapOfApprovedPaymentSummary.put(paysum.ECM_Contract__c,paysum.Payment_Summary_Item__r); 
                                                                   }
                                                       }
                    
                    System.debug('mapOfApprovedPaymentSummary--->'+mapOfApprovedPaymentSummary);
                    System.debug('psLst--->'+psLst.size());
                    System.debug('listOfPayItems--->'+listOfPayItems.size());
                    System.debug('mapOfupdatePayItems--->'+mapOfupdatePayItems.size());
                    //map of Tiering
                    for(ECM_Tiering__c tier:[SELECT Id,Name,ECM_Contract_Item__c,
                                             ECM_Tier_1_volume_limit__c,ECM_Tier_1_rate_per_UoM__c,
                                             ECM_Tier_2_volume_limit__c,ECM_Tier2_rate_per_UoM__c,
                                             ECM_Tier_3_volume_limit__c,ECM_Tier_3_rate_per_UoM__c 
                                             FROM ECM_Tiering__c Where ECM_Contract_Item__c IN:contItemIds]){
                                                 mapOfTier.put(tier.ECM_Contract_Item__c,tier);
                                             }
                    
                    
                    for(VolumeInputWrapper volwrap : volumeWrap){
                        if(!volwrap.alteredVolume.isEmpty()){
                            for(ChildVolumeWrapper childVolWrap : volwrap.alteredVolume){
                                uniqueDepletionId.add(childVolWrap.uniqueStr);
                            }
                        }
                        
                    }
                    
                    List<Depletions__c> listOfDepletions = [Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,
                                                            ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c 
                                                            FROM Depletions__c where Unique_ID__c IN:uniqueDepletionId AND ECM_Start_Period__c>=:conRec.StartDate AND ECM_End_Period__c<=:conRec.Contract_End_Date__c AND ECM_Volume__c!=Null];
                    
                    If(!listOfDepletions.isEmpty()){
                        for(ECM_Payment_Summary_Item__c psItems : listOfPayItems){
                            System.debug('psItems-->'+psItems);
                            for(Depletions__c depletn : listOfDepletions){                
                                if((psItems.ECM_Contract_Item__r.ECM_Product__r.Product__c == depletn.ECM_Product__c) && (psItems.ECM_Payment_Summary__r.ECM_Start_Period__c <= depletn.ECM_Start_Period__c) && (psItems.ECM_Payment_Summary__r.ECM_End_Period__c >= depletn.ECM_End_Period__c)){
                                    if(updatePayItems.containskey(psItems.Id)){ 
                                        updatePayItems.get(psItems.Id).ECM_Confirmed_Volume__c += depletn.ECM_Volume__c;
                                        updatePayItems.get(psItems.Id).ECM_Confirmed_Amount_Per_Payment__c = updatePayItems.get(psItems.Id).ECM_Confirmed_Volume__c * Decimal.valueOf(psItems.ECM_Contract_Item__r.ECM_UoM__c);
                                    }else{
                                        updatePayItems.put(psItems.Id,new ECM_Payment_Summary_Item__c(Id=psItems.Id,ECM_Confirmed_Volume__c=depletn.ECM_Volume__c,ECM_Confirmed_Amount_Per_Payment__c=depletn.ECM_Volume__c * Decimal.valueOf(psItems.ECM_Contract_Item__r.ECM_UoM__c),ECM_Percentage_Target_Achieved__c=null));
                                    }
                                    if(marSet.Ecm_Enable_Target__c){
                                        updatePayItems.get(psItems.Id).ECM_Percentage_Target_Achieved__c=(updatePayItems.get(psItems.Id).ECM_Confirmed_Volume__c/psItems.ECM_Contract_Item__r.ECM_Volume_Target_per_PF__c)*100;
                                    }
                                }                
                            }
                        }
                    }
                    
                    //Calculating Confirmed based on Tiering values
                    if(mapOfTier.size()>0){
                        for(Id paySumId : mapOfupdatePayItems.keySet()){
                            Decimal TotalConfirmedAmount = 0;
                            for(ECM_Payment_Summary_Item__c paySumItem: mapOfupdatePayItems.get(paySumId)){
                                decimal volume=0;
                                Decimal payment=0;
                                Id contractId = paySumItem.ECM_Payment_Summary__r.ECM_Contract__c;
                                Id contractItemId = paySumItem.ECM_Contract_Item__c;
                                //getting approved payment summary items
                                if(mapOfApprovedPaymentSummary.containsKey(contractId) 
                                   && 
                                   mapOfTier.containsKey(contractItemId)){
                                       for(ECM_Payment_Summary_Item__c approvedpaySumItem: mapOfApprovedPaymentSummary.get(contractId)){
                                           //Calculating Volume and Confirmed amount from approved Payment Summaries
                                           if(contractItemId == approvedpaySumItem.ECM_Contract_Item__c){
                                               volume += approvedpaySumItem.ECM_Confirmed_Volume__c;
                                               payment += approvedpaySumItem.ECM_Confirmed_Amount_Per_Payment__c;
                                           }
                                       }
                                   }
                                volume += updatePayItems.get(paySumItem.Id).ECM_Confirmed_Volume__c;
                                System.debug('Volume--->'+Volume);
                                System.debug('psLst--->'+psLst);
                                //Tiering Values check based on accumulated Volume
                                if( mapOfTier.containsKey(contractItemId)){
                                    System.debug('mapOfTier--->'+mapOfTier.get(contractItemId));
                                    //Volume check whether it is less than or equal to Tier1 Volume
                                    if(volume <= mapOfTier.get(contractItemId).ECM_Tier_1_volume_limit__c){
                                        updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                            = (volume * mapOfTier.get(contractItemId).ECM_Tier_1_rate_per_UoM__c).setScale(2) 
                                            - payment;
                                    }
                                    //Volume check whether it is greater than Tier1 volume and less than or equal to Tier2 Volume
                                    else if(volume > mapOfTier.get(contractItemId).ECM_Tier_1_volume_limit__c
                                            && 
                                            volume <= mapOfTier.get(contractItemId).ECM_Tier_2_volume_limit__c){
                                                updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                                    = (volume * mapOfTier.get(contractItemId).ECM_Tier2_rate_per_UoM__c).setScale(2) 
                                                    - payment;
                                            }
                                    //Volume check whether it is greater than Tier2 volume and less than or equal to Tier3 Volume
                                    else if(volume > mapOfTier.get(contractItemId).ECM_Tier_2_volume_limit__c
                                            && 
                                            volume <= mapOfTier.get(contractItemId).ECM_Tier_3_volume_limit__c){
                                                updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                                    = (volume * mapOfTier.get(contractItemId).ECM_Tier_3_rate_per_UoM__c).setScale(2) 
                                                    - payment;
                                            }
                                    //Volume check whether it is greater than Tier3 
                                    else if(volume > mapOfTier.get(contractItemId).ECM_Tier_3_volume_limit__c){
                                        //Market Setting Check if it is -- Pay at tier 3 rate any exceeding volume (opt.1)
                                        if(marSet.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c 
                                           == 
                                           'Pay at tier 3 rate any exceeding volume (opt.1)'){
                                               updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                                   = (volume * mapOfTier.get(contractItemId).ECM_Tier_3_rate_per_UoM__c).setScale(2) 
                                                   - payment;
                                           }
                                        //Market Setting Check if it is Not -- Pay at tier 3 rate any exceeding volume (opt.1)
                                        else{
                                            //Check if Tier3 colume and Tier3 Uom is greater than equal to zero
                                            if(((mapOfTier.get(contractItemId).ECM_Tier_3_volume_limit__c
                                                 * mapOfTier.get(contractItemId).ECM_Tier_3_rate_per_UoM__c)
                                                -payment) >= 0){
                                                    updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c 
                                                        = ((mapOfTier.get(contractItemId).ECM_Tier_3_volume_limit__c
                                                            * mapOfTier.get(contractItemId).ECM_Tier_3_rate_per_UoM__c).setScale(2)
                                                           -payment);
                                                }
                                            // Check if Tier3 colume and Tier3 Uom is less than zero                     
                                            else{
                                                updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c = 0;
                                            }
                                        }
                                    }
                                    
                                }
                                TotalConfirmedAmount += updatePayItems.get(paySumItem.Id).ECM_Confirmed_Amount_Per_Payment__c;
                            }
                            //Updating Total Amount Confirmed
                            //updatePaySum.add(new ECM_Payment_Summary__c(Id=paySumId,ECM_Total_Amount_Confirmed__c=TotalConfirmedAmount.setScale(2)));
                            psMap.put(paySumId,TotalConfirmedAmount.setScale(2));
                        }                         
                    }
                    system.debug('Update Paysum='+updatePaySum);
                    system.debug('Update Payitems='+updatePayItems);
                    
                    if(!updatePayItems.isEmpty()){
                        update updatePayItems.values();
                    }
                    updatePaySum = psAchievedTableCalc(mapOfupdatePayItems.keySet(),psMap);
                    //Updating Payment summaries
                    System.debug(updatePaySum);
                    if(!updatePaySum.isEmpty()){
                        update updatePaySum;
                    }
                }            
            }catch(exception ex){
                system.debug('Exception ='+ex.getMessage());
                System.debug('Class:ECM_updatePaymentSummaryItemsQueuable\nmethod:Execute\nException:::' + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());
            }
    }
    /*
	* @description : % Achieved Table calc in Payment Summary Page
	* @return : List<ECM_Payment_Summary__c>
	* @param : Set<Id> , Map<Id,Decimal> 
	*/
    public static List<ECM_Payment_Summary__c> psAchievedTableCalc(Set<Id> paySumId, Map<Id,Decimal> psMap){
        List<ECM_Payment_Summary__c> paySumList = new List<ECM_Payment_Summary__c>();
        Map<Id, ECM_PaymentSummaryController.brandCalculation> psWrapMap= new Map<Id, ECM_PaymentSummaryController.brandCalculation>();
        if(!paySumId.isEmpty()){
            for(ECM_Payment_Summary__c psObj : [SELECT Id, ECM_Start_Period__c,ECM_End_Period__c,ECM_Contract__r.ECM_Duration__c,
                                                (SELECT Id,ECM_Confirmed_Volume__c, ECM_Contract_Item__r.ECM_Lead_Brand__c,ECM_Contract_Item__r.ECM_Volume__c  
                                                 FROM Payment_Summary_Item__r) FROM ECM_Payment_Summary__c WHERE Id IN :paySumId])
            {
                psWrapMap.put(psObj.Id, ECM_PaymentSummaryController.getBrandCalulation(psObj));
            }
            if(!psWrapMap.isEmpty()){
                for(Id psId : psWrapMap.keySet()){   
                    ECM_Payment_Summary__c paySumObj = new ECM_Payment_Summary__c(Id=psId);
                    if(psMap.containsKey(psId)){
                        paySumObj.ECM_Total_Amount_Confirmed__c = psMap.get(psId);
                    }
                    //calc for PS %Achieved Table
                    Decimal totalActualVol = psWrapMap.get(psId).sumOfNonLeadActualVol + psWrapMap.get(psId).sumOfLeadActualVol;
                    Decimal totalTarget = psWrapMap.get(psId).sumOfNonLeadVolTarget + psWrapMap.get(psId).sumOfLeadVolTarget;
                    Decimal achievedOverallVol = totalActualVol + totalTarget;
                    paySumObj.ECM_Achieved_Non_Leading_Brand__c = psWrapMap.get(psId).sumOfNonLeadVolTarget == 0 || psWrapMap.get(psId).sumOfNonLeadVolTarget ==null ? 0 :((psWrapMap.get(psId).sumOfNonLeadActualVol*100)/psWrapMap.get(psId).sumOfNonLeadVolTarget).setScale(1);
                    paySumObj.ECM_Achieved_Leading_Brand__c = psWrapMap.get(psId).sumOfLeadVolTarget == 0 || psWrapMap.get(psId).sumOfLeadVolTarget == null ? 0:((psWrapMap.get(psId).sumOfLeadActualVol*100)/psWrapMap.get(psId).sumOfLeadVolTarget).setScale(1);
                    paySumObj.ECM_Achieved_Overall__c = totalTarget == null || totalTarget ==0 ? 0 : ((totalActualVol*100)/totalTarget).setScale(1);
                    paySumList.add(paySumObj);
                }
            }
        }
        System.debug(paySumList);
        return paySumList;
    }
    
    
    public class VolumeInputWrapper{
        @AuraEnabled
        public List<ChildVolumeWrapper> alteredVolume{get;set;}
        
    }
    Public class ChildVolumeWrapper{
        
        @AuraEnabled
        public String uniqueStr{get;set;}
        
    }
    
    
}