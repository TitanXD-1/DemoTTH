/**********************************************************************
Name: ECM_CreatePaymentSummaryController
=======================================================================
Purpose: This Class is used to create Non volume and Volume Payment Summaries
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0       Pravalika Golamari    14/01/2021        Initial Development
1.1       Anuja Chattopadhyay   05/07/2021        ECM-4400:Modified fetchUserDetails to include profile check 
                                                   using Generate_Vol_based_PS_Enabled_Profile Label 
***********************************************************************/ 
public without sharing class ECM_CreatePaymentSummaryController {
    @AuraEnabled
    public static ECM_Payment_Summary__c createPaymentSummary(String contractId) {
        ECM_Payment_Summary__c pS =new ECM_Payment_Summary__c() ;
        pS.ECM_Contract__c=contractId;
        pS.ECM_Type__c='Volume-Based';
        pS.ECM_Payment_Summary_Status__c ='Open';
        
        Contract cont = [SELECT id, Name, StartDate, Contract_End_Date__c FROM Contract WHERE Id=:contractId];
        List<ECM_Payment_Summary__c> psList = [SELECT Id, ECM_Type__c, ECM_Start_Period__c, ECM_End_Period__c,ECM_Contract__c FROM ECM_Payment_Summary__c WHERE ECM_End_Period__c != null AND ECM_Type__c = 'Volume-Based' AND ECM_Contract__c =: contractId order by ECM_End_Period__c desc];
        if(psList.size()>0){
            ps.ECM_Start_Period__c = psList[0].ECM_End_Period__c+1;
        }
        else{
            ps.ECM_Start_Period__c = cont.StartDate;
        }
        date newDate = System.today().addMonths(-1);
        Date firstDayOfMonth = newDate.toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        ps.ECM_End_Period__c = lastDayOfMonth;
        
        insert pS;
        
        map<Id,Decimal> contrtItemIdVolumeMap = new Map<Id,Decimal>();
		map<Id,Decimal> contrtItemIdPaymentMap = new Map<Id,Decimal>();
		
        list<ECM_Payment_Summary_Item__c> psItemList = [SELECT Id, ECM_Confirmed_Volume__c,ECM_Confirmed_Amount_Per_Payment__c, ECM_Payment_Summary__c, ECM_Contract_Item__r.ECM_Product__c, ECM_Contract_Item__c
														FROM ECM_Payment_Summary_Item__c 
                                                        where ECM_Payment_Summary__r.ECM_Type__c = 'Volume-Based' AND ECM_Payment_Summary__r.ECM_Payment_Summary_Status__c = 'Approved' AND ECM_Payment_Summary__r.ECM_Contract__c =: contractId];
        if(psItemList.size()>0){
            for(ECM_Payment_Summary_Item__c psItem : psItemList){
				
                if(contrtItemIdVolumeMap.containskey(psItem.ECM_Contract_Item__c)){
                    if(psItem.ECM_Confirmed_Volume__c != null){
                        Decimal volume = psItem.ECM_Confirmed_Volume__c + contrtItemIdVolumeMap.get(psItem.ECM_Contract_Item__c);
                        contrtItemIdVolumeMap.put(psItem.ECM_Contract_Item__c, volume);
                    }
                }
                else{
                    if(psItem.ECM_Confirmed_Volume__c != null){
                        contrtItemIdVolumeMap.put(psItem.ECM_Contract_Item__c, psItem.ECM_Confirmed_Volume__c);
                    }

                }
				
				if(contrtItemIdPaymentMap.containskey(psItem.ECM_Contract_Item__c)){
                    if(psItem.ECM_Confirmed_Amount_Per_Payment__c != null){
                        Decimal payment = psItem.ECM_Confirmed_Amount_Per_Payment__c + contrtItemIdPaymentMap.get(psItem.ECM_Contract_Item__c);
                        contrtItemIdPaymentMap.put(psItem.ECM_Contract_Item__c, payment);
                    }
                }else{
					
										
					if(psItem.ECM_Confirmed_Amount_Per_Payment__c != null){
                        contrtItemIdPaymentMap.put(psItem.ECM_Contract_Item__c, psItem.ECM_Confirmed_Amount_Per_Payment__c);
                    }
				}
				
            }
        }
        List<ECM_Payment_Summary_Item__c> createPaymentItems = insertPaymentItems(contractId,contrtItemIdVolumeMap,ps,contrtItemIdPaymentMap);
        /*list<ECM_Contract_Item__c> contractItemList = [SELECT Id, ECM_Contract__c, ECM_Product__c, ECM_Actual_Volume_YTD__c, ECM_UoM__c FROM ECM_Contract_Item__c WHERE ECM_Contract__c =: contractId];
if(contractItemList.size() > 0){
List<ECM_Payment_Summary_Item__c> newPSItemList = new list<ECM_Payment_Summary_Item__c>();
for(ECM_Contract_Item__c ci : contractItemList){
ECM_Payment_Summary_Item__c newPSI = new ECM_Payment_Summary_Item__c();
newPSI.ECM_Payment_Summary__c = pS.Id;
newPSI.ECM_Contract_Item__c = ci.Id;
if(ci.ECM_Actual_Volume_YTD__c == null){
ci.ECM_Actual_Volume_YTD__c = 0;
}
if(ci.ECM_UoM__c == null){
ci.ECM_UoM__c = '0';
}
if(contrtItemIdVolumeMap.containskey(ci.Id)){
newPSI.ECM_Confirmed_Volume__c = ci.ECM_Actual_Volume_YTD__c - contrtItemIdVolumeMap.get(ci.Id);
}
else{
newPSI.ECM_Confirmed_Volume__c = ci.ECM_Actual_Volume_YTD__c;
}
newPSI.ECM_Confirmed_Amount_Per_Payment__c =  newPSI.ECM_Confirmed_Volume__c * decimal.valueOf(ci.ECM_UoM__c);

newPSItemList.add(newPSI);
}
insert newPSItemList;
}*/
        try{
            if(createPaymentItems.size()>0){
                //insert createPaymentItems;
            } 
        }catch(exception ex){
            system.debug('Error While inserting PaymentItems Method createPaymentSummary'+ex);
        }
        
        return pS;
    }
    
     @AuraEnabled
    public static PaymentSummaryWrapper createPaymentSummaryNonVolume(String contractId){
        ECM_Payment_Summary__c pS =new ECM_Payment_Summary__c() ;
        PaymentSummaryWrapper pswrap = new PaymentSummaryWrapper();
 
        try{
            contract contr =  retriveContract(contractId);
            /*pswrap.status = contr.status!='Active'?'':contr.account.Country__r.Name!='Australia'?'':'Active';
            if(pswrap.status==''){
              return pswrap;
            }*/
            pS.ECM_Contract__c=contractId;
            pS.ECM_Type__c='Non-Volume';
            pS.ECM_Payment_Summary_Status__c ='Open';
            insert pS;
            pswrap.PsId = pS.Id;
            return pswrap;
        }catch(Exception ex ){
            system.debug('Error='+ex);
        }
        
        return pswrap;
    }
    public Static List<ECM_Payment_Summary_Item__c> insertPaymentItems(string contractId, Map<Id,Decimal> contrtItemIdVolumeMap, ECM_Payment_Summary__c ps, Map<Id,Decimal> contrtItemIdPaymentMap){
        list<ECM_Payment_Summary_Item__c> newPSItemList = new list<ECM_Payment_Summary_Item__c>();
        List<ECM_Tiering__c>tieringList= new List<ECM_Tiering__c>();
        list<ECM_Contract_Item__c> contractItemList = [SELECT Id, ECM_Contract__c,ECM_Contract__r.account.market__c, ECM_Product__c, ECM_Actual_Volume_YTD__c,ECM_UoM__c,(select id,ECM_Tier_1_rate_per_UoM__c,ECM_Tier_1_volume_limit__c,ECM_Tier2_rate_per_UoM__c,ECM_Tier_2_volume_limit__c,ECM_Tier_3_rate_per_UoM__c,ECM_Tier_3_volume_limit__c from Tierings__r)
                                                       FROM ECM_Contract_Item__c 
                                                       WHERE ECM_Contract__c =: contractId];
        if(contractItemList.size() > 0){
			list<Market_Setting__c>marketSetting= [select id,ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c from Market_Setting__c where Geography__c =:contractItemList[0].ECM_Contract__r.account.market__c ];
			
            //List<ECM_Payment_Summary_Item__c> newPSItemList = new list<ECM_Payment_Summary_Item__c>();
            for(ECM_Contract_Item__c ci : contractItemList){
                ECM_Payment_Summary_Item__c newPSI = new ECM_Payment_Summary_Item__c();
                newPSI.ECM_Payment_Summary__c = ps.Id;
                newPSI.ECM_Contract_Item__c = ci.Id;
                if(ci.ECM_Actual_Volume_YTD__c == null){
                    ci.ECM_Actual_Volume_YTD__c = 0;
                }
                if(ci.ECM_UoM__c == null){
                    ci.ECM_UoM__c = '0';
                }
                if(contrtItemIdVolumeMap!=Null && contrtItemIdVolumeMap.containskey(ci.Id)){
                    newPSI.ECM_Confirmed_Volume__c = ci.ECM_Actual_Volume_YTD__c - contrtItemIdVolumeMap.get(ci.Id);
                }
                else{
                    newPSI.ECM_Confirmed_Volume__c = ci.ECM_Actual_Volume_YTD__c;
                }
				

                tieringList=ci.Tierings__r;
				
				if(!tieringList.isEmpty()){
					Decimal rate_Per_UOM=0.00;
					if(ci.ECM_Actual_Volume_YTD__c<=tieringList[0].ECM_Tier_1_volume_limit__c){
						
						rate_Per_UOM=tieringList[0].ECM_Tier_1_rate_per_UoM__c;
					}else if(ci.ECM_Actual_Volume_YTD__c<=tieringList[0].ECM_Tier_2_volume_limit__c){
						rate_Per_UOM=tieringList[0].ECM_Tier2_rate_per_UoM__c;
					}else if(ci.ECM_Actual_Volume_YTD__c<=tieringList[0].ECM_Tier_3_volume_limit__c){
						rate_Per_UOM=tieringList[0].ECM_Tier_3_rate_per_UoM__c;
					}else{
						if(!marketSetting.isEmpty()){
							if(marketSetting[0].ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c=='Pay at tier 3 rate any exceeding volume (opt.1)'){
								
								rate_Per_UOM=tieringList[0].ECM_Tier_3_rate_per_UoM__c;
								
							}else if(marketSetting[0].ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c=='Pay only per tier 3 volume limit (opt.2)'){
								
								rate_Per_UOM=tieringList[0].ECM_Tier_3_rate_per_UoM__c;
								ci.ECM_Actual_Volume_YTD__c=tieringList[0].ECM_Tier_3_volume_limit__c;
							}
						}
					}
					if(contrtItemIdpaymentMap!=null && contrtItemIdpaymentMap.get(ci.Id)!=null){
						newPSI.ECM_Confirmed_Amount_Per_Payment__c= (ci.ECM_Actual_Volume_YTD__c*rate_Per_UOM)-(contrtItemIdpaymentMap.get(ci.Id));
					}else{
						newPSI.ECM_Confirmed_Amount_Per_Payment__c= (ci.ECM_Actual_Volume_YTD__c*rate_Per_UOM);
					}
					
				}else{
					    newPSI.ECM_Confirmed_Amount_Per_Payment__c =  newPSI.ECM_Confirmed_Volume__c * decimal.valueOf(ci.ECM_UoM__c);
				}
                newPSItemList.add(newPSI);
            }
            //insert newPSItemList;
        }
        return newPSItemList;
    }
    
    @AuraEnabled
    public static ECM_Payment_Summary__c retrivePaymentSummary(String contractId) {
        try{
            ECM_Payment_Summary__c ps = [SELECT Id,Name,ECM_Contract__r.Status FROM ECM_Payment_Summary__c WHERE ECM_Type__c = 'Volume-Based' AND (ECM_Payment_Summary_Status__c='Open' OR ECM_Payment_Summary_Status__c ='In Approval process') AND  ECM_Contract__c =: contractId LIMIT 1 ];
            return ps;
            
        }
        catch(Exception ex){
            system.debug('Exception----'+ex);
            ECM_Payment_Summary__c ps1=New ECM_Payment_Summary__c();
            return ps1;            
        }
        
    }
      @AuraEnabled
    public static Contract retriveContract(String contractId){
        
        try{
            Contract con = [SELECT Id,Status,Account.Country__r.Name FROM Contract WHERE Id =: contractId LIMIT 1];
            return con;
            
        }
        catch(Exception ex){
            system.debug('Exception----'+ex);
            return null;
            
        }
        
    }
    @AuraEnabled
    public static User retriveCurrentUserProfile(){
        
        String userid= userinfo.getUserId();
      //  String userProfileType = [select profile.name,Available_Countries__c from User  where Id=:userid limit 1];
        try{
            User userProfile = [select profile.name,Available_Countries__c from User  where Id=:userid AND (profile.name=:'Sales Representative' OR profile.name=:'CIO User') limit 1];
               return userProfile;  
        }
        catch(Exception ex){
            system.debug('Exception----'+ex);
            return null;
            
        }
        
    }
 
    /*******************************************************************
    Method  : fetchUserDetails
    Purpose : This methods used to validate if logged in user's profile is mentioned in Generate Vol Based PS Enabled Profile 
    ********************************************************************/      
    @AuraEnabled 
    public static boolean fetchUserDetails(){
        Map<String,Boolean>paysumVolumeMapMdt= new Map<String,Boolean>();
        String getAuthProfile = Label.Generate_Vol_based_PS_Enabled_Profile;//These profiles are having access to generate Vol Based PS creation link
        Boolean volumecheck = false;
        
        try{
            User loggedInUser = [SELECT profile.name,Available_Countries__c FROM User  WHERE Id=:UserInfo.getUserId() LIMIT 1];
            for(ECM_Technical_Market_Setting__mdt mdt: [SELECT masterlabel,ECM_Country__c,ECM_Payment_Summary_Volume__c,ECM_Contract_Extra_Approval__c
                                                        FROM ECM_Technical_Market_Setting__mdt 
                                                        WHERE ECM_Payment_Summary_Volume__c=true]){
                paysumVolumeMapMdt.put(mdt.ECM_Country__c,mdt.ECM_Payment_Summary_Volume__c);
            }
            
            if(paysumVolumeMapMdt.containsKey(loggedInUser.Available_Countries__c) && paysumVolumeMapMdt.get(loggedInUser.Available_Countries__c)!=null 
               && getAuthProfile.contains(loggedInUser.profile.name)){ 
               volumecheck= paysumVolumeMapMdt.get(loggedInUser.Available_Countries__c);
            }
            System.debug('@@volumecheck' +volumecheck);
            return volumecheck;
        }
        catch(Exception ex){
            System.debug('Exception----'+ex);
            return null;
            
        }
    }

    public class PaymentSummaryWrapper{
        @AuraEnabled
        public string status{get;set;}
        @AuraEnabled
        public string PsName{get;set;}
        @AuraEnabled
        public string PsId{get;set;}
    }
}