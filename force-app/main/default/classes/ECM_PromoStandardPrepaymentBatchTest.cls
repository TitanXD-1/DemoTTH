/*=======================================================================
Purpose: This is Class for Creating Payment Summaries for Promo Prepayment and non Australian Contracts
Test Class: ECM_BatchPromoPrepaymentPSGenerationBatchTest
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                DATE              DETAIL
1.0      Joshraj Sen             22/12/2023        146153: Provide Coverage for ECM_PromoStandardPSGenerationBatch and ECM_BatchPromoPrePaymentPSGeneration
***********************************************************************/ 
@isTest
public class ECM_PromoStandardPrepaymentBatchTest
{
    @isTest
    public static void testBatch1()
    {
       ECM_BatchPromoPrePaymentPSGeneration batch=new ECM_BatchPromoPrePaymentPSGeneration();
       System.assert(batch!=null,'Created a New Instance of Batch');
       Database.executeBatch(batch,200);
    }
    @isTest
    public static void testBatch2()
    {
       ECM_PromoStandardPSGenerationBatch batch=new ECM_PromoStandardPSGenerationBatch();
       System.assert(batch!=null,'Created a New Instance of Batch');
       Database.executeBatch(batch,200);
    }
    
    
    @testsetup
    public static void createData()
    {
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB'); 
        List<Pick_Up_Options__c> pickUps=ECM_PromoStandardPrepaymentBatchTest.getPickupOptions(geographyId);
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickUps[0].Id; 
        insert outletAccount;
        ECM_Sales_Driver__c sd=new ECM_Sales_Driver__c();
        sd.Geography__c=geographyId;
        sd.Name='Test Sales Driver';
        sd.ECM_Budget_Type__c=pickUps[1].Id;
        sd.ECM_Activation_Spend_Sub_Group__c=pickUps[2].Id;
        sd.RecordTypeId= ECM_Sales_Driver__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Spend').getRecordTypeId();
        insert sd;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.StartDate=System.today()-1;
        objContract.Contract_End_Date__c = System.today();
        insert objContract;
        objContract.Status = 'Active';
        update objContract;
        List<ECM_Payment_Frequency__c> paymentFreqs=ECM_PromoStandardPrepaymentBatchTest.getPaymentFrequencies(geographyId);
        List<ECM_Sales_Driver_Item__c> sdIs=ECM_PromoStandardPrepaymentBatchTest.getSalesDriverItems(objContract.Id,sd.Id,paymentFreqs);        
        Product__c product1=EDGE_UtilityTestClass.getProd();
        insert product1;
        Market_Assortment_Product__c map1=new Market_Assortment_Product__c();
        map1.Product__c=product1.Id;
        map1.Market_Assortment__c=geographyId;
        insert map1;
        List<ECM_Contract_Item__c> cis =ECM_PromoStandardPrepaymentBatchTest.getContractItems(objContract.Id,map1.Id);       
        List <ECM_Sales_Driver_Item_Detail__c> sids=ECM_PromoStandardPrepaymentBatchTest.getSalesDriverItemDetails(sdIs,cis);           
        System.assert(sids.size()==4,'The Size Matches Perfectly');
    }
    public static List<Pick_Up_Options__c> getPickupOptions(String geographyId)
    {
        List<Pick_Up_Options__c> pickUps=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickUps.add(pickupOption); 
        Pick_Up_Options__c pickupOption2 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption2.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        pickupOption2.Name = 'Budget[GB]';
        pickUps.add(pickupOption2);
        Pick_Up_Options__c pickupOption3 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption3.RecordTypeId=Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Spend Sub-Group').getRecordTypeId();
        pickupOption3.Name = 'Brand Marketing A&P[GB]';
        pickUps.add(pickupOption3);
        insert pickUps;
        return pickUps;
    }
    public static List<ECM_Payment_Frequency__c> getPaymentFrequencies(String geographyId)
    {
        List<ECM_Payment_Frequency__c> paymentFreqs=new List<ECM_Payment_Frequency__c>();
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='At the End of the Contract';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        //paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_Prepayment__c=true;
        paymfreq.ECM_Geography__c=geographyId;
        paymentFreqs.add(paymfreq);
         ECM_Payment_Frequency__c paymfreq1 = new ECM_Payment_Frequency__c();
        paymfreq1.ECM_Type__c='Partial Prepayment';
        paymfreq1.ECM_Other_Investment__c=true;
        paymfreq1.ECM_Volume_target__c=true;
        //paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq1.ECM_Prepayment__c=true;
        paymfreq1.ECM_Geography__c=geographyId;
        paymentFreqs.add(paymfreq1);
        Insert paymentFreqs;
        return paymentFreqs;
    }
    
    public static List<ECM_Sales_Driver_Item__c> getSalesDriverItems(String contractId,String salesDriverId,List<ECM_Payment_Frequency__c> paymentFreqs)
    {
        List<ECM_Sales_Driver_Item__c> sdIs=new List<ECM_Sales_Driver_Item__c>();
        ID sdiRecId=ECM_Sales_Driver_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Spend').getRecordTypeId();
        ECM_Sales_Driver_Item__c sdI1 = new ECM_Sales_Driver_Item__c(Contract__c = contractId, ECM_Sales_Driver__c = salesDriverId,ECM_Payment_Frequency__c=paymentFreqs[0].Id, 
                                                                    RecordTypeId = sdiRecId, ECM_Total_Investment_Amount__c = 150);        sdIs.add(sdI1);
        ECM_Sales_Driver_Item__c sdI2 = new ECM_Sales_Driver_Item__c(Contract__c = contractId, ECM_Sales_Driver__c = salesDriverId,ECM_Payment_Frequency__c=paymentFreqs[1].Id,ECM_1st_Prepayment_Date__c=System.today(), 
                                                                      RecordTypeId = sdiRecId, ECM_Total_Investment_Amount__c = 150);        sdIs.add(sdI2);
        insert sdIs;
        return sdIs;
    }
    public static List<ECM_Contract_Item__c> getContractItems(String contractId, String mapId)
    {
        List<ECM_Contract_Item__c> cis =new List<ECM_Contract_Item__c>();
        ECM_Contract_Item__c ci1=new ECM_Contract_Item__c();
        ci1.ECM_Contract__c=contractId;
        ci1.ECM_Product__c=mapId;
        cis.add(ci1);
        ECM_Contract_Item__c ci2=new ECM_Contract_Item__c(); 
        ci2.ECM_Contract__c=contractId; 
        ci2.ECM_Product__c=mapId; 
        cis.add(ci2); 
        ECM_Contract_Item__c ci3=new ECM_Contract_Item__c(); 
        ci3.ECM_Contract__c=contractId; 
        ci3.ECM_Product__c=mapId; 
        cis.add(ci3); 
        ECM_Contract_Item__c ci4=new ECM_Contract_Item__c(); 
        ci4.ECM_Contract__c=contractId; 
        ci4.ECM_Product__c=mapId; 
        cis.add(ci4); 
        insert cis;
        return cis;   
    }
    public static List <ECM_Sales_Driver_Item_Detail__c> getSalesDriverItemDetails(List<ECM_Sales_Driver_Item__c> sdis, List<ECM_Contract_Item__c> cis)
    {
        List <ECM_Sales_Driver_Item_Detail__c> sids=new List<ECM_Sales_Driver_Item_Detail__c>();
        ECM_Sales_Driver_Item_Detail__c sid1=new ECM_Sales_Driver_Item_Detail__c();
        sid1.ECM_Investment_Amount__c=100;
        sid1.ECM_Sales_Driver_Item__c=sdis[0].Id;
        sid1.ECM_Product__c=cis[0].Id;
        sids.add(sid1);
        ECM_Sales_Driver_Item_Detail__c sid2=new ECM_Sales_Driver_Item_Detail__c();
        sid2.ECM_Investment_Amount__c=100;
        sid2.ECM_Sales_Driver_Item__c=sdis[0].Id;
        sid2.ECM_Product__c=cis[1].Id;
        sids.add(sid2);
        ECM_Sales_Driver_Item_Detail__c sid3=new ECM_Sales_Driver_Item_Detail__c();
        sid3.ECM_Investment_Amount__c=100;
        sid3.ECM_Sales_Driver_Item__c=sdis[1].Id;
        sid3.ECM_Product__c=cis[2].Id;
        sids.add(sid3);
        ECM_Sales_Driver_Item_Detail__c sid4=new ECM_Sales_Driver_Item_Detail__c();
        sid4.ECM_Investment_Amount__c=100;
        sid4.ECM_Sales_Driver_Item__c=sdis[1].Id;
        sid4.ECM_Product__c=cis[3].Id;
        sids.add(sid4);
        insert sids;
        return sids;
    }
}