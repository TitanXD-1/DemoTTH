/*
Project : DiageoOne
Author: 
Description : callout Mock for  D1_SAPOrderSimulator
*/

@isTest
@SuppressWarnings('PMD.ExcessiveParameterList')
public class D1_SAPOrderSimulatorCalloutMockTest implements WebserviceMock {
    public void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType){
            // start - specify the response you want to send
            D1_OrderSimulationController.DT_SalesOrderSimulate_Header_Response headerResponse = new D1_OrderSimulationController.DT_SalesOrderSimulate_Header_Response();
            headerResponse.PURCH_NO_C = '123456789';
            headerResponse.VALUE = '123456789';
            headerResponse.TAX = '123';
            headerResponse.CURRENCY_x = '123';
            headerResponse.ORDER_DATE = Date.today();
            headerResponse.BELOW_MIN = false;
            headerResponse.ABOVE_MAX = false;
            headerResponse.MESSAGE_VALUE = 'Test';
            headerResponse.OUTSIDE_ATP = false;
            headerResponse.ATP_DAYS = 5;
            
            List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1> itemResponseList = new List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1>();
            D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1 itemResponse =  new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1();
            itemResponse.ITM_NUMBER = '0000012345';
			itemResponse.MATERIAL  = '0000012345';
			itemResponse.MAT_ENTRD = '0000012345';
			itemResponse.TARGET_QTY = '1';
			itemResponse.KBMENG = '1';
			itemResponse.SALES_UNIT = 'CAS';
			itemResponse.PRICE = '0.0';
			itemResponse.TAX = '0.0';
			itemResponse.CURRENCY_x = 'GBP';
			itemResponse.DEPOSIT = 'test string';
			itemResponse.PRICE_ERROR = false;
			itemResponse.QUANTITY_ERROR = false;
			itemResponse.BELOW_MIN = false;
			itemResponse.MESSAGE_VALUE  = 'test string';
			itemResponse.YPRI_VALUE = 15.2;
			itemResponse.ICM3_VALUE  = 15.2;
			itemResponse.IPI3_VALUE = 15.2;
			itemResponse.ZBPI_VALUE = 15.2;
			itemResponse.ZBCF_VALUE = 15.2;
			itemResponse.ICS3_VALUE = 15.2;
			itemResponse.ICMI_VALUE = 15.2;
			itemResponse.ZBNF_VALUE = 15.2;
			itemResponse.YZ51_VALUE = 15.2;
			itemResponse.ZEFI_VALUE = 15.2;
			itemResponse.YMA7_VALUE = 15.2;
			itemResponse.YMA8_VALUE = 15.2;
			itemResponse.ICM3_RATE = 15.2;
			itemResponse.IPI3_RATE = 15.2;
			itemResponse.ZBPI_RATE = 15.2;
			itemResponse.ZBCF_RATE = 15.2;
			itemResponse.ICS3_RATE = 15.2;
			itemResponse.YZ51_RATE = 15.2;
			itemResponse.ZEFI_RATE = 15.2;
			itemResponse.YMA7_RATE = 15.2;
			itemResponse.YMA8_RATE = 15.2;
			itemResponse.YMAX_RATE = 15.2;
			itemResponse.YMIN_RATE = 15.2;
			itemResponse.YMIW_RATE = 15.2;
			itemResponse.YMIV_RATE = 15.2;
			itemResponse.LISTPRICE_UNIT = '0.0';
			itemResponse.UNITARY_REBATE = '0.0';
			itemResponse.COMMERCIAL_DISCOUNT = '0%';
			itemResponse.LOGISTIC_DISCOUNT = '0.0';
			itemResponse.OTHER_DISCOUNT = '0%';
			itemResponse.DISCOUNT_CURRMARK = '0.0';
			itemResponse.SPECIAL_TAXDUTY = '0.0';
			itemResponse.NETVALUE_UNIT = '0.0';
			itemResponse.VAT = '0.0';
            itemResponseList.add(itemResponse);
            
            List<D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response> msgResponseList = new List<D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response>();
            D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response  msgResponse = new D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response();
            msgResponse.TYPE_x = 'Test';
            msgResponse.MESSAGE = 'Test';
            msgResponse.ID = '12345';
            msgResponse.NUMBER_x = '123425';  
            msgResponseList.add(msgResponse);

            D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1 responseX =  new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1();
            responseX.VBELN = 'Test';
            responseX.STATUS = 'Success';
            responseX.HEADER  = headerResponse ;
            responseX.ITEMS  = itemResponseList ;
            responseX.MESSAGES  = msgResponseList;
            response.put('response_x', responseX);
            System.assert(responseX.HEADER != null, 'response not found');
        }
    
}