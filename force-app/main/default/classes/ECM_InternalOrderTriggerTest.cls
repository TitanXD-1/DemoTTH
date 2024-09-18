@isTest
public class ECM_InternalOrderTriggerTest {
@isTest
static void insertIOTest(){
      Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
      Id geographyAUId = EDGE_UtilityTestClass.setupCountry('AU');
    /*  Account acc = EDGE_UtilityTestClass.getOutletRecord();
      insert acc;
      acc.country__c = geographyId; 
      update acc;
      Account acc1 = EDGE_UtilityTestClass.getDistriAccRec();
      insert acc1;
      Contact con = new Contact();
      con.LastName = 'My';
      con.FirstName = 'Test';
      con.Email = 'test@abc.com';
      con.AccountId = acc1.id;
      con.Contact_Type__c = 'Primary';
      insert con;
      Date myDate = Date.newInstance(2020, 5, 17);
  List<Contract> contractlst =new List<Contract>();
      Contract contr = new Contract(Name = 'Test',AccountId = acc.id,Contract_End_Date__c=myDate);
      contractlst.add(contr); 
      Contract contr1 = new Contract(Name = 'Test1',AccountId = acc.id,Contract_End_Date__c=myDate);
      contractlst.add(contr1);
      insert contractlst;  
      AccountContactRelation ACR = new AccountContactRelation();
      ACR.AccountId = acc.id;
      ACR.ContactId = con.id;
      ACR.Contact_Type__c = 'Primary';
      ACR.IsActive = true;
      insert ACR;*/
      Product__c product = new Product__c();
      product.Name='Test';
      product.Product_Full_Name__c = 'Test Product 1 full name';
      product.Country__c=geographyId;
      insert product;
      System.assert(product!=null,'product should not be null');
      Product_UOM__c prdtUOM = new Product_UOM__c();
      prdtUOM.Product__c = product.Id;
      prdtUOM.Conversion_Factor__c = 2;
      prdtUOM.Type__c = 'BTL';
      prdtUOM.Unique_ID__c = product.Id + '_BTL';
      insert prdtUOM;
      Territory_Hierarchy__c territoryHierarchy = EDGE_UtilityTestClass.getterritoryHierarchy(geographyId,'Business Unit');
      insert territoryHierarchy;
      Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
      territory.Business_Unit__c = territoryHierarchy.Id;
      insert territory;
      
      
      Territory_Budget__c territoryBudget = new Territory_Budget__c();
      territoryBudget.ECM_Type__c =  'TI';
      territoryBudget.Territory__c = territory.id;
      territoryBudget.End_Date__c = system.today()+5;
      territoryBudget.Initial_Amount__c = 100.00;
      territoryBudget.Start_Date__c = system.today()+10;
      territoryBudget.ECM_Territory_Hierarchy__c = territoryHierarchy.id;
      insert territoryBudget; 
              
      String bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();

      Pick_Up_Options__c pickOption= new Pick_Up_Options__c();
      pickOption.Name='A&P[ES]';
      pickOption.Geography__c=geographyId;
      pickOption.RecordTypeId=bRecordTypeId;
      Insert pickOption;
      
      ECM_Internal_Order__c ioRecord = new ECM_Internal_Order__c();
      ioRecord.Name = 'IO-123456789';
      ioRecord.ECM_Product__c = product.Id;
      ioRecord.ECM_Budget_Type__c = territoryBudget.Id;
      ioRecord.ECM_Budget_Type_Pickup_Option__c = pickOption.Id;
      ioRecord.ECM_Geography__c = geographyId;
      ioRecord.ECM_Description__c = 'Testing Record';
      ioRecord.ECM_Start_Date__c = Date.newInstance(System.today().year(), 7, 17);
      ioRecord.ECM_End_Date__c = Date.newInstance(System.today().year(), 7, 27);
      ioRecord.RecordTypeId= Schema.SObjectType.ECM_Internal_Order__c.getRecordTypeInfosByName().get('CM Internal Order').getRecordTypeId();
      ioRecord.ECM_Budget_Amount__c = 100;
      insert ioRecord;
              system.debug(LoggingLevel.Debug,'==Before '+ioRecord.ECM_Fiscal_Year__c);
              ioRecord.ECM_Start_Date__c = Date.newInstance(System.today().year()-1, 5, 17);
              ioRecord.ECM_End_Date__c = Date.newInstance(System.today().year(), 8, 17);
      system.debug(LoggingLevel.Debug,'=='+ioRecord.ECM_Fiscal_Year__c);
      update ioRecord;        
      Delete ioRecord;
        ECM_Internal_Order__c ioRecord1 = new ECM_Internal_Order__c();
        ioRecord1.Name = 'IO-123456780';
        ioRecord1.ECM_Product__c = product.Id;
        ioRecord1.ECM_Budget_Type__c = territoryBudget.Id;
        ioRecord1.ECM_Budget_Type_Pickup_Option__c = pickOption.Id;
        ioRecord1.ECM_Geography__c = geographyId;
        ioRecord1.ECM_Description__c = 'Testing Record';
        ioRecord1.ECM_Start_Date__c = Date.newInstance(System.today().year(), 7, 17);
        ioRecord1.ECM_End_Date__c = Date.newInstance(System.today().year()+2, 8, 27);
        ioRecord1.ECM_Budget_Amount__c = 100;
        ioRecord1.RecordTypeId= Schema.SObjectType.ECM_Internal_Order__c.getRecordTypeInfosByName().get('CM Internal Order').getRecordTypeId();
      insert ioRecord1;
      
      ioRecord1.ECM_Geography__c = geographyAUId;
      update ioRecord1;
      ioRecord1.RecordTypeId= Schema.SObjectType.ECM_Internal_Order__c.getRecordTypeInfosByName().get('CM Internal Order').getRecordTypeId();
      update ioRecord1;
  }
}