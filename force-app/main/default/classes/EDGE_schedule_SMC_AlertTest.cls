@isTest
public class EDGE_schedule_SMC_AlertTest {
    @isTest
    public static void testschedule() {
    Test.StartTest();
    EDGE_schedule_Send_Market_Cycle_Alert sh1 = new EDGE_schedule_Send_Market_Cycle_Alert();
    String sch = '0 0 23 * * ?'; system.schedule('Test Market Cycle Check', sch, sh1); Test.stopTest(); 
    }

}